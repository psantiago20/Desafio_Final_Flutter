# OmniConnect — Documentação do Frontend Flutter (Painel do Médico)

> Este documento descreve tudo que foi adicionado ao projeto Flutter, desde a estrutura de arquivos até decisões de design como paleta de cores e tipografia.

---

## Contexto

O app Flutter é exclusivamente voltado para o **médico**. O paciente interage com o sistema pelo WhatsApp (tratado pelo backend via webhooks e RAG). O painel do médico permite login, visualização do dashboard, gerenciamento de consultas e acesso ao perfil.

Nenhum arquivo do backend foi modificado. Toda a adição foi dentro de `frontend/lib/`.

---

## Estrutura de arquivos criada

```
frontend/lib/
├── main.dart
├── app_router.dart
│
├── core/
│   ├── constants/
│   │   └── app_constants.dart
│   ├── network/
│   │   └── api_client.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── utils/
│       └── token_storage.dart
│
├── shared/
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── appointment_model.dart
│   │   └── dashboard_stats_model.dart
│   └── widgets/
│       └── main_shell.dart
│
└── features/
    ├── auth/
    │   ├── data/
    │   │   └── auth_repository.dart
    │   ├── providers/
    │   │   └── auth_provider.dart
    │   └── presentation/
    │       └── screens/
    │           ├── login_screen.dart
    │           └── register_screen.dart
    │
    ├── dashboard/
    │   ├── data/
    │   │   └── dashboard_repository.dart
    │   ├── providers/
    │   │   └── dashboard_provider.dart
    │   └── presentation/
    │       └── screens/
    │           └── dashboard_screen.dart
    │
    ├── appointments/
    │   ├── data/
    │   │   └── appointments_repository.dart
    │   ├── providers/
    │   │   └── appointments_provider.dart
    │   └── presentation/
    │       └── screens/
    │           ├── appointments_screen.dart
    │           ├── appointment_detail_screen.dart
    │           └── new_appointment_screen.dart
    │
    └── profile/
        └── presentation/
            └── screens/
                └── profile_screen.dart
```

**Total: 23 arquivos Dart criados do zero.**

---

## Arquitetura adotada

O projeto segue o padrão **Feature-First** com separação interna por responsabilidade:

| Camada | Pasta | Responsabilidade |
|---|---|---|
| Dados | `data/` | Chamadas HTTP à API |
| Estado | `providers/` | Lógica e estado com Riverpod |
| Interface | `presentation/` | Telas e widgets visuais |

Essa separação garante que cada camada pode ser alterada sem impactar as outras. Por exemplo, trocar a URL da API afeta apenas `data/`, sem tocar em nenhuma tela.

---

## Descrição detalhada de cada arquivo

### `main.dart`
Ponto de entrada do app. Inicializa a localização `pt_BR` (para datas e moedas em português), envolve o app em `ProviderScope` do Riverpod e conecta o router ao `MaterialApp.router`.

### `app_router.dart`
Configura toda a navegação usando `go_router`. Tem dois mecanismos principais:

- **Redirecionamento de proteção**: se o médico não está logado e tenta acessar qualquer rota interna, é redirecionado para `/login`. Se já está logado e vai para `/login`, é redirecionado para `/dashboard`.
- **ShellRoute**: as rotas principais (dashboard, consultas, perfil) são envolvidas por um shell que exibe a barra de navegação inferior. Rotas secundárias (detalhe de consulta, nova consulta) ficam fora do shell e não mostram a barra.

| Rota | Tela |
|---|---|
| `/login` | Tela de login |
| `/register` | Tela de cadastro |
| `/dashboard` | Dashboard principal |
| `/appointments` | Lista de consultas |
| `/appointments/new` | Nova consulta |
| `/appointments/:id` | Detalhe de uma consulta |
| `/profile` | Perfil do médico |

---

### `core/constants/app_constants.dart`
Centraliza todas as URLs dos endpoints do backend. O IP `10.0.2.2` é o endereço padrão para acessar o `localhost` da máquina host a partir do emulador Android. Para dispositivo físico, basta trocar o IP aqui.

```dart
static const String baseUrl = 'http://10.0.2.2:8000';
```

---

### `core/network/api_client.dart`
Cliente HTTP estático que serve de base para toda comunicação com a API. Responsabilidades:

- Injeta automaticamente o header `Authorization: Bearer <token>` em todas as requisições após o login
- Disponibiliza métodos `get`, `post`, `put`, `patch` e `delete`
- Trata respostas com status `2xx` como sucesso e converte qualquer outro status em `ApiException` com código e mensagem legíveis
- Captura `SocketException` (sem conexão) e transforma em mensagem amigável em português

---

### `core/theme/app_theme.dart`
Define a identidade visual completa do app. Detalhado na seção de design abaixo.

---

### `core/utils/token_storage.dart`
Armazena o token JWT e os dados do usuário em memória durante a sessão. Simples e funcional para o escopo atual. Em produção, recomenda-se substituir por `flutter_secure_storage` para persistir o token entre sessões (evitando que o médico precise fazer login toda vez que fechar o app).

