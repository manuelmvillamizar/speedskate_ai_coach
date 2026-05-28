$files = Get-ChildItem -Path lib -Recurse -Filter *.dart

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw

    if ($null -eq $content) {
        continue
    }

    $bytes = [System.Text.Encoding]::GetEncoding(28591).GetBytes($content)
    $fixed = [System.Text.Encoding]::UTF8.GetString($bytes)

    Set-Content -Path $file.FullName -Value $fixed -Encoding UTF8

    Write-Host "Fixed $($file.FullName)"
}

Write-Host "Done"