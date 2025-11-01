# Lab 01 - Estrutura de Diretórios e Arquivos - PASSO A PASSO

## Objetivo
Demonstrar na prática a estrutura de diretórios `.github/workflows/`, elementos obrigatórios de um workflow e uso de variáveis.

---

## Passo 1: Criar o arquivo do workflow

Crie o arquivo `.github/workflows/lab-08.yaml` com o seguinte conteúdo:

```yaml
# Nome do workflow que aparece na interface do GitHub Actions
name: "Lab 01 - Estrutura de Diretórios e Arquivos"

# Define quando o workflow será executado
on:
  push:                    # Executa quando houver push
    branches: [ main ]     # Apenas na branch main
  workflow_dispatch:       # Permite execução manual pela interface

# Variáveis de ambiente globais do workflow
env:
  NODE_VERSION: '18'       # Disponível em todos os jobs e steps

# Define os trabalhos (jobs) que serão executados
jobs:
  demonstrar-estrutura:                  # ID único do job
    name: "Demonstrar Estrutura Básica"  # Nome exibido na interface
    runs-on: ubuntu-latest               # Sistema operacional do runner
    
    # Lista de etapas (steps) executadas sequencialmente
    steps:
      # Step 1: Faz checkout do código do repositório
      - name: Checkout do código
        uses: actions/checkout@v4        # Usa action pré-construída
      
      # Step 2: Lista arquivos no diretório .github/workflows
      - name: Mostrar estrutura .github/workflows
        run: |                           # Executa comandos shell
          echo "=== ESTRUTURA DO DIRETÓRIO .github/workflows ==="
          ls -la .github/workflows/
          echo ""
          echo "Total de workflows: $(ls -1 .github/workflows/*.y*ml 2>/dev/null | wc -l)"
      
      # Step 3: Mostra os 3 elementos obrigatórios de um workflow
      - name: Elementos obrigatórios do workflow
        run: |
          echo "=== ELEMENTOS OBRIGATÓRIOS ==="
          echo "1. name: Nome do workflow"
          echo "2. on: Eventos de trigger (push, workflow_dispatch)"
          echo "3. jobs: Tarefas a executar"
      
      # Step 4: Demonstra uso de variáveis e contextos do GitHub
      - name: Variáveis e contextos
        run: |
          echo "=== VARIÁVEIS E CONTEXTOS ==="
          echo "Variável env: ${{ env.NODE_VERSION }}"      # Acessa variável de ambiente
          echo "Repositório: ${{ github.repository }}"      # Contexto do GitHub
          echo "Branch: ${{ github.ref_name }}"             # Nome da branch
          echo "Actor: ${{ github.actor }}"                 # Usuário que executou
```

---

## Passo 2: Fazer commit e push

```bash
git add .github/workflows/lab-08.yaml
git commit -m "Lab 08: Estrutura de diretórios e arquivos"
git push origin main
```

---

## Passo 3: Verificar a execução

1. Acesse a aba **Actions** do seu repositório
2. Localize o workflow **"Lab 08 - Estrutura de Diretórios e Arquivos"**
3. Clique na execução mais recente
4. Analise os logs de cada step

**O que observar:**
- Lista de arquivos em `.github/workflows/`
- Total de workflows no repositório
- Os 3 elementos obrigatórios explicados
- Variáveis de ambiente e contextos do GitHub

---

## Passo 4: Testar execução manual

1. Na aba **Actions**, clique em **"Lab 08 - Estrutura de Diretórios e Arquivos"**
2. Clique em **"Run workflow"** → **"Run workflow"**
3. Observe a nova execução com evento `workflow_dispatch`

---

✅ **Lab concluído!** Você demonstrou:
- Estrutura `.github/workflows/`
- Elementos obrigatórios: `name`, `on`, `jobs`
- Variáveis de ambiente (`env`)
- Contextos do GitHub (`github.repository`, `github.actor`, etc.)
