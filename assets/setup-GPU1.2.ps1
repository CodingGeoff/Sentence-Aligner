# # <#
# # .SYNOPSIS
# # Auto GPU Environment Setup Script with Friendly Logging
# # .DESCRIPTION
# # Version: 4.0.0
# # Features:
# # - Multiple mirror support with automatic fallback
# # - Encouraging progress messages
# # - Clear manual download instructions
# # #>

# # # Configuration
# # $config = @{
# #     BaseDir         = "F:\GPU_Setup"
# #     CudaVersion     = "12.1"
# #     PythonVersion   = "3.10"
# #     MirrorSettings  = @{
# #         Pip         = "https://pypi.tuna.tsinghua.edu.cn/simple"
# #         PipTrust    = "https://pypi.tuna.tsinghua.edu.cn"
# #         Cuda        = @(
# #             "https://mirrors.nju.edu.cn/nvidia/cuda/",
# #             "https://developer.download.nvidia.com/compute/cuda/",
# #             "https://mirrors.aliyun.com/nvidia-cuda/"
# #         )
# #         Cudnn       = @(
# #             "https://mirrors.nju.edu.cn/nvidia/cudnn/",
# #             "https://developer.download.nvidia.com/compute/machine-learning/cudnn/",
# #             "https://mirrors.aliyun.com/nvidia-cuda/"
# #         )
# #     }
# #     LogFile         = "F:\GPU_Setup\install.log"
# # }

# # # Initialize directories
# # $directories = @(
# #     "$($config.BaseDir)\Downloads",
# #     "$($config.BaseDir)\Logs",
# #     "$($config.BaseDir)\Software"
# # )

# # # Logging system with encouragement
# # function Write-Log {
# #     param(
# #         [Parameter(Mandatory=$true)]
# #         [string]$Message,
# #         [ValidateSet("INFO","WARN","ERROR","SUCCESS","ENCOURAGE")]
# #         [string]$Level = "INFO"
# #     )
# #     $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
# #     $logEntry = "[$timestamp][$Level] $Message"
    
# #     try {
# #         [System.IO.File]::AppendAllText($config.LogFile, "$logEntry`n", (New-Object System.Text.UTF8Encoding $true))
# #     }
# #     catch {
# #         Write-Host "Log write failed: $_" -ForegroundColor Red
# #     }

# #     $color = switch ($Level) {
# #         "INFO"       { "Cyan" }
# #         "WARN"       { "Yellow" }
# #         "ERROR"      { "Red" }
# #         "SUCCESS"    { "Green" }
# #         "ENCOURAGE"  { "Magenta" }
# #     }
# #     Write-Host "[$Level] $Message" -ForegroundColor $color
# # }

# # # Enhanced download with multiple mirrors
# # function Download-FileWithRetry {
# #     param(
# #         [string]$UrlPattern,
# #         [string]$Destination,
# #         [int]$RetryCount = 2
# #     )
    
# #     $mirrors = if ($UrlPattern -match "cuda") {
# #         $config.MirrorSettings.Cuda
# #     } else {
# #         $config.MirrorSettings.Cudnn
# #     }

# #     foreach ($mirror in $mirrors) {
# #         $fullUrl = $mirror.TrimEnd('/') + "/" + $UrlPattern.TrimStart('/')
# #         $attempt = 1
        
# #         Write-Log -Message "🌍 Trying mirror: $($mirror.Split('/')[2])..." -Level ENCOURAGE
        
# #         while ($attempt -le $RetryCount) {
# #             try {
# #                 Write-Log -Message "🚀 Download attempt $attempt of $RetryCount" -Level INFO
# #                 $webClient = New-Object System.Net.WebClient
# #                 $webClient.DownloadFile($fullUrl, $Destination)
                
# #                 if (Test-Path $Destination) {
# #                     Write-Log -Message "🎉 Download successful!" -Level SUCCESS
# #                     return $true
# #                 }
# #             }
# #             catch {
# #                 Write-Log -Message "⚠️ Attempt $attempt failed: $($_.Exception.Message)" -Level WARN
# #                 Start-Sleep -Seconds (5 * $attempt)
# #             }
# #             $attempt++
# #         }
# #     }
    
