# Passo a Passo: Pipeline completa Stack Python

Este laboratório prepara as credenciais necessárias ANTES de executar a pipeline de CI/CD.

## Objetivo

Criar conta no Docker Hub, gerar token de acesso e configurar secrets no GitHub Actions.

## O que você vai configurar

- Conta Docker Hub
- Token de acesso Docker Hub
- GitHub Secrets (DOCKERHUB_USERNAME e DOCKERHUB_TOKEN)

## Pré-requisitos

- Conta no [GitHub](https://github.com)
- Conta no [Docker Hub](https://hub.docker.com) (gratuita)

## Passo 1: Criar conta no Docker Hub (se não tiver)

1. Acesse: https://hub.docker.com/signup
2. Preencha:
   - **Docker ID**: Escolha um username único (ex: `iesodias`)
   - **Email**: Seu email
   - **Password**: Senha segura
3. Clique em **Sign Up**
4. Verifique seu email e confirme a conta

Checkpoint: Faça login em https://hub.docker.com

## Passo 2: Criar Access Token no Docker Hub

1. Acesse: https://hub.docker.com
2. Faça login
3. Clique no seu **avatar** (canto superior direito)
4. Clique em **Account Settings**
5. No menu lateral esquerdo, clique em **Security**
6. Clique no botão **New Access Token**
7. Configure o token:
   - **Access Token Description**: `GitHub Actions CI/CD`
   - **Access permissions**: Selecione **Read, Write, Delete**
8. Clique em **Generate**
9. **COPIE O TOKEN AGORA** - ele só será exibido uma vez!

**Exemplo de token:**
```text
dckr_pat_AbCdEfGhIjKlMnOpQrStUvWxYz1234567890
```

Checkpoint: Token copiado e salvo em local seguro (temporariamente)

## Passo 3: Anotar suas credenciais

Você precisará de 2 informações:

| Informação          | Onde obter                                    | Exemplo         |
|---------------------|-----------------------------------------------|-----------------|
| **DOCKERHUB_USERNAME** | Seu Docker ID (username)                   | `iesodias`      |
| **DOCKERHUB_TOKEN**    | Token gerado no passo 2                    | `dckr_pat_...`  |

## Passo 4: Configurar Secrets no GitHub

No seu repositório GitHub:

1. Acesse: **Settings** (aba no topo do repositório)
2. No menu lateral esquerdo, expanda **Secrets and variables**
3. Clique em **Actions**
4. Clique no botão verde **New repository secret**

#### Secret 1: DOCKERHUB_USERNAME

1. Clique em **New repository secret**
2. Preencha:
   - **Name**: `DOCKERHUB_USERNAME`
   - **Secret**: Cole seu Docker ID (ex: `iesodias`)
3. Clique em **Add secret**

#### Secret 2: DOCKERHUB_TOKEN

1. Clique em **New repository secret** novamente
2. Preencha:
   - **Name**: `DOCKERHUB_TOKEN`
   - **Secret**: Cole o token gerado no passo 2
3. Clique em **Add secret**

## Passo 5: Verificar Secrets criados

Na página **Actions secrets and variables**, você deve ver:

- ✅ `DOCKERHUB_USERNAME`
- ✅ `DOCKERHUB_TOKEN`

**Status**: `Updated X seconds ago`

## Passo 6: Clonar repositório original e copiar arquivos

```bash
# Navegar para HOME
cd ~

# Clonar o repositório do laboratório
git clone https://github.com/iesodias/github-actions-app.git

# Clonar SEU repositório (substitua SEU_USUARIO)
git clone https://github.com/SEU_USUARIO/github-actions-lab.git

# Entrar no seu repositório
cd github-actions-lab

# Copiar arquivos ocultos (importantes!)
cp -r ~/github-actions-app/main.py .
cp -r ~/github-actions-app/requirements.txt .
cp -r ~/github-actions-app/Dockerfile .
cp -r ~/github-actions-app/static .
cp -r ~/github-actions-app/tests .
cp -r ~/github-actions-app/pytest.ini .
cp -r ~/github-actions-app/.github/workflows/locusfile.py .

# Verificar se os arquivos foram copiados
ls -la
```

## Passo 7: Criar arquivo de workflow

```yaml
name: CI/CD Pipeline - Task Manager

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:

env:
  PYTHON_VERSION: '3.11'
  NODE_VERSION: '18'

jobs:
  # Lint and Code Quality
  lint:
    name: Lint and Code Quality
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}

      - name: Cache dependencies
        uses: actions/cache@v4
        with:
          path: ~/.cache/pip
          key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}
          restore-keys: |
            ${{ runner.os }}-pip-

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install flake8 black isort
          pip install -r requirements.txt

      - name: Run Black (Code Formatting)
        run: black --check --diff .

      - name: Run isort (Import Sorting)
        run: isort --profile black --check-only --diff .

      - name: Run Flake8 (Linting)
        run: flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics

  # Unit Tests
  test:
    name: Unit Tests
    runs-on: ubuntu-latest
    needs: lint
    strategy:
      matrix:
        python-version: ['3.9', '3.10', '3.11']

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Python ${{ matrix.python-version }}
        uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}

      - name: Cache dependencies
        uses: actions/cache@v4
        with:
          path: ~/.cache/pip
          key: ${{ runner.os }}-pip-${{ matrix.python-version }}-${{ hashFiles('**/requirements.txt') }}
          restore-keys: |
            ${{ runner.os }}-pip-${{ matrix.python-version }}-

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt

      - name: Run tests with pytest
        run: |
          pytest --verbose --tb=short --cov=. --cov-report=xml --cov-report=term

      - name: Upload coverage to Codecov
        if: matrix.python-version == '3.11'
        uses: codecov/codecov-action@v4
        with:
          file: ./coverage.xml
          flags: unittests
          name: codecov-umbrella

  # Security Scan
  security:
    name: Security Scan
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install safety bandit
          pip install -r requirements.txt

      - name: Run Safety (Dependency Vulnerability Check)
        run: safety check

      - name: Run Bandit (Security Linting)
        run: bandit -r . -f json -o bandit-report.json || true

      - name: Upload Bandit Report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: bandit-report
          path: bandit-report.json

  # Build Docker Image
  build:
    name: Build Docker Image
    runs-on: ubuntu-latest
    needs: [test, security]
    outputs:
      image-tag: ${{ secrets.DOCKERHUB_USERNAME }}/task-manager:sha-${{ github.sha }}
      image-digest: ${{ steps.build.outputs.digest }}

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to Docker Hub
        if: github.event_name != 'pull_request'
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ secrets.DOCKERHUB_USERNAME }}/task-manager
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=sha,prefix=sha-
            type=raw,value=latest,enable={{is_default_branch}}

      - name: Build and push Docker image
        id: build
        uses: docker/build-push-action@v5
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          push: ${{ github.event_name != 'pull_request' }}
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  # Integration Tests
  integration-test:
    name: Integration Tests
    runs-on: ubuntu-latest
    needs: build
    if: github.event_name != 'pull_request'

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Build local Docker image for testing
        run: |
          docker build -t local-task-manager:test .

      - name: Start application container
        run: |
          docker run -d -p 8000:8000 --name integration-test-app \
            local-task-manager:test

      - name: Wait for application to be ready
        run: |
          timeout 60 bash -c 'until curl -f http://localhost:8000/api/health; do sleep 2; done'

      - name: Run API integration tests
        run: |
          # Test health endpoint
          curl -f http://localhost:8000/api/health

          # Test task creation
          TASK_ID=$(curl -s -X POST http://localhost:8000/api/tasks \
            -H "Content-Type: application/json" \
            -d '{"title":"Integration Test Task","priority":"high"}' | \
            python -c "import sys, json; print(json.load(sys.stdin)['id'])")

          # Test task retrieval
          curl -f http://localhost:8000/api/tasks/$TASK_ID

          # Test task update
          curl -f -X PUT http://localhost:8000/api/tasks/$TASK_ID \
            -H "Content-Type: application/json" \
            -d '{"completed":true}'

          # Test statistics
          curl -f http://localhost:8000/api/stats

          # Test task deletion
          curl -f -X DELETE http://localhost:8000/api/tasks/$TASK_ID

      - name: Test frontend accessibility
        run: |
          # Test that frontend loads
          curl -f http://localhost:8000/

          # Test static files
          curl -f http://localhost:8000/static/style.css
          curl -f http://localhost:8000/static/script.js

      - name: Cleanup integration test container
        if: always()
        run: docker stop integration-test-app && docker rm integration-test-app

  # Performance Tests
  performance-test:
    name: Performance Tests
    runs-on: ubuntu-latest
    needs: integration-test
    if: github.event_name != 'pull_request'

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}

      - name: Install dependencies
        run: |
          pip install locust

      - name: Build local Docker image for testing
        run: |
          docker build -t local-task-manager:test .

      - name: Run performance tests
        run: |
          # Start the application in background
          docker run -d -p 8000:8000 --name perf-test-app \
            local-task-manager:test

          # Wait for app to be ready
          timeout 60 bash -c 'until curl -f http://localhost:8000/api/health; do sleep 2; done'

          # Run basic load test
          locust -f .github/workflows/locustfile.py \
            --host http://localhost:8000 \
            --users 50 \
            --spawn-rate 5 \
            --run-time 2m \
            --headless \
            --only-summary

      - name: Cleanup
        if: always()
        run: docker stop perf-test-app && docker rm perf-test-app

  # Deploy to staging
  deploy-staging:
    name: Deploy to Staging
    runs-on: ubuntu-latest
    needs: [integration-test, performance-test]
    if: github.ref == 'refs/heads/develop' && github.event_name == 'push'
    environment:
      name: staging
      url: https://task-manager-staging.example.com

    steps:
      - name: Deploy to staging
        run: |
          echo "Deploying to staging environment..."
          echo "Image: ${{ needs.build.outputs.image-tag }}"
          # Add your staging deployment logic here

  # Deploy to production
  deploy-production:
    name: Deploy to Production
    runs-on: ubuntu-latest
    needs: [integration-test, performance-test]
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    environment:
      name: production
      url: https://task-manager.example.com

    steps:
      - name: Deploy to production
        run: |
          echo "Deploying to production environment..."
          echo "Image: ${{ needs.build.outputs.image-tag }}"
          # Add your production deployment logic here

  # Notification
  notify:
    name: Notify Deployment
    runs-on: ubuntu-latest
    needs: [deploy-staging, deploy-production]
    if: always() && (needs.deploy-staging.result != 'skipped' || needs.deploy-production.result != 'skipped')

    steps:
      - name: Notify success
        if: needs.deploy-staging.result == 'success' || needs.deploy-production.result == 'success'
        run: |
          echo "Deployment successful!"
          echo "Staging: ${{ needs.deploy-staging.result }}"
          echo "Production: ${{ needs.deploy-production.result }}"

      - name: Notify failure
        if: needs.deploy-staging.result == 'failure' || needs.deploy-production.result == 'failure'
        run: |
          echo "Deployment failed!"
          echo "Staging: ${{ needs.deploy-staging.result }}"
          echo "Production: ${{ needs.deploy-production.result }}"

```

## Passo 8: Enviar alterações para o repositório

Execute os comandos abaixo na raiz do projeto para versionar e publicar as mudanças:

```bash
git status
git add .
git commit -m "docs: padronizar README do projeto"
git push origin main
```

Depois do push, verifique no GitHub:
- Acesse seu repositório e confirme o commit na branch `main`.
- Veja se o README renderizou corretamente na página inicial do repositório.