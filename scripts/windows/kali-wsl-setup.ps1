[CmdletBinding()]
param(
	[switch]$SkipRebootPrompt,
	[switch]$SkipPauseOnExit
)

<#
.SYNOPSIS
Automates the setup of Kali Linux on Windows Subsystem for Linux (WSL) with Win-KeX integration.
.DESCRIPTION
Ensures the Windows host is virtualization-ready, installs and updates required Windows features, provisions the Kali Linux WSL distribution, installs core Kali toolsets, and configures systemd and Win-KeX shortcuts.

.PARAMETER SkipRebootPrompt
Skips the interactive reboot prompt when a restart is required for newly enabled optional Windows features.

.PARAMETER SkipPauseOnExit
Prevents the script from prompting before exit; use this when running from an existing console session.

.NOTES
Run this script from an elevated PowerShell session on Windows 11 or later. The script targets the default WSL distribution name `kali-linux`.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Info {
	param([string]$Message)
	Write-Host "[+] $Message"
}

function Write-WarningMessage {
	param([string]$Message)
	Write-Warning $Message
}

function Assert-Administrator {
	$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
	$principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
	if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
		throw 'This script must be executed from an elevated PowerShell session.'
	}
}

# Validates that each required optional Windows feature is enabled, triggering a restart if necessary.
function Enable-OptionalFeatureIfNeeded {
	param(
		[Parameter(Mandatory)][string]$Name
	)

	$feature = Get-WindowsOptionalFeature -Online -FeatureName $Name
	if ($feature.State -eq 'Enabled') {
		Write-Info "Windows feature '$Name' is already enabled."
		return $false
	}

	Write-Info "Enabling Windows feature '$Name'..."
	$result = Enable-WindowsOptionalFeature -Online -FeatureName $Name -NoRestart
	if ($result.RestartNeeded) {
		Write-Info "Windows feature '$Name' was enabled; a restart is required."
		return $true
	}

	Write-Info "Windows feature '$Name' was enabled successfully."
	return $false
}

# Surfaces virtualization requirements that may prevent WSL 2 from starting.
function Test-VirtualizationReadiness {
	$properties = 'HyperVRequirementDataExecutionPreventionAvailable', 'HyperVRequirementSecondLevelAddressTranslation', 'HyperVRequirementVirtualizationFirmwareEnabled'
	$info = Get-ComputerInfo -Property $properties
	foreach ($property in $properties) {
		$value = $info.$property
		if ($value -ne 'True') {
			Write-WarningMessage "System requirement '$property' is reported as '$value'. Check BIOS/UEFI virtualization settings."
		}
	}
}

# Runs a command inside Kali's WSL context and provides optional output capture.
function Invoke-KaliCommand {
	param(
		[Parameter(Mandatory)][string]$Command,
		[switch]$CaptureOutput,
		[switch]$AllowFailure
	)

	$arguments = @('-d', 'kali-linux', '-u', 'root', '--', 'bash', '-lc', $Command)
	if ($CaptureOutput) {
		$output = & wsl.exe @arguments 2>&1
	}
	else {
		& wsl.exe @arguments
	}
	$exitCode = $LASTEXITCODE

	if ($exitCode -ne 0 -and -not $AllowFailure) {
	$errorMessage = "WSL command failed with exit code $exitCode.`nCommand: $Command"
		if ($CaptureOutput -and $output) {
			$errorMessage += "`nOutput:`n$output"
		}
		throw $errorMessage
	}

	if ($CaptureOutput) {
		return [PSCustomObject]@{
			ExitCode = $exitCode
			Output   = if ($output -is [Array]) { $output -join [Environment]::NewLine } else { $output }
		}
	}

	return [PSCustomObject]@{ ExitCode = $exitCode }
}

# Uses dpkg-query to confirm whether a package is installed inside Kali.
function Test-KaliPackage {
	param(
		[Parameter(Mandatory)][string]$PackageName
	)

	$result = Invoke-KaliCommand "dpkg-query -W -f='${Status}' $PackageName 2>/dev/null" -CaptureOutput -AllowFailure
	if ($result.ExitCode -ne 0) {
		return $false
	}

	return $result.Output -match 'install ok installed'
}

