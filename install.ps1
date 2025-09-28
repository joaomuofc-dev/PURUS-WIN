#Requires -Version 5.1

<#
.SYNOPSIS
    Script de instalação do PurusWin - Ferramenta CLI para Técnicos de TI

.DESCRIPTION
    Este script baixa e instala automaticamente a versão mais recente do PurusWin
    do GitHub Releases, com verificação de integridade e opções de configuração.

.PARAMETER AddToPath
    Adiciona C:\Tools\PurusWin ao PATH do sistema

.PARAMETER CreateDesktopShortcut
    Cria um atalho na Área de Trabalho para o PurusWin.exe

.PARAMETER Simulate
    Executa em modo simulação - mostra o que seria feito sem executar

.EXAMPLE
    .\install.ps1
    Instalação básica do PurusWin

.EXAMPLE
    .\install.ps1 -AddToPath -CreateDesktopShortcut
    Instalação completa com PATH e atalho na área de trabalho

.EXAMPLE
    .\install.ps1 -Simulate
    Simula a instalação sem executar

.NOTES
    Autor: PurusWin Team
    Versão: 1.0.0
    Requer: PowerShell 5.1+, Privilégios de Administrador (para PATH)
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Adiciona C:\Tools\PurusWin ao PATH do sistema")]
    [switch]$AddToPath,
    
    [Parameter(HelpMessage = "Cria atalho na Área de Trabalho")]
    [switch]$CreateDesktopShortcut,
    
    [Parameter(HelpMessage = "Executa em modo simulação")]
    [switch]$Simulate
)

# Configurações
$script:Config = @{
    GitHubRepo = "joaomuofc-dev/PURUS-WIN"
    DownloadUrl = "https://github.com/joaomuofc-dev/PURUS-WIN/releases/latest/download/PurusWin.zip"
    HashUrl = "https://github.com/joaomuofc-dev/PURUS-WIN/releases/latest/download/PurusWin.zip.sha256"
    TempPath = "$env:TEMP\PurusWin.zip"
    HashTempPath = "$env:TEMP\PurusWin.zip.sha256"
    InstallPath = "C:\Tools\PurusWin"
    ExecutableName = "PurusWin.exe"
}

# Funções auxiliares
function Write-ColorMessage {
    param(
        [string]$Message,
        [string]$Color = "White",
        [string]$Prefix = "",
        [switch]$NoNewline
    )
    
    $fullMessage = if ($Prefix) { "$Prefix $Message" } else { $Message }
    
    if ($NoNewline) {
        Write-Host $fullMessage -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $fullMessage -ForegroundColor $Color
    }
}

function Write-Success {
    param([string]$Message)
    Write-ColorMessage -Message $Message -Color "Green" -Prefix "✅"
}

function Write-Info {
    param([string]$Message)
    Write-ColorMessage -Message $Message -Color "Cyan" -Prefix "ℹ️"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorMessage -Message $Message -Color "Yellow" -Prefix "⚠️"
}

function Write-Error {
    param([string]$Message)
    Write-ColorMessage -Message $Message -Color "Red" -Prefix "❌"
}

function Write-Progress {
    param([string]$Message)
    Write-ColorMessage -Message $Message -Color "Magenta" -Prefix "🔄"
}

function Test-AdminPrivileges {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-FileHash256 {
    param([string]$FilePath)
    
    try {
        $hash = Get-FileHash -Path $FilePath -Algorithm SHA256
        return $hash.Hash.ToLower()
    }
    catch {
        Write-Error "Erro ao calcular hash do arquivo: $($_.Exception.Message)"
        return $null
    }
}

function Download-File {
    param(
        [string]$Url,
        [string]$OutputPath,
        [string]$Description = "arquivo"
    )
    
    try {
        Write-Progress "Baixando $Description de $Url..."
        
        if ($Simulate) {
            Write-Info "[SIMULAÇÃO] Baixaria $Description para $OutputPath"
            return $true
        }
        
        # Usar WebClient para download com progress
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "PurusWin-Installer/1.0")
        
        # Registrar evento de progresso
        Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -Action {
            $percent = $Event.SourceEventArgs.ProgressPercentage
            Write-Progress -Activity "Baixando $Description" -Status "$percent% concluído" -PercentComplete $percent
        } | Out-Null
        
        $webClient.DownloadFile($Url, $OutputPath)
        $webClient.Dispose()
        
        Write-Progress -Activity "Baixando $Description" -Completed
        Write-Success "$Description baixado com sucesso!"
        return $true
    }
    catch {
        Write-Error "Falha ao baixar $Description`: $($_.Exception.Message)"
        return $false
    }
}

