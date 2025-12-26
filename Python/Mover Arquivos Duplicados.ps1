# 1) Defina a pasta alvo e quarentena
$Root = "D:\OneDrive - GRUPO ACO CEARENSE"
$Quar = "D:\Quarentena\Duplicados"

# 2) Liste arquivos e agrupe por tamanho (pré-filtro)
$files = Get-ChildItem -Path $Root -Recurse -File -ErrorAction SilentlyContinue
$sizeGroups = $files | Group-Object Length | Where-Object {$_.Count -gt 1}

# 3) Dentro de cada grupo de tamanho, calcule hash e agrupe
$dupGroups = foreach ($sg in $sizeGroups) {
  $withHash = $sg.Group | ForEach-Object {
    $h = (Get-FileHash -Algorithm SHA256 -Path $_.FullName).Hash
    $_ | Add-Member -NotePropertyName Hash -NotePropertyValue $h -PassThru
  }
  $withHash | Group-Object Hash | Where-Object {$_.Count -gt 1}
}

# 4) Crie quarentena e mova duplicados (mantém o primeiro de cada grupo)
New-Item -ItemType Directory -Path $Quar -Force | Out-Null
foreach ($g in $dupGroups) {
  $keep = $g.Group | Sort-Object FullName | Select-Object -First 1
  $dups = $g.Group | Where-Object {$_.FullName -ne $keep.FullName}
  foreach ($d in $dups) {
    $rel = $d.FullName.Substring($Root.Length).TrimStart('\')
    $dest = Join-Path $Quar $rel
    New-Item -ItemType Directory -Path (Split-Path $dest) -Force | Out-Null
    Move-Item -LiteralPath $d.FullName -Destination $dest
  }
}
