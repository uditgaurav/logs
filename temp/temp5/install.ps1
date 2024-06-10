param (
    [string]$AdminUser = ".\Administrator",
    [Parameter(Mandatory=$true)]
    [string]$AdminPass,
    [string]$InfraId = "",
    [string]$AccessKey = "",
    [string]$ServerUrl = "",
    [string]$LogDirectory = "C:\\HCE\\Logs",
    [string]$ChaosBasePath = "C:\\HCE",
    [int]$TaskPollIntervalSeconds = 5,
    [int]$TaskUpdateIntervalSeconds = 5,
    [int]$UpdateRetries = 5,
    [int]$UpdateRetryIntervalSeconds = 5,
    [int]$ChaosInfraLivenessUpdateIntervalSeconds = 5,
    [int]$ChaosInfraLogFileMaxSizeMb = 5,
    [int]$ChaosInfraLogFileMaxBackups = 2,
    [string]$CustomTlsCertificate = "",
    [string]$HttpProxy = "",
    [string]$HttpClientTimeout = "30s",
    [string]$InstallMode = "online"  # new parameter to determine installation mode
)

# Converts plain password to a secure string
function ConvertTo-SecureStringWrapper {
    param(
        [string]$password
    )
    return ConvertTo-SecureString $password -AsPlainText -Force
}

# Checks if the script is running with administrative privileges
function Check-AdminPrivileges {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    if (-not $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "This script requires administrative privileges. Please right-click the Command Prompt shortcut and select 'Run as Administrator' before executing this script."
    }
}

# Creates a directory if it does not exist
function Create-DirectoryIfNotExists {
    param(
        [string]$Path
    )
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -ItemType Directory
    }
}

# Updates the system PATH environment variable
function Update-SystemPath {
    param(
        [string]$NewPath
    )
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::Machine)
    if (-not ($currentPath -like "*$NewPath*")) {
        $newPath = $currentPath + ";" + $NewPath
        [Environment]::SetEnvironmentVariable("PATH", $newPath, [EnvironmentVariableTarget]::Machine)
        Write-Host "Updated PATH with $NewPath"
    }
}

# Function to verify that a binary exists at a specified path and update the PATH if needed
function Verify-AndExportBinary {
    param(
        [string]$BinaryPath,
        [string]$BinaryName
    )
    $binaryFullPath = Join-Path -Path $BinaryPath -ChildPath $BinaryName

    if (Test-Path $binaryFullPath) {
        Write-Host "$BinaryName found at $BinaryPath."
        Update-SystemPath -NewPath $BinaryPath
    } else {
        if ($BinaryName -eq "windows-chaos-infrastructure.exe") {
            throw "$BinaryName not found at $BinaryPath or in PATH. Installation failed."
        } else {
            Write-Warning "$BinaryName not found at $BinaryPath. Please ensure it is available for offline installation."
        }
    }
}

# Creates a configuration file
function Create-ConfigFile {
    param(
        [string]$ConfigPath
    )
    $configContent = @"
infraID: "$InfraId"
accessKey: "$AccessKey"
serverURL: "$ServerUrl"
logDirectory: "$LogDirectory"
taskPollIntervalSeconds: $TaskPollIntervalSeconds
taskUpdateIntervalSeconds: $TaskUpdateIntervalSeconds
updateRetries: $UpdateRetries
updateRetryIntervalSeconds: $UpdateRetryIntervalSeconds
chaosInfraLivenessUpdateIntervalSeconds: $ChaosInfraLivenessUpdateIntervalSeconds
chaosInfraLogFileMaxSizeMB: $ChaosInfraLogFileMaxSizeMb
chaosInfraLogFileMaxBackups: $ChaosInfraLogFileMaxBackups
customTLSCertificate: "$CustomTlsCertificate"
httpProxy: "$HttpProxy"
httpClientTimeout: "$HttpClientTimeout"
"@

    New-Item -Path $ConfigPath -ItemType File -Force | Out-Null
    $configContent | Set-Content -Path $ConfigPath
    Write-Host "Config file created at $ConfigPath"
}

# Function to create a log file
function Create-LogFile {
    param(
        [string]$LogPath
    )
    if (-not (Test-Path $LogPath)) {
        New-Item -Path $LogPath -ItemType File -Force
    }
}

