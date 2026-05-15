# Pitaya Social Network

Rede social acadêmica composta por múltiplos microsserviços Java/Spring Boot com interface web responsiva.

## 📋 Sumário

- [Visão Geral](#-visão-geral)
- [Pré-requisitos](#-pré-requisitos)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Instalação](#-instalação)
- [Configuração](#-configuração)
- [Execução](#-execução)
- [Arquitetura](#-arquitetura)
- [Recursos Futuro (DMs)](#-recursos-futuros-dms)
- [Personalização](#-personalização)
- [Manutenção](#-manutenção)
- [Considerações para Produção](#-considerações-para-produção)
- [Solução de Problemas](#-solução-de-problemas)
- [Licença](#-licença)

## 📖 Visão Geral

O Pitaya Social Network é uma plataforma de rede social projetada especificamente para ambientes acadêmicos. Ele permite que estudantes, pesquisadores e professores:

- Compartilhem publicações e atualizações
- Participem de grupos de estudo e pesquisa
- Acessem uma biblioteca de documentos acadêmicos
- Busquem e ofereçam mentoria
- Ganhem conquistas através de gamificação
- Recebam notificações em tempo real
- Trocar mensagens diretas privadas 

O sistema é construído usando uma arquitetura de microsserviços com:
- **Backend**: Microsserviços Java/Spring Boot
- **Frontend**: Interface web responsiva (HTML5/CSS3/JavaScript)
- **Infraestrutura**: Docker Compose para orquestração
- **Banco de Dados**: PostgreSQL para armazenamento persistente
- **Cache**: Redis para melhoria de desempenho
- **Mensageria**: RabbitMQ para comunicação assíncrona
- **Monitoramento**: Prometheus e Grafana

## 🔧 Pré-requisitos

Antes de iniciar, certifique-se de ter instalado:

| Ferramenta | Versão Mínima | Download |
|------------|---------------|----------|
| Docker | 20.10+ | [docs.docker.com/get-docker/](https://docs.docker.com/get-docker/) |
| Docker Compose | 2.0+ | [docs.docker.com/compose/install/](https://docs.docker.com/compose/install/) |
| Git | Qualquer versão | [git-scm.com/downloads](https://git-scm.com/downloads) |
| Espaço em Disco | 5GB+ | - |

## 📁 Estrutura do Projeto

```
pitaya-social-network/
├── docker-compose.yml              # Orquestração principal
├── docker-compose.dev.yml          # Configuração para desenvolvimento
├── services/                       # Código fonte dos microsserviços
│   ├── auth-service/
│   ├── user-service/
│   ├── post-service/
│   ├── group-service/
│   ├── library-service/
│   ├── mentorship-service/
│   ├── gamification-service/
│   ├── notification-service/
│   ├── discovery-service/
│   ├── config-service/
│   └── gateway-service/
├── frontend/                       # Interface web
│   ├── index.html
│   ├── assets/
│   ├── css/
│   │   ├── components.css
│   │   ├── layout.css
│   │   ├── main.css
│   │   ├── pages/
│   │   │   ├── auth.css
│   │   │   ├── feed.css
│   │   │   ├── groups.css
│   │   │   ├── library.css
│   │   │   ├── mentorship.css
│   │   │   └── profile.css
│   │   ├── reset.css
│   │   ├── responsive.css
│   │   └── themes.css
│   ├── js/
│   │   ├── app.js
│   │   ├── components/
│   │   ├── pages/
│   │   └── services/
│   └── pages/
│       ├── feed.html
│       ├── groups.html
│       ├── library.html
│       ├── login.html
│       ├── mentorship.html
│       └── profile.html
├── docker/                         # Configurações de infraestrutura
│   ├── grafana/
│   ├── postgres/
│   └── prometheus/
└── README.md                       # Este arquivo
```

## 💾 Instalação

### 1. Clone o repositório

```bash
git clone https://github.com/seu-usuario/pitaya-social-network.git
cd pitaya-social-network
```

### 2. Estrutura esperada

Após clonar, você deve ver a estrutura descrita acima. Os serviços já contêm o código-fonte pronto para ser compilado e executado via Docker.

## ⚙️ Configuração

### Variáveis de Ambiente

Crie um arquivo `.env` na raiz do projeto com o seguinte conteúdo:

```bash
# Chaves JWT para autenticação (OBRIGATÓRIO)
# Gere chaves seguras usando o comando abaixo
JWT_PRIVATE_KEY=sua_chave_privada_jwt_aqui
JWT_PUBLIC_KEY=sua_chave_publica_jwt_aqui

```

#### Gerando Chaves JWT Seguras

Execute estes comandos para gerar chaves JWT seguras:

```bash
# Gera chave privada RSA
openssl genpkey -algorithm RSA -out jwt_private_key.pem -pkeyopt rsa_keygen_bits:2048

# Gera chave pública correspondente
openssl rsa -pubout -in jwt_private_key.pem -out jwt_public_key.pem

# Converte para formato base64 necessário
JWT_PRIVATE_KEY=$(cat jwt_private_key.pem | base64 | tr -d '\n')
JWT_PUBLIC_KEY=$(cat jwt_public_key.pem | base64 | tr -d '\n')
```

Cole os valores gerados no seu arquivo `.env`.

> **Importante**: Nunca commit seu arquivo `.env` em repositórios públicos. Ele contém informações sensíveis.

## 🚀 Execução

### Iniciando Todos os Serviços

```bash
# Inicia todos os serviços em segundo plano
docker-compose up -d

# Para ver logs em tempo real de todos os serviços
docker-compose logs -f

# Para ver logs de um serviço específico
docker-compose logs -f [nome-do-servico]
```

### Aguardando a Inicialização

Após executar `docker-compose up -d`, aguarde aproximadamente 2-3 minutos para todos os serviços iniciarem completamente. Você pode verificar o status com:

```bash
docker-compose ps
```

Todos os serviços devem mostrar estado `Up` e `healthy`.

### Acessando a Aplicação

Uma vez que todos os serviços estejam rodando:

| Serviço | URL | Descrição |
|---------|-----|-----------|
| **Interface Web** | http://localhost | Página principal da aplicação |
| **API Gateway** | http://localhost:8080 | Entrada única para todos os serviços |
| **Serviço de Autenticação** | http://localhost:8081 | Gerenciamento de usuários e sessões |
| **Serviço de Usuários** | http://localhost:8082 | Operações de perfil e conexões |
| **Serviço de Posts** | http://localhost:8083 | Criação e gerenciamento de posts |
| **Eureka (Discovery)** | http://localhost:8761 | Painel de descoberta de serviços |
| **Config Server** | http://localhost:8888 | Servidor de configuração centralizada |
| **Prometheus** | http://localhost:9090 | Sistema de monitoramento e alertas |
| **Grafana** | http://localhost:3000 | Dashboards de visualização (usuário: admin, senha: admin) |

### Primeiro Acesso

1. Abra seu navegador e vá para http://localhost
2. Você será redirecionado para a página de login
3. Como ainda não há usuários cadastrados, clique em "Cadastrar"
4. Preencha o formulário com:
   - Nome completo
   - Nome de usuário
   - Email
   - Senha (mínimo 8 caracteres)
5. Após o cadastro, faça login com suas credenciais

### Parando o Sistema

```bash
# Para todos os serviços mantendo os volumes (dados)
docker-compose down

# Para parar e remover todos os volumes (EXCLUI DADOS)
docker-compose down -v
```

> **Atenção**: O comando com `-v` excluirá todos os dados persistentes (usuários, posts, configurações, etc.). Use apenas quando necessário.

## 🏗️ Arquitetura

### Serviços de Backend (Microsserviços)

| Serviço | Porta | Responsabilidade |
|---------|-------|------------------|
| discovery-service | 8761 | Eureka para descoberta de serviços |
| config-service | 8888 | Configuração centralizada (Spring Cloud Config) |
| gateway-service | 8080 | API Gateway (Spring Cloud Gateway) |
| auth-service | 8081 | Autenticação e autorização (OAuth2/JWT) |
| user-service | 8082 | Gerenciamento de usuários, perfis e conexões |
| post-service | 8083 | Criação, leitura, atualização e exclusão de posts |
| group-service | 8084 | Gerenciamento de grupos e comunidades |
| library-service | 8085 | Sistema de biblioteca de documentos acadêmicos |
| mentorship-service | 8086 | Plataforma de mentoria e orientação |
| gamification-service | 8087 | Sistema de conquistas, pontos e níveis |
| notification-service | 8088 | Envio de notificações em tempo real |
| message-service | 8089 | Mensagens diretas (DMs) privadas |

### Infraestrutura

| Componente | Descrição |
|------------|-----------|
| PostgreSQL | Banco de dados relacional principal (um banco por serviço) |
| Redis | Cache distribuído e armazenamento de sessões |
| RabbitMQ | Mensageria assíncrona para comunicação entre serviços |
| Prometheus | Coleta e armazenamento de métricas |
| Grafana | Visualização de métricas e criação de dashboards |

### Frontend

- Interface web responsiva construída com HTML5, CSS3 e JavaScript puro
- Comunica com os serviços através do API Gateway
- Suporte a temas claro/escuro
- Design mobile-first
- Arquitetura baseada em componentes

## 🚀 Mensagens Diretas (DMs) - Em Desenvolvimento

A funcionalidade de Mensagens Diretas (DMs) similar ao Twitter/X está em desenvolvimento. O serviço `message-service` foi criado com a estrutura básica do projeto Spring Boot, incluindo o modelo de dados (entidades Conversation, ConversationParticipant, Message) e o Dockerfile. Além disso, as páginas frontend básicas para lista de conversas e visualização de conversa foram implementadas.

Os recursos atualmente disponíveis incluem:

- Estrutura do serviço de backend com modelo de dados
- Dockerfile para containerização
- Página de lista de conversas (inbox)
- Página de visualização de conversa com interface de chat básica

Os recursos planejados para futuras implementações incluem:

- Implementação completa dos endpoints REST no backend
- Lógica de negócio para criação de conversas, envio de mensagens, etc.
- Suporte a mídia (imagens, GIFs, vídeos)
- Recibos de leitura (entregue, lido)
- Configurações de privacidade (receber mensagens de qualquer pessoa ou apenas de quem segue)
- Integração com notification-service para alertas
- Arquivamento e silenciar conversas
- Funcionalidade de busca dentro de conversas
- Edição e exclusão de mensagens

A documentação detalhada de implementação para este recurso pode ser encontrada em:
`docs/direct-messages/implementation-plan.md`

O serviço está documentado na seção de Arquitetura abaixo (ver mensagem-service na porta 8089). Para executar o serviço em desenvolvimento, seria necessário adicioná-lo ao `docker-compose.yml` ou executá-lo independentemente.

## 🎨 Personalização

### Alterando Portas

Para mudar as portas dos serviços, edite o arquivo `docker-compose.yml`:

```yaml
services:
  auth-service:
    ports:
      - "NOVA_PORTA:8081"  # Formato: "host:container"
```

### Variáveis de Ambiente

Cada serviço aceita variáveis de ambiente configuráveis na seção `environment` do `docker-compose.yml`.

### Escalando Serviços

Para aumentar instâncias de um serviço (útil para carga maior):

```bash
docker-compose up -d --scale user-service=3
```

### Temas do Frontend

Os temas estão definidos em `frontend/css/themes.css`. Para modificar:

1. Edite as variáveis CSS no `:root` seletor
2. Reconstrua se estiver usando um processo de build (atualmente é HTML/CSS/JS puro)

## 🔧 Manutenção

### Atualizando o Código

```bash
# Obter últimas alterações
git pull origin main

# Reconstruir imagens Docker
docker-compose build

# Reiniciar serviços
docker-compose up -d
```

### Fazendo Backup dos Dados

```bash
# Backup do PostgreSQL para auth-service
docker-compose exec auth-service pg_dump -U pitaya pitaya_auth > backup_auth.sql

# Repetir para outros serviços conforme necessário
# user-service, post-service, etc.
```

### Restaurando Backup

```bash
# Restaura auth-service
cat backup_auth.sql | docker-compose exec -T postgres psql -U pitaya pitaya_auth

# Repetir para outros bancos
```

### Verificando Logs

```bash
# Logs em tempo real
docker-compose logs -f

# Logs de serviço específico
docker-compose logs -f user-service

# Últimas 100 linhas
docker-compose logs --tail=100

# Logs desde um horário específico
docker-compose logs --since 1h
```

### Verificando Recursos

```bash
# Uso de CPU, memória, rede, I/O
docker stats

# Inspeção detalhada de um container
docker inspect [container-name]
```

## ☁️ Considerações para Produção

Para ambientes de produção, considere implementar:

### 1. Segurança
- Usar um reverse proxy (NGINX/Traefik) com terminação TLS
- Configurar firewalls adequados
- Implementar rate limiting
- Usar segredos gerenciados (AWS Secrets Manager, HashiCorp Vault, etc.)
- Rotacionar chaves JWT periodicamente

### 2. Monitoring e Alertas
- Configurar alertas no Prometheus/Grafana
- Implementar logging centralizado (ELK Stack, Loki)
- Adicionar health checks customizados
- Monitorar métricas de negócio (usuários ativos, posts por hora, etc.)

### 3. Escalabilidade
- Usar orquestrador (Kubernetes, Docker Swarm)
- Implementar auto-scaling baseado em métricas
- Configurar balanceamento de carga
- Usar CDN para assets estáticos

### 4. Backup e Recuperação de Desastres
- Backups automatizados e regulares do PostgreSQL
- Testar procedimentos de restauração periodicamente
- Implementar estratégia de backup 3-2-1
- Geo-replicação para alta disponibilidade

### 5. Performance
- Configurar pools de conexão adequadamente
- Otimizar consultas de banco de dados
- Implementar caching em múltiplas camadas
- Usar compressão de respostas HTTP
- Otimizar assets do frontend (minificação, bundling)

### 6. Observabilidade
- Distributed tracing (Jaeger, Zipkin)
- Métricas de negócio customizadas
- Logs estruturados (JSON)
- Dashboards de operações em tempo real

## 🐞 Solução de Problemas

### Serviços não estão saudáveis (unhealthy)

| Sintoma | Solução |
|---------|---------|
| Serviço mostrando `unhealthy` no `docker-compose ps` | 1. Verifique logs: `docker-compose logs [servico]`<br>2. Reinicie o serviço: `docker-compose restart [servico]`<br>3. Se persistir: `docker-compose down && docker-compose up -d` |
| Timeout na inicialização | Aumente o `start_period` no healthcheck do serviço afetado |
| Erros de conexão com banco | Verifique se o PostgreSQL está saudável: `docker-compose ps postgres` |

### Porta já em uso

| Sintoma | Solução |
|---------|---------|
| Erro ao iniciar: `Bind for 0.0.0.0:8080 failed: port is already allocated` | 1. Identifique o processo: `sudo lsof -i :8080`<br>2. Pare o processo conflitante ou mude a porta no docker-compose.yml<br>3. Reinicie o Docker se necessário: `sudo systemctl restart docker` |

### Problemas de memória

| Sintoma | Solução |
|---------|---------|
| Containers sendo mortos pelo OOM killer | 1. Reduza os limites de memória no docker-compose.yml<br>2. Monitore com `docker stats`<br>3. Considere aumentar swap do sistema<br>4. Para desenvolvimento, remova serviços não essenciais temporariamente |
| Lentidão geral | Verifique uso de memória e swap com `free -h` |

### Problemas de conexão entre serviços

| Sintoma | Solução |
|---------|---------|
| Serviço A não consegue alcançar Serviço B | 1. Verifique se ambos estão na mesma rede (`pitaya-network`)<br>2. Confirme os nomes de serviço no docker-compose.yml (use nomes de serviço, não localhost)<br>3. Teste conectividade: `docker-compose exec [servico-a] ping [servico-b]` |
| Erros de configuração não carregados | Verifique se o config-service está saudável e acessível |

### Problemas de desempenho no frontend

| Sintoma | Solução |
|---------|---------|
| Página carregando lentamente | 1. Verifique tamanho dos assets<br>2. Ative compressão gzip no nginx (se usando reverse proxy)<br>3. Otimize imagens<br>4. Minifique CSS/JS se aplicável |
| Erros no console do navegador | Verifique se o gateway-service está acessível e respondendo corretamente |

## 📄 Licença

Este projeto está licenciado sob a [Licença MIT](LICENSE).

## 👥 Contribuindo

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 🙏 Agradecimentos

- Equipe Spring Boot pelo excelente framework Java
- Comunidade Docker pela ferramenta de containerização
- Projetos open source utilizados: Eureka, Redis, PostgreSQL, RabbitMQ, Prometheus, Grafana
- Contribuidores da comunidade que ajudaram a melhorar este projeto

---

⚠️ **Aviso de Segurança**: Nunca execute este sistema em ambientes de produção sem implementar as medidas de segurança adequadas descritas na seção [Considerações para Produção](#considerações-para-produção). As credenciais padrão fornecidas são apenas para ambientes de desenvolvimento e teste.