# Gera o manifest.json do pacote (usado pela release e pelos testes).
param(
    [Parameter(Mandatory)][string]$Tag,
    [Parameter(Mandatory)][string]$ExeDir,
    [Parameter(Mandatory)][string]$KnownHashes,
    [Parameter(Mandatory)][string]$Out,
    [string]$Build = '',
    [string]$OfficialDir = '',
    [string]$SourceRoot = ''
)
$ErrorActionPreference = 'Stop'
$exes = @('openomsi.exe', 'openomsi-launcher.exe', 'openomsi-launcher-app.exe', 'omsi-plugin-host32.exe')
$base = $Tag.TrimStart('v')
function Sha256([string]$p) { (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLower() }
$files = [ordered]@{}
foreach ($e in $exes) { $files[$e] = Sha256 (Join-Path $ExeDir $e) }
$known = Get-Content -LiteralPath $KnownHashes -Raw -Encoding UTF8 | ConvertFrom-Json
$official = [ordered]@{}
$proven = [ordered]@{}
function Add-Hash($tabela, [string]$v, [string]$e, [string]$h) {
    if (-not $tabela.Contains($v)) { $tabela[$v] = [ordered]@{} }
    $atual = @()
    if ($tabela[$v].Contains($e)) { $atual = @($tabela[$v][$e]) }
    if ($atual -notcontains $h) { $atual += $h }
    $tabela[$v][$e] = @($atual)
}
foreach ($v in ($known.PSObject.Properties.Name | Where-Object { -not $_.StartsWith('_') })) {
    foreach ($tipo in @('official', 'local')) {
        $bloco = $known.$v.PSObject.Properties[$tipo]
        if ($null -eq $bloco) { continue }
        foreach ($e in $exes) {
            $p = $bloco.Value.PSObject.Properties[$e]
            if ($null -eq $p) { continue }
            foreach ($h in @($p.Value)) {
                Add-Hash $proven $v $e ([string]$h).ToLower()
                if ($tipo -eq 'official') { Add-Hash $official $v $e ([string]$h).ToLower() }
            }
        }
    }
}
if ($OfficialDir -and (Test-Path -LiteralPath $OfficialDir)) {
    foreach ($e in $exes) {
        $f = Get-ChildItem -LiteralPath $OfficialDir -Recurse -Filter $e -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($f) { $h = Sha256 $f.FullName; Add-Hash $proven $base $e $h; Add-Hash $official $base $e $h }
    }
}
foreach ($e in $exes) { Add-Hash $proven $base $e $files[$e] }
function Src([string[]]$rel) {
    $r = [ordered]@{}
    if (-not $SourceRoot) { return $r }
    foreach ($x in $rel) { $f = Join-Path $SourceRoot $x; if (Test-Path -LiteralPath $f) { $r[$x] = Sha256 $f } }
    return $r
}
$modules = @(
    [ordered]@{ id = 'hof_auto';  name = 'HOF automatico';      version = '1.0.0'; requires = @();          compatible_openomsi = @($base); source_sha256 = (Src @('crates/omsi-launcher-core/src/hof_auto.rs')) },
    [ordered]@{ id = 'door_cams'; name = 'Cameras das portas';  version = '0.1.0'; requires = @();          compatible_openomsi = @($base); source_sha256 = (Src @('crates/omsi-app/src/door_cams.rs')) },
    [ordered]@{ id = 'dashcam';   name = 'Dashcam (MP4)';       version = '0.1.0'; requires = @('ffmpeg');  compatible_openomsi = @($base); source_sha256 = (Src @('crates/omsi-app/src/dashcam.rs')) },
    [ordered]@{ id = 'ai_unstick'; name = 'IAs travadas'; version = '0.1.0'; requires = @(); compatible_openomsi = @($base); source_sha256 = (Src @('crates/omsi-sim/src/ai_traffic/unstick.rs')) }
)
$man = [ordered]@{
    manager = '1.2.0'
    package = "$Tag-hofauto"
    base = $base
    compatible_openomsi = @($base)
    build = $Build
    modules = $modules
    files = $files
    official = $official
    proven = $proven
    update = 'Gerenciador.cmd > Atualizar (consulta as releases deste repositorio)'
    restore = 'Gerenciador.cmd > Restaurar (escolhe a versao do backup) ou Desinstalar.cmd (volta aos oficiais)'
}
ConvertTo-Json -InputObject $man -Depth 8 | Set-Content -LiteralPath $Out -Encoding UTF8
Write-Host "manifest escrito: $Out"
