# Lab 06 - Passo a Passo: Matrix Strategy

## Objetivo
Criar workflow que executa testes em múltiplos sistemas operacionais e versões usando matrix strategy.

## Passo 1: Criar Workflow Matrix Strategy
1. No seu repositório `pipeline-labs`, criar arquivo `lab-06.yml` em `.github/workflows/`:

```yaml
name: Matrix Strategy

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  # Job com matrix para múltiplos ambientes
  test-matrix:
    runs-on: ${{ matrix.os }}
    
    strategy:
      fail-fast: false  # Não para se um job falhar
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        node-version: [16, 18, 20]
        include:
          # Configurações específicas
          - os: ubuntu-latest
            node-version: 20
            experimental: true
        exclude:
          # Excluir combinações problemáticas
          - os: windows-latest
            node-version: 16
    
    steps:
    - name: Checkout código
      uses: actions/checkout@v4
    
    - name: Informações da matrix
      run: |
        echo "OS: ${{ matrix.os }}"
        echo "Node: ${{ matrix.node-version }}"
        echo "Experimental: ${{ matrix.experimental }}"
    
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: ${{ matrix.node-version }}
    
    - name: Verificar versões
      run: |
        echo "Node version: $(node --version)"
        echo "NPM version: $(npm --version)"
    
    - name: Executar testes específicos do OS
      run: |
        echo "Executando testes no ${{ matrix.os }} com Node ${{ matrix.node-version }}..."
        sleep 2
        echo "Testes concluídos"
    
    - name: Teste experimental
      if: matrix.experimental == true
      run: |
        echo "Executando testes experimentais..."
        sleep 1
        echo "Testes experimentais concluídos"

  # Job que coleta resultados da matrix
  collect-results:
    runs-on: ubuntu-latest
    needs: test-matrix
    
    steps:
    - name: Coletar resultados
      run: |
        echo "Coletando resultados de todos os jobs da matrix..."
        echo "Todos os testes da matrix foram executados"
```

## Passo 2: Enviar para GitHub
```bash
cd pipeline-labs
git add .
git commit -m "feat: adicionar Lab 06 - Matrix Strategy"
git push origin main
```

## Passo 3: Verificar Execução
1. Vá para aba **"Actions"** no GitHub
2. Veja o workflow **"Matrix Strategy"** executando
3. Observe **8 jobs paralelos** criados pela matrix
4. Clique em diferentes jobs para ver OS e Node versions diferentes

## Teste Manual
1. Na aba Actions, clique em "Matrix Strategy"
2. Clique **"Run workflow"** → **"Run workflow"**
3. Observe todos os jobs da matrix executando simultaneamente

## Passo 4: Analisar Matrix Jobs
1. Após execução, veja a lista de jobs:
   - `test-matrix (ubuntu-latest, 16)`
   - `test-matrix (ubuntu-latest, 18)`
   - `test-matrix (ubuntu-latest, 20)` ← **Com experimental**
   - `test-matrix (windows-latest, 18)`
   - `test-matrix (windows-latest, 20)`
   - `test-matrix (macos-latest, 16)`
   - `test-matrix (macos-latest, 18)`
   - `test-matrix (macos-latest, 20)`
2. **Nota**: `windows-latest, 16` foi **excluído** pela configuração

## Passo 5: Verificar Job Dependente
1. Veja que `collect-results` executa **após** todos os jobs da matrix
2. Clique no job para ver que coletou resultados de todos

## O que o workflow faz:
- **Matrix**: 3 OS × 3 Node versions = 9 combinações
- **Exclude**: Remove Windows + Node 16 = 8 jobs finais
- **Include**: Adiciona flag experimental para Ubuntu + Node 20
- **fail-fast: false**: Continua mesmo se um job falhar
- **needs**: Job final aguarda todos da matrix terminarem

## Vantagens da Matrix Strategy:
- Testa **múltiplos ambientes** simultaneamente
- **Detecta problemas** específicos de OS/versão
- **Paralelização automática** pelo GitHub
- **Configurações flexíveis** com include/exclude

**✅ Lab concluído! Workflow com matrix strategy está funcionando.**