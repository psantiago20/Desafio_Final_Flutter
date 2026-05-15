# Plano de Implementação: Mensagens Diretas (DMs)

## Visão Geral
Este documento descreve a implementação de um sistema de Mensagens Diretas (DMs) semelhante ao recurso do Twitter/X, permitindo comunicação privada entre usuários da plataforma Pitaya Social Network.

## Escopo
- Conversas privadas 1:1 e em grupo (até 256 participantes)
- Envio de texto, imagens, GIFs e vídeos
- Recibos de leitura (entregue, lido)
- Configurações de privacidade (receber mensagens de qualquer pessoa ou apenas de quem segue)
- Integração com notification-service para alertas
- Arquivamento e silenciar conversas
- Frontend responsivo com interface de chat

## Arquitetura

### Microserviço: message-service
- **Tecnologia**: Java 21, Spring Boot 3.x
- **Banco de Dados**: PostgreSQL (schema separado ou novo banco)
- **Comunicação**: RESTful API, possível WebSocket para atualizações em tempo real (futuro)
- **Integração**: 
  - auth-service (validação de JWT)
  - user-service (dados de perfil)
  - notification-service (alertas de nova mensagem)
  - (opcional) storage-service para mídia

### Modelos de Dados Principais
```
Conversation
- id (UUID)
- type (PRIVATE, GROUP)
- name (para grupos)
- createdAt
- updatedAt
- createdBy (userId)

ConversationParticipant
- id
- conversationId
- userId
- joinedAt
- isAdmin (para grupos)
- lastReadAt
- notificationSetting (ALL, MENTIONS, NONE)

Message
- id (UUID)
- conversationId
- senderId
- content (texto)
- mediaType (TEXT, IMAGE, GIF, VIDEO, FILE)
- mediaUrl (referência ao storage)
- createdAt
- editedAt
- isEdited
- status (SENT, DELIVERED, READ)

MessageReadReceipt (opcional, pode ser derivado de lastReadAt)
- messageId
- userId
- readAt
```

### Endpoints API REST
```
POST   /conversations                 // Criar nova conversa
GET    /conversations                 // Listar conversas do usuário
GET    /conversations/{id}            // Obter detalhes da conversa
GET    /conversations/{id}/messages   // Paginar mensagens
POST   /conversations/{id}/messages   // Enviar mensagem
PUT    /messages/{id}/read            // Marcar como lida
DELETE /conversations/{id}            // Sair/excluir conversa
POST   /conversations/{id}/participants // Adicionar participante (grupo)
DELETE /conversations/{id}/participants/{userId} // Remover
PUT    /conversations/{id}/settings   // Atualizar nome/foto do grupo
POST   /messages/{id}/media           // Upload de mídia (separado ou dentro de POST message)
```

### Frontend
- **pages/messages.html**: Lista de conversas (inbox)
- **pages/conversation.html**: Visualização de uma conversa específica (pode ser modal ou página)
- Componentes reutilizáveis: MessageBubble, MediaPreview, ConversationListItem
- Estilos em `frontend/css/pages/messages.css` e `conversation.css`
- Lógica em `frontend/js/pages/MessagesPage.js` e `ConversationPage.js`

### Segurança
- Todos os endpoints protegidos por JWT (auth-service)
- Apenas participantes de uma conversa podem acessar suas mensagens
- Validação de permissão em cada endpoint
- Limites de taxa para prevenção de spam
- Sanitização de conteúdo (prevenção XSS)

### Considerações de Performance
- Paginação de mensagens (cursor-based ou offset-limit)
- Índices nos campos: conversationId, createdAt, senderId
- Possível uso de caches (Redis) para listas de conversas recentes
- WebSocket opcional para atualizações em tempo real (fase 2)

### Estratégia de Implementação (Fases)

#### Fase 1: MVP Básico
- [ ] Criar microserviço message-service com estrutura Spring Boot
- [ ] Definir entidades Conversation, ConversationParticipant, Message
- [ ] Implementar repositórios JPA
- [ ] Criar API REST para:
    - Criar conversa 1:1
    - Listar conversas
    - Enviar/mensagens de texto apenas
    - Marcar como lida
- [ ] Criar frontend:
    - Página de inbox (lista de conversas)
    - Página de conversa (chat simples com texto)
    - Botão para nova conversa
- [ ] Integrar com auth-service para obtenção do usuário atual
- [ ] Testes básicos de integração

#### Fase 2: Grupo e Mídia
- [ ] Suporte a conversas em grupo (criação, adição/remoção)
- [ ] Upload e exibição de imagens
- [ ] Suporte a GIFs (via URL ou upload)
- [ ] Atualizar frontend para anexar mídia
- [ ] Indicadores de upload/download

#### Fase 3: Recursos Avançados
- [ ] Recibos de leitura detalhados (entregue, lido)
- [ ] Configurações de privacidade (receber de todos vs apenas seguidos)
- [ ] Arquivar e silenciar conversas
- [ ] Busca dentro de conversas
- [ ] Edição e exclusão de mensagens
- [ ] Notificações em tempo real via WebSocket ou polling otimizado
- [ ] Integração com notification-service para push notifications
- [ ] Limites de tamanho e tipo de mídia

#### Fase 4: Otimizações e Polimento
- [ ] Testes de carga e otimização de consultas
- [ ] Melhorias de UI/UX (animações, indicadores de digitação)
- [ ] Suporte a múltiplos idiomas (i18n)
- [ ] Documentação de API (Swagger/OpenAPI)
- [ ] Testes de unidade e integração abrangentes
- [ ] Revisão de segurança

## Dependências
- Nenhuma nova dependência externa além do stack atual (PostgreSQL, Redis opcional para cache)
- Possível necessidade de serviço de storage para mídia (pode usar volume compartilhado ou serviço separado)

## Riscos e Mitigações
| Risco | Probabilidade | Impacto | Mitigação |
|-------|---------------|---------|-----------|
| Sobrecarga de banco devido a volume de mensagens | Médio | Alto | Particionamento por usuário, arquivamento, limites de retenção |
| Latência na entrega de mensagens | Médio | Médio | Implementar caching de listas, considerar WebSocket futuro |
| Complexidade de privacidade em grupos | Baixo | Médio | Regras claras de negócio, testes de autorização |
| Incompatibilidade com serviços existentes | Baixo | Alto | Manter contratos de API estáveis, versionamento se necessário |

## Cronograma Estimado (por fase)
- Fase 1: 2 semanas
- Fase 2: 1.5 semanas
- Fase 3: 2 semanas
- Fase 4: 1 semana

Total aproximado: 6.5 semanas de desenvolvimento.

## Próximos Passos Imediatos
1. Criar diretório do serviço: `services/message-service`
2. Adicionar módulo ao pom.xml raiz (se existir)
3. Criar documentação detalhada de API (OpenAPI)
4. Implementar Fase 1 conforme acima

---
*Este plano está sujeito a ajustes conforme feedback e descobertas durante o desenvolvimento.*