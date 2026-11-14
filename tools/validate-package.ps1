param([Parameter(Mandatory=$true)][string]$Path, [Parameter(Mandatory=$true)][string[]]$Folder)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
if ((Get-Item -LiteralPath $Path).Length -gt 64MB) { throw 'ZIP exceeds 64 MiB' }
$zip = [IO.Compression.ZipFile]::OpenRead($Path)
try {
    if ($zip.Entries.Count -gt 5000) { throw 'Too many ZIP entries' }
    $seen = @{}; $total = 0; $tocFound = @{}
    foreach ($entry in $zip.Entries) {
        $name = $entry.FullName
        $parts = $name.Split('/')
        if ($parts.Count -gt 12 -or $parts[0] -cnotin $Folder) { throw "Wrong ZIP root or depth: $name" }
        if ($name.Contains('\') -or $name -match '[\x00-\x1f<>:"|?*]') { throw "Unsafe ZIP path: $name" }
        foreach ($part in $parts) {
            if (!$part -or $part -in @('.','..') -or $part -match '[. ]$|^(?i:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\.|$)') { throw "Unsafe ZIP component: $part" }
        }
        if ($seen.ContainsKey($name.ToLowerInvariant())) { throw "Duplicate ZIP entry: $name" }
        $seen[$name.ToLowerInvariant()] = $true
        if ([IO.Path]::GetExtension($name) -match '^\.(?i:exe|dll|com|scr|pif|msi|bat|cmd|ps1|vbs|jar|sh|lnk|hta)$') { throw "Program in addon: $name" }
        $total += $entry.Length
        if ($total -gt 256MB) { throw 'Unpacked addon exceeds 256 MiB' }
        $reader = New-Object IO.MemoryStream
        $stream = $entry.Open()
        try { $stream.CopyTo($reader); $bytes = $reader.ToArray() } finally { $stream.Dispose(); $reader.Dispose() }
        if ($bytes.Length -ne $entry.Length) { throw "Wrong entry size: $name" }
        $entryFolder = $parts[0]
        if ($name -ceq "$entryFolder/$entryFolder.toc") {
            $tocFound[$entryFolder] = $true
            $tocText = [Text.Encoding]::UTF8.GetString($bytes)
            if ($tocText -notmatch '(?m)^## Interface: (11200|30300)\s*$') { throw 'Unsupported TOC interface' }
            foreach ($line in ($tocText -split '\r?\n')) {
                $line = $line.Trim()
                if ($line -and !$line.StartsWith('#')) {
                    if (!$zip.GetEntry("$entryFolder/$($line.Replace('\','/'))")) { throw "Missing TOC resource: $line" }
                }
            }
        }
    }
    foreach ($declaredFolder in $Folder) { if (!$tocFound[$declaredFolder]) { throw "Missing folder-matched TOC: $declaredFolder" } }
} finally { $zip.Dispose() }
Write-Output "Validated $Folder"
