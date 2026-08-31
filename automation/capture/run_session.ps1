<#
  Кинематик жазу сессиясын толық жүргізеді (ноутбукте немесе GPU VM-де):

    1. clipper watch-ты фонда іске қосады (Roblox логын тыңдайды)
    2. OBS жазуын бастайды (obs-websocket)
    3. Roblox-ты launchData=cinematic deep link-пен ашады
    4. -DurationSeconds күтеді
    5. Roblox-ты жабады
    6. OBS жазуын тоқтатады (файл жолын алады)
    7. clipper cut → ffmpeg клиптер → automation/upload/clips/ → git push
    8. Қазіргі YouTube workflow клиптерді жүктейді

  Алдын ала: OBS ашық тұруы керек, obs-websocket қосулы (пароль OBS_WS_PASSWORD),
  Roblox орнатылған әрі жазушы аккаунтпен кіріп қойылған, ffmpeg PATH-та,
  `pip install -r automation/capture/requirements.txt` орындалған.

  Мысал:
    powershell -File automation/capture/run_session.ps1 -DurationSeconds 420
#>

param(
    [int]$PlaceId = 82819939059036,
    [string]$LaunchData = "cinematic",
    [int]$DurationSeconds = 420,
    [string]$Python = "python"
)

$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$capture = $PSScriptRoot
$markers = Join-Path $env:TEMP "bfa_markers.json"

Write-Host "[session] repo: $repo"
if (Test-Path $markers) { Remove-Item $markers -Force }

# 1. clipper watch (фонда)
$watch = Start-Process $Python `
    -ArgumentList @("`"$capture\clipper.py`"", "watch", "--out", "`"$markers`"", "--duration", ($DurationSeconds + 30)) `
    -PassThru -WindowStyle Hidden
Write-Host "[session] clipper watch PID $($watch.Id)"
Start-Sleep -Seconds 2

# 2. OBS жазуын бастау + сессия басталу уақыты
& $Python "$capture\obs_ctl.py" start | Out-Null
$sessionStartMs = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
Write-Host "[session] OBS recording, t0=$sessionStartMs"

# 3. Roblox deep link
$deep = "roblox://experiences/start?placeId=$PlaceId&launchData=$LaunchData"
Start-Process $deep
Write-Host "[session] Roblox ашылды: $deep"

# 4. күту
Start-Sleep -Seconds $DurationSeconds

# 5. Roblox-ты жабу
Get-Process RobloxPlayerBeta -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Host "[session] Roblox жабылды"
Start-Sleep -Seconds 2

# 6. OBS тоқтату → жазба жолы
$recording = (& $Python "$capture\obs_ctl.py" stop | Select-Object -Last 1).Trim()
Write-Host "[session] жазба: $recording"

# clipper watch аяқталсын (маркерлерді флаштайды)
if (-not $watch.HasExited) {
    Stop-Process -Id $watch.Id -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 2

if (-not (Test-Path $recording)) {
    Write-Warning "[session] жазба файлы жоқ — тоқтатылды."
    exit 1
}

# 7. клип кесу + push
& $Python "$capture\clipper.py" cut `
    --recording "$recording" `
    --markers "$markers" `
    --session-start $sessionStartMs `
    --repo "$repo" `
    --push

Write-Host "[session] дайын."
