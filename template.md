# 🧪 Lab Template – Azure CLI Passo a Passo

## Lab Title

Descreva claramente o nome do laboratório.
**Exemplo:** Criar um Resource Group e uma Storage Account na Azure usando Azure CLI

---

## Objetivo

Explique de forma simples o que será feito no lab.
**Exemplo:** Demonstrar como criar e listar recursos básicos na Azure usando o `az cli` diretamente no terminal Linux.

---

## Requisitos

* Conta ativa na Azure
* Azure CLI instalado (`az version`)
* Sessão autenticada (`az login`)
* Acesso a um terminal Linux ou WSL

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

## Passo 2: Definir variáveis de ambiente

```bash
RESOURCE_GROUP="lab-rg"
LOCATION="eastus"
STORAGE_ACCOUNT="labstore$RANDOM"
```

> Essas variáveis serão usadas nos próximos comandos.

---

## Passo 3: Criar o Resource Group

```bash
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION \
  -o table
```

Confirme a criação:

```bash
az group list -o table
```

---

## Passo 4: Criar uma Storage Account

```bash
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS \
  --kind StorageV2 \
  -o table
```

Verifique se o recurso foi criado:

```bash
az storage account list -g $RESOURCE_GROUP -o table
```

---

## Passo 5: Explorar comandos úteis

Listar todos os recursos no grupo:

```bash
az resource list -g $RESOURCE_GROUP -o table
```

Mostrar detalhes de uma storage específica:

```bash
az storage account show -n $STORAGE_ACCOUNT -g $RESOURCE_GROUP -o jsonc
```

---

## Passo 6: Limpar recursos criados

Quando terminar o lab, exclua o grupo e todos os recursos associados:

```bash
az group delete -n $RESOURCE_GROUP --yes --no-wait
```

Verifique se foi removido:

```bash
az group list -o table
```

---

## Conclusão

✅ **Lab concluído!**
Você aprendeu a:

* Autenticar e definir o contexto da assinatura
* Criar e listar recursos básicos com `az cli`
* Limpar recursos para evitar custos desnecessários

---

## Convenção de Nomes

```
Lab-01-NomeDoLab
Lab-02-NomeDoLab
Lab-03-NomeDoLab
```

Para roteiro de explicação do instrutor, use o mesmo nome do lab com sufixo `_fala.md`.
