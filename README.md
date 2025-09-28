# 🛠️ PurusWin

**Ferramenta CLI Profissional para Técnicos de Informática**

[![.NET](https://img.shields.io/badge/.NET-8.0-blue.svg)](https://dotnet.microsoft.com/download)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows-lightgrey.svg)](https://www.microsoft.com/windows)

PurusWin é uma ferramenta de linha de comando desenvolvida especificamente para técnicos de informática, automatizando tarefas comuns de manutenção, instalação e diagnóstico em sistemas Windows.

## 🎯 Características Principais

- ✅ **Instalação Segura de Software** com verificação de integridade (SHA256)
- 🧹 **Limpeza Inteligente do Sistema** (arquivos temporários, cache de navegadores)
- 🖨️ **Reset e Manutenção de Impressoras** com backup automático
- 🛡️ **Verificação de Antivírus** usando Windows Defender
- 🔑 **Ativação Legítima** de Windows e Office (apenas chaves fornecidas)
- 🌐 **Diagnósticos de Rede** (ping, DNS lookup)
- 📊 **Modo Simulação** para visualizar ações antes da execução
- 🔒 **Armazenamento Seguro** de chaves usando Windows DPAPI
- 📈 **Barras de Progresso** e feedback visual detalhado

## 🚀 Instalação Rápida

### Opção 1: Script de Instalação (Recomendado)

```powershell
# Baixar e executar o instalador
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/usuario/puruswin/main/tools/install.ps1" -OutFile "install.ps1"
.\install.ps1 -AddToPath -CreateDesktopShortcut
```

### Opção 2: Instalação Manual

1. Baixe a versão mais recente dos [Releases](https://github.com/usuario/puruswin/releases)
2. Extraia para `C:\Tools\PurusWin`
3. Adicione ao PATH do sistema (opcional)

### Opção 3: Compilar do Código Fonte

```bash
git clone https://github.com/usuario/puruswin.git
cd puruswin
dotnet build --configuration Release
```

## 📖 Guia de Uso

### Menu Interativo

```bash
PurusWin.exe --menu
```

### Comandos Diretos

#### Instalação de Software
```bash
# Instalar Office (modo simulação)
PurusWin.exe --install office --simulate

# Instalar Chrome com força
PurusWin.exe --install chrome --force

# Listar softwares disponíveis
PurusWin.exe --install --list
```

#### Limpeza do Sistema
```bash
# Limpeza completa (simulação)
PurusWin.exe --cleanup --simulate

# Limpeza apenas de arquivos temporários
PurusWin.exe --cleanup temp --force

# Limpeza de cache de navegadores
PurusWin.exe --cleanup browser-cache
```

#### Reset de Impressoras
```bash
# Reset de todas as impressoras (simulação)
PurusWin.exe --printer-reset --simulate

# Reset de impressora específica
PurusWin.exe --printer-reset "HP LaserJet Pro" --force

# Listar impressoras instaladas
PurusWin.exe --printer-reset --list
```

#### Verificação de Antivírus
```bash
# Verificação rápida
PurusWin.exe --antivirus-scan quick

# Verificação completa
PurusWin.exe --antivirus-scan full

# Verificação personalizada
PurusWin.exe --antivirus-scan custom --path "C:\Downloads"
```

#### Ativação Legítima
```bash
# Ativar Windows com chave fornecida
PurusWin.exe --activation windows --key "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"

# Ativar Office (chave será solicitada)
PurusWin.exe --activation office

# Verificar status de ativação
PurusWin.exe --activation --status
```

#### Diagnósticos de Rede
```bash
# Teste completo de conectividade
PurusWin.exe --network-diagnostics

# Teste específico de hosts
PurusWin.exe --network-diagnostics --hosts "google.com,microsoft.com"
```

### Flags Globais

| Flag | Descrição |
|------|-----------|
| `--simulate` | Executa em modo simulação (não faz alterações reais) |
| `--force` | Força a execução sem confirmações |
| `--verbose` | Saída detalhada |
| `--timeout <ms>` | Define timeout personalizado |
| `--config <path>` | Usa arquivo de configuração personalizado |
| `--help` | Mostra ajuda |
| `--version` | Mostra versão |

## ⚙️ Configuração

O PurusWin usa um arquivo `config.yml` para personalizar seu comportamento:

```yaml
# Configurações Gerais
general:
  simulate: true              # Modo simulação por padrão
  log_level: "Info"          # Nível de log
  require_admin: true        # Requer privilégios administrativos

# Downloads
downloads:
  directory: "./DownloadsRapidos"
  allowed_extensions: [".exe", ".msi", ".msix"]
  require_hash_verification: true

# Hashes conhecidos de softwares
known_hashes:
  "office_2021_professional.exe": "a1b2c3d4e5f6..."
  "chrome_installer.exe": "c3d4e5f6789..."
```

### Localização do Arquivo de Configuração

1. `./config.yml` (diretório atual)
2. `%APPDATA%\PurusWin\config.yml`
3. `C:\Tools\PurusWin\config.yml`

## 🔒 Segurança

### Verificação de Integridade

Todos os downloads são verificados usando hashes SHA256:

```bash
# Verificar hash de um arquivo
PurusWin.exe --verify-hash "installer.exe" --expected "a1b2c3d4..."
```

### Armazenamento Seguro de Chaves

As chaves de ativação são armazenadas usando Windows DPAPI:

```bash
# Armazenar chave de forma segura
PurusWin.exe --store-key "windows" "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"

# Listar chaves armazenadas
PurusWin.exe --list-keys
```

### Modo Simulação

**SEMPRE** use `--simulate` primeiro para ver o que será feito:

```bash
PurusWin.exe --cleanup --simulate
```

## 🏗️ Arquitetura

### Estrutura do Projeto

```
src/PurusWin/
├── Core/                   # Classes principais
│   ├── ConfigManager.cs    # Gerenciamento de configuração
│   ├── Orchestrator.cs     # Orquestrador principal
│   └── Menu.cs            # Interface de menu
├── Plugins/               # Sistema de plugins
│   ├── IPlugin.cs         # Interface base
│   ├── InstallerPlugin.cs # Plugin de instalação
│   ├── PrinterPlugin.cs   # Plugin de impressoras
│   ├── ActivatorSafePlugin.cs # Plugin de ativação
│   └── AntivirusPlugin.cs # Plugin de antivírus
├── Utils/                 # Utilitários
│   ├── CryptoStore.cs     # Armazenamento seguro
│   ├── HashChecker.cs     # Verificação de hashes
│   └── WindowsHelpers.cs  # Helpers do Windows
├── Cli/                   # Interface de linha de comando
│   ├── ArgumentsParser.cs # Parser de argumentos
│   └── ProgressBar.cs     # Barra de progresso
└── Program.cs             # Ponto de entrada
```

### Sistema de Plugins

O PurusWin usa um sistema de plugins modular:

```csharp
public interface IPlugin
{
    string Name { get; }
    string Version { get; }
    string Description { get; }
    
    Task InitializeAsync();
    Task<bool> IsAvailableAsync();
    Task<PluginStatus> GetStatusAsync();
}
```

## 🧪 Testes

### Executar Testes

```bash
# Todos os testes
dotnet test

# Testes com cobertura
dotnet test --collect:"XPlat Code Coverage"

# Testes específicos
dotnet test --filter "Category=Unit"
```

### Estrutura de Testes

```
tests/PurusWin.Tests/
├── Core/
│   └── ConfigManagerTests.cs
├── Utils/
│   └── HashCheckerTests.cs
├── Cli/
│   └── ArgumentsParserTests.cs
└── Plugins/
    └── InstallerPluginTests.cs
```

## 📊 Exemplos Práticos

### Cenário 1: Setup Completo de Máquina

```bash
# 1. Verificar sistema
PurusWin.exe --network-diagnostics --simulate

# 2. Instalar softwares essenciais
PurusWin.exe --install office --simulate
PurusWin.exe --install chrome --simulate
PurusWin.exe --install 7zip --simulate

# 3. Limpeza inicial
PurusWin.exe --cleanup --simulate

# 4. Executar sem simulação
PurusWin.exe --install office,chrome,7zip --force
```

### Cenário 2: Manutenção Preventiva

```bash
# 1. Limpeza completa
PurusWin.exe --cleanup --force

# 2. Verificação de antivírus
PurusWin.exe --antivirus-scan quick

# 3. Reset de impressoras problemáticas
PurusWin.exe --printer-reset --force

# 4. Diagnóstico de rede
PurusWin.exe --network-diagnostics
```

### Cenário 3: Resolução de Problemas

```bash
# 1. Diagnóstico completo
PurusWin.exe --network-diagnostics --verbose
PurusWin.exe --antivirus-scan full

# 2. Reset específico
PurusWin.exe --printer-reset "Impressora Problemática" --force

# 3. Limpeza profunda
PurusWin.exe --cleanup temp,browser-cache --force
```

## 🔧 Desenvolvimento

### Pré-requisitos

- .NET 8.0 SDK
- Windows 10/11
- PowerShell 5.1+
- Visual Studio 2022 ou VS Code

### Configuração do Ambiente

```bash
# Clonar repositório
git clone https://github.com/usuario/puruswin.git
cd puruswin

# Restaurar dependências
dotnet restore

# Compilar
dotnet build

# Executar testes
dotnet test

# Executar aplicação
dotnet run --project src/PurusWin
```

### Contribuindo

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

### Criando Plugins

```csharp
public class MeuPlugin : IPlugin
{
    public string Name => "Meu Plugin";
    public string Version => "1.0.0";
    public string Description => "Descrição do plugin";

    public async Task InitializeAsync()
    {
        // Inicialização do plugin
    }

    public async Task<bool> IsAvailableAsync()
    {
        // Verificar se o plugin está disponível
        return true;
    }

    public async Task<PluginStatus> GetStatusAsync()
    {
        // Retornar status do plugin
        return new PluginStatus { IsHealthy = true };
    }
}
```

## 📋 Roadmap

### Versão 1.1.0
- [ ] Plugin de backup automático
- [ ] Integração com Windows Update
- [ ] Relatórios em HTML
- [ ] Suporte a scripts personalizados

### Versão 1.2.0
- [ ] Interface gráfica (GUI)
- [ ] Agendamento de tarefas
- [ ] Notificações do sistema
- [ ] Integração com Active Directory

### Versão 2.0.0
- [ ] Suporte a múltiplas máquinas
- [ ] Dashboard web
- [ ] API REST
- [ ] Plugins de terceiros

## ❓ FAQ

### P: O PurusWin funciona sem privilégios de administrador?
**R:** Algumas funcionalidades requerem privilégios administrativos (reset de impressoras, instalação de software, etc.). O PurusWin detecta automaticamente e informa quais operações estão disponíveis.

### P: É seguro usar o modo não-simulação?
**R:** Sim, mas sempre teste com `--simulate` primeiro. O PurusWin inclui verificações de segurança e backups automáticos quando apropriado.

### P: Como adicionar novos softwares para instalação?
**R:** Edite o arquivo `config.yml` e adicione os hashes SHA256 dos instaladores na seção `known_hashes`.

### P: O PurusWin coleta dados pessoais?
**R:** Não. O PurusWin opera completamente offline e não envia dados para servidores externos.

### P: Como reportar bugs ou solicitar features?
**R:** Use as [Issues do GitHub](https://github.com/usuario/puruswin/issues) para reportar problemas ou solicitar novas funcionalidades.

## 📄 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 🤝 Suporte

- 📧 Email: suporte@puruswin.com
- 💬 Discord: [PurusWin Community](https://discord.gg/puruswin)
- 📖 Wiki: [GitHub Wiki](https://github.com/usuario/puruswin/wiki)
- 🐛 Issues: [GitHub Issues](https://github.com/usuario/puruswin/issues)

## 🙏 Agradecimentos

- Comunidade .NET
- Contribuidores do projeto
- Técnicos de informática que testaram e forneceram feedback

---

**⚠️ AVISO IMPORTANTE:** O PurusWin é uma ferramenta poderosa que pode fazer alterações significativas no sistema. Sempre use o modo simulação primeiro e mantenha backups atualizados. Use apenas chaves de ativação legítimas e adquiridas legalmente.

**Desenvolvido com ❤️ para a comunidade de técnicos de informática**