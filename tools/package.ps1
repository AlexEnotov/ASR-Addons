param(
    [Parameter(Mandatory = $true)][ValidatePattern('^v[0-9]+\.[0-9]+\.[0-9]+$')][string]$Tag,
    [string]$OutputDirectory = 'release'
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$repoRoot = Split-Path $PSScriptRoot -Parent
$output = if ([IO.Path]::IsPathRooted($OutputDirectory)) { $OutputDirectory } else { Join-Path $repoRoot $OutputDirectory }
[IO.Directory]::CreateDirectory($output) | Out-Null
$modules = [ordered]@{ ASAdvisor = 'ASRAdvisor'; ASRStats = 'ASRStats'; ASRCombatText = 'ASRCombatText'; ASRSuite = 'ASRSuite' }
$hashes = @()
foreach ($folder in $modules.Keys) {
    $source = Join-Path $repoRoot $folder
    $toc = Join-Path $source "$folder.toc"
    $tocText = [IO.File]::ReadAllText($toc)
    if ($tocText -notmatch '(?m)^## Interface: (11200|30300)\s*$') { throw "Unsupported Interface: $folder" }
    # Runtime allowlist: development tools, tests and package metadata never enter the ZIP.
    $files = @(Get-ChildItem -LiteralPath $source -File | Where-Object { $_.Extension -in @('.lua', '.toc') })
    $media = Join-Path $source 'media'
    if (Test-Path -LiteralPath $media) { $files += @(Get-ChildItem -LiteralPath $media -Recurse -File) }
    $license = Join-Path $repoRoot 'LICENSE'
    $name = "$($modules[$folder])-$Tag.zip"
    $target = Join-Path $output $name
    # Rebuild the same local output file, without accumulating staging directories.
    $stream = [IO.File]::Open($target, [IO.FileMode]::Create)
    $zip = New-Object IO.Compression.ZipArchive($stream, [IO.Compression.ZipArchiveMode]::Create)
    try {
        $seen = @{}
        foreach ($file in ($files | Sort-Object FullName)) {
            if ($file.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Symlink not allowed: $file" }
            $relative = $file.FullName.Substring($source.Length).TrimStart([char[]]@('\','/')).Replace('\','/')
            $entryName = "$folder/$relative"
            if ($seen.ContainsKey($entryName.ToLowerInvariant())) { throw "Duplicate path: $entryName" }
            $seen[$entryName.ToLowerInvariant()] = $true
            if ($file.Extension -notin @('.lua','.toc','.tga','.png','.blp','.ttf','.otf')) { throw "Unexpected runtime asset: $entryName" }
            $entry = $zip.CreateEntry($entryName, [IO.Compression.CompressionLevel]::Optimal)
            $entry.LastWriteTime = [DateTimeOffset]::new(2026,1,1,0,0,0,[TimeSpan]::Zero)
            $destination = $entry.Open()
            try { $bytes = [IO.File]::ReadAllBytes($file.FullName); $destination.Write($bytes,0,$bytes.Length) } finally { $destination.Dispose() }
        }
        if (Test-Path -LiteralPath $license) {
            $entry = $zip.CreateEntry("$folder/LICENSE", [IO.Compression.CompressionLevel]::Optimal)
            $entry.LastWriteTime = [DateTimeOffset]::new(2026,1,1,0,0,0,[TimeSpan]::Zero)
            $destination = $entry.Open()
            try { $bytes = [IO.File]::ReadAllBytes($license); $destination.Write($bytes,0,$bytes.Length) } finally { $destination.Dispose() }
        }
    } finally { $zip.Dispose(); $stream.Dispose() }
    & (Join-Path $PSScriptRoot 'validate-package.ps1') -Path $target -Folder $folder
    $hashes += "$((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant())  $name"
}
[IO.File]::WriteAllLines((Join-Path $output 'SHA256SUMS'), $hashes, (New-Object Text.UTF8Encoding($false)))
Write-Output "Built four independent addons for $Tag in $output"
