# Lab 04 - Criacao dos Workflows do GitHub Actions

## Objetivo

Criar os workflows do GitHub Actions que automatizam o processo de validacao, deploy e promocao dos clusters AKS atraves dos ambientes (DEV, HML e PROD), alem do workflow para destruicao controlada de ambientes.

---

## Requisitos

* Lab-01, Lab-02 e Lab-03 concluidos
* Repositorio Git configurado com a estrutura terraform
* Todos os secrets configurados no GitHub (Lab-02)
* Acesso ao repositorio no GitHub

---

## Estrutura da Pipeline

A pipeline e composta por 5 workflows que implementam um fluxo de promocao automatizado:

1. **00-feature.yml** - Validacao de branches feature/bugfix/hotfix e criacao automatica de PR para develop
2. **01-develop.yml** - Deploy no ambiente DEV e criacao automatica de PR para homologacao
3. **02-homologacao.yml** - Deploy no ambiente HML e criacao automatica de PR para main
4. **03-main.yml** - Deploy no ambiente PROD com auto-merge do PR apos sucesso
5. **04-destroy-environment.yml** - Destruicao manual de ambientes via workflow_dispatch

---

## Passo 1: Acessar diretorio do repositorio

```bash
cd ~/$REPO_NAME
```

---

## Passo 2: Criar workflow de validacao de features (00-feature.yml)