# #     Write-Log -Message "💔 All download attempts failed" -Level ERROR
# #     return $false
# # }

# # # CUDA installation with progress
# # function Install-CUDA {
# #     $cudaUrlPattern = "v$($config.CudaVersion)/local_installers/cuda_$($config.CudaVersion).0_531.14_windows.exe"
# #     $localPath = "$($config.BaseDir)\Downloads\cuda_$($config.CudaVersion).exe"

# #     Write-Log -Message "🌈 Starting CUDA $($config.CudaVersion) setup..." -Level ENCOURAGE
    
# #     if (-not (Download-FileWithRetry -UrlPattern $cudaUrlPattern -Destination $localPath)) {
# #         Write-Log -Message "📥 Manual download needed:" -Level WARN
# #         Write-Log -Message "1. Visit https://developer.nvidia.com/cuda-toolkit-archive" -Level WARN
# #         Write-Log -Message "2. Download CUDA $($config.CudaVersion) installer" -Level WARN
# #         Write-Log -Message "3. Save to: $localPath" -Level WARN
# #         Write-Log -Message "💪 You've got this! We'll wait while you get the file." -Level ENCOURAGE
# #         throw "CUDA setup paused for manual download"
# #     }

# #     try {
# #         Write-Log -Message "⚙️ Installing CUDA - this might take a few minutes..." -Level INFO
# #         $process = Start-Process -FilePath $localPath -ArgumentList @("-s", "nvcc_$($config.CudaVersion)") -Wait -PassThru
        
# #         if ($process.ExitCode -eq 0) {
# #             Write-Log -Message "🎊 CUDA installed successfully!" -Level SUCCESS
# #         }
# #         else {
# #             throw "Installer exited with code $($process.ExitCode)"
# #         }
# #     }
# #     catch {
# #         Write-Log -Message "😟 Installation error: $_" -Level ERROR
# #         throw
# #     }
# # }

# # # cuDNN installation with progress
# # function Install-cuDNN {
# #     $cudnnUrlPattern = "v8.9.7/local_installers/12.x/cudnn-windows-x86_64-8.9.7.29_cuda12-archive.zip"
# #     $localPath = "$($config.BaseDir)\Downloads\cudnn.zip"

# #     Write-Log -Message "🌈 Starting cuDNN setup..." -Level ENCOURAGE
    
# #     if (-not (Download-FileWithRetry -UrlPattern $cudnnUrlPattern -Destination $localPath)) {
# #         Write-Log -Message "📥 Manual download needed:" -Level WARN
# #         Write-Log -Message "1. Visit https://developer.nvidia.com/cudnn" -Level WARN
# #         Write-Log -Message "2. Download cuDNN for CUDA $($config.CudaVersion)" -Level WARN
# #         Write-Log -Message "3. Save to: $localPath" -Level WARN
# #         Write-Log -Message "💪 Almost there! We'll continue once you have the file." -Level ENCOURAGE
# #         throw "cuDNN setup paused for manual download"
# #     }

# #     try {
# #         Write-Log -Message "⚙️ Setting up cuDNN..." -Level INFO
# #         Expand-Archive -Path $localPath -DestinationPath "$($config.BaseDir)\Software\cuDNN" -Force
        
# #         Get-ChildItem "$($config.BaseDir)\Software\cuDNN\*" | ForEach-Object {
# #             Copy-Item "$_\bin\*" "$env:CUDA_PATH\bin" -Force
# #             Copy-Item "$_\include\*" "$env:CUDA_PATH\include" -Force
# #             Copy-Item "$_\lib\*" "$env:CUDA_PATH\lib" -Force
# #         }
# #         Write-Log -Message "🎊 cuDNN configured successfully!" -Level SUCCESS
# #     }
# #     catch {
# #         Write-Log -Message "😟 Configuration error: $_" -Level ERROR
# #         throw
# #     }
# # }

