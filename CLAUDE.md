# CLAUDE.md — DattoRMM Script Repository

This file provides context for AI assistants and contributors working in this repository.

---

## Project Overview

This repository is a collection of **standalone PowerShell scripts** deployed through **Datto RMM** (Remote Monitoring & Management, formerly CentraStage) — a platform used by MSPs (Managed Service Providers) to remotely manage and automate tasks on client Windows endpoints.

**Target environments:**
- Windows 10 / 11 workstations
- Windows Server (all modern versions)
- Hyper-V hosts
- Active Directory / domain-joined machines

Scripts are executed by the Datto RMM agent running on each endpoint. There is no build step, package manager, or compilation — each `.ps1` file is a self-contained, directly executable script.

---

## Repository Structure

All scripts live at the **repository root** (flat layout — no subdirectories).

### VM & Hyper-V Management
| File | Purpose |
|------|---------|
| `reboot-required-hyperv-host.ps1` | Checks pending reboots; creates VM snapshots during HST maintenance window |
| `Create Checkpoint and Restart All Running Virtual Machines During Maintenance Hours.ps1` | Snapshots and restarts all running VMs during maintenance window |
| `Create Checkpoint and Shutdown Virtual Machines and Restart HyperV Host During Maintenance Hours.ps1` | Snapshots VMs, shuts them down, then restarts the Hyper-V host |
| `Checkpoint and Restart all Virtual Machines.ps1` | Unconditional checkpoint + restart of all VMs |
| `Check HyperV Host for VMs Running For More Than 30 Days.ps1` | Alerts when VMs have been running over 30 days without restart |

### DNS Management
| File | Purpose |
|------|---------|
| `Ensure all AD Servers are Listed as DNS Servers.ps1` | Validates all AD servers appear in DNS server lists |
| `Set DNS IP Address to Domain Controllers.ps1` | Sets adapter DNS to domain controller IPs |
| `Check for Malfunctioning DNS Server Settings.ps1` | Detects misconfigured or unreachable DNS servers |
| `Check for Static DNS Setting.ps1` | Checks whether static DNS is configured on adapters |

### System Monitoring & Health Checks
| File | Purpose |
|------|---------|
| `check for uac.ps1` | Checks UAC enablement status |
| `Service Check.ps1` | Validates a named service exists (service name via env var) |
| `Restart Service.ps1` | Restarts a named service with error handling |
| `Detect Old Print Jobs.ps1` | Monitors print queues for jobs older than a threshold |
| `OS Drive SSD Check.ps1` | Detects whether the OS drive is SSD or HDD |
| `Find All Local Admins.ps1` | Enumerates members of the local Administrators group |

### Application Management
| File | Purpose |
|------|---------|
| `Detect OneLaunch.ps1` | Searches user profiles for the OneLaunch application |
| `Remove OneLaunch.ps1` | Terminates OneLaunch processes and removes its folders |
| `Remove Cylance.ps1` | Uninstalls Cylance security software via MSI |

### Browser & Registry Configuration
| File | Purpose |
|------|---------|
| `Disable Edge and Chrome Notifications.ps1` | Sets registry keys to suppress browser notification prompts |

### Network Setup
| File | Purpose |
|------|---------|
| `Create Meraki VPN.ps1` | Creates an L2TP VPN connection using env-var-supplied parameters |

### Restart Management
| File | Purpose |
|------|---------|
| `Restart Computer During Maintenance Hours Only.ps1` | Time-gated restart (only executes within HST maintenance window) |

---

## Naming Conventions

Scripts use **descriptive, human-readable names** following the pattern:

```
<Action> + <Target>.ps1
```

Examples:
- `Detect OneLaunch.ps1`
- `Set DNS IP Address to Domain Controllers.ps1`
- `Restart Computer During Maintenance Hours Only.ps1`

**New scripts must follow this same pattern.** Avoid abbreviations or technical shorthand in filenames — clarity is preferred since names appear directly in the Datto RMM dashboard.

---

## Code Conventions

### Naming in Code
- **Functions**: PascalCase — e.g., `Test-PendingReboot`, `CheckTimeInHST`
- **Variables**: camelCase — e.g., `$serviceName`, `$runningVMs`, `$hstTime`

### RMM Output Markers

All scripts **must** wrap their primary output in these markers so Datto RMM can parse results:

```powershell
Write-Host "<-Start Result->"
Write-Host "Your result message here"
Write-Host "<-End Result->"
```

For extended diagnostic detail (optional, shown separately in RMM):

```powershell
Write-Host "<-Start Diagnostic->"
Write-Host "Detailed info here"
Write-Host "<-End Diagnostic->"
```

### Exit Codes

| Code | Meaning |
|------|---------|
| `Exit 0` | Success / no action needed / condition not met |
| `Exit 1` | Failure / alert condition / action required |