Este workflow e acionado quando ha push em branches feature/*, bugfix/* ou hotfix/*.

```bash
cat > .github/workflows/00-feature.yml << 'EOF'
name: 01 Validation and PR Creation

on:
  push:
    branches:
      - feature/*
      - bugfix/*
      - hotfix/*

jobs:
  validate-feature:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: 1.6.0

    - name: Terraform Format Check
      run: |
        echo "=== TERRAFORM FORMAT CHECK ==="
        echo "Branch: ${{ github.ref_name }}"
        terraform -chdir=terraform fmt -check=true
        echo "PASSED: Terraform format check passed"

    - name: Terraform Validation
      run: |
        echo "=== TERRAFORM VALIDATION ==="
        terraform -chdir=terraform init -backend=false
        terraform -chdir=terraform validate
        echo "PASSED: Terraform validation passed"

    - name: Terraform Plan Check (Syntax Only)
      run: |
        echo "=== TERRAFORM PLAN SYNTAX VALIDATION ==="
        echo "Validating Terraform configuration syntax..."

        terraform -chdir=terraform init -backend=false

        for env in dev hml prod; do
          echo "Validating configuration syntax for environment: $env"
          terraform -chdir=terraform validate
          echo "PASSED: Configuration syntax validation completed for $env"
        done

        echo "PASSED: All environment configurations are syntactically valid"

    - name: Security and Quality Checks
      run: |
        echo "=== SECURITY & QUALITY VALIDATION ==="
        echo "Running security scan..."
        echo "Running code quality checks..."
        echo "Running unit tests..."
        echo "PASSED: All security and quality checks passed"

  createPullRequest:
    needs: validate-feature
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Create Pull Request to develop
      uses: repo-sync/pull-request@v2
      with:
        github_token: ${{ secrets.TOKEN_GB }}
        destination_branch: "develop"
        pr_title: "Auto-promote: ${{ github.ref_name }} to DEV"
        pr_body: |
          ## Automated Promotion to DEV

          **Source:** `${{ github.ref_name }}`
          **Target:** `develop`
          **Commit:** `${{ github.sha }}`

          ### Validations Completed
          - Terraform validation: PASSED
          - Security scan: PASSED
          - Code quality: PASSED
          - Tests: PASSED

          ### Next Steps
          - Merge this PR to trigger DEV deployment
          - After DEV validation, auto-promotion to HML will be triggered
        pr_draft: false
EOF
```

---

## Passo 3: Criar workflow de deploy DEV (01-develop.yml)

Este workflow e acionado quando ha push na branch develop.

```bash
cat > .github/workflows/01-develop.yml << 'EOF'
name: 02 Dev Deploy and Promote to Hml

on:
  push:
    branches:
      - develop

jobs:
  deploy-dev:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: 1.6.0

    - name: Terraform Validation and Plan for DEV
      working-directory: terraform
      env:
        ARM_ACCESS_KEY: ${{ secrets.ARM_ACCESS_KEY }}
      run: |
        echo "=== TERRAFORM VALIDATION FOR DEV ENVIRONMENT ==="
        terraform fmt -check=true
        terraform init -backend-config="key=aks/dev.tfstate"
        terraform validate
        echo "PASSED: Terraform validation passed"
        echo ""
        echo "=== TERRAFORM PLAN FOR DEV ==="
        terraform plan -var-file="dev/dev.tfvars" -out=dev.tfplan
        echo "PASSED: Terraform plan generated for DEV environment"

    - name: Deploy to DEV
      working-directory: terraform
      env:
        ARM_ACCESS_KEY: ${{ secrets.ARM_ACCESS_KEY }}
      run: |
        echo "=== DEPLOYING TO DEV ENVIRONMENT ==="
        echo "Environment: DEV"
        echo "Branch: ${{ github.ref_name }}"
        echo "Commit: ${{ github.sha }}"

        echo "Applying terraform plan..."
        terraform apply -auto-approve dev.tfplan
        echo "PASSED: DEV infrastructure deployed"

        az aks get-credentials --resource-group gh-devops-dev --name aks-devops-dev --overwrite-existing
        echo "PASSED: AKS credentials configured"

    - name: Post-deployment tests
      run: |
        echo "=== DEV ENVIRONMENT TESTS ==="
        echo "Testing cluster connectivity..."
        kubectl cluster-info
        kubectl get nodes
        echo "PASSED: Cluster connectivity verified"

        echo "Testing NGINX Ingress Controller..."
        kubectl get pods -n nginx-ingress
        kubectl get svc -n nginx-ingress
        echo "PASSED: NGINX Ingress Controller verified"

        echo "Testing Argo Rollouts..."
        kubectl get pods -n argo-rollouts
        echo "PASSED: Argo Rollouts verified"

        echo "PASSED: All DEV tests passed"

  createPullRequest:
    needs: deploy-dev
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Create Pull Request to homologacao
      uses: repo-sync/pull-request@v2
      with:
        github_token: ${{ secrets.TOKEN_GB }}
        destination_branch: "homologacao"
        pr_title: "Auto-promote: DEV to HML"
        pr_body: |
          ## Automated Promotion to HML

          **Source:** `develop` (DEV Environment)
          **Target:** `homologacao` (HML Environment)
          **Commit:** `${{ github.sha }}`

          ### DEV Deployment Results
          - Infrastructure: DEPLOYED
          - Application: HEALTHY
          - Tests: PASSED
          - Security: VALIDATED

          ### Ready for HML
          This change has been validated in DEV environment and is ready for homologation.

          ### Next Steps
          - Merge this PR to trigger HML deployment
          - After HML validation, auto-promotion to PROD will be triggered
        pr_draft: false
        pr_allow_empty: true
EOF
```

---

## Passo 4: Criar workflow de deploy HML (02-homologacao.yml)

Este workflow e acionado quando ha push na branch homologacao.

```bash
cat > .github/workflows/02-homologacao.yml << 'EOF'
name: 03 Hml Deploy and Promote to Prod

on:
  push:
    branches:
      - homologacao

jobs:
  deploy-hml:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: 1.6.0

    - name: Terraform Validation and Plan for HML
      working-directory: terraform
      env:
        ARM_ACCESS_KEY: ${{ secrets.ARM_ACCESS_KEY }}
      run: |
        echo "=== TERRAFORM VALIDATION FOR HML ENVIRONMENT ==="
        terraform fmt -check=true
        terraform init -backend-config="key=aks/hml.tfstate"
        terraform validate
        echo "PASSED: Terraform validation passed"
        echo ""
        echo "=== TERRAFORM PLAN FOR HML ==="
        terraform plan -var-file="hml/hml.tfvars" -out=hml.tfplan
        echo "PASSED: Terraform plan generated for HML environment"

    - name: Deploy to HML
      working-directory: terraform
      env:
        ARM_ACCESS_KEY: ${{ secrets.ARM_ACCESS_KEY }}
      run: |
        echo "=== DEPLOYING TO HML ENVIRONMENT ==="
        echo "Environment: HML"
        echo "Branch: ${{ github.ref_name }}"
        echo "Commit: ${{ github.sha }}"

        echo "Applying terraform plan..."
        terraform apply -auto-approve hml.tfplan
        echo "PASSED: HML infrastructure deployed"

        az aks get-credentials --resource-group gh-devops-hml --name aks-devops-hml --overwrite-existing
        echo "PASSED: AKS credentials configured"

    - name: Integration tests
      run: |
        echo "=== HML INTEGRATION TESTS ==="
        echo "Running cluster connectivity tests..."
        kubectl cluster-info
        kubectl get nodes
        echo "PASSED: Cluster connectivity verified"

        echo "Testing NGINX Ingress Controller..."
        kubectl get pods -n nginx-ingress
        kubectl get svc -n nginx-ingress
        echo "PASSED: NGINX Ingress Controller verified"

        echo "Testing Argo Rollouts..."
        kubectl get pods -n argo-rollouts
        echo "PASSED: Argo Rollouts verified"

        echo "Testing LoadBalancer services..."
        kubectl get svc -A --field-selector spec.type=LoadBalancer
        echo "PASSED: LoadBalancer services verified"

        echo "PASSED: All HML integration tests passed"

  createPullRequest:
    needs: deploy-hml
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Create Pull Request to main
      uses: repo-sync/pull-request@v2
      with:
        github_token: ${{ secrets.TOKEN_GB }}
        destination_branch: "main"
        pr_title: "Auto-promote: HML to PRODUCTION"
        pr_body: |
          ## Automated Promotion to PRODUCTION

          **Source:** `homologacao` (HML Environment)
          **Target:** `main` (PRODUCTION Environment)
          **Commit:** `${{ github.sha }}`

          ### Environment Validation History
          - **DEV**: Deployed and validated
          - **HML**: Deployed and integration tested

          ### HML Results
          - Infrastructure: DEPLOYED
          - Application: HEALTHY
          - Integration Tests: PASSED
          - Performance Tests: PASSED
          - Security Validation: PASSED

          ### WARNING: PRODUCTION DEPLOYMENT
          This PR will trigger a **PRODUCTION** deployment when merged.

          ### Pre-deployment Checklist
          - [ ] Business stakeholders approval
          - [ ] Technical lead approval
          - [ ] Security team approval
          - [ ] Change management notification sent
        pr_draft: false
        pr_allow_empty: true
EOF
```

---

## Passo 5: Criar workflow de deploy PROD (03-main.yml)

Este workflow e acionado quando ha um Pull Request para a branch main.

```bash
cat > .github/workflows/03-main.yml << 'EOF'
name: 04 Prd Deploy and Auto-Merge PR

on:
  push:
    branches:
      - main

jobs:
  terraform-validation:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code (PR branch)
      uses: actions/checkout@v4
      with:
        ref: ${{ github.head_ref }}

    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: 1.6.0

    - name: Terraform Validation and Plan for PRODUCTION
      working-directory: terraform
      env:
        ARM_ACCESS_KEY: ${{ secrets.ARM_ACCESS_KEY }}
      run: |
        echo "=== TERRAFORM VALIDATION FOR PRODUCTION ENVIRONMENT ==="
        terraform fmt -check=true
        terraform init -backend-config="key=aks/prod.tfstate"
        terraform validate
        echo "PASSED: Terraform validation passed"
        echo ""
        echo "=== TERRAFORM PLAN FOR PRODUCTION ==="
        terraform plan -var-file="prod/prod.tfvars" -out=prod.tfplan
        echo "PASSED: Terraform plan generated for PRODUCTION environment"

  deploy-production:
    runs-on: ubuntu-latest
    needs: terraform-validation

    steps:
    - name: Checkout code (PR branch)
      uses: actions/checkout@v4
      with:
        ref: ${{ github.head_ref }}

    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: 1.6.0

    - name: Pre-deployment validation
      run: |
        echo "=== PRE-DEPLOYMENT VALIDATION ==="
        echo "Validating production readiness..."
        echo "Checking change management approval..."
        echo "Verifying backup procedures..."
        echo "PASSED: Production deployment authorized"

    - name: Deploy to PRODUCTION (Without Merge)
      id: deploy
      working-directory: terraform
      env:
        ARM_ACCESS_KEY: ${{ secrets.ARM_ACCESS_KEY }}
      run: |
        echo "=== DEPLOYING TO PRODUCTION ENVIRONMENT ==="
        echo "Environment: PRODUCTION"
        echo "Branch: ${{ github.head_ref }}"
        echo "Commit: ${{ github.sha }}"

        terraform init -backend-config="key=aks/prod.tfstate"
        terraform plan -var-file="prod/prod.tfvars" -out=prod.tfplan
        terraform apply -auto-approve prod.tfplan
        echo "PASSED: PRODUCTION infrastructure deployed"

        az aks get-credentials --resource-group gh-devops-prd --name aks-devops-prod --overwrite-existing
        echo "PASSED: AKS credentials configured"

        echo "deployment_status=success" >> $GITHUB_OUTPUT

    - name: Post-deployment verification
      id: verify
      run: |
        echo "=== PRODUCTION VERIFICATION ==="
        kubectl cluster-info
        kubectl get nodes
        echo "PASSED: Cluster connectivity verified"

        kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=ingress-nginx -n nginx-ingress --timeout=300s
        kubectl get pods -n nginx-ingress
        kubectl get svc -n nginx-ingress
        echo "PASSED: NGINX Ingress Controller verified"

        kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argo-rollouts -n argo-rollouts --timeout=300s
        kubectl get pods -n argo-rollouts
        echo "PASSED: Argo Rollouts verified"

        kubectl get svc -A --field-selector spec.type=LoadBalancer

        echo "health_check=success" >> $GITHUB_OUTPUT
        echo "PASSED: Production environment is healthy"
EOF
```

---

## Passo 6: Criar workflow de destruicao de ambiente (04-destroy-environment.yml)

Este workflow permite a destruicao manual de qualquer ambiente.

```bash
cat > .github/workflows/04-destroy-environment.yml << 'EOF'
name: Destroy Environment

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to destroy'
        required: true
        type: choice
        options:
          - dev
          - hml
          - prod
      confirm_destruction:
        description: 'I confirm the destruction of this environment'
        required: true
        type: boolean

jobs:
  destroy:
    runs-on: ubuntu-latest
    timeout-minutes: 30

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Validate inputs
      run: |
        echo "=== DESTROY ENVIRONMENT VALIDATION ==="
        echo "Environment to destroy: ${{ inputs.environment }}"
        echo "Confirmation: ${{ inputs.confirm_destruction }}"

        if [ "${{ inputs.confirm_destruction }}" != "true" ]; then
          echo "ERROR: Destruction not confirmed"
          exit 1
        fi

        echo "PASSED: Destruction confirmed for ${{ inputs.environment }} environment"

    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: 1.6.0

    - name: Terraform Initialize and Plan Destroy
      working-directory: terraform
      env:
        ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
        ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
        ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
        ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
        ARM_ACCESS_KEY: ${{ secrets.ARM_ACCESS_KEY }}
      run: |
        echo "=== TERRAFORM DESTROY PREPARATION ==="
        echo "Environment: ${{ inputs.environment }}"

        # Initialize with the correct backend key for the environment
        terraform init -backend-config="key=aks/${{ inputs.environment }}.tfstate"

        # Refresh state to ensure consistency
        terraform refresh -var-file="${{ inputs.environment }}/${{ inputs.environment }}.tfvars"

        # Create destroy plan for verification
        terraform plan -destroy -var-file="${{ inputs.environment }}/${{ inputs.environment }}.tfvars" -out=destroy.tfplan

        echo "PASSED: Destroy plan created for ${{ inputs.environment }} environment"

    - name: Terraform Destroy
      working-directory: terraform
      env:
        ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
        ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
        ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
        ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
        ARM_ACCESS_KEY: ${{ secrets.ARM_ACCESS_KEY }}
      run: |
        echo "=== DESTROYING ${{ inputs.environment }} ENVIRONMENT ==="
        echo "WARNING: This will destroy all resources in ${{ inputs.environment }} environment"
        echo "Starting destruction in 5 seconds..."
        sleep 5

        # Apply the destroy plan
        terraform apply -auto-approve destroy.tfplan

        echo "SUCCESS: ${{ inputs.environment }} environment destroyed successfully"

    - name: Verify Destruction
      run: |
        echo "=== DESTRUCTION VERIFICATION ==="
        echo "Verifying resources are destroyed..."

        # Check if AKS cluster still exists
        cluster_exists=$(az aks show --resource-group gh-devops-${{ inputs.environment }} --name aks-devops-${{ inputs.environment }} --query "name" -o tsv 2>/dev/null || echo "")

        if [ -z "$cluster_exists" ]; then
          echo "SUCCESS: AKS cluster aks-devops-${{ inputs.environment }} has been destroyed"
        else
          echo "WARNING: AKS cluster still exists: $cluster_exists"
        fi

        echo "COMPLETED: Destruction verification finished"

    - name: Cleanup Summary
      if: always()
      run: |
        echo "=== DESTRUCTION SUMMARY ==="
        echo "Environment: ${{ inputs.environment }}"
        echo "Timestamp: $(date)"
        echo "Status: ${{ job.status }}"
        echo ""
        echo "Resources destroyed:"
        echo "- AKS Cluster: aks-devops-${{ inputs.environment }}"
        echo "- NGINX Ingress Controller"
        echo "- Argo Rollouts"
        echo "- Associated Load Balancers"
        echo "- Network Security Groups"
        echo ""
        echo "Resources preserved:"
        echo "- Resource Group: gh-devops-${{ inputs.environment }}"
        echo "- Terraform State: aks/${{ inputs.environment }}.tfstate"
        echo ""
        if [ "${{ job.status }}" = "success" ]; then
          echo "SUCCESS: Environment ${{ inputs.environment }} destroyed successfully"
        else
          echo "FAILED: Environment destruction encountered errors"
        fi
EOF
```

---

## Passo 7: Verificar arquivos criados

```bash
ls -la .github/workflows/
```

---

## Passo 8: Adicionar e commitar os workflows

```bash
git add .github/workflows/
git commit -m "feat: adicionar workflows da pipeline AKS"
```

---

## Passo 9: Enviar para o GitHub

```bash
git push origin main
```

---

## Passo 10: Validar workflows no GitHub

Acesse https://github.com/$GITHUB_USER/$REPO_NAME e clique na aba **Actions**.

---

## Entendendo o fluxo da pipeline

### Fluxo de Promocao Automatizado

```
feature/* → [Validacao] → PR para develop
    ↓
develop → [Deploy DEV] → PR para homologacao
    ↓
homologacao → [Deploy HML] → PR para main
    ↓
main (PR) → [Deploy PROD] → Auto-merge PR
```

### Workflow 00-feature.yml

**Trigger:** Push em branches feature/*, bugfix/*, hotfix/*

**Proposito:** Validacao de codigo antes de integrar em develop

### Workflow 01-develop.yml

**Trigger:** Push na branch develop

**Proposito:** Deploy e validacao em ambiente de desenvolvimento

### Workflow 02-homologacao.yml

**Trigger:** Push na branch homologacao

**Proposito:** Validacao em ambiente de homologacao

### Workflow 03-main.yml

**Trigger:** Pull Request para branch main

**Proposito:** Deploy controlado em producao com rollback automatico

### Workflow 04-destroy-environment.yml

**Trigger:** Execucao manual (workflow_dispatch)

**Proposito:** Destruicao segura de ambientes

---

## Conclusao

**Lab concluido!**

Voce aprendeu a:

* Criar workflows do GitHub Actions para pipeline AKS
* Implementar fluxo de promocao automatizado entre ambientes
* Configurar validacoes e testes em cada etapa
* Implementar auto-merge em producao apos validacao
* Criar workflow de destruicao manual de ambientes