# # # Main workflow
# # try {
# #     # Initialize environment
# #     New-Item -Path $directories -ItemType Directory -Force | Out-Null

# #     Write-Host @"

# #     ██████╗ ██████╗ ██╗   ██╗ █████╗ 
# #     ██╔══██╗██╔══██╗██║   ██║██╔══██╗
# #     ██║  ██║██████╔╝██║   ██║███████║
# #     ██║  ██║██╔═══╝ ██║   ██║██╔══██║
# #     ██████╔╝██║     ╚██████╔╝██║  ██║
# #     ╚═════╝ ╚═╝      ╚═════╝ ╚═╝  ╚═╝
# #      GPU Environment Setup Wizard v4.0
# # "@ -ForegroundColor Magenta

# #     Write-Log -Message "🚀 Starting GPU environment setup!" -Level ENCOURAGE

# #     # CUDA Installation
# #     Install-CUDA

# #     # Set CUDA_PATH
# #     if (-not $env:CUDA_PATH) {
# #         $cudaPath = "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v$($config.CudaVersion)"
# #         [Environment]::SetEnvironmentVariable("CUDA_PATH", $cudaPath, "Machine")
# #         $env:CUDA_PATH = $cudaPath
# #         Write-Log -Message "🔧 Set CUDA_PATH environment variable" -Level INFO
# #     }

# #     # cuDNN Configuration
# #     Install-cuDNN

# #     # Python Environment
# #     Write-Log -Message "🐍 Creating Python virtual environment..." -Level INFO
# #     $venvPath = "$($config.BaseDir)\PythonEnv"
# #     python -m venv $venvPath
# #     Write-Log -Message "🎉 Python environment ready!" -Level SUCCESS

# #     # PyTorch Installation
# #     Write-Log -Message "🔥 Installing PyTorch with GPU support..." -Level ENCOURAGE
# #     & "$venvPath\Scripts\pip.exe" install torch torchvision torchaudio `
# #         --index-url $config.MirrorSettings.Pip `
# #         --trusted-host $config.MirrorSettings.PipTrust
# #     Write-Log -Message "🎉 PyTorch installed successfully!" -Level SUCCESS

# #     # Final Validation
# #     Write-Log -Message "🔍 Running final checks..." -Level INFO
# #     $validation = & "$venvPath\Scripts\python.exe" -c @"
# # import torch
# # print(f"PyTorch Version|{torch.__version__}")
# # print(f"CUDA Available|{torch.cuda.is_available()}")
# # if torch.cuda.is_available():
# #     print(f"GPU Model|{torch.cuda.get_device_name(0)}")
# #     print(f"CUDA Version|{torch.version.cuda}")
# #     print(f"cuDNN Version|{torch.backends.cudnn.version()}")
# # "@

# #     # Display results
# #     $validation | ConvertFrom-Csv -Delimiter "|" -Header "Item", "Value" | Format-Table -AutoSize

# #     Write-Log -Message "🎉🎉 All systems go! Your GPU environment is ready! 🎉🎉" -Level SUCCESS
# # }
# # catch {
# #     Write-Log -Message "😢 Setup paused due to error: $($_.Exception.Message)" -Level ERROR
# #     Write-Log -Message "💡 Check the log file for details: $($config.LogFile)" -Level WARN
# #     exit 1
# # }
# # finally {
# #     Write-Host "`n🌟 Setup process completed! " -NoNewline
# #     Write-Host "Full log available at: " -NoNewline
# #     Write-Host $config.LogFile -ForegroundColor Cyan
# # }


# <#
# .SYNOPSIS
# Official NVIDIA Environment Setup Script
# .DESCRIPTION
# Version: 5.0.0
# Features:
# - Direct download from NVIDIA official sources
# - Clean ASCII interface
# - Detailed manual instructions
# #>

