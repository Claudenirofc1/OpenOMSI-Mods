<#
 Instalador simples do openOMSI HOF Auto (projeto independente, NAO oficial).
 Troca SOMENTE 4 executaveis da pasta do jogo; faz backup dos originais antes e confere cada arquivo.
 NAO mexe em mapas, onibus, HOFs, configuracoes, OMSI 2 ou outros mods.
 -Desinstalar: devolve os originais do backup mais recente.
 -Modo Menu|Instalar|Atualizar|Reparar|Diagnostico|Exportar|Importar: OpenOMSI Mod Manager (ver README).
#>
param([switch]$Desinstalar, [switch]$SoPerfil, [ValidateSet('Menu','Instalar','Atualizar','Reparar','Diagnostico','Exportar','Importar')][string]$Modo = 'Instalar')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$publicadoNovo = ''
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

# ---- Mod Manager: manifesto, versao do jogo, estado, diagnostico ------------------------------
$repoGh = 'Claudenirofc1/openOMSI-HOF-Auto'
$estadoF = Join-Path $dadosDir 'estado.json'
$pendF = Join-Path $dadosDir 'pendente.txt'
function Ler-Manifesto([string]$pasta) {
    $f = Join-Path $pasta 'manifest.json'
    if (-not (Test-Path -LiteralPath $f)) { return $null }
    try { return (Get-Content -LiteralPath $f -Raw -Encoding UTF8 | ConvertFrom-Json) } catch { return $null }
}
function Versao-Jogo([string]$dest) {
    # Versao do openomsi.exe (so numeros, ex.: 0.3.54). Vazio = nao consegui ler.
    try {
        $e = Join-Path $dest 'openomsi.exe'
        if (-not (Test-Path -LiteralPath $e)) { return '' }
        $v = (Get-Item -LiteralPath $e).VersionInfo.ProductVersion
        if ($v -match '(\d+\.\d+\.\d+)') { return $Matches[1] }
    } catch { }
    return ''
}
function Estado-Ler {
    if (Test-Path -LiteralPath $estadoF) { try { return (Get-Content -LiteralPath $estadoF -Raw -Encoding UTF8 | ConvertFrom-Json) } catch { } }
    return $null
}
function Estado-Gravar($dest, $manifesto, [string]$publicado) {
    $o = [ordered]@{
        pasta_do_jogo = $dest
        pacote = $manifesto.package
        base_openomsi = $manifesto.base
        gerenciador = $manifesto.manager
        publicado_em = $publicado
        instalado_em = (Get-Date -Format s)
        modulos = @($manifesto.modules | ForEach-Object { $_.id + '@' + $_.version })
        arquivos = $manifesto.files
    }
    ($o | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $estadoF -Encoding UTF8
}
function Pasta-Do-Jogo {
    $st = Estado-Ler
    if ($st -and $st.pasta_do_jogo -and (Test-Path -LiteralPath (Join-Path $st.pasta_do_jogo 'openomsi.exe'))) { return [string]$st.pasta_do_jogo }
    return (Escolher-Pasta)
}
function Compativel($manifesto, [string]$versaoJogo) {
    # $true / $false / $null (nao sei: versao ilegivel)
    if (-not $manifesto) { return $false }
    if (-not $versaoJogo) { return $null }
    return (@($manifesto.compatible_openomsi) -contains $versaoJogo)
}
function Diagnosticar([string]$dest, $manifesto) {
    $linhas = New-Object System.Collections.ArrayList
    $problemas = New-Object System.Collections.ArrayList
    $vj = Versao-Jogo $dest
    [void]$linhas.Add("Pasta do jogo: $dest")
    [void]$linhas.Add("Versao do jogo (openomsi.exe): " + $(if ($vj) { $vj } else { 'nao consegui ler' }))
    if ($manifesto) {
        [void]$linhas.Add("Pacote: $($manifesto.package) (base openOMSI $($manifesto.base))")
        $c = Compativel $manifesto $vj
        if ($c -eq $false) { [void]$problemas.Add("A versao do jogo ($vj) NAO e a que este pacote suporta ($(@($manifesto.compatible_openomsi) -join ', ')). Nao instale: espere a release dessa versao."); }
        elseif ($null -eq $c) { [void]$problemas.Add('Nao consegui ler a versao do jogo; so instale se tiver certeza de que e a versao do pacote.') }
        foreach ($e in $exes) {
            $o = Join-Path $dest $e
            $esp = $manifesto.files.$e
            if (-not (Test-Path -LiteralPath $o)) { [void]$problemas.Add("Ausente no jogo: $e"); continue }
            if ($esp -and ((Hash $o) -ne $esp)) { [void]$problemas.Add("$e nao e o do pacote (jogo oficial/atualizado ou arquivo alterado)") }
        }
    } else { [void]$problemas.Add('manifest.json nao encontrado ao lado do instalador (pacote incompleto: extraia o ZIP inteiro).') }
    $st = Estado-Ler
    [void]$linhas.Add("Instalado antes: " + $(if ($st) { "$($st.pacote) em $($st.instalado_em)" } else { 'nao ha registro' }))
    $m = Ler-Mods
    foreach ($x in $mods) { [void]$linhas.Add(("Mod {0}: {1}" -f $x.id, $(if ($m[$x.id]) { 'ligado' } else { 'desligado' }))) }
    $bks = @(Get-ChildItem -LiteralPath $bkRaiz -Directory -ErrorAction SilentlyContinue)
    [void]$linhas.Add("Backups: $($bks.Count) em $bkRaiz")
    [void]$linhas.Add("Perfil salvo: " + $(if (Test-Path -LiteralPath $perfilDir) { $perfilDir } else { 'ainda nao' }))
    $ff = (Get-Command ffmpeg -ErrorAction SilentlyContinue) -or (Test-Path -LiteralPath (Join-Path $dest 'ffmpeg.exe')) -or (Test-Path -LiteralPath (Join-Path $homeCfg 'bin\ffmpeg.exe'))
    [void]$linhas.Add("ffmpeg (dashcam): " + $(if ($ff) { 'encontrado' } else { 'NAO encontrado' }))
    return [pscustomobject]@{ Linhas = $linhas; Problemas = $problemas }
}
function Mostrar-Diag($d) {
    $t = ($d.Linhas -join "`n")
    if ($d.Problemas.Count) { $t += "`n`nProblemas:`n- " + ($d.Problemas -join "`n- ") } else { $t += "`n`nNenhum problema encontrado." }
    Log ("diagnostico: " + ($d.Problemas -join ' | '))
    return $t
}
function Restaurar-Backup([string]$bkDir, [string]$dest) {
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
function Baixar-Atualizacao([string]$versaoBase, $atual) {
    # Consulta SOMENTE as releases deste repositorio no GitHub (https), baixa o ZIP, confere hashes do manifesto.
    $api = "https://api.github.com/repos/$repoGh/releases"
    $rels = Invoke-RestMethod -Uri $api -Headers @{ 'User-Agent' = 'openOMSI-Mod-Manager' } -TimeoutSec 30
    $tag = "v$versaoBase-hofauto"
    $rel = $rels | Where-Object { $_.tag_name -eq $tag } | Select-Object -First 1
    if (-not $rel) { return @{ Estado = 'sem-release'; Tag = $tag } }
    $asset = $rel.assets | Where-Object { $_.name -like '*.zip' } | Select-Object -First 1
    if (-not $asset) { return @{ Estado = 'sem-release'; Tag = $tag } }
    if ($atual -and $atual.publicado_em -and ([string]$asset.updated_at -eq [string]$atual.publicado_em)) { return @{ Estado = 'em-dia'; Tag = $tag } }
    if (-not $asset.browser_download_url.StartsWith("https://github.com/$repoGh/", [StringComparison]::OrdinalIgnoreCase)) { throw 'URL de download fora do repositorio oficial do projeto; recusado.' }
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
    $f.ClientSize = New-Object System.Drawing.Size(360, 330)
    $itens = @(@('Instalar', 'Instalar / escolher mods'), @('Atualizar', 'Atualizar (consulta o GitHub)'), @('Reparar', 'Reparar (diagnostico + autorizacao)'), @('Diagnostico', 'Diagnostico'), @('Exportar', 'Exportar perfil (backup recuperavel)'), @('Importar', 'Importar perfil'))
    $y = 14
    $script:escolhaMenu = $null
    foreach ($i in $itens) {
        $b = New-Object System.Windows.Forms.Button
        $b.Text = $i[1]; $b.Tag = $i[0]
        $b.Location = New-Object System.Drawing.Point(30, $y); $b.Size = New-Object System.Drawing.Size(300, 34)
        $b.Add_Click({ $script:escolhaMenu = $this.Tag; $this.FindForm().Close() })
        $f.Controls.Add($b); $y += 42
    }
    $f.ShowDialog() | Out-Null
    return $script:escolhaMenu
}
function Escolher-Pasta-Backup([string]$descricao) {
    $d = New-Object System.Windows.Forms.FolderBrowserDialog
    $d.Description = $descricao
    if ($d.ShowDialog() -ne 'OK') { return $null }
    return $d.SelectedPath
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
    # Instalacao interrompida antes? Volta ao backup dela antes de qualquer coisa.
    if (Test-Path -LiteralPath $pendF) {
        $linhas = Get-Content -LiteralPath $pendF -Encoding UTF8
        $bkp = $linhas[0]; $dp = $linhas[1]
        if ($bkp -and $dp -and (Test-Path -LiteralPath $bkp) -and -not (Abertos $dp)) {
            Restaurar-Backup $bkp $dp
            Log "recuperada instalacao interrompida"
            Msg "Uma instalacao anterior foi interrompida. Os arquivos originais foram devolvidos.`nRode o instalador de novo." 'openOMSI HOF Auto' 'OK' 'Warning' | Out-Null
        }
        Remove-Item -LiteralPath $pendF -Force -ErrorAction SilentlyContinue
        exit 1
    }
    if ($Modo -eq 'Menu') { $Modo = Menu-Gerenciador; if (-not $Modo) { exit 0 } }
    if ($Modo -eq 'Diagnostico') {
        $dp = Pasta-Do-Jogo; if (-not $dp) { exit 1 }
        Msg (Mostrar-Diag (Diagnosticar $dp (Ler-Manifesto $aqui))) 'Diagnostico' 'OK' 'Information' | Out-Null
        exit 0
    }
    if ($Modo -eq 'Exportar') {
        Salvar-Perfil
        $alvo = Escolher-Pasta-Backup 'Escolha onde guardar o backup do perfil (de preferencia outra unidade ou pendrive).'
        if (-not $alvo) { exit 1 }
        $sub = Join-Path $alvo ('openOMSI-HOF-Auto-perfil-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
        New-Item -ItemType Directory -Force $sub | Out-Null
        Copy-Item -Path (Join-Path $perfilDir '*') -Destination $sub -Force
        if (Test-Path -LiteralPath $estadoF) { Copy-Item -LiteralPath $estadoF -Destination $sub -Force }
        Log "perfil exportado para $sub"
        Msg "Backup do perfil criado em:`n$sub`n`nPara recuperar depois: Modo Importar (ou Gerenciador.cmd > Importar perfil)." 'openOMSI HOF Auto' 'OK' 'Information' | Out-Null
        exit 0
    }
    if ($Modo -eq 'Importar') {
        $orig = Escolher-Pasta-Backup 'Escolha a pasta do backup do perfil (openOMSI-HOF-Auto-perfil-...).'
        if (-not $orig) { exit 1 }
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
        $h = Join-Path $homeCfg 'hofauto-mods.cfg'
        Log "perfil importado ($n arquivos)"
        Msg "Perfil importado ($n arquivos) para:`n$perfilDir`n(copias anteriores mantidas com .antes-...)`nAgora rode Instalar: ele coloca o perfil no lugar sem sobrescrever o que ja existir." 'openOMSI HOF Auto' 'OK' 'Information' | Out-Null
        exit 0
    }
    if ($Modo -eq 'Atualizar' -and -not $SoPerfil -and -not $Desinstalar) {
        $dp = Pasta-Do-Jogo; if (-not $dp) { exit 1 }
        $vj = Versao-Jogo $dp
        if (-not $vj) { Msg 'Nao consegui ler a versao do jogo; atualizacao automatica recusada.' 'openOMSI HOF Auto' 'OK' 'Warning' | Out-Null; exit 1 }
        try { $r = Baixar-Atualizacao $vj (Estado-Ler) } catch { Msg ("Sem conexao ou GitHub indisponivel:`n" + $_.Exception.Message + "`n`nAs operacoes locais (instalar, reparar, restaurar) funcionam offline.") 'openOMSI HOF Auto' 'OK' 'Warning' | Out-Null; exit 1 }
        if ($r.Estado -eq 'sem-release') { Msg "Ainda nao existe release deste projeto para a versao $vj do jogo ($($r.Tag)).`nNao instale outra versao: espere ou use o jogo oficial." 'openOMSI HOF Auto' 'OK' 'Warning' | Out-Null; exit 1 }
        if ($r.Estado -eq 'em-dia') { Msg 'Voce ja esta com a versao mais recente.' 'openOMSI HOF Auto' 'OK' 'Information' | Out-Null; exit 0 }
        $aqui = $r.Pasta; $novos = Join-Path $aqui 'exe'; $publicadoNovo = $r.Publicado
        $Modo = 'Instalar'
    }
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
    $manifesto = Ler-Manifesto $aqui
    if (-not $manifesto) { throw 'manifest.json nao encontrado: pacote incompleto. Extraia o ZIP inteiro (ou baixe de novo).' }
    foreach ($e in $exes) {
        $esp = $manifesto.files.$e
        if (-not $esp -or ((Hash (Join-Path $novos $e)) -ne $esp)) { throw "O arquivo $e do pacote nao confere com o manifesto (download corrompido?). Nada foi alterado." }
    }
    $dest = Pasta-Do-Jogo
    if (-not $dest) { exit 1 }
    $diag = Diagnosticar $dest $manifesto
    $vj = Versao-Jogo $dest
    $comp = Compativel $manifesto $vj
    if ($comp -eq $false) { Msg ((Mostrar-Diag $diag) + "`n`nInstalacao recusada: versao incompativel. Nada foi alterado.") 'openOMSI HOF Auto' 'OK' 'Error' | Out-Null; exit 1 }
    if ($null -eq $comp) {
        $r0 = Msg "Nao consegui ler a versao do jogo em:`n$dest`n`nO pacote e para o openOMSI $($manifesto.base). Continuar mesmo assim?" 'openOMSI HOF Auto' 'YesNo' 'Warning'
        if ($r0 -ne 'Yes') { exit 1 }
    }
    if ($Modo -eq 'Reparar') {
        if (-not $diag.Problemas.Count) { Msg (Mostrar-Diag $diag) 'Nada a reparar' 'OK' 'Information' | Out-Null; exit 0 }
        $r1 = Msg ((Mostrar-Diag $diag) + "`n`nProposta: reinstalar os 4 executaveis do pacote (com backup) e reaplicar suas escolhas.`n`nAutoriza?") 'Reparar' 'YesNo' 'Question'
        if ($r1 -ne 'Yes') { exit 1 }
    }
    if (Abertos $dest) { Msg 'Feche o jogo e o launcher do openOMSI e rode o instalador de novo.' 'openOMSI HOF Auto' 'OK' 'Warning' | Out-Null; exit 1 }
    $restaurados = Restaurar-Perfil
    $escolha = Perguntar-Mods
    if ($null -eq $escolha) { exit 1 }
    $r = Msg "Instalar o openOMSI HOF Auto $versao em:`n$dest`n`nOs 4 executaveis originais serao guardados em backup. Mapas, onibus e configuracoes nao sao alterados.`n`nContinuar?" 'openOMSI HOF Auto' 'YesNo' 'Question'
    if ($r -ne 'Yes') { exit 1 }
    $bk = Join-Path $bkRaiz (Get-Date -Format 'yyyyMMdd-HHmmss')
    New-Item -ItemType Directory -Force $bk | Out-Null
    Set-Content -LiteralPath $pendF -Value @($bk, $dest) -Encoding UTF8
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
        Remove-Item -LiteralPath $pendF -Force -ErrorAction SilentlyContinue
        throw
    }
    Gravar-Mods $escolha
    Estado-Gravar $dest $manifesto $publicadoNovo
    Remove-Item -LiteralPath $pendF -Force -ErrorAction SilentlyContinue
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