function Test-FileIntegrity {
    param(
        [string]$FilePath,
        [string]$HashFilePath
    )
    
    if (-not (Test-Path $HashFilePath)) {
        Write-Warning "Arquivo de hash não encontrado. Pulando verificação de integridade."
        return $true
    }
    
    try {
        Write-Progress "Verificando integridade do arquivo..."
        
        if ($Simulate) {
            Write-Info "[SIMULAÇÃO] Verificaria integridade usando $HashFilePath"
            return $true
        }
        
        # Ler hash esperado
        $expectedHash = (Get-Content $HashFilePath -Raw).Trim().Split()[0].ToLower()
        
        # Calcular hash do arquivo baixado
        $actualHash = Get-FileHash256 -FilePath $FilePath
        
        if ($actualHash -eq $expectedHash) {
            Write-Success "Verificação de integridade passou! ✓"
            return $true
        } else {
            Write-Error "Verificação de integridade falhou!"
            Write-Error "Esperado: $expectedHash"
            Write-Error "Atual: $actualHash"
            return $false
        }
    }
    catch {
        Write-Error "Erro durante verificação de integridade: $($_.Exception.Message)"
        return $false
    }
}

function Install-PurusWin {
    param([string]$ZipPath, [string]$InstallPath)
    
    try {
        Write-Progress "Instalando PurusWin em $InstallPath..."
        
        if ($Simulate) {
            Write-Info "[SIMULAÇÃO] Extrairia $ZipPath para $InstallPath"
            return $true
        }
        
        # Limpar diretório de instalação se existir
        if (Test-Path $InstallPath) {
            Write-Info "Removendo instalação anterior..."
            Remove-Item $InstallPath -Recurse -Force
        }
        
        # Criar diretório de instalação
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
        
        # Extrair arquivo ZIP
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $InstallPath)
        
        # Verificar se o executável existe
        $exePath = Join-Path $InstallPath $script:Config.ExecutableName
        if (-not (Test-Path $exePath)) {
            Write-Error "Executável não encontrado após extração: $exePath"
            return $false
        }
        
        Write-Success "PurusWin instalado com sucesso em $InstallPath"
        return $true
    }
    catch {
        Write-Error "Erro durante instalação: $($_.Exception.Message)"
        return $false
    }
}

