# Lab 02 - Criacao de Service Principal para GitHub Actions

## Objetivo

Criar um Service Principal na Azure com permissoes adequadas para que o GitHub Actions possa autenticar e provisionar recursos (clusters AKS, redes, load balancers, etc.) de forma automatizada via pipeline CI/CD.

---

## Requisitos

* Conta ativa na Azure
* Azure CLI instalado (`az version`)
* Sessao autenticada (`az login`)
* Acesso a um terminal Linux ou WSL
* Permissoes de Owner ou superior na assinatura Azure (necessario para criar Service Principal)
* Lab-01 concluido (Resource Groups criados)

---

## O que e Service Principal?

Um Service Principal e uma identidade criada para uso com aplicacoes, servicos hospedados e ferramentas automatizadas para acessar recursos do Azure. Em vez de usar credenciais de usuario, o Service Principal fornece uma identidade gerenciavel com permissoes especificas.

**Por que precisamos disso?**
- Autenticacao segura do GitHub Actions com a Azure
- Permissoes granulares (apenas o necessario)
- Rotacao de credenciais sem impactar usuarios
- Auditoria de acoes automatizadas

---

## Passo 1: Fazer login na Azure

```bash
az login --use-device-code
```

Siga o link exibido no terminal e autentique com sua conta Azure.

Verifique a assinatura ativa:

```bash
az account show -o table
```

---

## Passo 2: Definir variaveis de ambiente

```bash
SP_NAME="sp-github-actions-aks"
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
```

Verifique se a subscription ID foi capturada corretamente:

```bash
echo "Subscription ID: $SUBSCRIPTION_ID"
```

---

## Passo 3: Criar o Service Principal

```bash
az ad sp create-for-rbac \
    --name $SP_NAME \
    --role Contributor \
    --scopes "/subscriptions/$SUBSCRIPTION_ID" \
    --sdk-auth
```

**Importante:** O output deste comando deve ser guardado com seguranca. Ele contem as credenciais que serao usadas no GitHub Actions.

O output tera o seguinte formato:

```json
{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientSecret": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

> **ATENCAO:** Guarde este JSON completo. Ele sera necessario para configurar o secret `AZURE_CREDENTIALS` no GitHub.

---

## Passo 4: Verificar o Service Principal criado

Listar Service Principals:

```bash
az ad sp list --display-name $SP_NAME -o table
```

Obter detalhes do Service Principal:

```bash
az ad sp list --display-name $SP_NAME --query "[0].{DisplayName:displayName, AppId:appId, ObjectId:id}" -o table
```

---

## Passo 5: Verificar permissoes atribuidas

```bash
az role assignment list --assignee $(az ad sp list --display-name $SP_NAME --query "[0].appId" -o tsv) -o table
```

Voce deve ver que o Service Principal tem a role **Contributor** no escopo da subscription.

---

## Passo 6: Extrair valores individuais do Service Principal

Apos criar o Service Principal no Passo 3, extraia os valores necessarios para os secrets do GitHub:

```bash
# Obter Subscription ID
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
echo "ARM_SUBSCRIPTION_ID=$SUBSCRIPTION_ID"

# Obter Tenant ID
TENANT_ID=$(az account show --query tenantId --output tsv)
echo "ARM_TENANT_ID=$TENANT_ID"

# Obter Client ID (App ID do Service Principal)
CLIENT_ID=$(az ad sp list --display-name $SP_NAME --query "[0].appId" --output tsv)
echo "ARM_CLIENT_ID=$CLIENT_ID"

# Obter ARM_ACCESS_KEY (do Lab-01)
# Execute no terminal onde criou a Storage Account:
# STORAGE_ACCOUNT_KEY=$(az storage account keys list \
#     --resource-group gh-terraform \
#     --account-name ghdevopsautomatf \
#     --query '[0].value' -o tsv)
# echo "ARM_ACCESS_KEY=$STORAGE_ACCOUNT_KEY"
```

> **IMPORTANTE:** O `ARM_CLIENT_SECRET` (clientSecret) so e exibido UMA VEZ no momento da criacao do Service Principal (Passo 3). Guarde esse valor com seguranca!

---

## Passo 7: Obter ARM_ACCESS_KEY do Lab-01

Se voce nao salvou o `ARM_ACCESS_KEY` do Lab-01, obtenha-o novamente:

```bash
ARM_ACCESS_KEY=$(az storage account keys list \
    --resource-group gh-terraform \
    --account-name ghdevopsautomatf \
    --query '[0].value' -o tsv)