# Toggles systemd support within Kali's /etc/wsl.conf using an inline Python script.
function Enable-SystemdSupport {
	$check = Invoke-KaliCommand "python3 - <<'PY'
import configparser, os
path = '/etc/wsl.conf'
cfg = configparser.ConfigParser()
cfg.optionxform = str
if os.path.exists(path):
	with open(path, 'r', encoding='utf-8', errors='ignore') as f:
		cfg.read_file(f)
if 'boot' not in cfg:
	cfg['boot'] = {}
changed = cfg['boot'].get('systemd', '').lower() != 'true'
cfg['boot']['systemd'] = 'true'
if changed:
	tmp = path + '.tmp'
	with open(tmp, 'w', encoding='utf-8') as f:
		cfg.write(f)
	os.replace(tmp, path)
print('changed' if changed else 'unchanged')
PY" -CaptureOutput

	if ($check.Output -like '*changed*') {
		Write-Info 'Enabled systemd support in /etc/wsl.conf.'
		return $true
	}

	Write-Info 'Systemd support was already enabled.'
	return $false
}

# Creates a Windows shortcut that launches the specified WSL command when missing.
function New-ShortcutIfMissing {
	param(
		[Parameter(Mandatory)][string]$Path,
		[Parameter(Mandatory)][string]$Arguments,
		[string]$Description
	)

	if (Test-Path -LiteralPath $Path) {
		Write-Info "Shortcut already exists: $Path"
		return
	}

	Write-Info "Creating shortcut: $Path"
	$shell = New-Object -ComObject WScript.Shell
	$shortcut = $shell.CreateShortcut($Path)
	$shortcut.TargetPath = Join-Path $env:SystemRoot 'System32\wsl.exe'
	$shortcut.Arguments = $Arguments
	$shortcut.WorkingDirectory = $env:USERPROFILE
	$shortcut.WindowStyle = 1
	if ($Description) {
		$shortcut.Description = $Description
	}
	$shortcut.Save()
}

# Determines whether the script should pause before closing to display output.
function Test-PauseOnExitCondition {
	param([switch]$SkipPauseOnExit)

	if ($SkipPauseOnExit) {
		return $false
	}

	if ($Host.Name -ne 'ConsoleHost') {
		return $false
	}

	if ([Environment]::GetEnvironmentVariable('WT_SESSION')) {
		return $false
	}

	return $true
}