# Creates and starts a Windows service
function Create-Service {
    param(
        [string]$serviceName,
        [string]$serviceBinaryPath,
        [string]$logDirectory,
        [string]$configFilePath,
        [string]$adminUser,
        [string]$adminPassPlainText
    )
    # Include the logDirectory and ConfigFilePath flags in the service binary's command line arguments
    $servicePath = "`"$serviceBinaryPath --LogDirectory $logDirectory --ConfigFilePath $configFilePath`""

    $scArgs = @("create", $serviceName, "binPath= ", $servicePath, "start= ", "auto", "obj= ", $adminUser, "password= ", $adminPassPlainText)
    $process = Start-Process "sc" -ArgumentList $scArgs -NoNewWindow -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        throw "Failed to create service with provided credentials. Exit code: $($process.ExitCode)"
    }

    Start-Service -Name $serviceName -ErrorAction Stop
    Write-Host "Service created and started successfully."
}

function Log-Message {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "WARNING", "ERROR")]
        [string]$Level = "INFO",

        [Parameter(Mandatory=$false)]
        [string]$LogFile
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$Level] $Message"

    # Print to console
    switch ($Level) {
        "INFO" { Write-Host $logMessage -ForegroundColor Cyan }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
    }

    # Append to log file if specified
    if ($LogFile) {
        Add-Content -Path $LogFile -Value $logMessage
    }
}

$secureAdminPass = ConvertTo-SecureStringWrapper -password $AdminPass

try {
    # Ensuring the script runs with administrative privileges
    Check-AdminPrivileges

    Create-DirectoryIfNotExists -Path $ChaosBasePath

    # Define tools to check and export
    $tools = @(
        @{
            Name = "Testlimit";
            ExtractPath = "$ChaosBasePath\Testlimit";
            if ([Environment]::Is64BitOperatingSystem) {
                BinaryName = "testlimit64.exe"
            } else {
                BinaryName = "testlimit32.exe"
            }
        }
    )

    $ServiceBinaryVersion = "main"

    # Determine the architecture of the system
    if ([Environment]::Is64BitOperatingSystem) {
        $architecture = "64"
    } else {
        $architecture = "32"
    }

    # Define the service binary path
    $serviceBinary = @{
        Name = "windows-chaos-infrastructure";
        ExtractPath = "$ChaosBasePath";
        BinaryName = "windows-chaos-infrastructure.exe"
    }

    # Check if the mode is offline
    if ($InstallMode -eq "offline") {
        foreach ($tool in $tools) {
            Verify-AndExportBinary -BinaryPath $tool.ExtractPath -BinaryName $tool.BinaryName
        }
        Verify-AndExportBinary -BinaryPath $serviceBinary.ExtractPath -BinaryName $serviceBinary.BinaryName
    } else {
        # Download and extract each tool
        foreach ($tool in $tools) {
            Download-AndExtractTool -tool $tool
        }

        # Accept Testlimit EULA
        Accept-TestlimitEULA

        # Download and extract the service binary
        Download-AndExtractServiceBinary -binary $serviceBinary
    }

    # Create the configuration file
    $configPath = "$ChaosBasePath\config.yaml"
    Create-ConfigFile -ConfigPath $configPath

    # Create a log file under the specified log directory
    $logFilePath = Join-Path -Path $LogDirectory -ChildPath "windows-chaos-infrastructure.log"
    Create-LogFile -LogPath $logFilePath

    # Create and start the Windows service
    $serviceName = "WindowsChaosInfrastructure"
    $serviceBinaryPath = "$ChaosBasePath\windows-chaos-infrastructure.exe"
    $configPath = "$ChaosBasePath\config.yaml"
    $adminPassPlainText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureAdminPass))

    Create-Service -serviceName $serviceName -serviceBinaryPath $serviceBinaryPath -logDirectory $LogDirectory -configFilePath $configPath -adminUser $AdminUser -adminPassPlainText $adminPassPlainText

} catch {
    Write-Error "Error occurred: $_"
    Log-Message -Message "Error occurred: $_" -Level "ERROR" -LogFile $logFilePath
    exit
}
