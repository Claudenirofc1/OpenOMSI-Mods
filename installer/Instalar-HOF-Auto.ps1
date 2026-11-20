<#
 Instalador simples do openOMSI HOF Auto (projeto independente, NAO oficial).
 Troca SOMENTE 4 executaveis da pasta do jogo; faz backup dos originais antes e confere cada arquivo.
 NAO mexe em mapas, onibus, HOFs, configuracoes, OMSI 2 ou outros mods.
 -Desinstalar: devolve os originais do backup mais recente.
#>
param([switch]$Desinstalar, [switch]$SoPerfil)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
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

# ---- Mods escolhidos (caixas) e perfil salvo --------------------------------------------------
# O jogo le ~/.openomsi/hofauto-mods.cfg (nome=1 liga, nome=0 desliga). Uma COPIA do perfil
# (escolhas + cameras das portas + dashcam + retrovisores) fica em Documentos\openOMSI-HOF-Auto\perfil:
# sobrevive a desinstalar o jogo e a formatar o PC, se voce guardar essa pasta.
$mods = @(
    @{ id = 'hof_auto';  texto = 'HOF automatico (escolhe o HOF do onibus sozinho)' },
    @{ id = 'door_cams'; texto = 'Cameras das portas (popup ao abrir a porta)  [Ctrl+K]' },
    @{ id = 'dashcam';   texto = 'Dashcam (grava a viagem em MP4, precisa do ffmpeg)  [Ctrl+J]' }
)
$homeCfg = Join-Path $env:USERPROFILE '.openomsi'
$perfilDir = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'openOMSI-HOF-Auto\perfil'
$arqPerfil = @('hofauto-mods.cfg', 'door_cams.cfg', 'dashcam.cfg', 'mirror_hud.cfg')
function Ler-Mods {
    $r = @{}
    foreach ($m in $mods) { $r[$m.id] = $true }
    foreach ($f in @((Join-Path $perfilDir 'hofauto-mods.cfg'), (Join-Path $homeCfg 'hofauto-mods.cfg'))) {
        if (Test-Path -LiteralPath $f) {
            foreach ($l in (Get-Content -LiteralPath $f -Encoding UTF8)) {
                $l = ($l -split '#')[0].Trim()
                if ($l -match '^([^=]+)=(.*)$') { $r[$Matches[1].Trim().ToLower()] = ($Matches[2].Trim().ToLower() -notin @('0', 'off', 'false', 'no')) }
            }
        }
    }
    return $r
}
function Perguntar-Mods {
    $atual = Ler-Mods
    $f = New-Object System.Windows.Forms.Form
    $f.Text = 'openOMSI HOF Auto - quais mods?'
    $f.StartPosition = 'CenterScreen'; $f.FormBorderStyle = 'FixedDialog'; $f.MaximizeBox = $false; $f.MinimizeBox = $false
    $f.ClientSize = New-Object System.Drawing.Size(520, (110 + 30 * $mods.Count))
    $t = New-Object System.Windows.Forms.Label
    $t.Text = 'Marque os mods que quer usar. Pode mudar depois rodando o instalador de novo.'
    $t.Location = New-Object System.Drawing.Point(14, 12); $t.Size = New-Object System.Drawing.Size(495, 36)
    $f.Controls.Add($t)
    $caixas = @{}
    $y = 52
    foreach ($m in $mods) {
        $c = New-Object System.Windows.Forms.CheckBox
        $c.Text = $m.texto; $c.Checked = [bool]$atual[$m.id]
        $c.Location = New-Object System.Drawing.Point(20, $y); $c.Size = New-Object System.Drawing.Size(485, 24)
        $f.Controls.Add($c); $caixas[$m.id] = $c; $y += 30
    }
    $ok = New-Object System.Windows.Forms.Button
    $ok.Text = 'Continuar'; $ok.DialogResult = 'OK'
    $ok.Location = New-Object System.Drawing.Point(300, ($y + 14)); $ok.Size = New-Object System.Drawing.Size(100, 30)
    $no = New-Object System.Windows.Forms.Button
    $no.Text = 'Cancelar'; $no.DialogResult = 'Cancel'
    $no.Location = New-Object System.Drawing.Point(410, ($y + 14)); $no.Size = New-Object System.Drawing.Size(95, 30)
    $f.Controls.Add($ok); $f.Controls.Add($no); $f.AcceptButton = $ok; $f.CancelButton = $no
    if ($f.ShowDialog() -ne 'OK') { return $null }
    $r = @{}
    foreach ($m in $mods) { $r[$m.id] = $caixas[$m.id].Checked }
    return $r
}
function Gravar-Mods($escolha) {
    New-Item -ItemType Directory -Force $homeCfg | Out-Null
    $linhas = @('# Escolhas do instalador openOMSI HOF Auto (1 = ligado, 0 = desligado). Vale na hora, sem reiniciar o jogo.')
    foreach ($m in $mods) { $linhas += ('{0}={1}' -f $m.id, [int][bool]$escolha[$m.id]) }
    Set-Content -LiteralPath (Join-Path $homeCfg 'hofauto-mods.cfg') -Value $linhas -Encoding UTF8
}
function Salvar-Perfil {
    New-Item -ItemType Directory -Force $perfilDir | Out-Null
    foreach ($a in $arqPerfil) {
        $o = Join-Path $homeCfg $a
        if (Test-Path -LiteralPath $o) { Copy-Item -LiteralPath $o -Destination (Join-Path $perfilDir $a) -Force }
    }
    Log "perfil salvo em $perfilDir"
}
function Restaurar-Perfil {
    # So traz de volta o que NAO existe no PC (nunca sobrescreve o que voce ja tem).
    if (-not (Test-Path -LiteralPath $perfilDir)) { return 0 }
    New-Item -ItemType Directory -Force $homeCfg | Out-Null
    $n = 0
    foreach ($a in $arqPerfil) {
        $c = Join-Path $perfilDir $a
        $d = Join-Path $homeCfg $a
        if ((Test-Path -LiteralPath $c) -and -not (Test-Path -LiteralPath $d)) { Copy-Item -LiteralPath $c -Destination $d; $n++ }
    }
    if ($n) { Log "perfil restaurado ($n arquivos)" }
    return $n
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
    if ($SoPerfil) {
        $n = Restaurar-Perfil
        Msg "Perfil conferido em:`n$perfilDir`n`nArquivos trazidos de volta: $n" 'openOMSI HOF Auto' 'OK' 'Information' | Out-Null
        exit 0
    }
    if ($Desinstalar) {
        Salvar-Perfil
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
    $restaurados = Restaurar-Perfil
    $escolha = Perguntar-Mods
    if ($null -eq $escolha) { exit 1 }
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
    Gravar-Mods $escolha
    Salvar-Perfil
    $aviso = ''
    if ($escolha['dashcam'] -and -not (Get-Command ffmpeg -ErrorAction SilentlyContinue) -and -not (Test-Path -LiteralPath (Join-Path $dest 'ffmpeg.exe')) -and -not (Test-Path -LiteralPath (Join-Path $homeCfg 'bin\ffmpeg.exe'))) { $aviso = "`n`nAtencao: a dashcam precisa do ffmpeg.exe. Coloque-o na pasta do jogo ou em $homeCfg\bin (ou instale com: winget install ffmpeg)." }
    Msg ("Instalado com sucesso.`n`nAbra o jogo normalmente.`nPara voltar ao original: Desinstalar.cmd (nesta mesma pasta).`n`nSuas escolhas e cameras ficaram salvas em:`n$perfilDir`nGuarde essa pasta para restaurar depois de formatar o PC." + $aviso) 'openOMSI HOF Auto' 'OK' 'Information' | Out-Null
    exit 0
} catch {
    Log ("ERRO: " + $_.Exception.Message)
    Msg ("Nao foi possivel concluir:`n`n" + $_.Exception.Message + "`n`nOs originais foram mantidos/restaurados. Detalhes: $logf") 'openOMSI HOF Auto' 'OK' 'Error' | Out-Null
    exit 1
}