# # Configuration
# $config = @{
#     BaseDir         = "F:\GPU_Setup"
#     CudaVersion     = "12.1"
#     PythonVersion   = "3.10"
#     LogFile         = "F:\GPU_Setup\install.log"
#     OfficialUrls    = @{
#         Cuda     = "https://developer.download.nvidia.com/compute/cuda/12.1.0/local_installers/cuda_12.1.0_531.14_windows.exe"
#         Cudnn    = "https://developer.nvidia.com/downloads/compute/cudnn/secure/8.9.7/local_installers/12.x/cudnn-windows-x86_64-8.9.7.29_cuda12-archive.zip"
#     }
# }

# # Initialize directories
# $directories = @(
#     "$($config.BaseDir)\Downloads",
#     "$($config.BaseDir)\Logs",
#     "$($config.BaseDir)\Software"
# )

# # Robust logging system
# function Write-Log {
#     param(
#         [Parameter(Mandatory=$true)]
#         [string]$Message,
#         [ValidateSet("INFO","WARN","ERROR","SUCCESS")]
#         [string]$Level = "INFO"
#     )
#     $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
#     $logEntry = "[$timestamp][$Level] $Message"
    
#     try {
#         [System.IO.File]::AppendAllText($config.LogFile, "$logEntry`n", [System.Text.Encoding]::UTF8)
#     }
#     catch {
#         Write-Host "Log write failed: $_" -ForegroundColor Red
#     }

#     $color = switch ($Level) {
#         "INFO"    { "Cyan" }
#         "WARN"    { "Yellow" }
#         "ERROR"   { "Red" }
#         "SUCCESS" { "Green" }
#     }
#     Write-Host "[$Level] $Message" -ForegroundColor $color
# }

# # Official download with retry
# function Download-OfficialFile {
#     param(
#         [string]$Url,
#         [string]$Destination,
#         [int]$RetryCount = 3
#     )
#     $attempt = 1
#     while ($attempt -le $RetryCount) {
#         try {
#             Write-Log -Message "Download attempt $attempt (Official Source)" -Level INFO
#             $webClient = New-Object System.Net.WebClient
#             $webClient.DownloadFile($Url, $Destination)
            
#             if (Test-Path $Destination) {
#                 Write-Log -Message "Download completed: $Destination" -Level SUCCESS
#                 return $true
#             }
#         }
#         catch {
#             Write-Log -Message "Download failed: $($_.Exception.Message)" -Level WARN
#             Start-Sleep -Seconds (10 * $attempt)
#         }
#         $attempt++
#     }
    
#     Write-Log -Message "Critical: Failed to download from official source" -Level ERROR
#     Write-Log -Message "Manual steps required:" -Level WARN
#     Write-Log -Message "1. Visit NVIDIA Developer site:"
#     Write-Log -Message "   - CUDA: https://developer.nvidia.com/cuda-downloads" -Level WARN
#     Write-Log -Message "   - cuDNN: https://developer.nvidia.com/cudnn" -Level WARN
#     Write-Log -Message "2. Login with NVIDIA developer account"
#     Write-Log -Message "3. Download files and save to:" -Level WARN
#     Write-Log -Message "   CUDA: $($config.BaseDir)\Downloads\cuda_$($config.CudaVersion).exe" -Level WARN
#     Write-Log -Message "   cuDNN: $($config.BaseDir)\Downloads\cudnn.zip" -Level WARN
#     return $false
# }

# # CUDA Installation
# function Install-CUDA {
#     $localPath = "$($config.BaseDir)\Downloads\cuda_$($config.CudaVersion).exe"

#     if (-not (Download-OfficialFile -Url $config.OfficialUrls.Cuda -Destination $localPath)) {
#         throw "CUDA download failed. Follow manual instructions above."
#     }

#     try {
#         Write-Log -Message "Starting CUDA installation..." -Level INFO
#         $process = Start-Process -FilePath $localPath -ArgumentList @("-s") -Wait -PassThru
        
#         if ($process.ExitCode -ne 0) {
#             throw "Installer exited with code $($process.ExitCode)"
#         }
#         Write-Log -Message "CUDA installed successfully" -Level SUCCESS
#     }
#     catch {
#         Write-Log -Message "Installation error: $_" -Level ERROR
#         throw
#     }
# }

