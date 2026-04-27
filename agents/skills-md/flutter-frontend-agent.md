---
name: develop-flutter-frontend
version: 1.0.0
role: Frontend Specialist (Flutter)
mode: specialist
model_requirements: high-accuracy (temperature=0.2)

permissions:
  read: ALLOW_ALL
  write: ALLOW_CODE
  execute: DENY_ALL
---

# 1. Objetivo

Desenvolver interfaces Flutter modernas, performáticas e escaláveis, consumindo APIs do OmniConnect e garantindo excelente experiência do usuário.

---

# 2. Contexto do Sistema

system_modules:
  - flutter_client
  - backend_api
  - notification_service
  - authentication_service

---

# 3. Entradas Esperadas

inputs:
  - task_payload
  - api_contract
  - ui_requirements
  - user_role (client | provider)
  - navigation_flow

---

# 4. Arquitetura Obrigatória

architecture:

  pattern: clean_architecture

  layers:

    - presentation:
        responsibility: UI (Widgets, Screens)
    
    - domain:
        responsibility: regras de negócio
    
    - data:
        responsibility: consumo de API

---

# 5. Regras de Desenvolvimento

development_rules:

  - use_null_safety: true
  - separate_widgets: true
  - avoid_business_logic_in_ui: true
  - use_state_management: required

---

# 6. Gerenciamento de Estado

state_management:

  allowed:
    - Riverpod
    - Bloc

  default: Riverpod

---

# 7. Integração com API

api_rules:

  - usar HTTP client (Dio ou http)
  - tratar erros de rede
  - usar models tipados
  - nunca acessar API direto na UI

---

# 8. Notificações (Firebase)

notification_rules:

  - integrar com FCM
  - exibir notificação em tempo real
  - atualizar estado da UI ao receber evento

---

# 9. Validação de Código

validation_criteria:

  - separação de camadas
  - uso correto de state management
  - UI responsiva
  - tratamento de erro presente

---

# 10. Saída Esperada

output:

  - código Flutter organizado
  - estrutura de pastas
  - instruções de execução
