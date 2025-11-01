# Lab 03 - Passo a Passo: Push Trigger Workflow

## Objetivo
Criar workflow que executa apenas em push para branches específicas e quando arquivos específicos são modificados.

## Passo 1: Criar Workflow Push Trigger
1. No seu repositório `pipeline-labs`, criar arquivo `lab-03.yml` em `.github/workflows/`:

```yaml
name: Push Trigger Workflow

### Executa apenas em push
on:
  push:
    branches: 
      - main
      - develop
    paths:
      - 'src/**' # CRIAR ESSES ARQUIVOS PARA FUNCIONAR
      - 'README.md' # CRIAR ESSES ARQUIVOS PARA FUNCIONAR

jobs:
  push-job:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout código
      uses: actions/checkout@v4
    
    - name: Informações do Push
      run: |
        echo "Workflow disparado por PUSH"
        echo "Commit: ${{ github.sha }}"
        echo "Autor: ${{ github.actor }}"
        echo "Branch: ${{ github.ref_name }}"
        echo "Repositório: ${{ github.repository }}"
    
    - name: Listar arquivos modificados
      run: |
        echo "Arquivos no repositório:"
        ls -la
```

## Passo 2: Criar Estrutura de Arquivos Necessária
```bash
cd pipeline-labs

# Criar pasta src
mkdir src

# Criar arquivo dentro de src
echo "console.log('Hello World');" > src/app.js

# Criar README.md (se não existe)
echo "# Pipeline Labs - Projeto de Testes" > README.md
```

## Passo 3: Enviar para GitHub
```bash
git add .
git commit -m "feat: adicionar Lab 03 - Push Trigger"
git push origin main
```

## Passo 4: Verificar Execução
1. Vá para aba **"Actions"** no GitHub
2. Veja o workflow **"Push Trigger Workflow"** executando
3. Clique no job para ver os logs de cada step

## Teste: Push que NÃO Executa
```bash
# Criar arquivo fora do path configurado
echo "test" > test.txt
git add test.txt
git commit -m "arquivo fora do src"
git push origin main
```
**Resultado**: Workflow NÃO executa (arquivo não está em src/ nem é README.md)

## Teste: Push que EXECUTA
```bash
# Modificar arquivo em src/
echo "// Nova linha" >> src/app.js
git add .
git commit -m "modificando arquivo em src"
git push origin main
```
**Resultado**: Workflow EXECUTA (arquivo está em src/)

**✅ Lab concluído! Workflow com push trigger específico está funcionando.**