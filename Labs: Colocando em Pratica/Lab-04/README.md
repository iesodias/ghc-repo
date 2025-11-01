# Lab 04 - Passo a Passo: Issue Trigger Workflow

## Objetivo
Criar workflow que executa automaticamente quando issues são criadas, editadas, fechadas ou recebem labels, com resposta automática.

## Passo 1: Criar Workflow Issue Trigger
1. No seu repositório `pipeline-labs`, criar arquivo `lab-04.yml` em `.github/workflows/`:

```yaml
name: Issue Trigger Workflow
# Permissões para permitir comentários automáticos
permissions:
  issues: write

# Executa quando issues são criadas, editadas ou fechadas
on:
  issues:
    types: [opened, edited, closed, labeled]

jobs:
  issue-job:
    runs-on: ubuntu-latest
    
    steps:
    - name: Informações da Issue
      run: |
        echo "Workflow disparado por ISSUE"
        echo "Ação: ${{ github.event.action }}"
        echo "Issue #${{ github.event.issue.number }}"
        echo "Título: ${{ github.event.issue.title }}"
        echo "Autor: ${{ github.event.issue.user.login }}"
        echo "Labels: ${{ join(github.event.issue.labels.*.name, ', ') }}"
    
    - name: Resposta automática (nova issue)
      if: github.event.action == 'opened'
      uses: actions/github-script@v7
      with:
        script: |
          github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: 'Obrigado por reportar esta issue! Nossa equipe irá analisá-la em breve.'
          })
```

## Passo 2: Enviar para GitHub
```bash
cd pipeline-labs
git add .
git commit -m "feat: adicionar Lab 04 - Issue Trigger"
git push origin main
```

## Passo 3: Testar Criando Issue
1. Vá para seu repositório no GitHub
2. Clique na aba **"Issues"**
3. Clique **"New issue"**
4. Título: "Teste do Lab 04"
5. Descrição: "Esta é uma issue de teste para o workflow"
6. Clique **"Submit new issue"**

## Passo 4: Verificar Execução
1. Vá para aba **"Actions"** no GitHub
2. Veja o workflow **"Issue Trigger Workflow"** executando
3. Clique no job para ver os logs
4. Volte para a issue criada e veja o comentário automático

## Teste: Adicionar Label
1. Na issue criada, clique **"Labels"**
2. Adicione label "bug" ou "enhancement"
3. Vá para Actions e veja nova execução do workflow

## Teste: Fechar Issue
1. Na issue, clique **"Close issue"**
2. Vá para Actions e veja nova execução do workflow
3. Verifique nos logs que `github.event.action` = "closed"

## O que o workflow faz:
- Monitora events: opened, edited, closed, labeled
- Mostra informações detalhadas da issue
- Adiciona comentário automático em novas issues
- Executa apenas quando há atividade em issues

**✅ Lab concluído! Workflow com issue trigger está funcionando.**