# # cuDNN Installation
# function Install-cuDNN {
#     $localPath = "$($config.BaseDir)\Downloads\cudnn.zip"

#     if (-not (Download-OfficialFile -Url $config.OfficialUrls.Cudnn -Destination $localPath)) {
#         throw "cuDNN download failed. Follow manual instructions above."
#     }

#     try {
#         Write-Log -Message "Extracting cuDNN package..." -Level INFO
#         Expand-Archive -Path $localPath -DestinationPath "$($config.BaseDir)\Software\cuDNN" -Force
        
#         Get-ChildItem "$($config.BaseDir)\Software\cuDNN\*" | ForEach-Object {
#             Copy-Item "$_\bin\*" "$env:CUDA_PATH\bin" -Force
#             Copy-Item "$_\include\*" "$env:CUDA_PATH\include" -Force
#             Copy-Item "$_\lib\*" "$env:CUDA_PATH\lib" -Force
#         }
#         Write-Log -Message "cuDNN configured successfully" -Level SUCCESS
#     }
#     catch {
#         Write-Log -Message "Configuration error: $_" -Level ERROR
#         throw
#     }
# }

# # Main Process
# try {
#     # Initialize
#     New-Item -Path $directories -ItemType Directory -Force | Out-Null
#     Write-Host @"

#     ====================================
#     NVIDIA Environment Setup Wizard v5.0
#     ====================================
#     Official Source Edition
#     Log file: $($config.LogFile)
# "@ -ForegroundColor Cyan

#     Write-Log -Message "Initializing GPU environment setup" -Level INFO

#     # CUDA Setup
#     Install-CUDA

#     # Set CUDA_PATH
#     if (-not $env:CUDA_PATH) {
#         $cudaPath = "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v$($config.CudaVersion)"
#         [Environment]::SetEnvironmentVariable("CUDA_PATH", $cudaPath, "Machine")
#         $env:CUDA_PATH = $cudaPath
#         Write-Log -Message "System environment variable CUDA_PATH set" -Level INFO
#     }

#     # cuDNN Setup
#     Install-cuDNN

#     # Python Environment
#     Write-Log -Message "Creating Python virtual environment" -Level INFO
#     $venvPath = "$($config.BaseDir)\PythonEnv"
#     & python -m venv $venvPath
#     Write-Log -Message "Virtual environment created at $venvPath" -Level SUCCESS

#     # PyTorch Installation
#     Write-Log -Message "Installing PyTorch with CUDA support" -Level INFO
#     & "$venvPath\Scripts\pip.exe" install torch torchvision torchaudio
#     Write-Log -Message "PyTorch installation completed" -Level SUCCESS

#     # Validation
#     $validation = & "$venvPath\Scripts\python.exe" -c @"
# import torch
# print(f"PyTorch Version|{torch.__version__}")
# print(f"CUDA Available|{torch.cuda.is_available()}")
# if torch.cuda.is_available():
#     print(f"GPU Model|{torch.cuda.get_device_name(0)}")
#     print(f"CUDA Version|{torch.version.cuda}")
#     print(f"cuDNN Version|{torch.backends.cudnn.version()}")
# "@

#     # Display Results
#     $validation | ConvertFrom-Csv -Delimiter "|" -Header "Component", "Value" | Format-Table -AutoSize

#     Write-Log -Message "Environment setup completed successfully" -Level SUCCESS
# }
# catch {
#     Write-Log -Message "Setup failed: $($_.Exception.Message)" -Level ERROR
#     Write-Log -Message "Consult log file for details: $($config.LogFile)" -Level WARN
#     exit 1
# }
# finally {
#     Write-Host "`nOperation completed. Review log at: " -NoNewline
#     Write-Host $config.LogFile -ForegroundColor Cyan
# }

<#
.SYNOPSIS
NVIDIA Environment Setup Script with Local File Detection
.DESCRIPTION
Version: 6.0.0
Features:
- Official NVIDIA sources
- Local file detection
- Comprehensive error handling
#>

