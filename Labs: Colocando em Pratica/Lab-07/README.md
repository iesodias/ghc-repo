# Lab 07 - Passo a Passo: Steps Condicionais

## Objetivo
Criar workflow com steps condicionais que executam baseados em eventos, branches, inputs e status de execução.

## Passo 1: Criar Workflow Steps Condicionais
1. No seu repositório `pipeline-labs`, criar arquivo `lab-07.yml` em `.github/workflows/`:

```yaml
name: Steps Condicionais

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:
    inputs:
      run_tests:
        description: 'Executar testes?'
        required: false
        default: true
        type: boolean
      deploy_environment:
        description: 'Ambiente para deploy'
        required: false
        default: 'none'
        type: choice
        options:
        - none
        - development
        - staging
        - production

jobs:
  conditional-steps:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout código
      uses: actions/checkout@v4
    
    - name: Step sempre executado
      run: |
        echo "Este step sempre executa"
        echo "Evento: ${{ github.event_name }}"
        echo "Branch: ${{ github.ref_name }}"
    
    - name: Step apenas em push
      if: github.event_name == 'push'
      run: |
        echo "Este step executa apenas em PUSH"
        echo "Commit: ${{ github.sha }}"
    
    - name: Step apenas em PR
      if: github.event_name == 'pull_request'
      run: |
        echo "Este step executa apenas em PULL REQUEST"
        echo "PR #${{ github.event.number }}"
    
    - name: Step apenas na main
      if: github.ref == 'refs/heads/main'
      run: |
        echo "Este step executa apenas na branch MAIN"
    
    - name: Executar testes (input manual)
      if: github.event.inputs.run_tests == 'true' || github.event_name != 'workflow_dispatch'
      run: |
        echo "Executando testes..."
        sleep 2
        echo "Testes concluídos"
    
    - name: Deploy para Development
      if: github.event.inputs.deploy_environment == 'development'
      run: |
        echo "Deploy para DEVELOPMENT"
        sleep 1
        echo "Deploy concluído"
    
    - name: Deploy para Staging
      if: github.event.inputs.deploy_environment == 'staging'
      run: |
        echo "Deploy para STAGING"
        sleep 2
        echo "Deploy concluído"
    
    - name: Deploy para Production
      if: github.event.inputs.deploy_environment == 'production'
      run: |
        echo "Deploy para PRODUCTION"
        echo "Aguardando aprovação manual..."
        sleep 3
        echo "Deploy concluído"
    
    - name: Step com múltiplas condições
      if: github.event_name == 'push' && github.ref == 'refs/heads/main' && success()
      run: |
        echo "Push na main com sucesso nos steps anteriores"
    
    - name: Step que executa mesmo com falha
      if: always()
      run: |
        echo "Este step sempre executa, mesmo se houver falhas"
        echo "Status dos jobs anteriores: ${{ job.status }}"
    
    - name: Step apenas se houver falha
      if: failure()
      run: |
        echo "Este step executa apenas se houver falha"
    
    - name: Cleanup
      if: always()
      run: |
        echo "Limpeza final sempre executada"
```

## Passo 2: Enviar para GitHub
```bash
cd pipeline-labs
git add .
git commit -m "feat: adicionar Lab 07 - Steps Condicionais"
git push origin main
```

## Passo 3: Testar Push (Automático)
1. Vá para aba **"Actions"** no GitHub
2. Veja o workflow **"Steps Condicionais"** executando
3. Observe quais steps executaram (push + main branch)

## Teste Manual com Inputs
1. Na aba Actions, clique em "Steps Condicionais"
2. Clique **"Run workflow"**
3. Configure inputs:
   - **run_tests**: ✓ (marcado)
   - **deploy_environment**: "staging"
4. Clique **"Run workflow"**
5. Veja execução com deploy para staging

## Teste Manual - Deploy Production
1. Execute workflow manualmente novamente
2. Configure:
   - **run_tests**: ✓ (marcado)
   - **deploy_environment**: "production"
3. Observe o deploy para production (mais longo)

## Passo 4: Criar Pull Request para Testar
```bash
# Criar nova branch
git checkout -b test-pr

# Fazer mudança
echo "# Nova funcionalidade" >> test.md

# Commit e push
git add .
git commit -m "test: adicionar arquivo para testar PR"
git push origin test-pr
```

1. No GitHub, vá para **"Pull requests"**
2. Clique **"New pull request"**
3. Selecione `test-pr` → `main`
4. Crie o PR
5. Veja workflow executando com steps de PR

## O que o workflow demonstra:
- **Condições por evento**: `if: github.event_name == 'push'`
- **Condições por branch**: `if: github.ref == 'refs/heads/main'`
- **Inputs manuais**: `if: github.event.inputs.deploy_environment == 'staging'`
- **Múltiplas condições**: `if: github.event_name == 'push' && github.ref == 'refs/heads/main'`
- **Status conditions**: `if: always()`, `if: failure()`, `if: success()`

## Tipos de Condições:
- **sempre**: sem `if` ou `if: always()`
- **sucesso**: `if: success()` (padrão)
- **falha**: `if: failure()`
- **cancelado**: `if: cancelled()`
- **personalizada**: `if: github.event_name == 'push'`

**✅ Lab concluído! Workflow com steps condicionais está funcionando.**