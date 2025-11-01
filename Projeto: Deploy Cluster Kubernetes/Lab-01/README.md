# Lab 01 - Configuracao Inicial do Azure para Pipeline AKS

## Objetivo

Preparar a infraestrutura base na Azure necessaria para gerenciar o estado do Terraform (backend remoto) e criar os Resource Groups dos ambientes de desenvolvimento, homologacao e producao onde os clusters AKS serao implantados.

---

## Requisitos

* Conta ativa na Azure
* Azure CLI instalado (`az version`)
* Sessao autenticada (`az login`)
* Acesso a um terminal Linux ou WSL
* Permissoes de Contributor ou superior na assinatura Azure

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
LOCATION="brazilsouth"
TERRAFORM_RG="gh-terraform"
STORAGE_ACCOUNT="ghdevopsautomatf"
CONTAINER_NAME="tfstate"

# Environment Resource Groups
DEV_RG="gh-devops-dev"
HML_RG="gh-devops-hml"
PRD_RG="gh-devops-prd"
```

> Essas variaveis serao usadas para criar os recursos na Azure.

---

## Passo 3: Criar Resource Group para o Terraform State

```bash
az group create --name $TERRAFORM_RG --location $LOCATION -o table
```

Confirme a criacao:

```bash
az group list -o table | grep $TERRAFORM_RG
```

---

## Passo 4: Criar Storage Account para armazenar o estado do Terraform

```bash
az storage account create \
    --name $STORAGE_ACCOUNT \
    --resource-group $TERRAFORM_RG \
    --location $LOCATION \
    --sku Standard_LRS \
    --kind StorageV2 \
    --access-tier Hot \
    --encryption-services blob file \
    --https-only true \
    --min-tls-version TLS1_2 \
    -o table
```

Verifique se o recurso foi criado:

```bash
az storage account list -g $TERRAFORM_RG -o table
```

---

## Passo 5: Criar container para o Terraform State

```bash
az storage container create \
    --name $CONTAINER_NAME \
    --account-name $STORAGE_ACCOUNT \
    --auth-mode login
```

Liste os containers criados:

```bash
az storage container list --account-name $STORAGE_ACCOUNT --auth-mode login -o table
```

---

## Passo 6: Criar Resource Groups dos ambientes

Criar Resource Group de Desenvolvimento:

```bash
az group create --name $DEV_RG --location $LOCATION -o table
```

Criar Resource Group de Homologacao:

```bash
az group create --name $HML_RG --location $LOCATION -o table
```

Criar Resource Group de Producao:

```bash
az group create --name $PRD_RG --location $LOCATION -o table
```

Verifique se todos foram criados:

```bash
az group list -o table | grep "gh-devops"
```

---

## Passo 7: Obter a chave de acesso da Storage Account

```bash
STORAGE_ACCOUNT_KEY=$(az storage account keys list \
    --resource-group $TERRAFORM_RG \
    --account-name $STORAGE_ACCOUNT \
    --query '[0].value' -o tsv)

echo "ARM_ACCESS_KEY=$STORAGE_ACCOUNT_KEY"
```

> **IMPORTANTE:** Guarde essa chave com seguranca. Ela sera necessaria para configurar os GitHub Secrets.

---

## Passo 8: Verificar configuracao do backend do Terraform

A configuracao do backend que sera utilizada nos arquivos Terraform:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "gh-terraform"
    storage_account_name = "ghdevopsautomatf"
    container_name       = "tfstate"
    key                  = "aks/dev.tfstate"  # Muda conforme ambiente: dev, hml, prd
  }
}
```

---

## Passo 9: Configurar GitHub Secrets

Para que o GitHub Actions possa executar o Terraform, e necessario configurar os seguintes secrets no repositorio:

1. Acesse seu repositorio no GitHub
2. Va em **Settings** > **Secrets and variables** > **Actions**
3. Adicione os seguintes secrets:

**ARM_ACCESS_KEY**: A chave obtida no Passo 7

```
ARM_ACCESS_KEY=<chave-da-storage-account>
```

**AZURE_CREDENTIALS**: Credenciais do Service Principal (sera criado no proximo lab)

**ARM_SUBSCRIPTION_ID**: ID da sua assinatura Azure

```bash
az account show --query id -o tsv
```

---

## Passo 10: Validar recursos criados

Liste todos os Resource Groups criados:

```bash
az group list -o table | grep -E "gh-terraform|gh-devops"
```

Verifique a Storage Account:

```bash
az storage account show \
    --name $STORAGE_ACCOUNT \
    --resource-group $TERRAFORM_RG \
    -o jsonc
```

Liste todos os recursos no Resource Group do Terraform:

```bash
az resource list -g $TERRAFORM_RG -o table
```

---

## Execucao automatizada (opcional)

Para executar todos os passos de uma vez, utilize o script fornecido:

```bash
chmod +x script.sh
./script.sh
```

O script ira:
- Verificar se os recursos ja existem antes de criar
- Criar todos os Resource Groups necessarios
- Configurar a Storage Account com seguranca habilitada
- Exibir as informacoes necessarias para configuracao do Terraform e GitHub Actions

---

## Limpeza de recursos (quando necessario)

**ATENCAO:** Execute apenas quando quiser remover TODA a infraestrutura criada.

Remover Resource Groups dos ambientes:

```bash
az group delete -n $DEV_RG --yes --no-wait
az group delete -n $HML_RG --yes --no-wait
az group delete -n $PRD_RG --yes --no-wait
```

Remover Resource Group do Terraform (CUIDADO: isso apaga o estado do Terraform):

```bash
az group delete -n $TERRAFORM_RG --yes --no-wait
```

Verificar remocao:

```bash
az group list -o table
```

---

## Conclusao

**Lab concluido!**

Voce aprendeu a:

* Criar Resource Groups para gerenciamento de estado do Terraform
* Configurar Storage Account segura para backend remoto do Terraform
* Criar estrutura de Resource Groups para ambientes (Dev, Hml, Prd)
* Obter credenciais necessarias para integracao com GitHub Actions
* Preparar o ambiente Azure para deploy de clusters AKS via CI/CD

---

## Proximos passos

1. Criar Service Principal para autenticacao do GitHub Actions (Lab-02)
2. Configurar os arquivos Terraform para provisionamento do AKS (Lab-03)
3. Criar o workflow do GitHub Actions para deploy automatizado (Lab-04)
