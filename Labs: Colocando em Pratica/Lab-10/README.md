## Lab 03: Variáveis de Repositório e Ambiente

### Objetivo

Neste lab você vai aprender a trabalhar com **variáveis de repositório** (acessíveis em todos os workflows) e **variáveis de ambiente específicas** (configuradas por environment como dev, staging e production). Você vai entender a ordem de precedência (variáveis de ambiente sobrescrevem variáveis de repositório) e casos de uso práticos para cada tipo, simulando um cenário real de deploy em múltiplos ambientes.

---

### 1. Criar estrutura local

```bash
# Crie o diretório base e acesse-o
mkdir lab-03-variaveis-repo-env
cd lab-03-variaveis-repo-env
```

---

### 2. Criar repositório no GitHub

1. Acesse [https://github.com](https://github.com)
2. Clique em **New Repository**
3. Nome: `lab-03-variaveis-repo-env`
4. Deixe **sem README**, **sem .gitignore**, **sem license** (vamos configurar localmente)

---

### 3. Inicializar Git e conectar com repositório remoto

```bash
git init
git remote add origin https://github.com/SEU_USUARIO/lab-03-variaveis-repo-env.git
echo "# lab-03-variaveis-repo-env" > README.md
git add .
git commit -m "first commit"
git push -u origin main
```

---

### 4. Criar estrutura do GitHub Actions

```bash
mkdir -p .github/workflows
```

---

### 5. Criar o workflow principal

Crie o arquivo `.github/workflows/deploy-ambientes.yml` com o conteúdo abaixo:

```yaml
name: Deploy Multi-Ambientes

on:
  workflow_dispatch:  # Permite execução manual para testar cada ambiente

jobs:
  # Job 1: Mostra as variáveis de repositório (compartilhadas)
  mostrar-variaveis-repositorio:
    runs-on: ubuntu-latest
    steps:
      - name: Exibir variáveis de repositório
        run: |
          echo "=== VARIÁVEIS DE REPOSITÓRIO ==="
          echo "Aplicação: ${{ vars.APP_NAME }}"
          echo "Região: ${{ vars.DEFAULT_REGION }}"
          echo "Timeout padrão: ${{ vars.DEFAULT_TIMEOUT }}"
          echo "Versão do Node: ${{ vars.NODE_VERSION }}"

  # Job 2: Deploy em Desenvolvimento
  deploy-dev:
    runs-on: ubuntu-latest
    environment: dev  # Usa o environment "dev"
    steps:
      - name: Configurar ambiente DEV
        run: |
          echo "=== DEPLOY EM DESENVOLVIMENTO ==="
          echo "Aplicação: ${{ vars.APP_NAME }}"
          echo "Ambiente: ${{ vars.ENVIRONMENT }}"
          echo "API URL: ${{ vars.API_URL }}"
          echo "Database: ${{ vars.DATABASE_NAME }}"
          echo "Região: ${{ vars.DEFAULT_REGION }}"
          echo "Debug Mode: ${{ vars.DEBUG_MODE }}"
          echo "Max Connections: ${{ vars.MAX_CONNECTIONS }}"

      - name: Simular build para DEV
        run: |
          echo "Compilando aplicação para ${{ vars.ENVIRONMENT }}..."
          echo "URL de destino: ${{ vars.API_URL }}"
          sleep 2
          echo "Build concluído para DEV"

  # Job 3: Deploy em Staging
  deploy-staging:
    runs-on: ubuntu-latest
    environment: staging  # Usa o environment "staging"
    needs: deploy-dev     # Só executa após deploy-dev
    steps:
      - name: Configurar ambiente STAGING
        run: |
          echo "=== DEPLOY EM STAGING ==="
          echo "Aplicação: ${{ vars.APP_NAME }}"
          echo "Ambiente: ${{ vars.ENVIRONMENT }}"
          echo "API URL: ${{ vars.API_URL }}"
          echo "Database: ${{ vars.DATABASE_NAME }}"
          echo "Região: ${{ vars.DEFAULT_REGION }}"
          echo "Debug Mode: ${{ vars.DEBUG_MODE }}"
          echo "Max Connections: ${{ vars.MAX_CONNECTIONS }}"

      - name: Simular testes de integração
        run: |
          echo "Executando testes em ${{ vars.ENVIRONMENT }}..."
          echo "Endpoint: ${{ vars.API_URL }}/health"
          sleep 2
          echo "Testes aprovados em STAGING"

  # Job 4: Deploy em Produção
  deploy-production:
    runs-on: ubuntu-latest
    environment: production  # Usa o environment "production"
    needs: deploy-staging    # Só executa após deploy-staging
    steps:
      - name: Configurar ambiente PRODUCTION
        run: |
          echo "=== DEPLOY EM PRODUÇÃO ==="
          echo "Aplicação: ${{ vars.APP_NAME }}"
          echo "Ambiente: ${{ vars.ENVIRONMENT }}"
          echo "API URL: ${{ vars.API_URL }}"
          echo "Database: ${{ vars.DATABASE_NAME }}"
          echo "Região: ${{ vars.DEFAULT_REGION }}"
          echo "Debug Mode: ${{ vars.DEBUG_MODE }}"
          echo "Max Connections: ${{ vars.MAX_CONNECTIONS }}"

      - name: Deploy em produção
        run: |
          echo "Realizando deploy em ${{ vars.ENVIRONMENT }}..."
          echo "URL pública: ${{ vars.API_URL }}"
          sleep 3
          echo "Deploy em PRODUÇÃO concluído com sucesso!"

      - name: Notificar equipe
        run: |
          echo "Enviando notificação de deploy para ${{ vars.API_URL }}"
          echo "Versão implantada: ${{ vars.APP_NAME }} em ${{ vars.ENVIRONMENT }}"
```

---

### 6. Subir alterações para o GitHub

```bash
git add .
git commit -m "add workflow com variáveis de repositório e ambientes"
git push
```

---

### 7. Verificar resultado

#### Passo 1: Criar as Variáveis de Repositório

Antes de executar o workflow, você precisa criar as variáveis de repositório que são compartilhadas entre todos os ambientes:

1. Acesse o repositório no GitHub
2. Vá em **Settings** → **Secrets and variables** → **Actions**
3. Clique na aba **Variables** (não Secrets)
4. Clique em **New repository variable**
5. Crie as seguintes variáveis:

| Nome da Variável | Valor Exemplo |
|------------------|---------------|
| `APP_NAME` | `MeuApp` |
| `DEFAULT_REGION` | `us-east-1` |
| `DEFAULT_TIMEOUT` | `30` |
| `NODE_VERSION` | `18.x` |

**Importante:** Variáveis de repositório são acessíveis em todos os workflows e jobs, mas podem ser sobrescritas por variáveis de ambiente específicas.

---

#### Passo 2: Criar os Environments e suas Variáveis

Agora você vai criar três ambientes (dev, staging, production) e definir variáveis específicas para cada um:

##### **Environment: dev**

1. Vá em **Settings** → **Environments**
2. Clique em **New environment**
3. Nome: `dev`
4. Clique em **Configure environment**
5. Na seção **Environment variables**, clique em **Add variable**
6. Crie as seguintes variáveis para DEV:

| Nome da Variável | Valor para DEV |
|------------------|----------------|
| `ENVIRONMENT` | `development` |
| `API_URL` | `https://dev-api.meuapp.com` |
| `DATABASE_NAME` | `meuapp_dev` |
| `DEBUG_MODE` | `true` |
| `MAX_CONNECTIONS` | `10` |

---

##### **Environment: staging**

1. Vá em **Settings** → **Environments**
2. Clique em **New environment**
3. Nome: `staging`
4. Clique em **Configure environment**
5. (Opcional) Ative **Required reviewers** para simular aprovação antes do deploy
6. Na seção **Environment variables**, adicione:

| Nome da Variável | Valor para STAGING |
|------------------|---------------------|
| `ENVIRONMENT` | `staging` |
| `API_URL` | `https://staging-api.meuapp.com` |
| `DATABASE_NAME` | `meuapp_staging` |
| `DEBUG_MODE` | `false` |
| `MAX_CONNECTIONS` | `50` |

---

##### **Environment: production**

1. Vá em **Settings** → **Environments**
2. Clique em **New environment**
3. Nome: `production`
4. Clique em **Configure environment**
5. (Recomendado) Ative **Required reviewers** para proteger produção
6. (Opcional) Configure **Deployment branches** para aceitar apenas `main`
7. Na seção **Environment variables**, adicione:

| Nome da Variável | Valor para PRODUCTION |
|------------------|-----------------------|
| `ENVIRONMENT` | `production` |
| `API_URL` | `https://api.meuapp.com` |
| `DATABASE_NAME` | `meuapp_prod` |
| `DEBUG_MODE` | `false` |
| `MAX_CONNECTIONS` | `200` |

---

#### Passo 3: Executar o Workflow

1. Vá na aba **Actions**
2. Selecione o workflow **Deploy Multi-Ambientes**
3. Clique em **Run workflow** → **Run workflow**
4. Aguarde a execução

---

#### Passo 4: Analisar os Resultados

Verifique os logs de cada job:

- **Job 1 (mostrar-variaveis-repositorio):** Exibe apenas as variáveis de repositório
- **Job 2 (deploy-dev):** Mostra as variáveis de DEV (sobrescrevendo as de repositório quando houver conflito)
- **Job 3 (deploy-staging):** Mostra as variáveis de STAGING (valores diferentes de DEV)
- **Job 4 (deploy-production):** Mostra as variáveis de PRODUCTION (ambiente final)

**Observe que:**
- A variável `APP_NAME` (repositório) é usada em todos os ambientes
- A variável `API_URL` é diferente em cada ambiente (específica)
- Variáveis de ambiente **sobrescrevem** variáveis de repositório com o mesmo nome

---

### Dica Extra

#### Ordem de Precedência de Variáveis

Quando há variáveis com o mesmo nome, a precedência é:

1. **Variáveis de Environment** (mais alta prioridade)
2. **Variáveis de Repositório** (prioridade média)
3. **Variáveis de Organização** (prioridade baixa)

**Exemplo prático:**
- Se você criar `DEFAULT_REGION` como variável de repositório com valor `us-east-1`
- E criar `DEFAULT_REGION` no environment `production` com valor `eu-west-1`
- O job usando `environment: production` vai usar `eu-west-1` (sobrescreve)

---

#### Quando Usar Cada Tipo

**Variáveis de Repositório:**
- Configurações compartilhadas entre todos os ambientes
- Versões de ferramentas (Node, Python, etc.)
- Nomes de aplicação
- Timeouts padrão
- Configurações gerais de CI/CD

**Variáveis de Environment:**
- URLs de API específicas por ambiente
- Nomes de bancos de dados por ambiente
- Configurações de debug (ativado em dev, desativado em prod)
- Limites de recursos por ambiente
- Regiões de deploy específicas

---

#### Desafio Extra

1. Crie um quarto ambiente chamado `qa` (Quality Assurance)
2. Configure variáveis específicas para QA
3. Adicione um job `deploy-qa` que executa entre `deploy-staging` e `deploy-production`
4. Configure **Required reviewers** no ambiente `production` e veja como o workflow aguarda aprovação manual

---

#### Proteções de Environment

Os environments permitem configurar:
- **Required reviewers:** Aprovação manual antes do deploy
- **Wait timer:** Atraso antes de iniciar o deploy
- **Deployment branches:** Restringir quais branches podem fazer deploy
- **Environment secrets:** Secrets específicos por ambiente (além de variáveis)

Essas proteções são essenciais em ambientes de produção!

---

### Conclusão

Parabéns! Você dominou o uso de variáveis de repositório e variáveis de ambiente no GitHub Actions. Agora você sabe como:

- Criar e usar variáveis de repositório compartilhadas
- Configurar environments (dev, staging, production)
- Definir variáveis específicas por ambiente
- Entender a ordem de precedência entre variáveis
- Aplicar proteções e aprovações em ambientes críticos
- Simular pipelines de deploy realistas com múltiplos ambientes

> Você está pronto para construir pipelines de CI/CD profissionais com configurações específicas por ambiente!
