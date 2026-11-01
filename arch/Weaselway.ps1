param([ValidateSet('start','stop','status','viewer')][string]$Action = 'start')
$ErrorActionPreference = 'Stop'
if ($Action -eq 'stop' -or $Action -eq 'status') {
    & wsl.exe -d archlinux -u root -- /opt/weaselway/libexec/control-session $Action
    exit $LASTEXITCODE
}
if ($Action -eq 'start') {
    & wsl.exe -d archlinux -u root -- /opt/weaselway/libexec/control-session start
    if ($LASTEXITCODE -ne 0) { throw 'KDE session failed to start; use the status command.' }
    # Keep only this distro alive while the desktop session is active.
    $holder = Get-CimInstance Win32_Process -Filter "Name='wsl.exe'" | Where-Object { $_.CommandLine -like '*-d archlinux -- bash -c "while systemctl is-active --quiet weaselway-session.service; do sleep 5; done"*' }
    if (-not $holder) {
        Start-Process wsl.exe -WindowStyle Hidden -ArgumentList @('-d','archlinux','--','bash','-c','"while systemctl is-active --quiet weaselway-session.service; do sleep 5; done"')
    }
}
$existingViewer = Get-CimInstance Win32_Process -Filter "Name='sdl-freerdp.exe'" | Where-Object { $_.ExecutablePath -eq '\\wsl.localhost\archlinux\opt\weaselway\viewer\sdl-freerdp.exe' }
if ($existingViewer) {
    Write-Output 'The Arch KDE viewer is already running.'
    exit 0
}
& wsl.exe -d archlinux -- ww-start-viewer
exit $LASTEXITCODE