$config = @{
    BaseDir         = "F:\GPU_Setup"
    CudaVersion     = "12.1"
    PythonVersion   = "3.10"
    LogFile         = "F:\GPU_Setup\install.log"
    OfficialUrls    = @{
        Cuda     = "https://developer.download.nvidia.com/compute/cuda/12.1.0/local_installers/cuda_12.1.0_531.14_windows.exe"
        Cudnn    = "https://developer.nvidia.com/downloads/compute/cudnn/secure/8.9.7/local_installers/12.x/cudnn-windows-x86_64-8.9.7.29_cuda12-archive.zip"
    }
    RequiredFiles   = @{
        Cuda     = "F:\GPU_Setup\Downloads\cuda_12.1.exe"
        Cudnn    = "F:\GPU_Setup\Downloads\cudnn.zip"
    }
}

# Initialize directories
$directories = @(
    "$($config.BaseDir)\Downloads",
    "$($config.BaseDir)\Logs",
    "$($config.BaseDir)\Software"
)

function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [ValidateSet("INFO","WARN","ERROR","SUCCESS")]
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp][$Level] $Message"
    
    try {
        [System.IO.File]::AppendAllText($config.LogFile, "$logEntry`n", [System.Text.Encoding]::UTF8)
    }
    catch {
        Write-Host "Log write failed: $_" -ForegroundColor Red
    }

    $color = switch ($Level) {
        "INFO"    { "Cyan" }
        "WARN"    { "Yellow" }
        "ERROR"   { "Red" }
        "SUCCESS" { "Green" }
    }
    Write-Host "[$Level] $Message" -ForegroundColor $color
}

function Test-FileExists {
    param(
        [string]$Path,
        [int]$MinSizeMB = 10
    )
    try {
        if (Test-Path $Path) {
            $file = Get-Item $Path
            if ($file.Length -gt ($MinSizeMB * 1MB)) {
                Write-Log -Message "Local file detected: $Path" -Level INFO
                return $true
            }
            Write-Log -Message "File too small, needs redownload: $Path" -Level WARN
        }
        return $false
    }
    catch {
        Write-Log -Message "File check failed: $_" -Level ERROR
        return $false
    }
}

function Download-FileWithRetry {
    param(
        [string]$Url,
        [string]$Destination,
        [int]$RetryCount = 3
    )
    
    # Skip download if valid file exists
    if (Test-FileExists -Path $Destination) {
        return $true
    }

    $attempt = 1
    while ($attempt -le $RetryCount) {
        try {
            Write-Log -Message "Download attempt $attempt/$RetryCount from official source" -Level INFO
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($Url, $Destination)
            
            if (Test-FileExists -Path $Destination) {
                Write-Log -Message "Download completed successfully" -Level SUCCESS
                return $true
            }
        }
        catch {
            Write-Log -Message "Download failed: $($_.Exception.Message)" -Level WARN
            Start-Sleep -Seconds (10 * $attempt)
        }
        $attempt++
    }
    
    if (Test-FileExists -Path $Destination) {
        Write-Log -Message "Using existing file despite download errors" -Level WARN
        return $true
    }
    
    Write-Log -Message "Critical download failure after $RetryCount attempts" -Level ERROR
    return $false
}

function Install-CUDA {
    try {
        # Check for existing installer
        if (-not (Test-FileExists -Path $config.RequiredFiles.Cuda)) {
            if (-not (Download-FileWithRetry -Url $config.OfficialUrls.Cuda -Destination $config.RequiredFiles.Cuda)) {
                throw "CUDA setup requires manual download. Save to: $($config.RequiredFiles.Cuda)"
            }
        }

        Write-Log -Message "Starting CUDA installation..." -Level INFO
        $process = Start-Process -FilePath $config.RequiredFiles.Cuda -ArgumentList @("-s") -Wait -PassThru
        
        if ($process.ExitCode -ne 0) {
            throw "Installer exited with code $($process.ExitCode)"
        }
        Write-Log -Message "CUDA installation validated" -Level SUCCESS
    }
    catch {
        Write-Log -Message "CUDA installation failed: $_" -Level ERROR
        throw
    }
}