echo "ARM_ACCESS_KEY=$ARM_ACCESS_KEY"
```

---

## Passo 8: Criar Personal Access Token do GitHub (TOKEN_GB)

O `TOKEN_GB` e um Personal Access Token (PAT) do GitHub necessario para algumas operacoes da pipeline.

### 8.1: Acessar configuracoes do GitHub

1. No GitHub, clique na sua **foto de perfil** (canto superior direito)
2. Clique em **Settings**
3. No menu lateral esquerdo, role ate o final e clique em **Developer settings**
4. Clique em **Personal access tokens** > **Tokens (classic)**
5. Clique em **Generate new token** > **Generate new token (classic)**

### 8.2: Configurar o token

- **Note:** `GitHub Actions AKS Pipeline`
- **Expiration:** Escolha um periodo adequado (90 dias, 1 ano, ou sem expiracao)
- **Select scopes:** Marque as seguintes permissoes:
  - `repo` (Full control of private repositories)
  - `workflow` (Update GitHub Action workflows)
  - `write:packages` (Upload packages to GitHub Package Registry)
  - `read:packages` (Download packages from GitHub Package Registry)

### 8.3: Gerar e copiar o token

1. Clique em **Generate token**
2. **COPIE O TOKEN IMEDIATAMENTE** - ele so sera exibido uma vez!
3. O token tera o formato: `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

```bash
# Exemplo de formato
TOKEN_GB=ghp_1A2b3C4d5E6f7G8h9I0jKlMnOpQrStUvWxYz
```

---

## Passo 9: Configurar GitHub Secrets

Agora voce precisa adicionar TODOS os secrets no seu repositorio GitHub:

1. Acesse seu repositorio no GitHub
2. Va em **Settings** > **Secrets and variables** > **Actions**
3. Clique em **New repository secret**

### Secret 1: AZURE_CREDENTIALS

- **Name:** `AZURE_CREDENTIALS`
- **Secret:** Cole o JSON completo do output do Passo 3

