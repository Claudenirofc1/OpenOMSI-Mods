# Testes do OpenOMSI Mod Manager (instalador). Roda no Windows PowerShell 5.1 e no pwsh, em pastas
# temporarias isoladas (jogo falso + -RaizTeste). Nao toca no jogo nem nas configuracoes do usuario.
param([string]$Shell = '', [string]$Repo = '')
$ErrorActionPreference = 'Stop'
if (-not $Repo) { $Repo = Split-Path -Parent $PSScriptRoot }
if (-not $Shell) { $Shell = (Get-Process -Id $PID).Path }
$exes = @('openomsi.exe', 'openomsi-launcher.exe', 'openomsi-launcher-app.exe', 'omsi-plugin-host32.exe')
$script:ok = 0; $script:falha = 0
function Check([string]$nome, [bool]$cond, [string]$detalhe = '') {
    if ($cond) { $script:ok++; Write-Host "  ok   $nome" }
    else { $script:falha++; Write-Host "  FALHOU  $nome  $detalhe" -ForegroundColor Red }
}
function Sha256([string]$p) { (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLower() }
function Novo-Falso([string]$dir, [string]$semente) {
    New-Item -ItemType Directory -Force $dir | Out-Null
    foreach ($e in $exes) { Set-Content -LiteralPath (Join-Path $dir $e) -Value ("$semente-$e-" + ('x' * 200)) -Encoding ASCII }
}
function Gerenciador([string[]]$argumentos) {
    $out = & $Shell -NoProfile -ExecutionPolicy Bypass -File $script:ps1 @argumentos 2>&1
    $script:ultimo = $LASTEXITCODE
    $script:saida = ($out | Out-String)
    return $script:ultimo
}
$raiz = Join-Path ([IO.Path]::GetTempPath()) ('hofauto-teste-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force $raiz | Out-Null
Write-Host "Shell: $Shell`nRaiz: $raiz"

# 1) sintaxe
Write-Host '== sintaxe'
foreach ($f in (Get-ChildItem -Path (Join-Path $Repo 'installer'), (Join-Path $Repo 'tools'), (Join-Path $Repo 'tests') -Filter *.ps1)) {
    $erros = $null; $tokens = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$tokens, [ref]$erros)
    Check ("sintaxe " + $f.Name) ($erros.Count -eq 0) (($erros | ForEach-Object { $_.Message }) -join '; ')
}

# 2) ambiente: jogo "oficial" falso, pacote novo falso, manifesto real gerado pela ferramenta
$jogoOrig = Join-Path $raiz 'oficial'; Novo-Falso $jogoOrig 'oficial'
$pkExe = Join-Path $raiz 'pacote-exe'; Novo-Falso $pkExe 'mod'
$known = Join-Path $raiz 'known.json'
$kn = [ordered]@{ '0.3.54' = [ordered]@{ official = [ordered]@{} } }
foreach ($e in $exes) { $kn['0.3.54'].official[$e] = @(Sha256 (Join-Path $jogoOrig $e)) }
ConvertTo-Json -InputObject $kn -Depth 6 | Set-Content -LiteralPath $known -Encoding UTF8
$pacote = Join-Path $raiz 'pacote'
New-Item -ItemType Directory -Force $pacote | Out-Null
Copy-Item -Path (Join-Path $Repo 'installer\*') -Destination $pacote -Recurse -Force
Copy-Item -Path $pkExe -Destination (Join-Path $pacote 'exe') -Recurse -Force
& $Shell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Repo 'tools\Make-Manifest.ps1') -Tag v0.3.54 -ExeDir (Join-Path $pacote 'exe') -KnownHashes $known -Out (Join-Path $pacote 'manifest.json') -Build teste | Out-Null
Check 'manifest gerado' (Test-Path (Join-Path $pacote 'manifest.json'))
$script:ps1 = Join-Path $pacote 'Instalar-HOF-Auto.ps1'
$man = Get-Content -LiteralPath (Join-Path $pacote 'manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
Check 'manifest tem 4 modulos com compatibilidade propria' ((@($man.modules).Count -eq 4) -and (@($man.modules[0].compatible_openomsi) -contains '0.3.54'))

function Novo-Ambiente([string]$nome) {
    $r = Join-Path $raiz $nome
    $g = Join-Path $r 'jogo'; Copy-Item -Path $jogoOrig -Destination $g -Recurse -Force
    return @{ Raiz = (Join-Path $r 'teste'); Jogo = $g }
}
function Roda([hashtable]$amb, [string[]]$extra) {
    return (Gerenciador (@('-Silencioso', '-RaizTeste', $amb.Raiz, '-PastaJogo', $amb.Jogo) + $extra))
}
function Iguais([string]$dirA, [string]$dirB) {
    foreach ($e in $exes) { if ((Sha256 (Join-Path $dirA $e)) -ne (Sha256 (Join-Path $dirB $e))) { return $false } }
    return $true
}

# 3) diagnostico prova a versao sem alterar nada
Write-Host '== diagnostico'
$a = Novo-Ambiente 'diag'
$c = Roda $a @('-Modo', 'Diagnostico')
Check 'diagnostico sai 0' ($c -eq 0) $saida
$log = Join-Path $a.Raiz 'dados\instalacao.log.txt'
Check 'versao provada por hash' ((Get-Content -LiteralPath $log -Raw) -match 'PROVADA')
Check 'diagnostico nao altera o jogo' (Iguais $a.Jogo $jogoOrig)

# 4) instalacao, perfil e configuracoes pessoais
Write-Host '== instalacao'
$a = Novo-Ambiente 'inst'
$cfgDir = Join-Path $a.Raiz 'home\.openomsi'
New-Item -ItemType Directory -Force $cfgDir | Out-Null
Set-Content -LiteralPath (Join-Path $cfgDir 'door_cams.cfg') -Value 'meu|cam=minha' -Encoding ASCII
Set-Content -LiteralPath (Join-Path $cfgDir 'hofauto-mods.cfg') -Value 'dashcam=1' -Encoding ASCII
$c = Roda $a @('-Modo', 'Instalar', '-ModsEscolhidos', 'hof_auto=1,door_cams=1,dashcam=0')
Check 'instalar sai 0' ($c -eq 0) $saida
Check 'executaveis iguais ao pacote' (Iguais $a.Jogo $pkExe)
$mc = Get-Content -LiteralPath (Join-Path $cfgDir 'hofauto-mods.cfg') -Raw
Check 'escolhas gravadas' (($mc -match 'hof_auto=1') -and ($mc -match 'door_cams=1') -and ($mc -match 'dashcam=0')) $mc
Check 'config pessoal preservada' ((Get-Content -LiteralPath (Join-Path $cfgDir 'door_cams.cfg') -Raw).Trim() -eq 'meu|cam=minha')
$bks = @(Get-ChildItem -LiteralPath (Join-Path $a.Raiz 'dados\backup') -Directory)
Check 'um backup versionado criado' ($bks.Count -eq 1)
$meta = Get-Content -LiteralPath (Join-Path $bks[0].FullName 'backup.json') -Raw | ConvertFrom-Json
Check 'backup marcado como oficial' ([bool]$meta.oficial)
Check 'config antiga guardada no backup' ((Get-Content -LiteralPath (Join-Path $bks[0].FullName 'config\hofauto-mods.cfg') -Raw).Trim() -eq 'dashcam=1')
Check 'estado.json gravado' (Test-Path (Join-Path $a.Raiz 'dados\estado.json'))
Check 'perfil salvo em Documentos' (Test-Path (Join-Path $a.Raiz 'docs\perfil\hofauto-mods.cfg'))
Check 'pendente removido' (-not (Test-Path (Join-Path $a.Raiz 'dados\pendente.txt')))

# 5) segunda instalacao/reparo e diagnostico depois de instalado
$c = Roda $a @('-Modo', 'Reparar')
Check 'reparar sem problemas sai 0 e nao muda nada' (($c -eq 0) -and (Iguais $a.Jogo $pkExe))
$c = Roda $a @('-Modo', 'Instalar', '-ModsEscolhidos', 'dashcam=1')
Check 'reinstalar sai 0 (versao provada pelo estado/pacote)' ($c -eq 0) $saida
$bks = @(Get-ChildItem -LiteralPath (Join-Path $a.Raiz 'dados\backup') -Directory | Sort-Object Name)
Check 'segundo backup criado (nunca apaga os antigos)' ($bks.Count -eq 2)

# 6) restauracao selecionavel
Write-Host '== restauracao'
$primeiro = $bks[0].Name
$c = Roda $a @('-Modo', 'Restaurar', '-Backup', $primeiro)
Check 'restaurar backup escolhido sai 0' ($c -eq 0) $saida
Check 'arquivos oficiais de volta' (Iguais $a.Jogo $jogoOrig)
Check 'config do backup restaurada' ((Get-Content -LiteralPath (Join-Path $cfgDir 'hofauto-mods.cfg') -Raw).Trim() -eq 'dashcam=1')
Check 'config anterior guardada (.antes)' (@(Get-ChildItem -LiteralPath $cfgDir -Filter 'hofauto-mods.cfg.antes-*').Count -ge 1)
Check 'backups so aumentam' (@(Get-ChildItem -LiteralPath (Join-Path $a.Raiz 'dados\backup') -Directory).Count -ge 3)
$c = Roda $a @('-Modo', 'Restaurar', '-Backup', 'nao-existe')
Check 'backup inexistente e recusado' ($c -eq 1)

# 7) desinstalar volta aos oficiais
$c = Roda $a @('-Modo', 'Instalar')
Check 'instala de novo' (($c -eq 0) -and (Iguais $a.Jogo $pkExe))
$c = Roda $a @('-Desinstalar')
Check 'desinstalar sai 0' ($c -eq 0) $saida
Check 'desinstalar devolve os oficiais' (Iguais $a.Jogo $jogoOrig)
Check 'door_cams.cfg pessoal continua la' (Test-Path (Join-Path $cfgDir 'door_cams.cfg'))

# 8) compatibilidade: jogo desconhecido bloqueia, sem confirmacao manual possivel
Write-Host '== compatibilidade'
$a = Novo-Ambiente 'desc'
Add-Content -LiteralPath (Join-Path $a.Jogo 'openomsi.exe') -Value 'atualizacao-oficial-nova'
$antes = Sha256 (Join-Path $a.Jogo 'openomsi.exe')
$c = Roda $a @('-Modo', 'Instalar')
Check 'versao nao provada: instalacao bloqueada (sai 1)' ($c -eq 1) $saida
Check 'nada foi alterado' ((Sha256 (Join-Path $a.Jogo 'openomsi.exe')) -eq $antes)
Check 'nao cria backup nem pendencia' (-not (Test-Path (Join-Path $a.Raiz 'dados\pendente.txt')))
$c = Roda $a @('-Modo', 'Reparar')
Check 'reparar tambem bloqueia' ($c -eq 1)
$c = Roda $a @('-Modo', 'Atualizar')
Check 'atualizar bloqueia (versao nao provada)' ($c -eq 1)

# pacote adulterado
$a = Novo-Ambiente 'adult'
$pkAdult = Join-Path $raiz 'pacote-adulterado'
Copy-Item -Path $pacote -Destination $pkAdult -Recurse -Force
Add-Content -LiteralPath (Join-Path $pkAdult 'exe\openomsi.exe') -Value 'lixo'
$ps1Real = $script:ps1; $script:ps1 = Join-Path $pkAdult 'Instalar-HOF-Auto.ps1'
$c = Roda $a @('-Modo', 'Instalar')
Check 'hash do pacote nao confere: recusa' (($c -eq 1) -and (Iguais $a.Jogo $jogoOrig))
$script:ps1 = $ps1Real

# modulo individual incompativel: so ele fica desligado
$a = Novo-Ambiente 'modinc'
$pkMod = Join-Path $raiz 'pacote-modinc'
Copy-Item -Path $pacote -Destination $pkMod -Recurse -Force
$mj = Get-Content -LiteralPath (Join-Path $pkMod 'manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($m in $mj.modules) { if ($m.id -eq 'dashcam') { $m.compatible_openomsi = @('0.9.9') } }
ConvertTo-Json -InputObject $mj -Depth 10 | Set-Content -LiteralPath (Join-Path $pkMod 'manifest.json') -Encoding UTF8
$script:ps1 = Join-Path $pkMod 'Instalar-HOF-Auto.ps1'
$c = Roda $a @('-Modo', 'Instalar', '-ModsEscolhidos', 'hof_auto=1,door_cams=1,dashcam=1')
$mc = Get-Content -LiteralPath (Join-Path $a.Raiz 'home\.openomsi\hofauto-mods.cfg') -Raw
Check 'modulo incompativel desligado, os outros ligados' (($c -eq 0) -and ($mc -match 'dashcam=0') -and ($mc -match 'hof_auto=1') -and ($mc -match 'door_cams=1')) $mc
# dependencia de modulo: door_cams exige hof_auto (inventado) -> ambos ficam desligados se hof_auto incompativel
$a = Novo-Ambiente 'dep'
$pkDep = Join-Path $raiz 'pacote-dep'
Copy-Item -Path $pacote -Destination $pkDep -Recurse -Force
$mj = Get-Content -LiteralPath (Join-Path $pkDep 'manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($m in $mj.modules) {
    if ($m.id -eq 'hof_auto') { $m.compatible_openomsi = @('0.9.9') }
    if ($m.id -eq 'door_cams') { $m.requires = @('hof_auto') }
}
ConvertTo-Json -InputObject $mj -Depth 10 | Set-Content -LiteralPath (Join-Path $pkDep 'manifest.json') -Encoding UTF8
$script:ps1 = Join-Path $pkDep 'Instalar-HOF-Auto.ps1'
$c = Roda $a @('-Modo', 'Instalar')
$mc = Get-Content -LiteralPath (Join-Path $a.Raiz 'home\.openomsi\hofauto-mods.cfg') -Raw
Check 'dependencia de modulo respeitada' (($c -eq 0) -and ($mc -match 'hof_auto=0') -and ($mc -match 'door_cams=0') -and ($mc -match 'dashcam=1')) $mc
$script:ps1 = $ps1Real

# 9) interrupcao no meio da instalacao + recuperacao
Write-Host '== interrupcao'
$a = Novo-Ambiente 'queda'
$c = Roda $a @('-Modo', 'Instalar', '-SimularQueda', '2')
Check 'queda simulada (codigo 99)' ($c -eq 99) $saida
Check 'jogo ficou misturado (2 arquivos novos)' (-not (Iguais $a.Jogo $jogoOrig) -and -not (Iguais $a.Jogo $pkExe))
Check 'pendencia registrada' (Test-Path (Join-Path $a.Raiz 'dados\pendente.txt'))
$c = Roda $a @('-Modo', 'Diagnostico')
Check 'proxima execucao recupera (sai 1 avisando)' ($c -eq 1) $saida
Check 'arquivos anteriores devolvidos' (Iguais $a.Jogo $jogoOrig)
Check 'pendencia limpa' (-not (Test-Path (Join-Path $a.Raiz 'dados\pendente.txt')))
$c = Roda $a @('-Modo', 'Instalar')
Check 'depois da recuperacao instala normalmente' (($c -eq 0) -and (Iguais $a.Jogo $pkExe))

# 10) exportar / importar perfil
Write-Host '== perfil'
$a = Novo-Ambiente 'perfil'
$cfgDir = Join-Path $a.Raiz 'home\.openomsi'
New-Item -ItemType Directory -Force $cfgDir | Out-Null
Set-Content -LiteralPath (Join-Path $cfgDir 'dashcam.cfg') -Value 'bus|cam=1,2,3' -Encoding ASCII
Set-Content -LiteralPath (Join-Path $cfgDir 'door_cams.cfg') -Value 'bus|on=1' -Encoding ASCII
$c = Roda $a @('-Modo', 'Instalar')
$usb = Join-Path $raiz 'pendrive'; New-Item -ItemType Directory -Force $usb | Out-Null
$c = Roda $a @('-Modo', 'Exportar', '-PastaDestino', $usb)
$exp = @(Get-ChildItem -LiteralPath $usb -Directory)
Check 'exportar cria pasta de backup' (($c -eq 0) -and ($exp.Count -eq 1) -and (Test-Path (Join-Path $exp[0].FullName 'dashcam.cfg')))
# "PC formatado": ambiente novo, sem nada
$b = Novo-Ambiente 'formatado'
$c = Roda $b @('-Modo', 'Importar', '-PastaOrigem', $exp[0].FullName)
$cfgB = Join-Path $b.Raiz 'home\.openomsi'
Check 'importar recoloca as configuracoes' (($c -eq 0) -and ((Get-Content -LiteralPath (Join-Path $cfgB 'dashcam.cfg') -Raw).Trim() -eq 'bus|cam=1,2,3') -and (Test-Path (Join-Path $cfgB 'door_cams.cfg')))

# 11) atualizar com rede real: nao pode quebrar nem alterar o jogo
Write-Host '== atualizar (rede real do GitHub)'
$a = Novo-Ambiente 'atual'
$c = Roda $a @('-Modo', 'Instalar')
$c = Roda $a @('-Modo', 'Atualizar')
Check 'atualizar termina sem excecao (0 ou 1)' (($c -eq 0) -or ($c -eq 1)) $saida
Check 'jogo continua integro (pacote ou oficial)' ((Iguais $a.Jogo $pkExe) -or (Iguais $a.Jogo $jogoOrig))

Write-Host ("`nRESULTADO ($Shell): {0} ok, {1} falhas" -f $script:ok, $script:falha)
Remove-Item -LiteralPath $raiz -Recurse -Force -ErrorAction SilentlyContinue
if ($script:falha -gt 0) { exit 1 }
exit 0
