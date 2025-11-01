# Lab 02 - Passo a Passo: Schedule Trigger Workflow

## Objetivo
Criar workflow que executa automaticamente em horários programados usando cron.

## Passo 1: Criar Workflow Agendado
1. No seu repositório `pipeline-labs`, criar arquivo `lab-02.yml` em `.github/workflows/`:

```yaml
name: Schedule Trigger Workflow

## Executa em horários programados (cron)
on:
  schedule:
    # Executa às 18:42 Brasília (21:42 UTC)
    - cron: '55 21 * * *'
  
  # Permite execução manual para testes
  workflow_dispatch:

jobs:
  scheduled-job:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout código
      uses: actions/checkout@v4
    
    - name: Informações do Schedule
      run: |
        echo "Workflow disparado por SCHEDULE"
        echo "Data atual: $(date)"
        echo "Hora UTC: $(date -u)"
        echo "Timezone: $(date +%Z)"
    
    - name: Relatório diário automatizado
      run: |
        echo "RELATÓRIO DIÁRIO AUTOMATIZADO"
        echo "================================"
        echo "Total de commits: $(git rev-list --all --count)"
        echo "Contribuidores únicos: $(git shortlog -sn | wc -l)"
        echo "Último commit: $(git log -1 --pretty=format:'%h - %s (%an, %ar)')"
```

## Passo 2: Enviar para GitHub
```bash
cd pipeline-labs
git add .
git commit -m "feat: adicionar Lab 02 - Schedule Trigger"
git push origin main
```

## Passo 3: Testar Execução Manual
1. Vá para aba **"Actions"** no GitHub
2. Clique em **"Schedule Trigger Workflow"**
3. Clique **"Run workflow"** → **"Run workflow"**
4. Veja o workflow executando e examine os logs

## Passo 4: Entender o Cron
O workflow está programado para executar:
- **Diariamente às 6:00 (Brasília)** - `0 9 * * *`
- **Segundas às 11:00 (Brasília)** - `0 14 * * 1`

**Formato cron**: `minuto hora dia mês dia-da-semana`

## O que o workflow faz:
- Mostra informações de data/hora
- Gera relatório automatizado do repositório
- Conta commits e contribuidores
- Exibe último commit

## Troubleshooting - Schedule não executou

### 1. Verificar Requisitos Básicos
```bash
# Confirmar que está na branch main
git branch

# Verificar se repositório é público
# (Ir no GitHub → Settings → verificar se está "Public")
```

### 2. Verificar na Aba Actions
1. Vá para **Actions** no GitHub
2. Clique em **"All workflows"** 
3. Se não aparece nenhuma execução no horário esperado = problema de configuração

### 3. Possíveis Causas
- **Repositório privado** = Schedule não funciona
- **Branch diferente de main** = Schedule não funciona  
- **Sintaxe cron errada** = Verifique em [crontab.guru](https://crontab.guru)
- **Horário UTC/Brasília** = GitHub usa UTC, ajustar +3 horas
- **Delay do GitHub** = Pode atrasar até 10-15 minutos

### 4. Teste Imediato
Para testar agora, **execute manualmente**:
1. Actions → "Schedule Trigger Workflow" 
2. "Run workflow" → "Run workflow"
3. Se funcionar manual = problema é só no schedule

### 5. Verificar Logs
Se apareceu execução mas falhou:
1. Clique na execução que falhou
2. Clique no job "scheduled-job"  
3. Veja qual step deu erro

**✅ Lab concluído! Workflow agendado está configurado.**