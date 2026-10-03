# MelonLoader 0.7 reinstall patch for Last Epoch 1.5.1.
# net6 rejects an assembly that contains more than one nested type named <>O.
# MelonLoader.Installer regenerates Il2CppAssemblies and drops the rename.
#
# Known unpatched hashes are the 2026-10-03 generation for GameAssembly SHA512
# 526F4AFA67253B22A11FC0A55236EFE5F6211E57AA4E9999B6FB0E7A298DF5E6843A70CF642F691971D00156FE833437156464EDA4E76919FBA36D67FF23A1D4.
# When the generated file matches, this script copies the patched DLL from the kit.
# When the game build differs, it renames <>O in the generated file instead.
# Save.json and QuadStashs are not touched.

param(
    [string]$GamePath = 'E:\SteamLibrary\steamapps\common\Last Epoch'
)

$ErrorActionPreference = 'Stop'
$kit = Split-Path -Parent $MyInvocation.MyCommand.Path

function Get-Sha256([string]$Path) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $hash = $sha.ComputeHash($stream)
    } finally {
        $stream.Dispose()
        $sha.Dispose()
    }
    return ([System.BitConverter]::ToString($hash) -replace '-', '')
}

$unpatched = @{
    'UnityEngine.CoreModule.dll' = 'A1EA1ABBA940968F833D0F200D47BD107A72D20D1BAAF470468ABF2627422890'
    'UnityEngine.UIElementsModule.dll' = 'CA295ED959D7DC66246F9E0F2D045850FF914FA592D736831F1CAF7171E55D3E'
}

if (Get-Process -Name 'Last Epoch' -ErrorAction SilentlyContinue) {
    Write-Output '게임이 실행 중입니다. 종료한 뒤 이 패치를 다시 실행하세요.'
    exit 3
}

$exe = Join-Path $GamePath 'Last Epoch.exe'
if (-not (Test-Path -LiteralPath $exe)) {
    Write-Output "Last Epoch.exe 를 찾지 못했습니다: $exe"
    exit 1
}

$modFiles = @(
    'LastEpoch_Hud.dll',
    'LastEpoch_Hud\Assets\lastepochmods',
    'LastEpoch_Hud\Locales\base.json',
    'LastEpoch_Hud\Locales\en.json',
    'LastEpoch_Hud\Locales\fr.json',
    'LastEpoch_Hud\Locales\zh.json'
)
foreach ($rel in $modFiles) {
    $src = Join-Path $kit (Join-Path 'Mods' $rel)
    $dest = Join-Path $GamePath (Join-Path 'Mods' $rel)
    if (-not (Test-Path -LiteralPath $src)) {
        Write-Output "키트에 파일이 없습니다: $rel"
        exit 4
    }
    $destDir = Split-Path -Parent $dest
    if (-not (Test-Path -LiteralPath $destDir)) {
        [System.IO.Directory]::CreateDirectory($destDir) | Out-Null
    }
    $same = $false
    if (Test-Path -LiteralPath $dest) {
        $same = (Get-Sha256 $src) -eq (Get-Sha256 $dest)
    }
    if ($same) {
        Write-Output "모드 그대로: $rel"
    } else {
        [System.IO.File]::Copy($src, $dest, $true)
        Write-Output "모드 덮어씀: $rel"
    }
}

$asmDir = Join-Path $GamePath 'MelonLoader\Il2CppAssemblies'
$core = Join-Path $asmDir 'UnityEngine.CoreModule.dll'
if (-not (Test-Path -LiteralPath $core)) {
    Write-Output 'Il2Cpp 어셈블리가 아직 없습니다.'
    Write-Output '게임을 한 번 실행해 생성이 끝난 뒤 종료하고, 이 패치를 다시 실행하세요.'
    exit 2
}

foreach ($name in @($unpatched.Keys)) {
    $dest = Join-Path $asmDir $name
    $src = Join-Path $kit (Join-Path 'MelonLoader\Il2CppAssemblies' $name)
    if (-not (Test-Path -LiteralPath $dest)) {
        Write-Output "생성본 없음, 덮어쓰기 생략: $name"
        continue
    }
    $destHash = Get-Sha256 $dest
    $srcHash = Get-Sha256 $src
    if ($destHash -eq $srcHash) {
        Write-Output "이미 패치됨: $name"
        continue
    }
    if ($destHash -eq $unpatched[$name]) {
        $bak = "$dest.bak"
        if (-not (Test-Path -LiteralPath $bak)) {
            [System.IO.File]::Copy($dest, $bak, $false)
        }
        [System.IO.File]::Copy($src, $dest, $true)
        Write-Output "키트 파일로 덮어씀: $name"
    } else {
        Write-Output "이번 생성본은 키트와 다릅니다. 그 자리에서 이름을 바꿉니다: $name"
    }
}

$cecil = Join-Path $GamePath 'MelonLoader\net6\Mono.Cecil.dll'
if (-not (Test-Path -LiteralPath $cecil)) {
    Write-Output "Mono.Cecil.dll 을 찾지 못했습니다: $cecil"
    exit 4
}
Add-Type -Path $cecil

function Get-AngleOTypes([Mono.Cecil.AssemblyDefinition]$asm) {
    $found = New-Object System.Collections.Generic.List[Mono.Cecil.TypeDefinition]
    $stack = New-Object System.Collections.Generic.Stack[Mono.Cecil.TypeDefinition]
    foreach ($t in $asm.MainModule.Types) { $stack.Push($t) }
    while ($stack.Count -gt 0) {
        $t = $stack.Pop()
        if ($t.Name -eq '<>O') { $found.Add($t) }
        foreach ($c in $t.NestedTypes) { $stack.Push($c) }
    }
    return $found
}

$renamed = 0
Get-ChildItem -LiteralPath $asmDir -Filter *.dll | ForEach-Object {
    $resolver = New-Object Mono.Cecil.DefaultAssemblyResolver
    $resolver.AddSearchDirectory($asmDir)
    $rp = New-Object Mono.Cecil.ReaderParameters
    $rp.AssemblyResolver = $resolver
    $asm = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($_.FullName, $rp)
    $found = @(Get-AngleOTypes $asm)
    if ($found.Count -le 1) {
        $asm.Dispose()
        return
    }
    $i = 0
    foreach ($t in $found) {
        $i++
        $t.Name = "<>O_$i"
    }
    $bak = "$($_.FullName).bak"
    if (-not (Test-Path -LiteralPath $bak)) {
        [System.IO.File]::Copy($_.FullName, $bak, $false)
    }
    $tmp = "$($_.FullName).tmp"
    $asm.Write($tmp)
    $asm.Dispose()
    [System.IO.File]::Copy($tmp, $_.FullName, $true)
    [System.IO.File]::Delete($tmp)
    $script:renamed++
    Write-Output ("이름 변경: {0} {1}개" -f $_.Name, $found.Count)
}
if ($renamed -eq 0) {
    Write-Output '<>O 가 둘 이상인 어셈블리는 없습니다.'
}

foreach ($name in @('UnityEngine.CoreModule.dll', 'UnityEngine.UIElementsModule.dll')) {
    $dest = Join-Path $asmDir $name
    try {
        $loaded = [System.Reflection.Assembly]::LoadFrom($dest)
        Write-Output ("로드됨: {0}" -f $loaded.GetName().Name)
    } catch {
        $msg = $_.Exception.InnerException
        if (-not $msg) { $msg = $_.Exception }
        Write-Output ("로드 실패: {0}: {1}" -f $name, $msg.Message)
        exit 4
    }
}

Write-Output '패치가 끝났습니다. 게임을 다시 실행하세요.'
exit 0
