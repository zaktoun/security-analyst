# collect_windows.ps1 – Mengumpulkan data keamanan Windows Server

$OutputDir = "windows_data_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $OutputDir -Force

Write-Host "[1/8] Mengumpulkan system information..."
Get-ComputerInfo | Out-File "$OutputDir\system_info.txt"
systeminfo | Out-File "$OutputDir\systeminfo.txt"
Get-HotFix | Out-File "$OutputDir\patches.txt"

Write-Host "[2/8] Mengumpulkan user accounts..."
Get-LocalUser | Select-Object Name, Enabled, LastLogon, PasswordExpires | Out-File "$OutputDir\local_users.txt"
Get-LocalGroupMember -Group "Administrators" | Out-File "$OutputDir\admin_users.txt"
Get-LocalGroup | ForEach-Object { Get-LocalGroupMember -Group $_.Name } | Out-File "$OutputDir\all_group_members.txt"

Write-Host "[3/8] Mengumpulkan services..."
Get-Service | Where-Object {$_.Status -eq "Running"} | Out-File "$OutputDir\running_services.txt"
Get-WmiObject win32_service | Select-Object Name, DisplayName, PathName, StartMode, StartName | Out-File "$OutputDir\services_detail.txt"

Write-Host "[4/8] Mengumpulkan scheduled tasks..."
Get-ScheduledTask | Where-Object {$_.State -ne "Disabled"} | Out-File "$OutputDir\scheduled_tasks.txt"

Write-Host "[5/8] Mengumpulkan registry keys penting..."
$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\SYSTEM\CurrentControlSet\Services",
    "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
)
foreach ($path in $regPaths) {
    Get-Item -Path $path -ErrorAction SilentlyContinue | Out-File "$OutputDir\registry_$(($path -replace '\\','_') -replace ':','').txt"
}

Write-Host "[6/8] Mengumpulkan firewall rules..."
Get-NetFirewallRule | Where-Object {$_.Enabled -eq $true} | Out-File "$OutputDir\firewall_rules.txt"
Get-NetFirewallPortFilter | Out-File "$OutputDir\firewall_ports.txt"

Write-Host "[7/8] Mengumpulkan event logs (100 terakhir)..."
Get-EventLog -LogName Security -Newest 100 | Out-File "$OutputDir\eventlog_security.txt"
Get-EventLog -LogName Application -Newest 100 | Out-File "$OutputDir\eventlog_application.txt"
Get-EventLog -LogName System -Newest 100 | Out-File "$OutputDir\eventlog_system.txt"

Write-Host "[8/8] Memeriksa file startup dan autoruns..."
Get-CimInstance Win32_StartupCommand | Out-File "$OutputDir\startup_commands.txt"

Compress-Archive -Path "$OutputDir\*" -DestinationPath "$OutputDir.zip" -Force
Remove-Item -Path "$OutputDir" -Recurse -Force
Write-Host "✅ Data Windows terkumpul di $OutputDir.zip"
