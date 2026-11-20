<#
 Instalador simples do openOMSI HOF Auto (projeto independente, NAO oficial).
 Troca SOMENTE 4 executaveis da pasta do jogo; faz backup dos originais antes e confere cada arquivo.
 NAO mexe em mapas, onibus, HOFs, configuracoes, OMSI 2 ou outros mods.
 -Desinstalar: devolve os originais do backup mais recente.
#>
param([switch]$Desinstalar)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
$exes = @('openomsi.exe', 'openomsi-launcher.exe', 'openomsi-launcher-app.exe', 'omsi-plugin-host32.exe')
$aqui = Split-Path -Parent $MyInvocation.MyCommand.Path
$novos = Join-Path $aqui 'exe'
$dadosDir = Join-Path $env:LOCALAPPDATA 'openOMSI-HOF-Auto'
$bkRaiz = Join-Path $dadosDir 'backup'
$logf = Join-Path $dadosDir 'instalacao.log.txt'
New-Item -ItemType Directory -Force $dadosDir | Out-Null
function Log([string]$s) { try { Add-Content -Encoding UTF8 -Path $logf -Value ("{0} {1}" -f (Get-Date -Format s), $s) } catch { } }
function Msg([string]$t, [string]$titulo = 'openOMSI HOF Auto', [string]$botoes = 'OK', [string]$icone = 'Information') {
    [System.Windows.Forms.MessageBox]::Show($t, $titulo, $botoes, $icone)
}
function Hash([string]$p) { (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash }
function Abertos([string]$raiz) {
    $n = @('openomsi', 'openomsi-launcher', 'openomsi-launcher-app', 'omsi-plugin-host32')
    Get-Process -Name $n -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path.StartsWith($raiz, [StringComparison]::OrdinalIgnoreCase) }
}
function Escolher-Pasta {
    $cands = @('D:\Games\OpenOMSI', 'C:\Games\OpenOMSI', 'E:\Games\OpenOMSI', (Join-Path $env:ProgramFiles 'OpenOMSI'), (Join-Path $env:LOCALAPPDATA 'Programs\OpenOMSI'), (Join-Path $env:USERPROFILE 'Games\OpenOMSI'))
    foreach ($c in $cands) {
        if (Test-Path -LiteralPath (Join-Path $c 'openomsi.exe')) {
            $r = Msg "Encontrei o openOMSI em:`n`n$c`n`nInstalar aqui?" 'openOMSI HOF Auto' 'YesNo' 'Question'
            if ($r -eq 'Yes') { return $c }
        }
    }
    while ($true) {
        $d = New-Object System.Windows.Forms.FolderBrowserDialog
        $d.Description = 'Escolha a PASTA DO JOGO openOMSI (a que contem o openomsi.exe).'
        if ($d.ShowDialog() -ne 'OK') { return $null }
        if (Test-Path -LiteralPath (Join-Path $d.SelectedPath 'openomsi.exe')) { return $d.SelectedPath }
        Msg "Nessa pasta nao existe o openomsi.exe. Escolha a pasta do jogo." 'openOMSI HOF Auto' 'OK' 'Warning' | Out-Null
    }
}
try {
    if ($Desinstalar) {
        $bk = Get-ChildItem -LiteralPath $bkRaiz -Directory -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -Last 1
        if (-not $bk) { Msg 'Nao encontrei nenhum backup para restaurar.' 'openOMSI HOF Auto' 'OK' 'Warning' | Out-Null; exit 1 }
        $dest = (Get-Content -LiteralPath (Join-Path $bk.FullName 'instalacao.txt') -Encoding UTF8 | Select-Object -First 1).Trim()
        if (Abertos $dest) { Msg 'Feche o jogo e o launcher antes de continuar.' 'openOMSI HOF Auto' 'OK' 'Warning' | Out-Null; exit 1 }
        foreach ($e in $exes) {
            $o = Join-Path $bk.FullName $e
            if (Test-Path -LiteralPath $o) {
                $t = Join-Path $dest ($e + '.restaurando')
                Copy-Item -LiteralPath $o -Destination $t -Force
                if ((Hash $t) -ne (Hash $o)) { Remove-Item -LiteralPath $t -Force; throw "Falha ao conferir $e" }
                Move-Item -LiteralPath $t -Destination (Join-Path $dest $e) -Force
                Log "restaurado $e"
            }
        }
        Msg "Pronto. O jogo voltou aos arquivos originais:`n$dest" 'openOMSI HOF Auto' 'OK' 'Information' | Out-Null
        exit 0
    }
    if (-not (Test-Path -LiteralPath $novos)) { throw "Pasta 'exe' nao encontrada ao lado do instalador. Extraia o ZIP inteiro antes de instalar." }
    $versao = ''
    $vf = Join-Path $aqui 'VERSAO.txt'
    if (Test-Path -LiteralPath $vf) { $versao = (Get-Content -LiteralPath $vf -Encoding UTF8 | Select-Object -First 1) }
    $dest = Escolher-Pasta
    if (-not $dest) { exit 1 }
    if (Abertos $dest) { Msg 'Feche o jogo e o launcher do openOMSI e rode o instalador de novo.' 'openOMSI HOF Auto' 'OK' 'Warning' | Out-Null; exit 1 }
    $r = Msg "Instalar o openOMSI HOF Auto $versao em:`n$dest`n`nOs 4 executaveis originais serao guardados em backup. Mapas, onibus e configuracoes nao sao alterados.`n`nContinuar?" 'openOMSI HOF Auto' 'YesNo' 'Question'
    if ($r -ne 'Yes') { exit 1 }
    $bk = Join-Path $bkRaiz (Get-Date -Format 'yyyyMMdd-HHmmss')
    New-Item -ItemType Directory -Force $bk | Out-Null
    Set-Content -LiteralPath (Join-Path $bk 'instalacao.txt') -Value $dest -Encoding UTF8
    $feitos = @()
    try {
        foreach ($e in $exes) {
            $n = Join-Path $novos $e
            $o = Join-Path $dest $e
            if (-not (Test-Path -LiteralPath $n)) { throw "Faltando no pacote: $e" }
            if (Test-Path -LiteralPath $o) {
                Copy-Item -LiteralPath $o -Destination (Join-Path $bk $e) -Force
                if ((Hash $o) -ne (Hash (Join-Path $bk $e))) { throw "Backup de $e nao confere" }
            }
        }
        foreach ($e in $exes) {
            $n = Join-Path $novos $e
            $o = Join-Path $dest $e
            if ((Test-Path -LiteralPath $o) -and ((Hash $o) -eq (Hash $n))) { Log "ja igual: $e"; continue }
            $t = Join-Path $dest ($e + '.novo')
            Copy-Item -LiteralPath $n -Destination $t -Force
            if ((Hash $t) -ne (Hash $n)) { Remove-Item -LiteralPath $t -Force; throw "Copia de $e nao confere" }
            Move-Item -LiteralPath $t -Destination $o -Force
            $feitos += $e
            Log "instalado $e"
        }
    } catch {
        foreach ($e in $feitos) {
            $b = Join-Path $bk $e
            if (Test-Path -LiteralPath $b) { Copy-Item -LiteralPath $b -Destination (Join-Path $dest $e) -Force }
        }
        throw
    }
    Msg "Instalado com sucesso.`n`nAbra o jogo normalmente.`nPara voltar ao original: Desinstalar.cmd (nesta mesma pasta)." 'openOMSI HOF Auto' 'OK' 'Information' | Out-Null
    exit 0
} catch {
    Log ("ERRO: " + $_.Exception.Message)
    Msg ("Nao foi possivel concluir:`n`n" + $_.Exception.Message + "`n`nOs originais foram mantidos/restaurados. Detalhes: $logf") 'openOMSI HOF Auto' 'OK' 'Error' | Out-Null
    exit 1
}