Always exit explicitly — do not rely on implicit exit codes.

### Error Handling

- Use `-ErrorAction SilentlyContinue` for non-critical lookups where failure is acceptable
- Use `-ErrorAction Stop` with `try/catch` blocks for critical operations (service restarts, VM checkpoints, etc.)
- Check `$?` or `$LASTEXITCODE` after operations before proceeding

```powershell
try {
    Restart-Service -Name $serviceName -ErrorAction Stop
    Write-Host "Service restarted successfully."
} catch {
    Write-Host "Failed to restart service: $_"
    Exit 1
}
```

---

## Parameterization — Environment Variables

Scripts receive all runtime inputs via **Datto RMM environment variables**. These are configured in the RMM component definition and injected as environment variables at execution time.

Access pattern:

```powershell
$serviceName = $env:service_name
$serverAddress = $env:serveraddress
```

**Always document expected environment variables** in a comment block at the top of each script:

```powershell
# Environment Variables (set in Datto RMM component):
#   service_name  - Name of the Windows service to check/restart
```

Common variable names seen in this repo:
- `$env:service_name` — Windows service name
- `$env:name` — VPN or connection name
- `$env:serveraddress` — Remote server IP or hostname
- `$env:dnssuffix` — DNS suffix for VPN connection
- `$env:vpnpassword` — Pre-shared key or password (never hardcode)

**Never hardcode credentials or sensitive values** — always consume them from `$env:` variables supplied by Datto RMM.

---

## Maintenance Window / Time Zone Handling

Scripts that perform disruptive actions (reboots, VM restarts, host shutdowns) check that execution falls within the configured **maintenance window** before proceeding.

The organization's maintenance window is in **Hawaii Standard Time (HST), UTC−10**.

Standard pattern:

```powershell
function CheckTimeInHST {
    $utcTime = [System.DateTime]::UtcNow
    $hstTime = $utcTime.AddHours(-10)
    $hour = $hstTime.Hour
    # Maintenance window: 10 PM – 4 AM HST
    return ($hour -ge 22 -or $hour -lt 4)
}

if (-not (CheckTimeInHST)) {
    Write-Host "Outside maintenance window. Exiting."
    Exit 0
}
```

Adjust the hour range if the maintenance window changes, but keep the UTC→HST conversion pattern.

---

## Datto RMM / CentraStage Integration

- **Agent registry path**: `HKLM:\SOFTWARE\CentraStage` — used by some scripts to read agent metadata
- Scripts run under the **Datto RMM agent service account** (typically SYSTEM or a dedicated account)
- Use `Get-WmiObject` or `Get-CimInstance` for system info (some older scripts use `Get-WmiObject`; prefer `Get-CimInstance` for new scripts on modern OS)
- Hyper-V cmdlets (`Get-VM`, `Checkpoint-VM`, etc.) require the Hyper-V PowerShell module to be installed on the host

---

## Development Workflow

1. **Write** the script as a standalone `.ps1` file at the repository root
2. **Name** the file using the Action + Target convention
3. **Document** required environment variables in a comment block at the top
4. **Test** manually on a representative test machine or Datto RMM sandbox environment
5. **Commit** with a clear message:
   ```
   Create <Script Name>.ps1
   ```
   or for updates:
   ```
   Update <Script Name>.ps1 - <brief description of change>
   ```
6. **Push** to the working branch; Datto RMM pulls scripts from the configured branch/repo

There is no build system, package manager, or compilation step.

---

## Testing

There is no automated test framework in this repository. Scripts are validated by:
- Manual execution on a test Windows endpoint
- Datto RMM component sandbox/test mode (if available in your RMM account)
- Code review before deployment to production components

If adding Pester tests in the future, follow the convention `<ScriptName>.Tests.ps1` and place them in a `/Tests` subdirectory.

---

## CI/CD

There is currently **no CI/CD pipeline**. No GitHub Actions, no linting automation.

Recommended future improvement:
- Add a GitHub Actions workflow that runs **PSScriptAnalyzer** on all `.ps1` files on push/PR to catch common PowerShell issues before deployment.

---

## Security Guidelines

Scripts in this repository perform **privileged operations** on production systems:
- Service restarts
- DNS configuration changes
- VM checkpoint creation and host reboots
- Registry modifications
- Software uninstallation

Follow these rules:
1. **Never hardcode credentials**, passwords, or pre-shared keys — always use `$env:` variables
2. **Validate environment variable inputs** before using them in destructive operations (e.g., check that `$serviceName` is not empty before passing to `Restart-Service`)
3. **Scope changes narrowly** — modify only what the script is designed to change
4. **Log actions** using the RMM output markers so there is an audit trail in the RMM dashboard
5. **Use maintenance windows** for any operation that could cause user-facing downtime
