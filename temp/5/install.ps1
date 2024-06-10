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
    [string]$InstallMode = "online"
)

# Accept the Testlimit EULA
function Accept-TestlimitEULA {
    if ([Environment]::Is64BitOperatingSystem) {
        $architectureSuffix = "64"
    } else {
        $architectureSuffix = ""
    }
    $testlimitExecutable = "testlimit$architectureSuffix.exe"
    $testlimitPath = Join-Path -Path $ChaosBasePath -ChildPath ("Testlimit\" + $testlimitExecutable)
    $arguments = "/accepteula /m 1"

    Write-Host "Accepting Testlimit EULA for $testlimitExecutable..."
    Start-Process -FilePath $testlimitPath -ArgumentList $arguments -NoNewWindow -Wait -RedirectStandardOutput "null"
    Write-Host "Testlimit EULA accepted for $testlimitExecutable."
}

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

# Downloads and extracts the service binary
function Download-AndExtractServiceBinary {
    param(
        [hashtable]$binary
    )
    $binaryFilePath = Join-Path -Path $binary.ExtractPath -ChildPath "windows-chaos-infrastructure.exe"
    if (-not (Test-Path $binaryFilePath)) {
        Write-Host ("Downloading {0} binary..." -f $binary.Name)
        Invoke-WebRequest -Uri $binary.DownloadUrl -OutFile $binary.Path -ErrorAction Stop
        Write-Host ("Extracting {0} binary..." -f $binary.Name)
        Expand-Archive -Path $binary.Path -DestinationPath $binary.ExtractPath -Force -ErrorAction Stop
        Remove-Item -Path $binary.Path -Force
    } else {
        Write-Host ("{0} binary is already present." -f $binary.Name)
    }
}

# Downloads and extracts a specified tool
function Download-AndExtractTool {
    param(
        [hashtable]$tool
    )
    if (-not (Test-Path $tool.Destination)) {
        Write-Host ("Downloading {0}..." -f $tool.Name)
        Invoke-WebRequest -Uri $tool.DownloadUrl -OutFile $tool.Destination -ErrorAction Stop
        Write-Host ("Extracting {0}..." -f $tool.Name)
        Expand-Archive -Path $tool.Destination -DestinationPath $tool.ExtractPath -Force -ErrorAction Stop
        Remove-Item -Path $tool.Destination -Force
        Update-SystemPath $tool.ExecutablePath
    } else {
        Write-Host ("{0} is already downloaded." -f $tool.Name)
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

# Function to verify that a binary exists at a specified path and update the PATH if needed
function Verify-AndExportBinary {
    param(
        [string]$BinaryPath,
        [string]$BinaryName
    )
    $binaryFullPath = Join-Path -Path $BinaryPath -ChildPath $BinaryName

    try {
        & $binaryFullPath
        Write-Host "$BinaryName is installed and available."
    } catch {
        Write-Host "$BinaryName not found in PATH. Checking in $BinaryPath..."
        if (Test-Path $binaryFullPath) {
            Update-SystemPath -NewPath $BinaryPath
            try {
                & $binaryFullPath
                Write-Host "$BinaryName executed successfully after updating PATH."
            } catch {
                throw "$BinaryName is available at $BinaryPath but could not be executed. Please check the binary."
            }
        } else {
            Write-Error "$BinaryName not found at $BinaryPath. Please ensure it is available for offline installation."
            throw "$BinaryName not found at $BinaryPath. Exiting installation."
        }
    }
}

$secureAdminPass = ConvertTo-SecureStringWrapper -password $AdminPass

try {
    # Ensuring the script runs with administrative privileges
    Check-AdminPrivileges

    Create-DirectoryIfNotExists -Path $ChaosBasePath

    # Define tools to download and extract
    $tools = @(
        @{
            Name = "Testlimit";
            DownloadUrl = "https://app.harness.io/public/shared/tools/chaos/windows/Testlimit.zip";
            Destination = "$ChaosBasePath\testlimit.zip";
            ExecutablePath = "$ChaosBasePath\Testlimit";
            ExtractPath = "$ChaosBasePath\Testlimit";
            BinaryName = if ([Environment]::Is64BitOperatingSystem) { "testlimit64.exe" } else { "testlimit32.exe" }
        }
    )

    $ServiceBinaryVersion = "1.38.0"

    # Determine the architecture of the system
    $architecture = if ([Environment]::Is64BitOperatingSystem) { "64" } else { "32" }

    # Define the service binary to download and extract based on architecture
    $serviceBinary = @{
        Name = "windows-chaos-infrastructure";
        DownloadUrl = "https://app.harness.io/public/shared/tools/chaos/windows/$ServiceBinaryVersion/windows-chaos-infrastructure-$architecture.exe.zip";
        Path = "$ChaosBasePath\windows-chaos-infrastructure.exe.zip";
        ExtractPath = "$ChaosBasePath";
        BinaryName = "windows-chaos-infrastructure.exe"
    }

    # Check if the mode is offline
    if ($InstallMode -eq "offline") {
        foreach ($tool in $tools) {
            Verify-AndExportBinary -BinaryPath $tool.ExtractPath -BinaryName $tool.BinaryName
        }

        # Verify windows-chaos-infrastructure binary
        $binaryFullPath = Join-Path -Path $serviceBinary.ExtractPath -ChildPath $serviceBinary.BinaryName
        if (-not (Test-Path $binaryFullPath)) {
            Write-Error "$($serviceBinary.BinaryName) not found at $($serviceBinary.ExtractPath). Exiting installation."
            throw "$($serviceBinary.BinaryName) not found at $($serviceBinary.ExtractPath). Exiting installation."
        } else {
            Verify-AndExportBinary -BinaryPath $serviceBinary.ExtractPath -BinaryName $serviceBinary.BinaryName
        }
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