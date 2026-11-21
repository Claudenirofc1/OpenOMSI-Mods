<#
 OpenOMSI Mod Manager (projeto independente, NAO oficial) - o instalador existente, evoluido.
 Troca SOMENTE 4 executaveis da pasta do jogo, com backup versionado e conferencia por hash.
 NAO mexe em mapas, onibus, HOFs, saves, OMSI 2 ou outros mods.
 Modos: Menu | Instalar | Atualizar | Reparar | Diagnostico | Restaurar | Exportar | Importar
 -Desinstalar: volta aos arquivos oficiais (backup oficial mais recente).
 Parametros de teste (CI): -Silencioso -RaizTeste -PastaJogo -ModsEscolhidos -Backup -PastaDestino -PastaOrigem -SimularQueda
 Codigos de saida: 0 ok, 1 recusado/erro (nada alterado), 99 queda simulada.
#>
param(
    [switch]$Desinstalar,
    [switch]$SoPerfil,
    [ValidateSet('Menu', 'Instalar', 'Atualizar', 'Reparar', 'Diagnostico', 'Restaurar', 'Exportar', 'Importar')][string]$Modo = 'Instalar',
    [switch]$Silencioso,
    [string]$RespostaPadrao = 'Yes',
    [string]$PastaJogo = '',
    [string]$ModsEscolhidos = '',
    [string]$Backup = '',
    [string]$PastaDestino = '',
    [string]$PastaOrigem = '',
    [string]$RaizTeste = '',
    [int]$SimularQueda = 0
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$exes = @('openomsi.exe', 'openomsi-launcher.exe', 'openomsi-launcher-app.exe', 'omsi-plugin-host32.exe')
$aqui = Split-Path -Parent $MyInvocation.MyCommand.Path
$novos = Join-Path $aqui 'exe'
$repoGh = 'Claudenirofc1/OpenOMSI-Mods'
if ($RaizTeste) {
    $dadosDir = Join-Path $RaizTeste 'dados'
    $homeCfg = Join-Path $RaizTeste 'home\.openomsi'
    $perfilDir = Join-Path $RaizTeste 'docs\perfil'
} else {
    $dadosDir = Join-Path $env:LOCALAPPDATA 'openOMSI-HOF-Auto'
    $homeCfg = Join-Path $env:USERPROFILE '.openomsi'
    $perfilDir = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'openOMSI-HOF-Auto\perfil'
}
$bkRaiz = Join-Path $dadosDir 'backup'
$logf = Join-Path $dadosDir 'instalacao.log.txt'
$estadoF = Join-Path $dadosDir 'estado.json'
$pendF = Join-Path $dadosDir 'pendente.txt'
New-Item -ItemType Directory -Force $dadosDir | Out-Null
$mods = @(
    @{ id = 'hof_auto';  texto = 'HOF automatico (escolhe o HOF do onibus sozinho)' },
    @{ id = 'door_cams'; texto = 'Cameras das portas (popup ao abrir a porta)  [Ctrl+K]' },
    @{ id = 'dashcam';   texto = 'Dashcam (grava a viagem em MP4, precisa do ffmpeg)  [Ctrl+J]' },
    @{ id = 'ai_unstick'; texto = 'Recuperar IAs travadas de vez (so remove fora da vista; nunca onibus)' }
)
$arqPerfil = @('hofauto-mods.cfg', 'door_cams.cfg', 'dashcam.cfg', 'mirror_hud.cfg')
$publicadoNovo = ''

function Log([string]$s) { try { Add-Content -Encoding UTF8 -Path $logf -Value ("{0} {1}" -f (Get-Date -Format s), $s) } catch { } }
function Msg([string]$t, [string]$titulo = 'openOMSI Mod Manager', [string]$botoes = 'OK', [string]$icone = 'Information') {
    Log ('[msg] ' + ($t -replace "`r?`n", ' | '))
    if ($Silencioso) { if ($botoes -eq 'YesNo') { return $RespostaPadrao } else { return 'OK' } }
    [System.Windows.Forms.MessageBox]::Show($t, $titulo, $botoes, $icone)
}
function Hash([string]$p) { (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLower() }
function Abertos([string]$raiz) {
    $n = @('openomsi', 'openomsi-launcher', 'openomsi-launcher-app', 'omsi-plugin-host32')
    Get-Process -Name $n -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path.StartsWith($raiz, [StringComparison]::OrdinalIgnoreCase) }
}
function Ler-Json([string]$f) {
    if (-not (Test-Path -LiteralPath $f)) { return $null }
    try { return (Get-Content -LiteralPath $f -Raw -Encoding UTF8 | ConvertFrom-Json) } catch { return $null }
}
function Ler-Manifesto([string]$pasta) { return (Ler-Json (Join-Path $pasta 'manifest.json')) }

# ---- escolhas dos mods e perfil ----------------------------------------------------------------
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
function Perguntar-Mods($compat) {
    $atual = Ler-Mods
    $r = @{}
    if ($Silencioso) {
        foreach ($m in $mods) { $r[$m.id] = [bool]$atual[$m.id] }
        foreach ($par in ($ModsEscolhidos -split '[,;]')) {
            if ($par -match '^\s*([^=\s]+)\s*=\s*(\d)\s*$') { $r[$Matches[1].ToLower()] = ($Matches[2] -ne '0') }
        }
    } else {
        $f = New-Object System.Windows.Forms.Form
        $f.Text = 'openOMSI Mod Manager - quais mods?'
        $f.StartPosition = 'CenterScreen'; $f.FormBorderStyle = 'FixedDialog'; $f.MaximizeBox = $false; $f.MinimizeBox = $false
        $f.ClientSize = New-Object System.Drawing.Size(540, (110 + 30 * $mods.Count))
        $t = New-Object System.Windows.Forms.Label
        $t.Text = 'Marque os mods que quer usar. Mods incompativeis com a sua versao do jogo ficam desativados.'
        $t.Location = New-Object System.Drawing.Point(14, 12); $t.Size = New-Object System.Drawing.Size(515, 36)
        $f.Controls.Add($t)
        $caixas = @{}
        $y = 52
        foreach ($m in $mods) {
            $c = New-Object System.Windows.Forms.CheckBox
            $c.Text = $m.texto; $c.Checked = ([bool]$atual[$m.id] -and [bool]$compat[$m.id]); $c.Enabled = [bool]$compat[$m.id]
            if (-not $compat[$m.id]) { $c.Text = $m.texto + '  (incompativel)' }
            $c.Location = New-Object System.Drawing.Point(20, $y); $c.Size = New-Object System.Drawing.Size(505, 24)
            $f.Controls.Add($c); $caixas[$m.id] = $c; $y += 30
        }
        $ok = New-Object System.Windows.Forms.Button
        $ok.Text = 'Continuar'; $ok.DialogResult = 'OK'
        $ok.Location = New-Object System.Drawing.Point(320, ($y + 14)); $ok.Size = New-Object System.Drawing.Size(100, 30)
        $no = New-Object System.Windows.Forms.Button
        $no.Text = 'Cancelar'; $no.DialogResult = 'Cancel'
        $no.Location = New-Object System.Drawing.Point(430, ($y + 14)); $no.Size = New-Object System.Drawing.Size(95, 30)
        $f.Controls.Add($ok); $f.Controls.Add($no); $f.AcceptButton = $ok; $f.CancelButton = $no
        if ($f.ShowDialog() -ne 'OK') { return $null }
        foreach ($m in $mods) { $r[$m.id] = $caixas[$m.id].Checked }
    }
    foreach ($m in $mods) { if (-not $compat[$m.id]) { $r[$m.id] = $false } }
    return $r
}
function Gravar-Mods($escolha) {
    New-Item -ItemType Directory -Force $homeCfg | Out-Null
    $linhas = @('# Escolhas do openOMSI Mod Manager (1 = ligado, 0 = desligado). Vale na hora, sem reiniciar o jogo.')
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

# ---- estado, prova de versao e compatibilidade por modulo --------------------------------------
function Estado-Gravar($dest, $manifesto, [string]$publicado, [string]$vj) {
    $o = [ordered]@{
        pasta_do_jogo = $dest
        pacote = $manifesto.package
        base_openomsi = $vj
        gerenciador = $manifesto.manager
        publicado_em = $publicado
        instalado_em = (Get-Date -Format s)
        modulos = @($manifesto.modules | ForEach-Object { $_.id + '@' + $_.version })
        arquivos = $manifesto.files
    }
    ConvertTo-Json -InputObject $o -Depth 6 | Set-Content -LiteralPath $estadoF -Encoding UTF8
}
function Pasta-Do-Jogo {
    if ($PastaJogo) {
        if (Test-Path -LiteralPath (Join-Path $PastaJogo 'openomsi.exe')) { return $PastaJogo }
        return $null
    }
    $st = Ler-Json $estadoF
    if ($st -and $st.pasta_do_jogo -and (Test-Path -LiteralPath (Join-Path $st.pasta_do_jogo 'openomsi.exe'))) { return [string]$st.pasta_do_jogo }
    return (Escolher-Pasta)
}
function Escolher-Pasta {
    $cands = @('D:\Games\OpenOMSI', 'C:\Games\OpenOMSI', 'E:\Games\OpenOMSI', (Join-Path $env:ProgramFiles 'OpenOMSI'), (Join-Path $env:LOCALAPPDATA 'Programs\OpenOMSI'), (Join-Path $env:USERPROFILE 'Games\OpenOMSI'))
    foreach ($c in $cands) {
        if (Test-Path -LiteralPath (Join-Path $c 'openomsi.exe')) {
            $r = Msg "Encontrei o openOMSI em:`n`n$c`n`nUsar esta pasta?" 'openOMSI Mod Manager' 'YesNo' 'Question'
            if ($r -eq 'Yes') { return $c }
        }
    }
    if ($Silencioso) { return $null }
    Msg "Na proxima janela, escolha o arquivo openomsi.exe do SEU jogo (ele fica na pasta onde o openOMSI esta instalado).`n`nO instalador usa a pasta desse arquivo e so troca os 4 programas do jogo, com backup. Seus onibus, mapas, HOFs e saves nao sao tocados." 'openOMSI Mod Manager' 'OK' 'Information' | Out-Null
    while ($true) {
        $d = New-Object System.Windows.Forms.OpenFileDialog
        $d.Title = 'Escolha o openomsi.exe do seu jogo'
        $d.Filter = 'openOMSI (openomsi.exe)|openomsi.exe|Programas (*.exe)|*.exe'
        $d.CheckFileExists = $true
        if ($d.ShowDialog() -ne 'OK') { return $null }
        $pasta = Split-Path -Parent $d.FileName
        if ((Split-Path -Leaf $d.FileName) -ieq 'openomsi.exe' -and (Test-Path -LiteralPath (Join-Path $pasta 'openomsi.exe'))) { return $pasta }
        Msg 'Esse arquivo nao e o openomsi.exe. Escolha o openomsi.exe da pasta do jogo.' 'openOMSI Mod Manager' 'OK' 'Warning' | Out-Null
    }
}
function Lista-De([object]$obj, [string]$exe) {
    if ($null -eq $obj) { return @() }
    $p = $obj.PSObject.Properties[$exe]
    if ($null -eq $p) { return @() }
    return @($p.Value | ForEach-Object { ([string]$_).ToLower() })
}
function Provar-Versao([string]$dest, $manifesto) {
    # Versao do openOMSI PROVADA pelos hashes: todos os executaveis presentes (e o openomsi.exe) precisam
    # bater com builds conhecidos dessa versao (oficial, build local do mesmo codigo, ou o que este gerenciador instalou).
    # Retorna '' se nao for possivel provar. Nao ha confirmacao manual.
    if (-not $manifesto -or -not $manifesto.proven) { return '' }
    if (-not (Test-Path -LiteralPath (Join-Path $dest 'openomsi.exe'))) { return '' }
    $st = Ler-Json $estadoF
    foreach ($v in $manifesto.proven.PSObject.Properties.Name) {
        $ok = $true
        foreach ($e in $exes) {
            $o = Join-Path $dest $e
            if (-not (Test-Path -LiteralPath $o)) { continue }
            $h = Hash $o
            $conhecidos = Lista-De $manifesto.proven.$v $e
            if (($conhecidos -notcontains $h) -and -not ($st -and $st.base_openomsi -eq $v -and $st.arquivos -and ((Lista-De $st.arquivos $e) -contains $h))) { $ok = $false; break }
        }
        if ($ok) { return $v }
    }
    return ''
}
function Origem-Oficial([string]$dir, $manifesto) {
    # $true se TODOS os executaveis em $dir sao oficiais conhecidos
    if (-not $manifesto -or -not $manifesto.official) { return $false }
    $n = 0
    foreach ($e in $exes) {
        $o = Join-Path $dir $e
        if (-not (Test-Path -LiteralPath $o)) { continue }
        $n++
        $h = Hash $o
        $achou = $false
        foreach ($v in $manifesto.official.PSObject.Properties.Name) { if ((Lista-De $manifesto.official.$v $e) -contains $h) { $achou = $true } }
        if (-not $achou) { return $false }
    }
    return ($n -gt 0)
}
function Compat-Modulos($manifesto, [string]$vj) {
    # id -> $true/$false: o modulo declara suportar esta versao do jogo e suas dependencias de modulo estao ok.
    $r = @{}
    foreach ($m in $mods) { $r[$m.id] = $false }
    if (-not $vj) { return $r }
    foreach ($mm in @($manifesto.modules)) { $r[[string]$mm.id] = (@($mm.compatible_openomsi) -contains $vj) }
    foreach ($mm in @($manifesto.modules)) {
        foreach ($d in @($mm.requires)) { if ($r.ContainsKey([string]$d) -and -not $r[[string]$d]) { $r[[string]$mm.id] = $false } }
    }
    return $r
}
function Diagnosticar([string]$dest, $manifesto) {
    $linhas = New-Object System.Collections.ArrayList
    $problemas = New-Object System.Collections.ArrayList
    [void]$linhas.Add("Pasta do jogo: $dest")
    $vj = ''
    if ($manifesto) {
        $vj = Provar-Versao $dest $manifesto
        [void]$linhas.Add("Pacote: $($manifesto.package) (base openOMSI $($manifesto.base))")
        if ($vj) { [void]$linhas.Add("Versao do jogo PROVADA por hash: $vj") }
        else { [void]$problemas.Add('Nao consegui PROVAR a versao do jogo (os executaveis nao batem com nenhum build conhecido). Patches bloqueados.') }
        if ($vj -and (@($manifesto.compatible_openomsi) -notcontains $vj)) { [void]$problemas.Add("A versao do jogo ($vj) nao e suportada por este pacote ($(@($manifesto.compatible_openomsi) -join ', ')). Patches bloqueados.") }
        foreach ($e in $exes) {
            $o = Join-Path $dest $e
            $esp = [string]$manifesto.files.$e
            if (-not (Test-Path -LiteralPath $o)) { [void]$problemas.Add("Ausente no jogo: $e"); continue }
            if ($esp -and ((Hash $o) -ne $esp.ToLower())) { [void]$problemas.Add("$e nao e o do pacote (jogo oficial/atualizado ou arquivo alterado)") }
        }
        $cm = Compat-Modulos $manifesto $vj
        foreach ($m in $mods) { [void]$linhas.Add(("Modulo {0}: {1}" -f $m.id, $(if ($cm[$m.id]) { 'compativel' } else { 'INCOMPATIVEL/bloqueado' }))) }
    } else { [void]$problemas.Add('manifest.json nao encontrado ao lado do instalador (pacote incompleto: extraia o ZIP inteiro).') }
    $st = Ler-Json $estadoF
    [void]$linhas.Add("Instalado antes: " + $(if ($st) { "$($st.pacote) em $($st.instalado_em)" } else { 'sem registro' }))
    $m2 = Ler-Mods
    foreach ($x in $mods) { [void]$linhas.Add(("Mod {0}: {1}" -f $x.id, $(if ($m2[$x.id]) { 'ligado' } else { 'desligado' }))) }
    $bks = @(Get-ChildItem -LiteralPath $bkRaiz -Directory -ErrorAction SilentlyContinue)
    [void]$linhas.Add("Backups: $($bks.Count) em $bkRaiz")
    [void]$linhas.Add("Perfil salvo: " + $(if (Test-Path -LiteralPath $perfilDir) { $perfilDir } else { 'ainda nao' }))
    $ff = [bool](Get-Command ffmpeg -ErrorAction SilentlyContinue) -or (Test-Path -LiteralPath (Join-Path $dest 'ffmpeg.exe')) -or (Test-Path -LiteralPath (Join-Path $homeCfg 'bin\ffmpeg.exe'))
    [void]$linhas.Add("ffmpeg (dashcam): " + $(if ($ff) { 'encontrado' } else { 'NAO encontrado' }))
    return [pscustomobject]@{ Linhas = $linhas; Problemas = $problemas; Versao = $vj }
}
function Texto-Diag($d) {
    $t = ($d.Linhas -join "`n")
    if ($d.Problemas.Count) { $t += "`n`nProblemas:`n- " + ($d.Problemas -join "`n- ") } else { $t += "`n`nNenhum problema encontrado." }
    return $t
}

# ---- backups versionados ------------------------------------------------------------------------
function Novo-Backup([string]$dest, $manifesto, [string]$vj) {
    $nome = Get-Date -Format 'yyyyMMdd-HHmmssfff'
    $bk = Join-Path $bkRaiz $nome
    New-Item -ItemType Directory -Force $bk | Out-Null
    foreach ($e in $exes) {
        $o = Join-Path $dest $e
        if (Test-Path -LiteralPath $o) {
            Copy-Item -LiteralPath $o -Destination (Join-Path $bk $e) -Force
            if ((Hash $o) -ne (Hash (Join-Path $bk $e))) { throw "Backup de $e nao confere" }
        }
    }
    $cfgDir = Join-Path $bk 'config'
    New-Item -ItemType Directory -Force $cfgDir | Out-Null
    foreach ($a in $arqPerfil) {
        $c = Join-Path $homeCfg $a
        if (Test-Path -LiteralPath $c) { Copy-Item -LiteralPath $c -Destination (Join-Path $cfgDir $a) -Force }
    }
    $st = Ler-Json $estadoF
    $meta = [ordered]@{
        criado = (Get-Date -Format s)
        pasta_do_jogo = $dest
        jogo_versao = $vj
        pacote_anterior = $(if ($st) { [string]$st.pacote } else { '' })
        oficial = (Origem-Oficial $bk $manifesto)
    }
    ConvertTo-Json -InputObject $meta | Set-Content -LiteralPath (Join-Path $bk 'backup.json') -Encoding UTF8
    return $bk
}
function Listar-Backups {
    $r = @()
    foreach ($d in @(Get-ChildItem -LiteralPath $bkRaiz -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending)) {
        $m = Ler-Json (Join-Path $d.FullName 'backup.json')
        $dest = ''
        if ($m) { $dest = [string]$m.pasta_do_jogo }
        else { $i = Join-Path $d.FullName 'instalacao.txt'; if (Test-Path -LiteralPath $i) { $dest = (Get-Content -LiteralPath $i -Encoding UTF8 | Select-Object -First 1).Trim() } }
        $r += [pscustomobject]@{
            Nome = $d.Name; Caminho = $d.FullName; Jogo = $dest
            Oficial = [bool]($m -and $m.oficial)
            Texto = ('{0}  |  jogo {1}  |  {2}' -f $d.Name, $(if ($m) { $m.jogo_versao } else { '?' }), $(if ($m -and $m.oficial) { 'arquivos OFICIAIS' } else { 'arquivos do mod/outros' }))
        }
    }
    return $r
}
function Escolher-Backup($lista) {
    if ($Backup) { return ($lista | Where-Object { $_.Nome -eq $Backup } | Select-Object -First 1) }
    if ($Silencioso) { return ($lista | Select-Object -First 1) }
    $f = New-Object System.Windows.Forms.Form
    $f.Text = 'Escolha a versao do backup a restaurar'; $f.StartPosition = 'CenterScreen'
    $f.ClientSize = New-Object System.Drawing.Size(640, 330)
    $lb = New-Object System.Windows.Forms.ListBox
    $lb.Location = New-Object System.Drawing.Point(10, 10); $lb.Size = New-Object System.Drawing.Size(620, 260)
    foreach ($b in $lista) { [void]$lb.Items.Add($b.Texto) }
    $lb.SelectedIndex = 0
    $ok = New-Object System.Windows.Forms.Button; $ok.Text = 'Restaurar este'; $ok.DialogResult = 'OK'
    $ok.Location = New-Object System.Drawing.Point(400, 285); $ok.Size = New-Object System.Drawing.Size(110, 30)
    $no = New-Object System.Windows.Forms.Button; $no.Text = 'Cancelar'; $no.DialogResult = 'Cancel'
    $no.Location = New-Object System.Drawing.Point(520, 285); $no.Size = New-Object System.Drawing.Size(100, 30)
    $f.Controls.Add($lb); $f.Controls.Add($ok); $f.Controls.Add($no)
    if ($f.ShowDialog() -ne 'OK') { return $null }
    return $lista[$lb.SelectedIndex]
}
function Restaurar-Arquivos([string]$bkDir, [string]$dest) {
    foreach ($e in $exes) {
        $o = Join-Path $bkDir $e
        if (Test-Path -LiteralPath $o) {
            $t = Join-Path $dest ($e + '.restaurando')
            Copy-Item -LiteralPath $o -Destination $t -Force
            if ((Hash $t) -ne (Hash $o)) { Remove-Item -LiteralPath $t -Force; throw "Falha ao conferir $e" }
            Move-Item -LiteralPath $t -Destination (Join-Path $dest $e) -Force
            Log "restaurado $e (de $bkDir)"
        }
    }
}
function Restaurar-Config([string]$bkDir) {
    $cfgDir = Join-Path $bkDir 'config'
    if (-not (Test-Path -LiteralPath $cfgDir)) { return 0 }
    New-Item -ItemType Directory -Force $homeCfg | Out-Null
    $n = 0
    foreach ($a in $arqPerfil) {
        $c = Join-Path $cfgDir $a
        if (Test-Path -LiteralPath $c) {
            $d = Join-Path $homeCfg $a
            if (Test-Path -LiteralPath $d) { Copy-Item -LiteralPath $d -Destination ($d + '.antes-' + (Get-Date -Format 'yyyyMMddHHmmss')) -Force }
            Copy-Item -LiteralPath $c -Destination $d -Force; $n++
        }
    }
    return $n
}

# ---- atualizar, menu, exportar/importar --------------------------------------------------------
function Baixar-Atualizacao([string]$versaoBase, $atual) {
    $api = "https://api.github.com/repos/$repoGh/releases"
    $rels = Invoke-RestMethod -Uri $api -Headers @{ 'User-Agent' = 'openOMSI-Mod-Manager' } -TimeoutSec 30
    $tag = "v$versaoBase-hofauto"
    $rel = $rels | Where-Object { $_.tag_name -eq $tag } | Select-Object -First 1
    if (-not $rel) { return @{ Estado = 'sem-release'; Tag = $tag } }
    $asset = $rel.assets | Where-Object { $_.name -like '*.zip' } | Select-Object -First 1
    if (-not $asset) { return @{ Estado = 'sem-release'; Tag = $tag } }
    if ($atual -and $atual.publicado_em -and ([string]$asset.updated_at -eq [string]$atual.publicado_em)) { return @{ Estado = 'em-dia'; Tag = $tag } }
    if (-not ([string]$asset.browser_download_url).StartsWith("https://github.com/$repoGh/", [StringComparison]::OrdinalIgnoreCase)) { throw 'URL de download fora do repositorio oficial do projeto; recusado.' }
    $tmp = Join-Path $env:TEMP ('hofauto-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force $tmp | Out-Null
    $zip = Join-Path $tmp 'pacote.zip'
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zip -TimeoutSec 600
    Expand-Archive -LiteralPath $zip -DestinationPath (Join-Path $tmp 'x') -Force
    return @{ Estado = 'baixado'; Tag = $tag; Pasta = (Join-Path $tmp 'x'); Publicado = [string]$asset.updated_at }
}
function Menu-Gerenciador {
    $f = New-Object System.Windows.Forms.Form
    $f.Text = 'OpenOMSI Mod Manager'; $f.StartPosition = 'CenterScreen'; $f.FormBorderStyle = 'FixedDialog'; $f.MaximizeBox = $false
    $itens = @(@('Instalar', 'Instalar / escolher mods'), @('Atualizar', 'Atualizar (consulta o GitHub)'), @('Reparar', 'Reparar (diagnostico + autorizacao)'), @('Diagnostico', 'Diagnostico'), @('Restaurar', 'Restaurar backup (escolher a versao)'), @('Exportar', 'Exportar perfil (backup recuperavel)'), @('Importar', 'Importar perfil'))
    $f.ClientSize = New-Object System.Drawing.Size(360, (28 + 42 * $itens.Count))
    $y = 14
    $script:escolhaMenu = $null
    foreach ($i in $itens) {
        $b = New-Object System.Windows.Forms.Button
        $b.Text = $i[1]; $b.Tag = $i[0]
        $b.Location = New-Object System.Drawing.Point(30, $y); $b.Size = New-Object System.Drawing.Size(300, 34)
        $b.Add_Click({ $script:escolhaMenu = $this.Tag; $this.FindForm().Close() })
        $f.Controls.Add($b); $y += 42
    }
    [void]$f.ShowDialog()
    return $script:escolhaMenu
}
function Escolher-Pasta-Backup([string]$descricao, [string]$fixa) {
    if ($fixa) { return $fixa }
    if ($Silencioso) { return $null }
    $d = New-Object System.Windows.Forms.FolderBrowserDialog
    $d.Description = $descricao
    if ($d.ShowDialog() -ne 'OK') { return $null }
    return $d.SelectedPath
}

# ---- fluxo principal ----------------------------------------------------------------------------
function Recuperar-Interrompida {
    if (-not (Test-Path -LiteralPath $pendF)) { return $false }
    $l = @(Get-Content -LiteralPath $pendF -Encoding UTF8)
    $bkp = $l[0]; $dp = $l[1]
    if ($bkp -and $dp -and (Test-Path -LiteralPath $bkp) -and -not (Abertos $dp)) {
        Restaurar-Arquivos $bkp $dp
        Log 'recuperada instalacao interrompida'
        Msg "Uma instalacao anterior foi interrompida. Os arquivos anteriores foram devolvidos (backup $bkp).`nRode o gerenciador de novo." 'openOMSI Mod Manager' 'OK' 'Warning' | Out-Null
    }
    Remove-Item -LiteralPath $pendF -Force -ErrorAction SilentlyContinue
    return $true
}
function Principal {
    if (Recuperar-Interrompida) { return 1 }
    if ($Desinstalar) { $script:Modo = 'Restaurar' }
    if ($SoPerfil) {
        $n = Restaurar-Perfil
        Msg "Perfil conferido em:`n$perfilDir`n`nArquivos trazidos de volta: $n" 'openOMSI Mod Manager' 'OK' 'Information' | Out-Null
        return 0
    }
    if ($script:Modo -eq 'Menu') { $sel = Menu-Gerenciador; if (-not $sel) { return 0 }; $script:Modo = $sel }
    $modo = $script:Modo

    if ($modo -eq 'Exportar') {
        Salvar-Perfil
        $alvo = Escolher-Pasta-Backup 'Escolha onde guardar o backup do perfil (de preferencia outra unidade ou pendrive).' $PastaDestino
        if (-not $alvo) { return 1 }
        $sub = Join-Path $alvo ('openOMSI-HOF-Auto-perfil-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
        New-Item -ItemType Directory -Force $sub | Out-Null
        Copy-Item -Path (Join-Path $perfilDir '*') -Destination $sub -Force
        if (Test-Path -LiteralPath $estadoF) { Copy-Item -LiteralPath $estadoF -Destination $sub -Force }
        Log "perfil exportado para $sub"
        Msg "Backup do perfil criado em:`n$sub`n`nPara recuperar depois: Gerenciador > Importar perfil." 'openOMSI Mod Manager' 'OK' 'Information' | Out-Null
        return 0
    }
    if ($modo -eq 'Importar') {
        $orig = Escolher-Pasta-Backup 'Escolha a pasta do backup do perfil (openOMSI-HOF-Auto-perfil-...).' $PastaOrigem
        if (-not $orig) { return 1 }
        New-Item -ItemType Directory -Force $perfilDir | Out-Null
        $n = 0
        foreach ($a in $arqPerfil) {
            $c = Join-Path $orig $a
            if (Test-Path -LiteralPath $c) {
                $d = Join-Path $perfilDir $a
                if (Test-Path -LiteralPath $d) { Copy-Item -LiteralPath $d -Destination ($d + '.antes-' + (Get-Date -Format 'yyyyMMddHHmmss')) -Force }
                Copy-Item -LiteralPath $c -Destination $d -Force; $n++
            }
        }
        $n2 = Restaurar-Perfil
        Log "perfil importado ($n arquivos, $n2 colocados no jogo)"
        Msg "Perfil importado ($n arquivos) para:`n$perfilDir`nColocados no lugar (sem sobrescrever o que ja existia): $n2" 'openOMSI Mod Manager' 'OK' 'Information' | Out-Null
        return 0
    }

    $dest = Pasta-Do-Jogo
    if (-not $dest) { Msg 'Pasta do jogo nao encontrada.' 'openOMSI Mod Manager' 'OK' 'Warning' | Out-Null; return 1 }
    $manifesto = Ler-Manifesto $aqui

    if ($modo -eq 'Diagnostico') {
        Msg (Texto-Diag (Diagnosticar $dest $manifesto)) 'Diagnostico' 'OK' 'Information' | Out-Null
        return 0
    }
    if (Abertos $dest) { Msg 'Feche o jogo e o launcher do openOMSI e rode o gerenciador de novo.' 'openOMSI Mod Manager' 'OK' 'Warning' | Out-Null; return 1 }

    if ($modo -eq 'Restaurar') {
        $lista = @(Listar-Backups | Where-Object { (-not $Desinstalar) -or $_.Oficial })
        if (-not $lista.Count) { Msg $(if ($Desinstalar) { 'Nao encontrei backup com os arquivos OFICIAIS para restaurar.' } else { 'Nao encontrei nenhum backup.' }) 'openOMSI Mod Manager' 'OK' 'Warning' | Out-Null; return 1 }
        $esc = Escolher-Backup $lista
        if (-not $esc) { return 1 }
        $dd = $(if ($esc.Jogo) { $esc.Jogo } else { $dest })
        if (-not (Test-Path -LiteralPath $dd)) { $dd = $dest }
        $r = Msg "Restaurar os executaveis do backup:`n$($esc.Texto)`n`nem $dd ?`n(O estado atual tambem sera guardado em um novo backup.)" 'openOMSI Mod Manager' 'YesNo' 'Question'
        if ($r -ne 'Yes') { return 1 }
        $vj0 = ''
        if ($manifesto) { $vj0 = Provar-Versao $dd $manifesto }
        $antes = Novo-Backup $dd $manifesto $vj0
        Set-Content -LiteralPath $pendF -Value @($antes, $dd) -Encoding UTF8
        Restaurar-Arquivos $esc.Caminho $dd
        Remove-Item -LiteralPath $pendF -Force -ErrorAction SilentlyContinue
        $rc = Msg 'Restaurar tambem as configuracoes (escolhas dos mods, cameras, dashcam) guardadas nesse backup? As atuais viram .antes-...' 'openOMSI Mod Manager' 'YesNo' 'Question'
        if ($rc -eq 'Yes') { $nc = Restaurar-Config $esc.Caminho; Log "config restaurada ($nc)" }
        Msg "Pronto. Backup restaurado:`n$($esc.Nome)`nSeus mapas, onibus, HOFs e saves nao foram tocados." 'openOMSI Mod Manager' 'OK' 'Information' | Out-Null
        return 0
    }

    # ---- Instalar / Atualizar / Reparar ----
    if ($modo -eq 'Atualizar') {
        if (-not $manifesto) { Msg 'Sem manifest.json ao lado do gerenciador: nao sei qual versao atualizar.' 'openOMSI Mod Manager' 'OK' 'Warning' | Out-Null; return 1 }
        $vj0 = Provar-Versao $dest $manifesto
        if (-not $vj0) { Msg 'Nao consegui provar a versao do jogo; atualizacao recusada.' 'openOMSI Mod Manager' 'OK' 'Warning' | Out-Null; return 1 }
        try { $r = Baixar-Atualizacao $vj0 (Ler-Json $estadoF) } catch { Msg ("Sem conexao ou GitHub indisponivel:`n" + $_.Exception.Message + "`n`nAs operacoes locais (instalar, reparar, restaurar) funcionam offline.") 'openOMSI Mod Manager' 'OK' 'Warning' | Out-Null; return 1 }
        if ($r.Estado -eq 'sem-release') { Msg "Ainda nao existe release deste projeto para a versao $vj0 do jogo ($($r.Tag)).`nNao instale outra versao: espere ou use o jogo oficial." 'openOMSI Mod Manager' 'OK' 'Warning' | Out-Null; return 1 }
        if ($r.Estado -eq 'em-dia') { Msg 'Voce ja esta com a versao mais recente.' 'openOMSI Mod Manager' 'OK' 'Information' | Out-Null; return 0 }
        $script:aqui = $r.Pasta; $script:novos = Join-Path $r.Pasta 'exe'; $script:publicadoNovo = $r.Publicado
        $manifesto = Ler-Manifesto $script:aqui
    }
    if (-not (Test-Path -LiteralPath $script:novos)) { throw "Pasta 'exe' nao encontrada ao lado do instalador. Extraia o ZIP inteiro antes de instalar." }
    if (-not $manifesto) { Msg 'manifest.json nao encontrado: pacote incompleto. Extraia o ZIP inteiro (ou baixe de novo). Nada foi alterado.' 'openOMSI Mod Manager' 'OK' 'Error' | Out-Null; return 1 }
    foreach ($e in $exes) {
        $esp = [string]$manifesto.files.$e
        $n = Join-Path $script:novos $e
        if (-not $esp -or -not (Test-Path -LiteralPath $n) -or ((Hash $n) -ne $esp.ToLower())) { Msg "O arquivo $e do pacote nao confere com o manifesto (download corrompido?). Nada foi alterado." 'openOMSI Mod Manager' 'OK' 'Error' | Out-Null; return 1 }
    }
    $diag = Diagnosticar $dest $manifesto
    $vj = $diag.Versao
    if (-not $vj) { Msg ((Texto-Diag $diag) + "`n`nInstalacao BLOQUEADA: nao foi possivel provar a versao/compatibilidade. Nada foi alterado.") 'openOMSI Mod Manager' 'OK' 'Error' | Out-Null; return 1 }
    if (@($manifesto.compatible_openomsi) -notcontains $vj) { Msg ((Texto-Diag $diag) + "`n`nInstalacao BLOQUEADA: versao do jogo nao suportada por este pacote. Nada foi alterado.") 'openOMSI Mod Manager' 'OK' 'Error' | Out-Null; return 1 }
    $compat = Compat-Modulos $manifesto $vj
    # a pasta do jogo precisa aceitar escrita (jogo em 'Arquivos de Programas' exige administrador)
    $sonda = Join-Path $dest ('.hofauto-teste-' + [guid]::NewGuid().ToString('N'))
    try { Set-Content -LiteralPath $sonda -Value 'x' -ErrorAction Stop; Remove-Item -LiteralPath $sonda -Force -ErrorAction SilentlyContinue }
    catch { Msg "Sem permissao para gravar na pasta do jogo:`n$dest`n`nFeche este programa e abra de novo com o botao direito > Executar como administrador (comum quando o jogo esta em Arquivos de Programas). Nada foi alterado." 'openOMSI Mod Manager' 'OK' 'Warning' | Out-Null; return 1 }
    if ($modo -eq 'Reparar') {
        if (-not $diag.Problemas.Count) { Msg (Texto-Diag $diag) 'Nada a reparar' 'OK' 'Information' | Out-Null; return 0 }
        $r1 = Msg ((Texto-Diag $diag) + "`n`nProposta: reinstalar os 4 executaveis do pacote (com backup) e reaplicar suas escolhas.`n`nAutoriza?") 'Reparar' 'YesNo' 'Question'
        if ($r1 -ne 'Yes') { return 1 }
    }
    $restaurados = Restaurar-Perfil
    $escolha = Perguntar-Mods $compat
    if ($null -eq $escolha) { return 1 }
    if ($modo -ne 'Reparar') {
        $r = Msg "Instalar o openOMSI HOF Auto ($($manifesto.package)) em:`n$dest`n`nVersao do jogo provada: $vj. Os 4 executaveis atuais serao guardados em backup versionado. Mapas, onibus e configuracoes nao sao alterados.`n`nContinuar?" 'openOMSI Mod Manager' 'YesNo' 'Question'
        if ($r -ne 'Yes') { return 1 }
    }
    $bk = Novo-Backup $dest $manifesto $vj
    Set-Content -LiteralPath $pendF -Value @($bk, $dest) -Encoding UTF8
    $feitos = @()
    try {
        foreach ($e in $exes) {
            $n = Join-Path $script:novos $e
            $o = Join-Path $dest $e
            if ((Test-Path -LiteralPath $o) -and ((Hash $o) -eq (Hash $n))) { Log "ja igual: $e"; continue }
            $t = Join-Path $dest ($e + '.novo')
            Copy-Item -LiteralPath $n -Destination $t -Force
            if ((Hash $t) -ne (Hash $n)) { Remove-Item -LiteralPath $t -Force; throw "Copia de $e nao confere" }
            Move-Item -LiteralPath $t -Destination $o -Force
            $feitos += $e
            Log "instalado $e"
            if ($SimularQueda -gt 0 -and $feitos.Count -ge $SimularQueda) { Log 'QUEDA SIMULADA (teste)'; return 99 }
        }
    } catch {
        foreach ($e in $feitos) {
            $b = Join-Path $bk $e
            if (Test-Path -LiteralPath $b) { Copy-Item -LiteralPath $b -Destination (Join-Path $dest $e) -Force }
        }
        Remove-Item -LiteralPath $pendF -Force -ErrorAction SilentlyContinue
        throw
    }
    Gravar-Mods $escolha
    Salvar-Perfil
    Estado-Gravar $dest $manifesto $script:publicadoNovo $vj
    Remove-Item -LiteralPath $pendF -Force -ErrorAction SilentlyContinue
    $aviso = ''
    $ff = [bool](Get-Command ffmpeg -ErrorAction SilentlyContinue) -or (Test-Path -LiteralPath (Join-Path $dest 'ffmpeg.exe')) -or (Test-Path -LiteralPath (Join-Path $homeCfg 'bin\ffmpeg.exe'))
    if ($escolha['dashcam'] -and -not $ff) { $aviso = "`n`nAtencao: a dashcam precisa do ffmpeg.exe. Coloque-o na pasta do jogo ou em $homeCfg\bin (ou instale com: winget install ffmpeg)." }
    $off = @($mods | Where-Object { -not $compat[$_.id] } | ForEach-Object { $_.id })
    if ($off.Count) { $aviso += "`n`nMods bloqueados por incompatibilidade com a sua versao: " + ($off -join ', ') }
    Msg ("Instalado com sucesso.`n`nAbra o jogo normalmente.`nPara voltar ao original: Desinstalar.cmd. Para escolher outro backup: Gerenciador > Restaurar.`n`nSuas escolhas e cameras ficaram salvas em:`n$perfilDir`nExporte para outra unidade (Gerenciador > Exportar) para sobreviver a formatar o PC." + $aviso) 'openOMSI Mod Manager' 'OK' 'Information' | Out-Null
    return 0
}
try {
    $codigo = Principal
    exit $codigo
} catch {
    Log ('ERRO: ' + $_.Exception.Message)
    Msg ("Nao foi possivel concluir:`n`n" + $_.Exception.Message + "`n`nOs arquivos anteriores foram mantidos/restaurados. Detalhes: $logf") 'openOMSI Mod Manager' 'OK' 'Error' | Out-Null
    exit 1
}