```json
{
  "clientId": "a1b2c3d4-e5f6-7890-abcd-1234567890ab",
  "clientSecret": "X~8Q~abcdefghijklmnopqrstuvwxyz123456",
  "subscriptionId": "12345678-1234-1234-1234-123456789abc",
  "tenantId": "87654321-4321-4321-4321-abcdef123456",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

### Secret 2: ARM_CLIENT_ID

- **Name:** `ARM_CLIENT_ID`
- **Secret:** Cole o Client ID (appId) do Service Principal

```
a1b2c3d4-e5f6-7890-abcd-1234567890ab
```

### Secret 3: ARM_CLIENT_SECRET

- **Name:** `ARM_CLIENT_SECRET`
- **Secret:** Cole o clientSecret do JSON do Passo 3

```
X~8Q~abcdefghijklmnopqrstuvwxyz123456
```

### Secret 4: ARM_SUBSCRIPTION_ID

- **Name:** `ARM_SUBSCRIPTION_ID`
- **Secret:** Cole o Subscription ID obtido no Passo 6

```
12345678-1234-1234-1234-123456789abc
```

### Secret 5: ARM_TENANT_ID

- **Name:** `ARM_TENANT_ID`
- **Secret:** Cole o Tenant ID obtido no Passo 6

```
87654321-4321-4321-4321-abcdef123456
```

### Secret 6: ARM_ACCESS_KEY

- **Name:** `ARM_ACCESS_KEY`
- **Secret:** Cole a chave da Storage Account obtida no Passo 7

```
AbCdEfGhIjKlMnOpQrStUvWxYz0123456789+ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqr==
```

### Secret 7: TOKEN_GB

- **Name:** `TOKEN_GB`
- **Secret:** Cole o Personal Access Token criado no Passo 8

```
ghp_1A2b3C4d5E6f7G8h9I0jKlMnOpQrStUvWxYz
```

---

## Passo 10: Validar todos os secrets criados

Apos criar todos os secrets, verifique na pagina **Actions secrets and variables**:

Voce deve ver 7 secrets listados:

1. ARM_ACCESS_KEY
2. ARM_CLIENT_ID
3. ARM_CLIENT_SECRET
4. ARM_SUBSCRIPTION_ID
5. ARM_TENANT_ID
6. AZURE_CREDENTIALS
7. TOKEN_GB

---

## Passo 11: Tabela de referencia dos secrets

Use esta tabela como guia para verificar se todos os valores foram configurados corretamente:

| Secret Name | Onde Obter | Formato / Exemplo | Descricao |
|-------------|------------|-------------------|-----------|
| **AZURE_CREDENTIALS** | Output do comando `az ad sp create-for-rbac --sdk-auth` (Passo 3) | JSON completo | Credenciais completas do Service Principal |
| **ARM_CLIENT_ID** | `clientId` do JSON ou `az ad sp list --display-name sp-github-actions-aks` | `a1b2c3d4-e5f6-7890-abcd-1234567890ab` | Application (Client) ID do Service Principal |
| **ARM_CLIENT_SECRET** | `clientSecret` do JSON (apenas no momento da criacao) | `X~8Q~abcdefghijklmnopqrstuvwxyz123456` | Senha/Secret do Service Principal |
| **ARM_SUBSCRIPTION_ID** | `az account show --query id -o tsv` | `12345678-1234-1234-1234-123456789abc` | ID da assinatura Azure |
| **ARM_TENANT_ID** | `az account show --query tenantId -o tsv` | `87654321-4321-4321-4321-abcdef123456` | ID do Azure Active Directory (Tenant) |
| **ARM_ACCESS_KEY** | `az storage account keys list` (Lab-01, Passo 7) | `AbCdEfGh...xyz/abc==` (88 chars) | Chave de acesso da Storage Account para Terraform backend |
| **TOKEN_GB** | GitHub Settings > Developer settings > Personal access tokens | `ghp_1A2b3C4d5E6f7G8h9I0jKlMnOpQr...` | Personal Access Token do GitHub com permissoes de repo/workflow |

### Exemplo de valores (para referencia visual):

```bash
# Exemplo de como os valores se parecem (NAO USE ESTES VALORES REAIS!)

AZURE_CREDENTIALS='{"clientId":"a1b2c3d4-e5f6-7890-abcd-1234567890ab","clientSecret":"X~8Q~abcd...",...}'

ARM_CLIENT_ID='a1b2c3d4-e5f6-7890-abcd-1234567890ab'

ARM_CLIENT_SECRET='X~8Q~abcdefghijklmnopqrstuvwxyz123456'

ARM_SUBSCRIPTION_ID='12345678-1234-1234-1234-123456789abc'

ARM_TENANT_ID='87654321-4321-4321-4321-abcdef123456'

ARM_ACCESS_KEY='AbCdEfGhIjKlMnOpQrStUvWxYz0123456789+ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefgh=='

TOKEN_GB='ghp_1A2b3C4d5E6f7G8h9I0jKlMnOpQrStUvWxYz12345'
```

---

## Passo 12: Testar autenticacao do Service Principal

Faca login usando o Service Principal:

```bash
SP_APP_ID=$(az ad sp list --display-name $SP_NAME --query "[0].appId" -o tsv)
SP_PASSWORD="<client-secret-do-json-output>"
TENANT_ID=$(az account show --query tenantId -o tsv)

az login --service-principal \
    -u $SP_APP_ID \
    -p $SP_PASSWORD \
    --tenant $TENANT_ID
