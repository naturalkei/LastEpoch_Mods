# MelonLoader 0.7.x runs on net6. That runtime rejects an assembly that contains
# more than one nested type named <>O, even when each one has a different parent.
# Il2CppAssemblyGenerator writes those empty types into UnityEngine.CoreModule
# and UnityEngine.UIElementsModule. Rename them so the support module can load.
# Generated assemblies are not committed. A .bak is kept beside each patched DLL.

$ErrorActionPreference = "Stop"
$game = "E:\SteamLibrary\steamapps\common\Last Epoch"
$cecil = Join-Path $game "MelonLoader\net6\Mono.Cecil.dll"
$dir = Join-Path $game "MelonLoader\Il2CppAssemblies"
Add-Type -Path $cecil

function Get-AngleOTypes([Mono.Cecil.AssemblyDefinition]$asm) {
    $found = New-Object System.Collections.Generic.List[Mono.Cecil.TypeDefinition]
    $stack = New-Object System.Collections.Generic.Stack[Mono.Cecil.TypeDefinition]
    foreach ($t in $asm.MainModule.Types) { $stack.Push($t) }
    while ($stack.Count -gt 0) {
        $t = $stack.Pop()
        if ($t.Name -eq "<>O") { $found.Add($t) }
        foreach ($c in $t.NestedTypes) { $stack.Push($c) }
    }
    return $found
}

$patched = 0
Get-ChildItem $dir -Filter *.dll | ForEach-Object {
    $resolver = New-Object Mono.Cecil.DefaultAssemblyResolver
    $resolver.AddSearchDirectory($dir)
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
    if (-not (Test-Path $bak)) { Copy-Item $_.FullName $bak }
    $tmp = "$($_.FullName).tmp"
    $asm.Write($tmp)
    $asm.Dispose()
    Move-Item $tmp $_.FullName -Force
    $patched++
    Write-Output ("{0}: renamed {1}" -f $_.Name, $found.Count)
}
if ($patched -eq 0) { Write-Output "No assembly had more than one <>O type." }
