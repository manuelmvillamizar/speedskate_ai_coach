$files = Get-ChildItem -Path ".\lib" -Recurse -Filter *.dart

$replacements = @{
    "Ã¡" = "á"
    "Ã©" = "é"
    "Ã­" = "í"
    "Ã³" = "ó"
    "Ãº" = "ú"

    "Ã±" = "ñ"
    "Ã‘" = "Ñ"

    "â€¢" = "•"
    "â†’" = "→"

    "Â·" = "·"
    "Âº" = "º"
    "Âª" = "ª"

    "Â" = ""
}

foreach ($file in $files) {

    Write-Host "Corrigiendo $($file.FullName)"

    $content = Get-Content $file.FullName -Raw

    foreach ($key in $replacements.Keys) {
        $content = $content.Replace($key, $replacements[$key])
    }

    Set-Content -Path $file.FullName -Value $content -Encoding UTF8
}

Write-Host ""
Write-Host "Correccion terminada."