---

### `shared/models/user_model.dart`
Representa o usuário logado. Mapeado diretamente do schema `UserResponse` do backend. Getters úteis:

- `displayName` — retorna o nome completo ou o username caso não haja nome
- `isDoctor` — verifica se `role == 'doctor'`
- `isAdmin` — verifica se `role == 'admin'`

---

### `shared/models/appointment_model.dart`
Representa uma consulta. Mapeado do schema `AppointmentResponse`. Inclui método `copyWith` para atualizar campos específicos sem recriar o objeto inteiro, útil ao atualizar status ou anotações sem recarregar tudo da API.

---

### `shared/models/dashboard_stats_model.dart`
Representa o retorno completo do endpoint `/api/dashboard/stats`, incluindo contadores de pacientes, consultas por status, mensagens não lidas, receitas diária/semanal/mensal e taxa de não comparecimento.

---

### `shared/widgets/main_shell.dart`
Wrapper que envolve as telas principais e renderiza a barra de navegação inferior com três abas: Dashboard, Consultas e Perfil. Detecta a rota ativa automaticamente pelo `GoRouterState`, sem necessidade de gerenciar índice manualmente.

---

### `features/auth/data/auth_repository.dart`
Faz as chamadas reais de autenticação:

- **Login**: chama `/api/auth/login`, salva o token, injeta no `ApiClient` e já busca os dados do usuário em `/api/auth/me`
- **Cadastro**: registra com `role: "doctor"` fixo e chama o login automaticamente em seguida
- **Logout**: limpa o token do `ApiClient` e do `TokenStorage`

---

### `features/auth/providers/auth_provider.dart`
Gerencia o estado de autenticação com `StateNotifier`. O estado `AuthState` contém o usuário logado (ou `null`), um booleano de carregamento e uma mensagem de erro opcional. Qualquer widget do app pode observar `ref.watch(authProvider)` para saber se há usuário logado e quem é.

---

### `features/auth/presentation/screens/login_screen.dart`
Tela de login com:

- Campos de usuário e senha com validação
- Botão de mostrar/ocultar senha
- Indicador de carregamento no botão durante a requisição
- Exibição de erros vindos da API em um card vermelho
- Link para a tela de cadastro

---

### `features/auth/presentation/screens/register_screen.dart`
Tela de cadastro com:

- Campos de nome completo, e-mail, usuário, senha e confirmação de senha
- `role: "doctor"` definido automaticamente, sem o usuário precisar escolher
- Após cadastro bem-sucedido, faz login automático e redireciona para o dashboard

---

### `features/dashboard/data/dashboard_repository.dart`
Chama os três endpoints do dashboard:

- `/api/dashboard/stats` — estatísticas gerais
- `/api/dashboard/appointments/today` — consultas do dia atual
- `/api/dashboard/appointments/upcoming` — próximas consultas pendentes

---

### `features/dashboard/providers/dashboard_provider.dart`
Usa `FutureProvider.autoDispose`, que carrega os dados automaticamente quando a tela abre e libera memória ao sair. O `autoDispose` também permite `ref.invalidate()` para forçar recarregamento no pull-to-refresh.

---

### `features/dashboard/presentation/screens/dashboard_screen.dart`
Tela principal com:

- `SliverAppBar` que colapsa ao rolar, mostrando saudação com o primeiro nome do médico e a data em português
- Grid 2x2 de cards de estatísticas (total de pacientes, consultas pendentes, concluídas e receita do dia)
- Lista de consultas do dia com badge de status colorido
- Pull-to-refresh que recarrega tanto as estatísticas quanto as consultas
- Tratamento dos três estados em cada seção: carregando (shimmer), erro com botão de retry, e dados

---

### `features/appointments/data/appointments_repository.dart`
Implementa todo o CRUD de consultas mapeado aos endpoints do backend:

| Método | Endpoint | Ação |
|---|---|---|
| GET | `/api/appointments` | Listar com filtros opcionais |
| GET | `/api/appointments/:id` | Buscar por ID |
| POST | `/api/appointments` | Criar nova consulta |
| PATCH | `/api/appointments/:id/status` | Atualizar apenas o status |
| PUT | `/api/appointments/:id` | Atualizar campos (anotações) |
| DELETE | `/api/appointments/:id` | Deletar consulta |

---

### `features/appointments/providers/appointments_provider.dart`
Composto por três partes:

- `AppointmentFilters` — objeto imutável com os filtros ativos (status, data, doctor_id)
- `appointmentsListProvider` — `FutureProvider` que observa os filtros e recarrega automaticamente quando eles mudam
- `AppointmentActionsNotifier` — `StateNotifier` para ações de escrita (atualizar status, salvar anotações, deletar) com controle de loading e erro

---

### `features/appointments/presentation/screens/appointments_screen.dart`
Lista de consultas com:

- Chips horizontais de filtro por status (Todos, Pendente, Confirmado, Em Andamento, Concluído, Cancelado)
- Ao tocar em um chip, a lista recarrega automaticamente sem ação adicional
- Cada item mostra a data em destaque visual, horário, duração, tipo e badge de status colorido
- Pull-to-refresh
- Botão `+` no AppBar para criar nova consulta