function Add-ToSystemPath {
    param([string]$Path)
    
    try {
        Write-Progress "Adicionando $Path ao PATH do sistema..."
        
        if ($Simulate) {
            Write-Info "[SIMULAÇÃO] Adicionaria $Path ao PATH do sistema"
            return $true
        }
        
        # Verificar privilégios de administrador
        if (-not (Test-AdminPrivileges)) {
            Write-Error "Privilégios de administrador necessários para modificar PATH do sistema"
            Write-Info "Execute o script como administrador ou use apenas para o usuário atual"
            return $false
        }
        
        # Obter PATH atual do sistema
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
        
        # Verificar se já está no PATH
        if ($currentPath -split ";" | Where-Object { $_.TrimEnd('\') -eq $Path.TrimEnd('\') }) {
            Write-Info "Caminho já existe no PATH do sistema"
            return $true
        }
        
        # Adicionar ao PATH
        $newPath = "$currentPath;$Path"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
        
        Write-Success "Caminho adicionado ao PATH do sistema com sucesso!"
        Write-Info "Reinicie o terminal para que as mudanças tenham efeito"
        return $true
    }
    catch {
        Write-Error "Erro ao adicionar ao PATH: $($_.Exception.Message)"
        return $false
    }
}

function New-DesktopShortcut {
    param(
        [string]$TargetPath,
        [string]$ShortcutName = "PurusWin"
    )
    
    try {
        Write-Progress "Criando atalho na Área de Trabalho..."
        
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        $shortcutPath = Join-Path $desktopPath "$ShortcutName.lnk"
        
        if ($Simulate) {
            Write-Info "[SIMULAÇÃO] Criaria atalho em $shortcutPath"
            return $true
        }
        
        # Criar atalho usando COM
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $TargetPath
        $shortcut.WorkingDirectory = Split-Path $TargetPath
        $shortcut.Description = "PurusWin - Ferramenta CLI para Técnicos de TI"
        $shortcut.Arguments = "--menu"
        $shortcut.Save()
        
        Write-Success "Atalho criado na Área de Trabalho: $shortcutPath"
        return $true
    }
    catch {
        Write-Error "Erro ao criar atalho: $($_.Exception.Message)"
        return $false
    }
}

function Cleanup-TempFiles {
    Write-Progress "Limpando arquivos temporários..."
    
    if ($Simulate) {
        Write-Info "[SIMULAÇÃO] Limparia arquivos temporários"
        return
    }
    
    @($script:Config.TempPath, $script:Config.HashTempPath) | ForEach-Object {
        if (Test-Path $_) {
            Remove-Item $_ -Force -ErrorAction SilentlyContinue
        }
    }
}

# Função principal
function Main {
    # Banner
    Write-Host ""
    Write-ColorMessage "╔══════════════════════════════════════════════════════════════╗" -Color "Blue"
    Write-ColorMessage "║                    🚀 INSTALADOR PURUSWIN 🚀                 ║" -Color "Blue"
    Write-ColorMessage "║              Ferramenta CLI para Técnicos de TI              ║" -Color "Blue"
    Write-ColorMessage "╚══════════════════════════════════════════════════════════════╝" -Color "Blue"
    Write-Host ""
    
    if ($Simulate) {
        Write-Warning "MODO SIMULAÇÃO ATIVADO - Nenhuma alteração será feita"
        Write-Host ""
    }
    
    # Verificar se é necessário privilégio de administrador
    if ($AddToPath -and -not (Test-AdminPrivileges) -and -not $Simulate) {
        Write-Warning "A opção -AddToPath requer privilégios de administrador"
        Write-Info "Execute o script como administrador ou remova a opção -AddToPath"
        Write-Host ""
    }
    
    try {
        # 1. Download do arquivo principal
        Write-Info "Iniciando download do PurusWin..."
        if (-not (Download-File -Url $script:Config.DownloadUrl -OutputPath $script:Config.TempPath -Description "PurusWin.zip")) {
            throw "Falha no download do arquivo principal"
        }
        
        # 2. Download do arquivo de hash (opcional)
        Write-Info "Tentando baixar arquivo de verificação..."
        Download-File -Url $script:Config.HashUrl -OutputPath $script:Config.HashTempPath -Description "arquivo de hash" | Out-Null
        
        # 3. Verificação de integridade
        if (-not (Test-FileIntegrity -FilePath $script:Config.TempPath -HashFilePath $script:Config.HashTempPath)) {
            throw "Falha na verificação de integridade"
        }
        
        # 4. Instalação
        if (-not (Install-PurusWin -ZipPath $script:Config.TempPath -InstallPath $script:Config.InstallPath)) {
            throw "Falha na instalação"
        }
        
        # 5. Opções adicionais
        if ($AddToPath) {
            Add-ToSystemPath -Path $script:Config.InstallPath | Out-Null
        }
        
        if ($CreateDesktopShortcut) {
            $exePath = Join-Path $script:Config.InstallPath $script:Config.ExecutableName
            New-DesktopShortcut -TargetPath $exePath | Out-Null
        }
        
        # 6. Limpeza
        Cleanup-TempFiles
        
        # 7. Mensagem final
        Write-Host ""
        Write-ColorMessage "╔══════════════════════════════════════════════════════════════╗" -Color "Green"
        Write-ColorMessage "║                   🚀 INSTALAÇÃO CONCLUÍDA! 🚀                ║" -Color "Green"
        Write-ColorMessage "╚══════════════════════════════════════════════════════════════╝" -Color "Green"
        Write-Host ""
        
        if (-not $Simulate) {
            Write-Success "PurusWin foi instalado com sucesso em: $($script:Config.InstallPath)"
            Write-Info "Execute 'PurusWin.exe --menu' para começar."
            
            if ($AddToPath) {
                Write-Info "Após reiniciar o terminal, você pode executar 'PurusWin --menu' de qualquer lugar."
            }
            
            if ($CreateDesktopShortcut) {
                Write-Info "Um atalho foi criado na sua Área de Trabalho."
            }
        } else {
            Write-Info "Simulação concluída com sucesso!"
        }
        
        Write-Host ""
        
    }
    catch {
        Write-Host ""
        Write-Error "Instalação falhou: $($_.Exception.Message)"
        Write-Info "Verifique sua conexão com a internet e tente novamente."
        
        # Limpeza em caso de erro
        Cleanup-TempFiles
        
        exit 1
    }
}

# Executar instalação
Main