function Install-cuDNN {
    try {
        # Check for existing package
        if (-not (Test-FileExists -Path $config.RequiredFiles.Cudnn)) {
            throw "cuDNN package not found. Download from NVIDIA website and save to: $($config.RequiredFiles.Cudnn)"
        }

        Write-Log -Message "Extracting cuDNN package..." -Level INFO
        Expand-Archive -Path $config.RequiredFiles.Cudnn -DestinationPath "$($config.BaseDir)\Software\cuDNN" -Force
        
        Get-ChildItem "$($config.BaseDir)\Software\cuDNN\*" | ForEach-Object {
            Copy-Item "$_\bin\*" "$env:CUDA_PATH\bin" -Force
            Copy-Item "$_\include\*" "$env:CUDA_PATH\include" -Force
            Copy-Item "$_\lib\*" "$env:CUDA_PATH\lib" -Force
        }
        Write-Log -Message "cuDNN configuration completed" -Level SUCCESS
    }
    catch {
        Write-Log -Message "cuDNN installation failed: $_" -Level ERROR
        throw
    }
}

try {
    # Initialize environment
    New-Item -Path $directories -ItemType Directory -Force | Out-Null
    Write-Host @"

    ====================================
    NVIDIA Environment Setup Wizard v6.0
    ====================================
    Local File Detection Edition
    Log file: $($config.LogFile)
"@ -ForegroundColor Cyan

    Write-Log -Message "Initializing setup process" -Level INFO

    # CUDA Setup
    Install-CUDA

    # Set CUDA_PATH
    if (-not $env:CUDA_PATH) {
        $cudaPath = "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v$($config.CudaVersion)"
        [Environment]::SetEnvironmentVariable("CUDA_PATH", $cudaPath, "Machine")
        $env:CUDA_PATH = $cudaPath
        Write-Log -Message "System environment configured" -Level INFO
    }

    # cuDNN Setup
    Install-cuDNN

    # Python Environment
    Write-Log -Message "Creating Python virtual environment" -Level INFO
    $venvPath = "$($config.BaseDir)\PythonEnv"
    & python -m venv $venvPath
    Write-Log -Message "Virtual environment created" -Level SUCCESS

    # PyTorch Installation
    Write-Log -Message "Installing PyTorch components" -Level INFO
    & "$venvPath\Scripts\pip.exe" install torch torchvision torchaudio
    Write-Log -Message "PyTorch installation completed" -Level SUCCESS

    # Validation
    $validation = & "$venvPath\Scripts\python.exe" -c @"
import torch
print(f"PyTorch Version|{torch.__version__}")
print(f"CUDA Available|{torch.cuda.is_available()}")
if torch.cuda.is_available():
    print(f"GPU Model|{torch.cuda.get_device_name(0)}")
    print(f"CUDA Version|{torch.version.cuda}")
    print(f"cuDNN Version|{torch.backends.cudnn.version()}")
"@

    # Display Results
    $validation | ConvertFrom-Csv -Delimiter "|" -Header "Component", "Value" | Format-Table -AutoSize

    Write-Log -Message "Environment setup completed successfully" -Level SUCCESS
}
catch {
    Write-Log -Message "Setup process failed: $($_.Exception.Message)" -Level ERROR
    Write-Log -Message "Manual steps required:" -Level WARN
    Write-Log -Message "1. Download required files:" -Level WARN
    Write-Log -Message "   - CUDA: $($config.RequiredFiles.Cuda)" -Level WARN
    Write-Log -Message "   - cuDNN: $($config.RequiredFiles.Cudnn)" -Level WARN
    Write-Log -Message "2. Place files in specified locations" -Level WARN
    Write-Log -Message "3. Rerun this script" -Level WARN
    exit 1
}
finally {
    Write-Host "`nProcess completed. Review log at: " -NoNewline
    Write-Host $config.LogFile -ForegroundColor Cyan
}