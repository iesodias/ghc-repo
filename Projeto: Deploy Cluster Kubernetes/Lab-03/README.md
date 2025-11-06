# Lab 03 - Estrutura do Repositorio e Configuracao Terraform

## Objetivo

Criar o repositorio no GitHub, configurar a estrutura de diretorios necessaria e copiar os arquivos Terraform que serao utilizados para provisionar os clusters AKS nos ambientes de desenvolvimento, homologacao e producao.

---

## Requisitos

* Conta ativa no GitHub
* Git instalado localmente (`git --version`)
* Git configurado com suas credenciais
* Terminal Linux ou WSL
* Lab-01 e Lab-02 concluidos (infraestrutura Azure e secrets configurados)

---

## Passo 1: Criar repositorio no GitHub

1. Acesse https://github.com e faca login
2. Clique no botao **+** (canto superior direito) e selecione **New repository**
3. Configure o repositorio:
   - **Repository name:** `aks-pipeline-projeto` (ou nome de sua preferencia)
   - **Description:** `Pipeline CI/CD para deploy de clusters AKS com Terraform`
   - **Visibility:** Private (recomendado) ou Public
   - **Nao** marque "Add a README file"
   - **Nao** adicione .gitignore
   - **Nao** adicione license
4. Clique em **Create repository**

---

## Passo 2: Definir variaveis de ambiente

```bash
# Defina seu usuario do GitHub
GITHUB_USER="seu-usuario-github"

# Defina o nome do repositorio que voce criou
REPO_NAME="aks-pipeline-projeto"
```

---

## Passo 3: Clonar seu repositorio vazio

```bash
# Navegar para o diretorio home
cd ~

# Clonar o repositorio vazio
git clone https://github.com/$GITHUB_USER/$REPO_NAME.git

# Entrar no diretorio do repositorio
cd $REPO_NAME
```

---

## Passo 4: Clonar o repositorio de referencia

```bash
# Voltar para o diretorio home
cd ~

# Clonar o repositorio com os arquivos Terraform
git clone https://github.com/iesodias/teste-k8s.git
```

---

## Passo 5: Copiar a pasta terraform completa

```bash
# Copiar toda a estrutura terraform para seu repositorio
cp -r ~/teste-k8s/terraform ~/$REPO_NAME/
```

---

## Passo 6: Criar estrutura de diretorios para GitHub Actions

```bash
# Entrar no diretorio do repositorio
cd ~/$REPO_NAME

# Criar estrutura .github/workflows
mkdir -p .github/workflows
```

---

## Passo 7: Verificar estrutura criada

```bash
cd ~/$REPO_NAME

# Listar estrutura
ls -la
```

A estrutura esperada e:

```
.
├── .git/
├── .github/
│   └── workflows/
└── terraform/
    ├── backend.tf
    ├── dev/
    │   └── dev.tfvars
    ├── helm.tf
    ├── hml/
    │   └── hml.tfvars
    ├── ingress.tf
    ├── main.tf
    ├── outputs.tf
    ├── prod/
    │   └── prod.tfvars
    ├── providers.tf
    └── variables.tf
```

---

## Passo 8: Adicionar arquivos ao Git

```bash
cd ~/$REPO_NAME

# Adicionar todos os arquivos
git add .

# Verificar status
git status
```

---

## Passo 9: Criar primeiro commit

```bash
git commit -m "feat: adicionar estrutura terraform para provisionamento AKS

- Adiciona configuracao terraform com backend remoto Azure
- Configura providers (azurerm, helm, kubernetes)
- Adiciona arquivos de variaveis para 3 ambientes (dev, hml, prod)
- Configura ingress controller com Helm
- Cria estrutura .github/workflows para pipelines"
```

---

## Passo 10: Enviar para o GitHub

```bash
git push -u origin main
```

Se for solicitado autenticacao, use:
- **Username:** seu usuario do GitHub
- **Password:** seu Personal Access Token (criado no Lab-02)

---

## Passo 11: Validar no GitHub

Acesse https://github.com/$GITHUB_USER/$REPO_NAME e verifique se os arquivos foram enviados corretamente.

---

## Passo 12: Limpar repositorio temporario

```bash
# Remover o repositorio clonado temporariamente
rm -rf ~/teste-k8s
```

---

## Entendendo a estrutura Terraform

### backend.tf
Configura o backend remoto no Azure Storage para armazenar o estado do Terraform (criado no Lab-01).

### providers.tf
Define os providers necessarios:
- **azurerm**: Provisionamento de recursos Azure
- **helm**: Instalacao de charts no Kubernetes
- **kubernetes**: Gerenciamento de recursos K8s

### main.tf
Arquivo principal com definicao dos recursos AKS (cluster, node pools, networking).

### variables.tf
Declaracao de todas as variaveis utilizadas nos arquivos Terraform.

### helm.tf
Configuracao de charts Helm (nginx-ingress, cert-manager, etc).

### ingress.tf
Configuracao do Ingress Controller para roteamento de trafego.

### outputs.tf
Define os outputs que serao exportados apos apply (IPs, credenciais, endpoints).

### dev/dev.tfvars, hml/hml.tfvars, prod/prod.tfvars
Valores especificos de variaveis para cada ambiente.

---

## Troubleshooting

### Erro: "remote: Repository not found"

**Solucao:**
```bash
# Verificar a URL do remote
git remote -v

# Corrigir se necessario
git remote set-url origin https://github.com/$GITHUB_USER/$REPO_NAME.git
```

### Erro: "fatal: Authentication failed"

**Solucao:** Use um Personal Access Token no lugar da senha. Consulte Lab-02, Passo 8.

### Erro: "cp: cannot stat"

**Solucao:**
```bash
# Clonar novamente
cd ~
git clone https://github.com/iesodias/teste-k8s.git
```

criar branches

develop

homologacao


---

## Conclusao

**Lab concluido!**

Voce aprendeu a:

* Criar repositorio no GitHub para o projeto AKS
* Clonar e copiar arquivos de um repositorio de referencia
* Estruturar corretamente o repositorio com pastas terraform e .github
* Versionar e enviar arquivos para o GitHub
* Entender a organizacao dos arquivos Terraform por ambiente
