    def _force_search_node(self, state: AgentState, config: RunnableConfig = None):
        """Executa busca automática no banco de dados com regras estritas de fallback para recepção."""
        query = state["messages"][-1].content.lower()
        db = config["configurable"].get("db") if config else None
        if not db:
            return {"messages": [AIMessage(content="Erro técnico: Banco de dados indisponível.")]}

        # Contexto persistente
        target_medico_id = state.get("active_doctor_id")
        search_type = state.get("last_search_type")

        # 1. PRIORIDADE: PAGAMENTO E CONVÊNIO (Regra de ignorância/recepção)
        if search_type in ["pagamento", "convênio"]:
            pergunta_faq = "Quais as formas de pagamento?" if search_type == "pagamento" else "Quais convênios vocês aceitam?"
            logger.info(f"[Force Search] Buscando FAQ: {pergunta_faq}")
            result = execute_tool("buscar_faq", {"pergunta": pergunta_faq}, db)
            
            # Se não encontrou informação válida, vai para a recepção (Regra de Ouro)
            if not result or "não encontrado" in result.lower() or len(result) < 10:
                logger.warning("[Force Search] Informação de pagamento não encontrada. Fallback para recepção.")
                return {"messages": [AIMessage(content="Desculpe, não encontrei informações detalhadas sobre formas de pagamento ou parcelamento no meu sistema atual. 😅 Por favor, verifique esses detalhes diretamente com nossa recepção ao chegar na clínica! ✨")]}
                
            prefix = "Formas de pagamento oficiais: " if search_type == "pagamento" else "Convênios aceitos: "
            import uuid
            tid = f"faq_{uuid.uuid4().hex[:4]}"
            return {
                "messages": [
                    AIMessage(content="", tool_calls=[{"name": "buscar_faq", "args": {"pergunta": pergunta_faq}, "id": tid}]),
                    ToolMessage(tool_call_id=tid, name="buscar_faq", content=prefix + result)
                ]
            }

        # 2. BUSCA DE DATAS/HORÁRIOS
        if any(k in query for k in ['datas', 'horários', 'horario', 'os dois', 'ambos']):
            import uuid
            # Se não houver médico alvo OU pediu os dois, buscamos de AMBOS
            if not target_medico_id or any(k in query for k in ["os dois", "ambos", "os 2"]):
                logger.info("[Force Search] Buscando horários de TODOS os médicos.")
                res1 = execute_tool("buscar_horarios", {"medico_id": 1}, db) or "Sem horários."
                res2 = execute_tool("buscar_horarios", {"medico_id": 2}, db) or "Sem horários."
                cid1, cid2 = f"c1_{uuid.uuid4().hex[:4]}", f"c2_{uuid.uuid4().hex[:4]}"
                return {
                    "messages": [
                        AIMessage(content="", tool_calls=[
                            {"name": "buscar_horarios", "args": {"medico_id": 1}, "id": cid1},
                            {"name": "buscar_horarios", "args": {"medico_id": 2}, "id": cid2}
                        ]),
                        ToolMessage(tool_call_id=cid1, name="buscar_horarios", content=res1),
                        ToolMessage(tool_call_id=cid2, name="buscar_horarios", content=res2)
                    ]
                }
            else:
                logger.info(f"[Force Search] Buscando HORÁRIOS para médico ID {target_medico_id}")
                result = execute_tool("buscar_horarios", {"medico_id": target_medico_id}, db)
                tid = f"c_{uuid.uuid4().hex[:4]}"
                return {
                    "messages": [
                        AIMessage(content="", tool_calls=[{"name": "buscar_horarios", "args": {"medico_id": target_medico_id}, "id": tid}]),
                        ToolMessage(tool_call_id=tid, name="buscar_horarios", content=result)
                    ]
                }

        # 3. BUSCA DE VALORES
        if search_type == "valor":
            logger.info(f"[Force Search] Buscando VALORES")
            # Se já tem médico ativo, busca dele. Senão, mostra regra geral de recepção.
            if target_medico_id:
                result = execute_tool("buscar_medico", {"nome": state.get("active_doctor_name")}, db)
                if not result or "não encontrado" in result.lower() or len(result) < 5:
                    return {"messages": [AIMessage(content="Não tenho informações exatas sobre os valores deste médico. Por favor, verifique na recepção. ✨")]}
                import uuid
                tid = f"val_{uuid.uuid4().hex[:4]}"
                return {
                    "messages": [
                        AIMessage(content="", tool_calls=[{"name": "buscar_medico", "args": {"nome": state.get("active_doctor_name")}, "id": tid}]),
                        ToolMessage(tool_call_id=tid, name="buscar_medico", content="Valor da consulta: " + result)
                    ]
                }

        # 4. FALLBACK FINAL: RECEPÇÃO (Evita listar médicos por engano)
        logger.info("[Force Search] Nenhuma categoria de busca encontrada ou dados insuficientes. Encaminhando para recepção.")
        return {"messages": [AIMessage(content="Sabe o que é? Não consegui localizar essa informação exata agora. 😅 Mas não se preocupe! Você pode tirar essa dúvida rapidinho com nossa equipe na recepção ao chegar na clínica. ✨")]}