```

Verifique o contexto:

```bash
az account show -o table
```

Volte para o login normal:

```bash
az logout
az login
```

---

## Passo 13: (Opcional) Atribuir permissoes adicionais

Se sua pipeline precisar de permissoes especificas para recursos como Azure Container Registry (ACR) ou Key Vault, voce pode atribuir roles adicionais:

**Para ACR:**

```bash
ACR_NAME="seu-registry-name"
ACR_ID=$(az acr show --name $ACR_NAME --query id -o tsv)

az role assignment create \
    --assignee $(az ad sp list --display-name $SP_NAME --query "[0].appId" -o tsv) \
    --role AcrPush \
    --scope $ACR_ID
```

**Para Key Vault:**

```bash
KV_NAME="seu-keyvault-name"

az keyvault set-policy \
    --name $KV_NAME \
    --spn $(az ad sp list --display-name $SP_NAME --query "[0].appId" -o tsv) \
    --secret-permissions get list
```

---

## Passo 14: Validar configuracao completa

Verifique se todos os secrets necessarios foram criados no GitHub:

1. **AZURE_CREDENTIALS** (JSON do Service Principal)
2. **ARM_CLIENT_ID** (Client ID do Service Principal)
3. **ARM_CLIENT_SECRET** (Secret do Service Principal)
4. **ARM_SUBSCRIPTION_ID** (ID da subscription)
5. **ARM_TENANT_ID** (ID do Tenant)
6. **ARM_ACCESS_KEY** (Chave da Storage Account do Lab-01)
7. **TOKEN_GB** (Personal Access Token do GitHub)

Confirme que o Service Principal existe:

```bash
az ad sp list --display-name $SP_NAME -o table
```

Confirme as role assignments:

```bash
az role assignment list \
    --assignee $(az ad sp list --display-name $SP_NAME --query "[0].appId" -o tsv) \
    -o table
```

---

## Execucao automatizada (opcional)

Para executar todos os passos de uma vez, utilize o script fornecido:

```bash
chmod +x script.sh
./script.sh
```

O script ira:
- Obter automaticamente o Subscription ID
- Criar o Service Principal com permissoes de Contributor
- Exibir o JSON formatado para configuracao do GitHub Secret
- Mostrar instrucoes dos proximos passos

**IMPORTANTE:** Copie e guarde o output do script antes de fechar o terminal!

---

## Remocao do Service Principal (quando necessario)

**ATENCAO:** Execute apenas quando quiser remover completamente o Service Principal.

```bash
az ad sp delete --id $(az ad sp list --display-name $SP_NAME --query "[0].appId" -o tsv)
```

Verifique a remocao:

```bash
az ad sp list --display-name $SP_NAME -o table
```

---

## Troubleshooting

### Erro: "Insufficient privileges to complete the operation"

**Causa:** Voce nao tem permissoes para criar Service Principals.

**Solucao:** Solicite a um administrador da Azure AD para:
- Conceder a role "Application Administrator" ou
- Executar o script para voce e fornecer as credenciais

### Erro: "The client does not have authorization"

**Causa:** Sua conta nao tem permissoes de Owner na subscription.

**Solucao:** O Service Principal precisa ser criado por alguem com role Owner ou User Access Administrator.

### Service Principal ja existe

Se o Service Principal ja existe e voce perdeu as credenciais:

```bash
# Resetar o secret
az ad sp credential reset --name $SP_NAME --query password -o tsv
```

> Anote o novo client secret gerado e atualize o GitHub Secret.

---

## Conclusao

**Lab concluido!**

Voce aprendeu a:

* Criar Service Principal para autenticacao automatizada
* Configurar permissoes adequadas (role Contributor)
* Obter credenciais no formato adequado para GitHub Actions
* Configurar GitHub Secrets necessarios para a pipeline
* Validar e testar autenticacao do Service Principal
* Gerenciar permissoes adicionais conforme necessidade

---

## Proximos passos

1. Configurar arquivos Terraform para provisionamento do AKS (Lab-03)
2. Criar workflow do GitHub Actions para deploy automatizado (Lab-04)
3. Implementar pipeline completa de CI/CD para aplicacoes no AKS (Lab-05)
