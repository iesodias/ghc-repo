## Lab 01: Variáveis de Ambiente Básicas no GitHub Actions

### Objetivo

Neste lab, você aprenderá a trabalhar com variáveis de ambiente em diferentes níveis de um workflow do GitHub Actions: no nível do workflow, no nível do job e no nível do step. Ao final, você saberá como declarar e utilizar essas variáveis de forma prática e organizada.

---

### 1. Criar estrutura local

```bash
# Crie o diretório base e acesse-o
mkdir lab-variaveis-ambiente
cd lab-variaveis-ambiente
```

---

### 2. Criar repositório no GitHub

1. Acesse [https://github.com](https://github.com)
2. Clique em **New Repository**
3. Nome: `lab-variaveis-ambiente`
4. Deixe **sem README**, **sem .gitignore**, **sem license** (vamos configurar localmente)

---

### 3. Inicializar Git e conectar com repositório remoto

```bash
git init
git remote add origin https://github.com/SEU_USUARIO/lab-variaveis-ambiente.git
echo "# lab-variaveis-ambiente" > README.md
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

Crie o arquivo `.github/workflows/variaveis-ambiente.yml` com o conteúdo abaixo:

```yaml
name: Demonstração de Variáveis de Ambiente

on:
  push:
    branches:
      - main
  workflow_dispatch:

# Variáveis de ambiente no nível do WORKFLOW
env:
  WORKFLOW_VAR: "Variável definida no nível do workflow"
  AMBIENTE: "producao"
  VERSAO_APP: "1.0.0"

jobs:
  demonstracao-variaveis:
    runs-on: ubuntu-latest

    # Variáveis de ambiente no nível do JOB
    env:
      JOB_VAR: "Variável definida no nível do job"
      USUARIO: "devops-user"

    steps:
      - name: Exibir variáveis do workflow
        run: |
          echo "=== Variáveis do Workflow ==="
          echo "Variável WORKFLOW_VAR: ${{ env.WORKFLOW_VAR }}"
          echo "Ambiente: ${{ env.AMBIENTE }}"
          echo "Versão da aplicação: ${{ env.VERSAO_APP }}"

      - name: Exibir variáveis do job
        run: |
          echo "=== Variáveis do Job ==="
          echo "Variável JOB_VAR: ${{ env.JOB_VAR }}"
          echo "Usuário: ${{ env.USUARIO }}"

      - name: Exibir variável do step
        env:
          STEP_VAR: "Variável definida no nível do step"
          MENSAGEM: "Este é um exemplo prático!"
        run: |
          echo "=== Variáveis do Step ==="
          echo "Variável STEP_VAR: ${{ env.STEP_VAR }}"
          echo "Mensagem: ${{ env.MENSAGEM }}"

      - name: Combinar variáveis de diferentes níveis
        env:
          STEP_ESPECIFICO: "step-value"
        run: |
          echo "=== Combinação de Variáveis ==="
          echo "Workflow: ${{ env.WORKFLOW_VAR }}"
          echo "Job: ${{ env.JOB_VAR }}"
          echo "Step: ${{ env.STEP_ESPECIFICO }}"
          echo "Todas acessíveis no mesmo contexto!"

      - name: Usar variáveis em comandos práticos
        env:
          NOME_PROJETO: "lab-variaveis"
          TIMESTAMP: "2025-01-13"
        run: |
          echo "=== Exemplo Prático ==="
          echo "Compilando projeto: ${{ env.NOME_PROJETO }}"
          echo "Data de build: ${{ env.TIMESTAMP }}"
          echo "Ambiente de deploy: ${{ env.AMBIENTE }}"
          echo "Versão: ${{ env.VERSAO_APP }}"
```

---

### 6. Subir alterações para o GitHub

```bash
git add .
git commit -m "add workflow de variáveis de ambiente"
git push
```

---

### 7. Verificar resultado

1. Acesse o repositório no GitHub
2. Clique na aba **Actions**
3. Verifique se o workflow foi executado corretamente
4. Abra os logs de cada step e confirme se as variáveis estão sendo exibidas com seus respectivos valores
5. Observe como variáveis de diferentes níveis (workflow, job, step) são acessadas da mesma forma

---

### Dica Extra

**Precedência de variáveis**: Se você definir uma variável com o mesmo nome em diferentes níveis, a ordem de precedência é:
1. **Step** (maior prioridade)
2. **Job**
3. **Workflow** (menor prioridade)

Experimente criar uma variável chamada `TESTE` nos três níveis e veja qual valor é usado em cada contexto!

Você também pode combinar variáveis de ambiente com secrets do GitHub para dados sensíveis:
```yaml
env:
  API_URL: "https://api.exemplo.com"
  API_KEY: ${{ secrets.API_KEY }}
```

---

### Conclusão

> Parabéns! Você aprendeu a trabalhar com variáveis de ambiente em diferentes níveis do GitHub Actions. Agora você pode organizar melhor seus workflows, reutilizar valores e manter seu código mais limpo e manutenível!
