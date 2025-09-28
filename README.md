# 🛠️ PurusWin
Ferramenta CLI Profissional para Técnicos de Informática

PurusWin é uma ferramenta de linha de comando desenvolvida em C# (.NET 8) para automatizar tarefas de manutenção, instalação e diagnóstico no Windows. **Tudo legal e auditável — não inclui ativadores ilegais.**

## Características principais
- Instalação segura de software com verificação SHA256
- Limpeza inteligente do sistema (temporários, cache de navegadores)
- Reset e manutenção de impressoras (backup automático)
- Verificação via Windows Defender
- Aplicação de chaves **legítimas** (apenas com autorização)
- Diagnósticos de rede
- Modo `--simulate` por padrão
- Armazenamento seguro de chaves usando DPAPI
- Logs JSON estruturados

## Como começar (rápido)
1. Clone o repositório:
```bash
git clone https://github.com/joaomuofc-dev/PURUS-WIN.git
cd PURUS-WIN
```

2. Build & Run (desenvolvimento):

```bash
dotnet restore
dotnet build --configuration Release
dotnet run --project src/PurusWin
```

## Segurança

Sempre revise scripts antes de executar. Use `--simulate` para ver o que seria feito sem alterar o sistema.

## Contribuindo

Fork, crie uma branch `feature/*`, commit e abra PR. Siga as guidelines do projeto.

## Licença

MIT