## Lab 04: Variáveis de Contexto e Expressões

### Objetivo

Aprender a utilizar variáveis de contexto do GitHub Actions (github, runner, job, steps) e expressões para criar workflows dinâmicos e inteligentes. Você vai entender como acessar informações sobre o repositório, ambiente de execução, status de jobs e outputs de steps, além de usar funções como contains(), startsWith(), format() e toJSON() para lógica condicional.

---

### 1. Criar estrutura local

```bash
# Crie o diretório base e acesse-o
mkdir lab-contextos-expressoes
cd lab-contextos-expressoes
```

---

### 2. Criar repositório no GitHub

1. Acesse [https://github.com](https://github.com)
2. Clique em **New Repository**
3. Nome: `lab-contextos-expressoes`
4. Deixe **sem README**, **sem .gitignore**, **sem license** (vamos configurar localmente)

---

### 3. Inicializar Git e conectar com repositório remoto

```bash
git init
git remote add origin https://github.com/SEU_USUARIO/lab-contextos-expressoes.git
echo "# lab-contextos-expressoes" > README.md
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

Crie o arquivo `.github/workflows/contextos-expressoes.yml` com o conteúdo abaixo:

```yaml
name: Contextos e Expressões

on:
  push:
    branches:
      - main
      - develop
      - 'feature/**'
  pull_request:
  workflow_dispatch:

jobs:
  # Job 1: Demonstra contextos github e runner
  info-contexto:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout código
        uses: actions/checkout@v4

      # Contexto GITHUB - Informações do repositório e evento
      - name: Exibir contexto GitHub
        run: |
          echo "Repositório: ${{ github.repository }}"
          echo "Ator que disparou: ${{ github.actor }}"
          echo "Branch/Ref: ${{ github.ref }}"
          echo "Nome do branch: ${{ github.ref_name }}"
          echo "Evento: ${{ github.event_name }}"
          echo "SHA do commit: ${{ github.sha }}"
          echo "Mensagem do commit: ${{ github.event.head_commit.message }}"

      # Contexto RUNNER - Informações do ambiente de execução
      - name: Exibir contexto Runner
        run: |
          echo "Sistema Operacional: ${{ runner.os }}"
          echo "Arquitetura: ${{ runner.arch }}"
          echo "Nome do runner: ${{ runner.name }}"
          echo "Diretório temporário: ${{ runner.temp }}"
          echo "Diretório de ferramentas: ${{ runner.tool_cache }}"

      # Dump completo dos contextos para debug
      - name: Debug - Dump contexto GitHub completo
        run: echo '${{ toJSON(github) }}'

      - name: Debug - Dump contexto Runner completo
        run: echo '${{ toJSON(runner) }}'

  # Job 2: Demonstra outputs de steps e referências entre steps
  outputs-entre-steps:
    runs-on: ubuntu-latest
    outputs:
      # Exporta output para outros jobs usarem
      versao: ${{ steps.gerar-versao.outputs.version }}
      ambiente: ${{ steps.definir-ambiente.outputs.env_name }}
    steps:
      - name: Checkout código
        uses: actions/checkout@v4

      # Step que GERA um output
      - name: Gerar versão
        id: gerar-versao
        run: |
          VERSION="1.0.${{ github.run_number }}"
          echo "version=$VERSION" >> $GITHUB_OUTPUT
          echo "Versão gerada: $VERSION"

      # Step que GERA outro output
      - name: Definir ambiente baseado no branch
        id: definir-ambiente
        run: |
          if [[ "${{ github.ref }}" == "refs/heads/main" ]]; then
            ENV_NAME="production"
          elif [[ "${{ github.ref }}" == "refs/heads/develop" ]]; then
            ENV_NAME="staging"
          else
            ENV_NAME="development"
          fi
          echo "env_name=$ENV_NAME" >> $GITHUB_OUTPUT
          echo "Ambiente definido: $ENV_NAME"

      # Step que USA outputs de steps anteriores
      - name: Usar outputs dos steps anteriores
        run: |
          echo "Usando versão: ${{ steps.gerar-versao.outputs.version }}"
          echo "Usando ambiente: ${{ steps.definir-ambiente.outputs.env_name }}"
          echo "Tag completa: ${{ steps.definir-ambiente.outputs.env_name }}-v${{ steps.gerar-versao.outputs.version }}"

  # Job 3: Demonstra expressões e funções
  expressoes-e-funcoes:
    runs-on: ubuntu-latest
    # Usa output do job anterior
    needs: outputs-entre-steps
    steps:
      - name: Checkout código
        uses: actions/checkout@v4

      # Função contains() - Verifica se string contém texto
      - name: Verificar se é hotfix
        if: contains(github.ref, 'hotfix')
        run: echo "Este é um branch de HOTFIX - processo especial ativado!"

      # Função startsWith() - Verifica início da string
      - name: Ação apenas para feature branches
        if: startsWith(github.ref, 'refs/heads/feature/')
        run: echo "Branch de feature detectado: ${{ github.ref_name }}"

      # Função endsWith() - Verifica fim da string
      - name: Verificar se commit termina com número
        run: |
          if [[ "${{ endsWith(github.sha, '0') }}" == "true" ]]; then
            echo "SHA termina com zero!"
          else
            echo "SHA: ${{ github.sha }}"
          fi

      # Função format() - Formata strings dinamicamente
      - name: Criar mensagem formatada
        run: |
          MESSAGE="${{ format('Deploy da versão {0} para {1} por {2}', needs.outputs-entre-steps.outputs.versao, needs.outputs-entre-steps.outputs.ambiente, github.actor) }}"
          echo "$MESSAGE"

      # Expressão complexa com múltiplas condições
      - name: Deploy condicional
        if: |
          github.event_name == 'push' &&
          (github.ref == 'refs/heads/main' || github.ref == 'refs/heads/develop')
        run: |
          echo "Executando deploy automático..."
          echo "Versão: ${{ needs.outputs-entre-steps.outputs.versao }}"
          echo "Ambiente: ${{ needs.outputs-entre-steps.outputs.ambiente }}"

  # Job 4: Demonstra contexto JOB e verificação de status
  verificar-status:
    runs-on: ubuntu-latest
    needs: [info-contexto, outputs-entre-steps, expressoes-e-funcoes]
    if: always() # Sempre executa, mesmo se jobs anteriores falhem
    steps:
      - name: Verificar status dos jobs anteriores
        run: |
          echo "Status do job atual: ${{ job.status }}"
          echo "Analisando jobs anteriores..."

          # Verifica resultado do needs
          if [[ "${{ needs.info-contexto.result }}" == "success" ]]; then
            echo "info-contexto: SUCESSO"
          else
            echo "info-contexto: FALHOU"
          fi

          if [[ "${{ needs.outputs-entre-steps.result }}" == "success" ]]; then
            echo "outputs-entre-steps: SUCESSO"
          else
            echo "outputs-entre-steps: FALHOU"
          fi

          if [[ "${{ needs.expressoes-e-funcoes.result }}" == "success" ]]; then
            echo "expressoes-e-funcoes: SUCESSO"
          else
            echo "expressoes-e-funcoes: FALHOU"
          fi

      # Ação condicional baseada em sucesso de todos os jobs
      - name: Notificar sucesso total
        if: |
          needs.info-contexto.result == 'success' &&
          needs.outputs-entre-steps.result == 'success' &&
          needs.expressoes-e-funcoes.result == 'success'
        run: echo "Todos os jobs executaram com SUCESSO!"

      # Ação condicional se algum job falhou
      - name: Notificar falha
        if: |
          needs.info-contexto.result == 'failure' ||
          needs.outputs-entre-steps.result == 'failure' ||
          needs.expressoes-e-funcoes.result == 'failure'
        run: |
          echo "Pelo menos um job FALHOU!"
          echo "Verifique os logs acima para mais detalhes."

  # Job 5: Caso de uso prático - Nomear artefatos dinamicamente
  criar-artefato-dinamico:
    runs-on: ubuntu-latest
    needs: outputs-entre-steps
    steps:
      - name: Checkout código
        uses: actions/checkout@v4

      - name: Criar arquivo de build simulado
        run: |
          mkdir -p build
          echo "Build info" > build/info.txt
          echo "Versão: ${{ needs.outputs-entre-steps.outputs.versao }}" >> build/info.txt
          echo "Ambiente: ${{ needs.outputs-entre-steps.outputs.ambiente }}" >> build/info.txt
          echo "Branch: ${{ github.ref_name }}" >> build/info.txt
          echo "Commit: ${{ github.sha }}" >> build/info.txt
          echo "Actor: ${{ github.actor }}" >> build/info.txt
          cat build/info.txt

      # Nome do artefato usa expressões para ser dinâmico
      - name: Upload artefato com nome dinâmico
        uses: actions/upload-artifact@v4
        with:
          # Nome formatado dinamicamente: app-production-v1.0.123-abc1234
          name: ${{ format('app-{0}-v{1}-{2}', needs.outputs-entre-steps.outputs.ambiente, needs.outputs-entre-steps.outputs.versao, github.sha) }}
          path: build/
          retention-days: 5
```

---

### 6. Subir alterações para o GitHub

```bash
git add .
git commit -m "add workflow de contextos e expressões"
git push
```

---

### 7. Verificar resultado

1. Acesse o repositório no GitHub
2. Clique na aba **Actions**
3. Verifique se o workflow "Contextos e Expressões" foi executado
4. Analise os logs de cada job:

#### Job "info-contexto":
- Veja todas as informações do contexto **github** (repositório, ator, branch, SHA, evento)
- Veja todas as informações do contexto **runner** (OS, arquitetura, nome)
- Examine o dump completo em JSON dos contextos (útil para debug)

#### Job "outputs-entre-steps":
- Observe como a versão é gerada dinamicamente com `github.run_number`
- Veja como o ambiente é definido baseado no branch atual
- Confira como os outputs são usados em steps posteriores

#### Job "expressoes-e-funcoes":
- Se criar um branch `feature/nova-funcionalidade`, verá a mensagem específica para features
- Se criar um branch `hotfix/correcao`, verá a mensagem de hotfix
- Observe as mensagens formatadas usando `format()`
- Veja que o deploy condicional só executa em push para main ou develop

#### Job "verificar-status":
- Sempre executa devido ao `if: always()`
- Mostra o status de todos os jobs anteriores
- Demonstra como criar lógica de notificação baseada em resultados

#### Job "criar-artefato-dinamico":
- Acesse a aba **Actions** → clique no workflow → seção **Artifacts**
- Veja que o artefato tem um nome dinâmico como: `app-production-v1.0.42-abc1234def`
- Baixe o artefato e veja o arquivo `info.txt` com todos os dados de contexto

**Para testar diferentes cenários:**

```bash
# Teste 1: Criar um branch de feature
git checkout -b feature/teste-contextos
git push -u origin feature/teste-contextos
# Veja que o job "expressoes-e-funcoes" detecta o branch de feature

# Teste 2: Criar um branch de hotfix
git checkout -b hotfix/correcao-urgente
git push -u origin hotfix/correcao-urgente
# Veja que o step "Verificar se é hotfix" será executado

# Teste 3: Fazer push no develop
git checkout -b develop
git push -u origin develop
# Veja que o ambiente será "staging" e o deploy condicional executará
```

---

### Dica Extra

#### Principais Contextos Disponíveis:

| Contexto | Quando Usar | Exemplo |
|----------|-------------|---------|
| **github** | Informações do repositório, evento, commit, PR | `${{ github.repository }}`, `${{ github.actor }}` |
| **runner** | Informações do ambiente de execução | `${{ runner.os }}`, `${{ runner.arch }}` |
| **job** | Status do job atual | `${{ job.status }}` |
| **steps** | Outputs de steps anteriores | `${{ steps.meu-step.outputs.valor }}` |
| **needs** | Outputs e resultados de jobs anteriores | `${{ needs.outro-job.outputs.versao }}` |
| **env** | Variáveis de ambiente | `${{ env.MINHA_VAR }}` |
| **secrets** | Secrets do repositório | `${{ secrets.API_KEY }}` |

#### Funções Úteis de Expressões:

```yaml
# contains() - Verifica se contém texto
if: contains(github.ref, 'feature')
if: contains(github.event.head_commit.message, '[skip ci]')

# startsWith() - Verifica início
if: startsWith(github.ref, 'refs/heads/release/')

# endsWith() - Verifica fim
if: endsWith(github.ref, '/main')

# format() - Formata strings
run: echo "${{ format('Versão {0} em {1}', env.VERSION, env.ENV) }}"

# toJSON() - Converte para JSON (ótimo para debug)
run: echo '${{ toJSON(github) }}'
run: echo '${{ toJSON(steps) }}'

# join() - Junta arrays
run: echo "${{ join(github.event.commits.*.message, ', ') }}"

# fromJSON() - Parse JSON
env:
  CONFIG: ${{ fromJSON('{"env":"prod","debug":false}') }}
```

#### Casos de Uso Práticos:

1. **Nomear artefatos com informações dinâmicas:**
```yaml
name: app-${{ github.ref_name }}-${{ github.run_number }}-${{ github.sha }}
```

2. **Deploy apenas em horário comercial (9h-18h UTC):**
```yaml
if: github.event_name == 'push' && github.ref == 'refs/heads/main' &&
    github.event.head_commit.timestamp >= '09:00' &&
    github.event.head_commit.timestamp <= '18:00'
```

3. **Pular CI se commit contém [skip ci]:**
```yaml
if: "!contains(github.event.head_commit.message, '[skip ci]')"
```

4. **Executar step apenas no primeiro commit do dia:**
```yaml
if: github.run_number == 1
```

5. **Notificar falhas apenas em branches importantes:**
```yaml
if: |
  failure() &&
  (github.ref == 'refs/heads/main' || github.ref == 'refs/heads/develop')
```

#### Desafio Extra:

Modifique o workflow para:
1. Adicionar um step que usa `contains()` para verificar se a mensagem do commit contém "BREAKING CHANGE"
2. Se contiver, incrementar a major version (2.0.x) em vez da minor (1.x.x)
3. Criar um output que indica se é uma breaking change
4. No job de verificação, adicionar uma mensagem especial se for breaking change

---

### Conclusão

Parabéns! Você aprendeu a trabalhar com os principais contextos do GitHub Actions e criar workflows dinâmicos usando expressões e funções. Agora você sabe como acessar informações do repositório, ambiente de execução, status de jobs e criar lógica condicional complexa. Esses conceitos são fundamentais para workflows avançados e profissionais!