---

### `features/appointments/presentation/screens/appointment_detail_screen.dart`
Tela de detalhe com:

- Card de cabeçalho com dados gerais da consulta (paciente, tipo, data, duração, motivo, valor e status de pagamento)
- Botões de ação de status que seguem o **fluxo real do backend**:
  - `pending` → pode ir para `confirmed` ou `cancelled`
  - `confirmed` → pode ir para `in_progress` ou `no_show`
  - `in_progress` → pode ir para `completed`
  - `completed` / `cancelled` → sem ações disponíveis
- Três campos de anotações clínicas (sintomas, diagnóstico, prescrição) bloqueados por padrão, ativados pelo botão de edição no AppBar para evitar alterações acidentais
- Após salvar, invalida o provider de lista para sincronizar

---

### `features/appointments/presentation/screens/new_appointment_screen.dart`
Formulário de nova consulta com:

- Campo de ID do paciente
- Seletor de data (DatePicker nativo do Flutter)
- Seletor de hora (TimePicker nativo)
- Chips de tipo de consulta (Consulta, Retorno, Exame, Procedimento, Acompanhamento)
- Chips de duração (15, 30, 45, 60, 90 minutos)
- Campo de motivo (opcional)
- Campo de valor
- O ID do médico é preenchido automaticamente do usuário logado

---

### `features/profile/presentation/screens/profile_screen.dart`
Tela de perfil com:

- Avatar com inicial do nome sobre fundo verde
- Badge do papel do usuário em português
- Card com informações da conta (usuário, e-mail, data de cadastro, status)
- Atalhos para Dashboard e Consultas
- Botão de logout que limpa o estado e redireciona para login

---

## Design

### Paleta de cores

| Nome | Hex | Uso |
|---|---|---|
| `primary` | `#1A6B5A` | Cor principal — botões, ícones ativos, destaques |
| `primaryLight` | `#2E9E82` | Variação mais clara do primário |
| `primaryDark` | `#0F4A3E` | Variação mais escura para contraste |
| `background` | `#F5F7F6` | Fundo geral de todas as telas |
| `surface` | `#FFFFFF` | Fundo de cards e componentes elevados |
| `surfaceVariant` | `#EDF2F0` | Fundo de campos de input |
| `textPrimary` | `#1C2B27` | Texto principal — títulos e conteúdo |
| `textSecondary` | `#5A7068` | Texto secundário — labels e descrições |
| `textHint` | `#9BB5AE` | Placeholders e ícones desativados |
| `border` | `#DDE8E4` | Bordas de cards e inputs |
| `divider` | `#EDF2F0` | Linhas divisórias |

#### Cores de status de consulta

| Status | Hex | Rótulo em português |
|---|---|---|
| `pending` | `#F59E0B` (âmbar) | Pendente |
| `confirmed` | `#3B82F6` (azul) | Confirmado |
| `completed` | `#10B981` (verde) | Concluído |
| `cancelled` | `#EF4444` (vermelho) | Cancelado |
| `in_progress` | `#8B5CF6` (roxo) | Em Andamento |

### Tipografia

Duas famílias do Google Fonts combinadas:

| Família | Uso | Característica |
|---|---|---|
| **DM Serif Display** | Títulos, AppBar, saudações | Serifada, elegante, dá personalidade |
| **DM Sans** | Todo o resto — corpo, labels, botões | Sans-serif, limpa, boa legibilidade |

### Componentes visuais

- **Cards**: cantos arredondados de `16px`, sem elevação, com borda sutil `#DDE8E4`
- **Botões primários**: fundo `#1A6B5A`, texto branco, cantos `12px`, sem elevação
- **Inputs**: fundo `#EDF2F0`, borda ativa em `#1A6B5A` com `1.5px`
- **Badges de status**: fundo com `12% de opacidade` da cor do status, texto na cor cheia — cria contraste sem peso visual
- **Barra de navegação inferior**: fundo branco, ícone ativo em `#1A6B5A`, sem elevação, com borda superior sutil

---

## Dependências utilizadas

Todas já estavam declaradas no `pubspec.yaml` original — nenhuma nova dependência foi adicionada.

| Pacote | Versão | Uso |
|---|---|---|
| `go_router` | `^14.0.0` | Navegação declarativa com proteção de rotas |
| `flutter_riverpod` | `^2.5.1` | Gerenciamento de estado |
| `http` | `^1.2.1` | Requisições HTTP à API |
| `google_fonts` | `^6.2.1` | DM Sans e DM Serif Display |
| `intl` | `^0.19.0` | Formatação de datas e moedas em `pt_BR` |

---

## Como rodar

```bash
cd frontend
flutter pub get
flutter run
```

> Para dispositivo físico, troque o IP em `lib/core/constants/app_constants.dart`:
> ```dart
> static const String baseUrl = 'http://SEU_IP_LOCAL:8000';
> ```
