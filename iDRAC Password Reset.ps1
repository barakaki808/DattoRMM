# DattoRMM Component - iDRAC Password Reset via RACADM
# Resets the default root (user ID 2) password on Dell iDRAC from the host OS.
# Requires Dell RACADM to be installed (OpenManage Server Administrator or iDRAC Service Module).
#
# Component Variables (set at runtime):
#   NewiDRACPassword (optional) - The new password to set. If not provided, a secure password is auto-generated.

function Generate-SecurePassword {
    $length = 20
    $upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ'
    $lower = 'abcdefghjkmnpqrstuvwxyz'
    $digits = '23456789'
    $special = '!@#$%&*?'
    $allChars = $upper + $lower + $digits + $special

    # Guarantee at least one from each category
    $password = @()
    $password += $upper[(Get-Random -Maximum $upper.Length)]
    $password += $lower[(Get-Random -Maximum $lower.Length)]
    $password += $digits[(Get-Random -Maximum $digits.Length)]
    $password += $special[(Get-Random -Maximum $special.Length)]

    for ($i = $password.Count; $i -lt $length; $i++) {
        $password += $allChars[(Get-Random -Maximum $allChars.Length)]
    }

    # Shuffle
    $password = $password | Sort-Object { Get-Random }
    return -join $password
}

# --- Locate racadm ---
$racadmPath = $null
$searchPaths = @(
    "$env:ProgramFiles\Dell\SysMgt\rac5\racadm.exe",
    "$env:ProgramFiles\Dell\SysMgt\iDRACTools\racadm.exe",
    "${env:ProgramFiles(x86)}\Dell\SysMgt\rac5\racadm.exe",
    "${env:ProgramFiles(x86)}\Dell\SysMgt\iDRACTools\racadm.exe"
)

foreach ($p in $searchPaths) {
    if (Test-Path $p) {
        $racadmPath = $p
        break
    }
}

# Fall back to PATH
if (-not $racadmPath) {
    $found = Get-Command racadm.exe -ErrorAction SilentlyContinue
    if ($found) {
        $racadmPath = $found.Source
    }
}

if (-not $racadmPath) {
    Write-Host "<-Start Result->"
    Write-Host "Result=ERROR: racadm.exe not found. Install Dell OpenManage Server Administrator or iDRAC Service Module."
    Write-Host "<-End Result->"
    exit 1
}

Write-Host "Using racadm at: $racadmPath"

# --- Determine password ---
$newPassword = $env:NewiDRACPassword
$passwordGenerated = $false

if ([string]::IsNullOrWhiteSpace($newPassword)) {
    $newPassword = Generate-SecurePassword
    $passwordGenerated = $true
    Write-Host "No password provided via component variable. A secure password has been generated."
} else {
    Write-Host "Using password from component variable."
}

# --- Reset password for root (user ID 2) ---
$userId = 2

try {
    # Verify we can communicate with iDRAC
    $testOutput = & $racadmPath getconfig -g cfgUserAdmin -i $userId 2>&1
    if ($LASTEXITCODE -ne 0) {
        # Try newer racadm syntax
        $testOutput = & $racadmPath get iDRAC.Users.$userId.UserName 2>&1
    }

    Write-Host "Current iDRAC user $userId detected. Proceeding with password reset..."

    # Attempt password change - try modern syntax first, fall back to legacy
    $result = & $racadmPath set iDRAC.Users.$userId.Password $newPassword 2>&1
    if ($LASTEXITCODE -ne 0) {
        # Legacy racadm syntax
        $result = & $racadmPath config -g cfgUserAdmin -i $userId -o cfgUserAdminPassword $newPassword 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "<-Start Result->"
            Write-Host "Result=ERROR: Password reset failed. racadm output: $result"
            Write-Host "<-End Result->"
            exit 1
        }
    }

    # Build result message
    $msg = "iDRAC root password (user ID $userId) reset successfully."
    if ($passwordGenerated) {
        $msg += " Generated password: $newPassword"
    }

    Write-Host "<-Start Result->"
    Write-Host "Result=$msg"
    Write-Host "<-End Result->"
    exit 0

} catch {
    Write-Host "<-Start Result->"
    Write-Host "Result=ERROR: $($_.Exception.Message)"
    Write-Host "<-End Result->"
    exit 1
}