function Invoke-Main {
	Assert-Administrator
	Test-VirtualizationReadiness

	$restartNeeded = $false
	foreach ($featureName in @('Microsoft-Windows-Subsystem-Linux', 'VirtualMachinePlatform')) {
		if (Enable-OptionalFeatureIfNeeded -Name $featureName) {
			$restartNeeded = $true
		}
	}

	if ($restartNeeded) {
		if ($SkipRebootPrompt) {
			Write-WarningMessage 'A restart is required. Reboot the system, then run the script again.'
		}
		else {
			Write-Host 'A restart is required. Reboot the system, then run the script again.' -ForegroundColor Yellow
			Pause
		}
		return
	}

	Write-Info 'Updating the WSL base installation (wsl --update)...'
	& wsl.exe --update
	if ($LASTEXITCODE -ne 0) {
		Write-WarningMessage 'WSL could not be updated. Confirm that the Windows subsystem components are already current.'
	}

	Write-Info 'Setting the default WSL version to 2...'
	& wsl.exe --set-default-version 2
	if ($LASTEXITCODE -ne 0) {
		Write-WarningMessage 'Could not set the default WSL version. Verify that WSL 2 is supported on this system.'
	}

	Write-Info 'Checking whether the Kali Linux distribution is already installed...'
	$existingDistros = (& wsl.exe --list --quiet 2>$null) | ForEach-Object { $_.Trim() } | Where-Object { $_ }
	$kaliInstalled = $existingDistros -contains 'kali-linux'

	if (-not $kaliInstalled) {
		Write-Info 'Kali Linux is not installed. Starting installation (wsl --install -d kali-linux)...'
		& wsl.exe --install -d kali-linux
		Write-Host @'

The Kali Linux distribution installation has been triggered. Close any open windows, restart, and launch Kali manually once (for example, run "kali" in a terminal) to create the default user.
After initial setup, run this script again to complete the remaining configuration steps.
'@ -ForegroundColor Yellow
		return
	}

	Write-Info 'Kali Linux is already present. Setting the distribution as default...'
	& wsl.exe --set-default kali-linux
	if ($LASTEXITCODE -ne 0) {
		Write-WarningMessage 'Unable to set kali-linux as the default distribution. Run the command manually if needed.'
	}

	Write-Info 'Verifying that the distribution has been initialized...'
	$initCheck = Invoke-KaliCommand 'true' -CaptureOutput -AllowFailure
	if ($initCheck.ExitCode -ne 0) {
		throw 'Unable to start Kali inside WSL. Launch Kali manually once, create the user, then run the script again.'
	}

	Write-Info 'Running apt-get update && full-upgrade...'
	Invoke-KaliCommand 'DEBIAN_FRONTEND=noninteractive apt-get update'
	Invoke-KaliCommand 'DEBIAN_FRONTEND=noninteractive apt-get -y full-upgrade'

	if (-not (Test-KaliPackage -PackageName 'kali-linux-everything')) {
		Write-Info 'Installing the kali-linux-everything meta-package (all tools). This can take a long time...'
		Invoke-KaliCommand 'DEBIAN_FRONTEND=noninteractive apt-get -y install kali-linux-everything'
	}
	else {
		Write-Info 'The full Kali toolset (kali-linux-everything) is already installed.'
	}

	if (-not (Test-KaliPackage -PackageName 'kali-win-kex')) {
		Write-Info 'Installing Win-KeX for seamless desktop integration...'
		Invoke-KaliCommand 'DEBIAN_FRONTEND=noninteractive apt-get -y install kali-win-kex'
	}
	else {
		Write-Info 'kali-win-kex is already installed.'
	}

	$systemdChanged = Enable-SystemdSupport

	if ($systemdChanged) {
		Write-Info 'Restarting the WSL instance so systemd takes effect...'
		& wsl.exe --shutdown
	}

	$startMenuPath = Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs\Kali Win-KeX Seamless.lnk'
	New-ShortcutIfMissing -Path $startMenuPath -Arguments '-d kali-linux -- kex --win -s' -Description 'Launches Kali Win-KeX in seamless mode'

	$desktopShortcut = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Kali Win-KeX Seamless.lnk'
	New-ShortcutIfMissing -Path $desktopShortcut -Arguments '-d kali-linux -- kex --win -s' -Description 'Launches Kali Win-KeX in seamless mode'

	Write-Info 'Configuration complete.'
	Write-Host @'

Next steps:
 1. If Kali was just upgraded or restarted, start the instance again with "wsl -d kali-linux".
 2. Launch Win-KeX via the generated shortcut or with "wsl -d kali-linux -- kex --win -s".
 3. The "kali-linux-everything" package requires dozens of gigabytes; confirm that adequate disk space is available.
'@
	Write-Host @'

Next steps:
 1. If Kali was just upgraded or restarted, start the instance again with "wsl -d kali-linux".
 2. Launch Win-KeX via the generated shortcut or with "wsl -d kali-linux -- kex --win -s".
 3. The "kali-linux-everything" package requires dozens of gigabytes; confirm that adequate disk space is available.
'@
}

$shouldPauseOnExit = Test-PauseOnExitCondition -SkipPauseOnExit:$SkipPauseOnExit
$exitCode = 0

try {
	Invoke-Main
}
catch {
	$exitCode = 1
	Write-Error $_
}
finally {
	if ($shouldPauseOnExit) {
		Write-Host
		[void](Read-Host 'Press Enter to close this window')
	}
}

exit $exitCode
