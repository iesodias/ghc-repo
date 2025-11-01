## Lab 02: GitHub Secrets - Trabalhando com Informações Sensíveis

### Objetivo

Neste laboratório, você vai aprender a trabalhar com **GitHub Secrets** para armazenar e usar informações sensíveis de forma segura em seus workflows. Você entenderá como configurar secrets, utilizá-los em workflows e como o GitHub mascara automaticamente esses valores nos logs para proteger suas credenciais.

---

### 1. Criar estrutura local

```bash
# Crie o diretório base e acesse-o
mkdir lab-github-secrets
cd lab-github-secrets
```

---

### 2. Criar repositório no GitHub

1. Acesse [https://github.com](https://github.com)
2. Clique em **New Repository**
3. Nome: `lab-github-secrets`
4. Deixe **sem README**, **sem .gitignore**, **sem license** (vamos configurar localmente)

---

### 3. Inicializar Git e conectar com repositório remoto

```bash
git init
git remote add origin https://github.com/SEU_USUARIO/lab-github-secrets.git
echo "# lab-github-secrets" > README.md
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

Crie o arquivo `.github/workflows/secrets-demo.yml` com o conteúdo abaixo:

```yaml
name: Demo GitHub Secrets

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  demonstrar-secrets:
    runs-on: ubuntu-latest

    steps:
      # Step 1: Checkout do código
      - name: Fazer checkout do repositório
        uses: actions/checkout@v4

      # Step 2: Demonstrar uso de secrets em variáveis de ambiente
      - name: Configurar credenciais da API
        env:
          API_KEY: ${{ secrets.API_KEY }}
          API_URL: ${{ secrets.API_URL }}
        run: |
          echo "Configurando conexão com API externa..."
          echo "URL da API: $API_URL"
          echo "API Key está configurada: ${API_KEY:+SIM}"

      # Step 3: Simular conexão com banco de dados usando secrets
      - name: Conectar ao banco de dados
        env:
          DB_HOST: ${{ secrets.DB_HOST }}
          DB_USERNAME: ${{ secrets.DB_USERNAME }}
          DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
          DB_PORT: ${{ secrets.DB_PORT }}
        run: |
          echo "Configurando conexão com banco de dados..."
          echo "Host: $DB_HOST"
          echo "Porta: $DB_PORT"
          echo "Usuário: $DB_USERNAME"
          echo "Senha: $DB_PASSWORD"
          echo "Observe que a senha será mascarada nos logs!"

      # Step 4: Usar secret em um token de deploy
      - name: Preparar deploy com token
        env:
          DEPLOY_TOKEN: ${{ secrets.DEPLOY_TOKEN }}
        run: |
          echo "Preparando deploy..."
          echo "Token de deploy: $DEPLOY_TOKEN"
          echo "GitHub automaticamente mascara o valor real do token!"

      # Step 5: Demonstrar que secrets não são expostos em logs
      - name: Verificar segurança dos secrets
        run: |
          echo "Segurança dos Secrets:"
          echo "- Secrets nunca aparecem em logs (são substituídos por ***)"
          echo "- Secrets não são acessíveis em forks do repositório"
          echo "- Secrets só são expostos para workflows autorizados"
          echo "- Você pode atualizar secrets sem alterar o código"
```

---

### 6. Subir alterações para o GitHub

```bash
git add .
git commit -m "add workflow com github secrets"
git push
```

---

### 7. Verificar resultado

#### Passo 1: Criar os Secrets no GitHub (FAÇA ANTES DE EXECUTAR O WORKFLOW)

Antes de executar o workflow, você precisa criar os secrets no repositório:

1. Acesse seu repositório no GitHub
2. Clique em **Settings** (Configurações)
3. No menu lateral esquerdo, clique em **Secrets and variables** → **Actions**
4. Clique no botão **New repository secret**
5. Crie cada um dos seguintes secrets:

**Secret 1: API_KEY**
- Name: `API_KEY`
- Value: `abc123xyz789apikey`
- Clique em **Add secret**

**Secret 2: API_URL**
- Name: `API_URL`
- Value: `https://api.exemplo.com.br/v1`
- Clique em **Add secret**

**Secret 3: DB_HOST**
- Name: `DB_HOST`
- Value: `database.exemplo.com.br`
- Clique em **Add secret**

**Secret 4: DB_USERNAME**
- Name: `DB_USERNAME`
- Value: `admin_user`
- Clique em **Add secret**

**Secret 5: DB_PASSWORD**
- Name: `DB_PASSWORD`
- Value: `SenhaSegura@2024`
- Clique em **Add secret**

**Secret 6: DB_PORT**
- Name: `DB_PORT`
- Value: `5432`
- Clique em **Add secret**

**Secret 7: DEPLOY_TOKEN**
- Name: `DEPLOY_TOKEN`
- Value: `ghp_1234567890abcdefghijklmnopqrstuvwxyz`
- Clique em **Add secret**

#### Passo 2: Verificar os Secrets Criados

Após criar todos os secrets, você verá a lista de secrets configurados. Note que:
- O **valor** dos secrets **nunca é exibido** após a criação
- Você só pode **atualizar** ou **deletar** secrets, mas não visualizar
- Secrets aparecem listados apenas pelo nome

#### Passo 3: Executar o Workflow

1. Acesse a aba **Actions** no repositório
2. Selecione o workflow **Demo GitHub Secrets**
3. Clique em **Run workflow** → **Run workflow** (para executar manualmente)
4. Aguarde a execução

#### Passo 4: Analisar os Logs

1. Clique na execução do workflow
2. Clique no job **demonstrar-secrets**
3. Expanda cada step e observe:
   - Os valores dos secrets aparecem como `***` nos logs
   - Mesmo que você tente imprimir o valor, o GitHub mascara automaticamente
   - Mensagens de contexto aparecem normalmente
   - URLs, usernames e outros dados não sensíveis são visíveis

**Exemplo de como os logs devem aparecer:**
```
Configurando conexão com API externa...
URL da API: https://api.exemplo.com.br/v1
API Key está configurada: SIM

Configurando conexão com banco de dados...
Host: database.exemplo.com.br
Porta: 5432
Usuário: admin_user
Senha: ***
Observe que a senha será mascarada nos logs!

Preparando deploy...
Token de deploy: ***
GitHub automaticamente mascara o valor real do token!
```

---

### Dica Extra

#### Boas Práticas com GitHub Secrets

1. **Use Secrets para TODAS as informações sensíveis:**
   - Senhas, tokens de API, chaves SSH
   - Credenciais de banco de dados
   - Certificados e chaves privadas
   - Tokens de deploy e webhooks

2. **Diferença entre Secrets e Variables:**
   - **Secrets**: Para dados sensíveis, são mascarados nos logs, não podem ser lidos após criação
   - **Variables**: Para configurações não sensíveis, são visíveis nos logs, podem ser lidas

3. **Segurança adicional:**
   - Secrets não são expostos em **forks** do repositório
   - Secrets não são acessíveis em **pull requests** de forks
   - Use **environment secrets** para proteger deploys em ambientes específicos (produção, staging)
   - Nunca faça commit de secrets no código (use `.env` apenas localmente e adicione ao `.gitignore`)

4. **Organização:**
   - Use nomes descritivos: `PROD_DB_PASSWORD`, `STAGING_API_KEY`
   - Documente quais secrets são necessários no README do repositório
   - Mantenha secrets atualizados e rotacione periodicamente

5. **Testando localmente:**
   - Para testar workflows localmente, use ferramentas como [act](https://github.com/nektos/act)
   - Crie um arquivo `.secrets` local (nunca faça commit dele!)
   - Use variáveis de ambiente locais para simular secrets

#### Desafio Extra

Experimente criar um novo step que:
- Use um secret para fazer uma requisição HTTP real a uma API pública
- Exemplo: Use a API do GitHub com um Personal Access Token
- Veja como o token é mascarado mesmo em respostas de API

```yaml
- name: Fazer requisição autenticada
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  run: |
    curl -H "Authorization: token $GITHUB_TOKEN" \
         https://api.github.com/user
```

---

### Conclusão

> Parabéns! Você aprendeu a trabalhar com GitHub Secrets de forma segura e profissional. Agora você sabe como proteger informações sensíveis em seus workflows, compreende a diferença entre secrets e variables, e conhece as melhores práticas de segurança. Este conhecimento é fundamental para qualquer projeto CI/CD real!
