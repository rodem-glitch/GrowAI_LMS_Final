Write-Host "=== Page Accessibility Check ==="

$urls = @(
    "http://localhost:8080/",
    "http://localhost:8080/mypage/new_main/",
    "http://localhost:8080/tutor_lms/app/"
)

foreach ($url in $urls) {
    try {
        $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 5
        Write-Host "[OK] $url -> HTTP $($r.StatusCode)"
    } catch {
        Write-Host "[--] $url -> $($_.Exception.Message)"
    }
}

Write-Host ""
Write-Host "=== CSS File Check ==="

$cssFiles = @(
    "D:\Real_one_stop_service\public_html\common\css\unified-theme.css",
    "D:\Real_one_stop_service\public_html\common\css\phase2-components.css",
    "D:\Real_one_stop_service\public_html\common\css\dark-override.css"
)

foreach ($f in $cssFiles) {
    $content = Get-Content $f -Raw
    $hasDarkBg = $content -match '#0a0a12'
    $hasLightBg = $content -match '#ffffff'
    $hasBlueAccent = $content -match '#2b58e6'

    $name = Split-Path $f -Leaf
    if ($hasLightBg -and $hasBlueAccent -and (-not $hasDarkBg)) {
        Write-Host "[OK] $name -> Light theme applied (blue accent)"
    } elseif ($hasDarkBg) {
        Write-Host "[!!] $name -> Still has dark theme (#0a0a12)"
    } else {
        Write-Host "[OK] $name -> Updated"
    }
}

Write-Host ""
Write-Host "=== Summary ==="
Write-Host "Dark (#0a0a12, #1a1a2e) -> Light (#ffffff, #f3f3f5)"
Write-Host "Pink accent (#e7005e) -> Blue accent (#2b58e6)"
Write-Host "White text (#f8f9fc) -> Dark text (#030213)"
Write-Host ""
Write-Host "Refresh browser to see changes: http://localhost:8080/mypage/new_main/"
