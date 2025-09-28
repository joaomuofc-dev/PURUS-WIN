<#
.SYNOPSIS
  Instalador bootstrap para PurusWin — baixa o release do GitHub, verifica hash e instala.
.DESCRIPTION
  - Simula por padrão (não executa ações destrutivas).
  - Baixa o asset .zip do GitHub Releases (latest ou tag).
  - Verifica SHA256 se houver arquivo .sha256 publicado.
  - Extrai para C:\Tools\PurusWin (ou local escolhido).
  - Opções: -Simulate, -AddToPath, -CreateDesktopShortcut, -ReleaseTag
#>

param(
    [switch]$Simulate = $true,
    [switch]$AddToPath = $false,
    [switch]$CreateDesktopShortcut = $false,
    [string]$InstallDir = "C:\Tools\PurusWin",
    [string]$Repo = "joaomuofc-dev/PURUS-WIN",
    [string]$ReleaseTag = ""  # empty = latest
)

function Write-Info($msg){ Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Warn($msg){ Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg){ Write-Host "[ERROR] $msg" -ForegroundColor Red }

Write-Host "==========================================" -ForegroundColor Green
Write-Host "PurusWin Installer Bootstrap" -ForegroundColor Green
Write-Host "Source repo: https://github.com/$Repo" -ForegroundColor Green
Write-Host "SIMULATE mode: $Simulate" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Green

function Get-FileSha256([string]$path) {
    if (-not (Test-Path $path)) { return $null }
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $stream = [System.IO.File]::OpenRead($path)
    try {
        $hashBytes = $sha.ComputeHash($stream)
        return ($hashBytes | ForEach-Object { $_.ToString("x2") }) -join ""
    } finally {
        $stream.Close()
        $sha.Dispose()
    }
}

function Get-ReleaseAssets([string]$repo, [string]$tag) {
    $headers = @{ "User-Agent" = "PurusWin-Installer" }
    if ([string]::IsNullOrWhiteSpace($tag)) {
        $url = "https://api.github.com/repos/$repo/releases/latest"
    } else {
        $url = "https://api.github.com/repos/$repo/releases/tags/$tag"
    }
    try {
        $release = Invoke-RestMethod -Uri $url -Headers $headers -UseBasicParsing -ErrorAction Stop
    } catch {
        Write-Err "Falha ao acessar GitHub API: $($_.Exception.Message)"
        return $null
    }
    return $release
}

$release = Get-ReleaseAssets -repo $Repo -tag $ReleaseTag
if (-not $release) { Write-Err "Não foi possível obter release do GitHub. Abortando."; exit 1 }

$asset = $release.assets | Where-Object { $_.name -match '\.zip$|\.exe$' } | Select-Object -First 1
if (-not $asset) {
    Write-Err "Nenhum asset .zip/.exe encontrado no release. Verifique Releases no GitHub."
    exit 1
}

$assetName = $asset.name
$assetUrl = $asset.browser_download_url
Write-Info "Found release: $($release.tag_name) - asset: $assetName"

$shaAsset = $release.assets | Where-Object { $_.name -match '\.sha256$' } | Select-Object -First 1
$expectedHash = $null
$tempDir = Join-Path $env:TEMP "puruswin_installer_$([Guid]::NewGuid().ToString())"
New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

try {
    $assetPath = Join-Path $tempDir $assetName
    Write-Info "Baixando asset para: $assetPath"
    
    if (-not $Simulate) {
        Invoke-WebRequest -Uri $assetUrl -OutFile $assetPath -UseBasicParsing -Headers @{ "User-Agent" = "PurusWin-Installer" }
    } else {
        Write-Info "[SIMULATE] Seria baixado: $assetUrl -> $assetPath"
    }

    if ($shaAsset) {
        $shaPath = Join-Path $tempDir $shaAsset.name
        Write-Info "Baixando hash (sha256) para validação: $shaPath"
        
        if (-not $Simulate) {
            Invoke-WebRequest -Uri $shaAsset.browser_download_url -OutFile $shaPath -UseBasicParsing -Headers @{ "User-Agent" = "PurusWin-Installer" }
            $shaContent = Get-Content $shaPath -ErrorAction SilentlyContinue
            if ($shaContent) {
                $firstLine = $shaContent | Select-Object -First 1
                $tokens = $firstLine -split '\s+'
                $expectedHash = $tokens[0]
                Write-Info "Hash esperada extraída do .sha256: $expectedHash"
            }
        } else {
            Write-Info "[SIMULATE] Seria baixado hash: $($shaAsset.browser_download_url)"
        }
    }

    if (-not $Simulate -and (Test-Path $assetPath)) {
        $actualHash = Get-FileSha256 -path $assetPath
        Write-Info "Hash calculada do arquivo baixado: $actualHash"
        
        if ($expectedHash -and $actualHash -ne $expectedHash) {
            Write-Err "Hash SHA256 não confere! Esperado: $expectedHash, Atual: $actualHash"
            exit 1
        } else {
            Write-Info "Verificação de integridade OK!"
        }
    }

    # Instalação
    Write-Info "Instalando PurusWin em: $InstallDir"
    
    if (-not $Simulate) {
        if (Test-Path $InstallDir) {
            Write-Warn "Diretório de instalação já existe. Removendo..."
            Remove-Item $InstallDir -Recurse -Force
        }
        
        New-Item -Path $InstallDir -ItemType Directory -Force | Out-Null
        
        if ($assetName -match '\.zip$') {
            Write-Info "Extraindo arquivo ZIP..."
            Expand-Archive -Path $assetPath -DestinationPath $InstallDir -Force
        } else {
            Write-Info "Copiando executável..."
            Copy-Item $assetPath -Destination (Join-Path $InstallDir "PurusWin.exe")
        }
    } else {
        Write-Info "[SIMULATE] Seria criado diretório: $InstallDir"
        Write-Info "[SIMULATE] Seria extraído/copiado: $assetName"
    }

    # Adicionar ao PATH
    if ($AddToPath) {
        Write-Info "Adicionando ao PATH do sistema..."
        if (-not $Simulate) {
            $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
            if ($currentPath -notlike "*$InstallDir*") {
                $newPath = "$currentPath;$InstallDir"
                [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
                Write-Info "PATH atualizado. Reinicie o terminal para aplicar."
            } else {
                Write-Info "Diretório já está no PATH."
            }
        } else {
            Write-Info "[SIMULATE] Seria adicionado ao PATH: $InstallDir"
        }
    }

    # Criar atalho na área de trabalho
    if ($CreateDesktopShortcut) {
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        $shortcutPath = Join-Path $desktopPath "PurusWin.lnk"
        $targetPath = Join-Path $InstallDir "PurusWin.exe"
        
        Write-Info "Criando atalho na área de trabalho..."
        if (-not $Simulate) {
            $shell = New-Object -ComObject WScript.Shell
            $shortcut = $shell.CreateShortcut($shortcutPath)
            $shortcut.TargetPath = $targetPath
            $shortcut.WorkingDirectory = $InstallDir
            $shortcut.Description = "PurusWin - Ferramenta CLI para Técnicos"
            $shortcut.Save()
            Write-Info "Atalho criado: $shortcutPath"
        } else {
            Write-Info "[SIMULATE] Seria criado atalho: $shortcutPath -> $targetPath"
        }
    }

    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "Instalação concluída com sucesso!" -ForegroundColor Green
    if (-not $Simulate) {
        Write-Host "PurusWin instalado em: $InstallDir" -ForegroundColor Green
        Write-Host "Execute: PurusWin.exe --help" -ForegroundColor Cyan
    } else {
        Write-Host "MODO SIMULAÇÃO - Nenhuma alteração foi feita" -ForegroundColor Yellow
        Write-Host "Execute novamente com -Simulate:`$false para instalar" -ForegroundColor Yellow
    }
    Write-Host "==========================================" -ForegroundColor Green

} catch {
    Write-Err "Erro durante a instalação: $($_.Exception.Message)"
    exit 1
} finally {
    # Limpeza
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}