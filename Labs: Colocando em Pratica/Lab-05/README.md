# Lab 05 - Passo a Passo: Jobs Paralelos

## Objetivo
Criar workflow com múltiplos jobs que executam em paralelo para otimizar tempo de execução.

## Passo 1: Criar Workflow Jobs Paralelos
1. No seu repositório `pipeline-labs`, criar arquivo `lab-05.yml` em `.github/workflows/`:

```yaml
name: Jobs Paralelos

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  # Job 1: Análise de código
  code-analysis:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout código
      uses: actions/checkout@v4
    
    - name: Análise de sintaxe
      run: |
        echo "Analisando sintaxe do código..."
        sleep 3
        echo "Análise de sintaxe concluída"
    
    - name: Verificar padrões de código
      run: |
        echo "Verificando padrões de código..."
        sleep 2
        echo "Padrões verificados"
    
    - name: Upload relatório análise
      run: |
        echo "Fazendo upload do relatório..."
        echo "Relatório de análise gerado em $(date)" > analysis-report.txt
        echo "Relatório salvo"

  # Job 2: Testes unitários (executa em paralelo com code-analysis)
  unit-tests:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout código
      uses: actions/checkout@v4
    
    - name: Configurar ambiente de testes
      run: |
        echo "Configurando ambiente de testes..."
        sleep 2
        echo "Ambiente configurado"
    
    - name: Executar testes unitários
      run: |
        echo "Executando testes unitários..."
        sleep 4
        echo "Todos os testes passaram (15/15)"
    
    - name: Gerar relatório de cobertura
      run: |
        echo "Gerando relatório de cobertura..."
        sleep 1
        echo "Cobertura: 85%"

  # Job 3: Build da aplicação (executa em paralelo)
  build:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout código
      uses: actions/checkout@v4
    
    - name: Configurar ambiente de build
      run: |
        echo "Configurando ambiente de build..."
        sleep 2
        echo "Ambiente configurado"
    
    - name: Compilar aplicação
      run: |
        echo "Compilando aplicação..."
        sleep 5
        echo "Build concluído com sucesso"
    
    - name: Gerar artefatos
      run: |
        echo "Gerando artefatos..."
        mkdir -p build
        echo "Aplicação compilada em $(date)" > build/app.jar
        echo "Artefatos gerados"
    
    - name: Upload artefatos
      uses: actions/upload-artifact@v4
      with:
        name: build-artifacts
        path: build/
```

## Passo 2: Enviar para GitHub
```bash
cd pipeline-labs
git add .
git commit -m "feat: adicionar Lab 05 - Jobs Paralelos"
git push origin main
```

## Passo 3: Verificar Execução
1. Vá para aba **"Actions"** no GitHub
2. Veja o workflow **"Jobs Paralelos"** executando
3. Observe que os 3 jobs executam **simultaneamente**
4. Clique em cada job para ver os logs

## Teste Manual
1. Na aba Actions, clique em "Jobs Paralelos"
2. Clique **"Run workflow"** → **"Run workflow"**
3. Observe o paralelismo dos jobs em tempo real

## Passo 4: Verificar Artefatos
1. Após execução completa, clique no workflow executado
2. Role para baixo e veja seção **"Artifacts"**
3. Baixe o artefato `build-artifacts`
4. Descompacte e veja o arquivo `app.jar`

## O que o workflow faz:
- **Job 1 (code-analysis)**: Analisa código e padrões
- **Job 2 (unit-tests)**: Executa testes unitários
- **Job 3 (build)**: Compila aplicação e gera artefatos
- Todos executam **em paralelo** para economizar tempo
- Upload de artefato para download posterior

## Vantagem dos Jobs Paralelos:
- **Sequencial**: ~12 segundos (3+2+1+2+4+1+2+5 = 20s)
- **Paralelo**: ~7 segundos (máximo entre os jobs)

**✅ Lab concluído! Workflow com jobs paralelos está funcionando.**