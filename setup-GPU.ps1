# # # # # # <#
# # # # # # .SYNOPSIS
# # # # # # Auto GPU Environment Setup Script with Encouraging Logging
# # # # # # .DESCRIPTION
# # # # # # Version: 7.0.0
# # # # # # Features:
# # # # # # - Dual-source download (Official + Mirror)
# # # # # # - Smart local file detection
# # # # # # - Version compatibility verification
# # # # # # - Automatic log archiving
# # # # # # - Multi-stage integrity checks
# # # # # # #>

# # # # # # # Configuration
# # # # # # $config = @{
# # # # # #     BaseDir         = "F:\GPU_Setup"    # Base directory
# # # # # #     CudaVersion     = "12.1"           # CUDA main version
# # # # # #     CudnnVersion    = "8.9.7"          # cuDNN version
# # # # # #     PythonVersion   = "3.10"           # Python version
# # # # # #     MinFileSizeMB   = 100              # Minimum file size threshold (MB)
# # # # # #     RetryCount      = 3                # Download retry attempts
# # # # # #     LogFile         = "install.log"    # Log file name
# # # # # #     Sources = @{
# # # # # #         Official = @{
# # # # # #             Cuda  = "https://developer.download.nvidia.com/compute/cuda/12.1.0/local_installers/cuda_12.1.0_531.14_windows.exe"
# # # # # #             Cudnn = "https://developer.nvidia.com/downloads/compute/cudnn/secure/8.9.7/local_installers/12.x/cudnn-windows-x86_64-8.9.7.29_cuda12-archive.zip"
# # # # # #         }
# # # # # #         Mirror = @{
# # # # # #             Cuda  = @(
# # # # # #                 "https://mirrors.nju.edu.cn/nvidia/cuda/12.1.0/local_installers/cuda_12.1.0_531.14_windows.exe",
# # # # # #                 "https://mirrors.aliyun.com/nvidia-cuda/12.1.0/local_installers/cuda_12.1.0_531.14_windows.exe"
# # # # # #             )
# # # # # #             Cudnn = @(
# # # # # #                 "https://mirrors.nju.edu.cn/nvidia/cudnn/8.9.7/local_installers/12.x/cudnn-windows-x86_64-8.9.7.29_cuda12-archive.zip",
# # # # # #                 "https://mirrors.aliyun.com/nvidia-cuda/8.9.7/local_installers/12.x/cudnn-windows-x86_64-8.9.7.29_cuda12-archive.zip"
# # # # # #             )
# # # # # #         }
# # # # # #     }
# # # # # #     FileHashes = @{  # SHA256 hashes
# # # # # #         Cuda  = "A1B2C3D4E5F6..."  # Replace with actual hash
# # # # # #         Cudnn = "B2C3D4E5F6A1..."  # Replace with actual hash
# # # # # #     }
# # # # # # }

# # # # # # # Initialize directories
# # # # # # $directories = @(
# # # # # #     "Downloads",
# # # # # #     "Logs",
# # # # # #     "Software",
# # # # # #     "PythonEnv"
# # # # # # ) | ForEach-Object { Join-Path $config.BaseDir $_ }

# # # # # # # Logging system initialization
# # # # # # function Initialize-Logging {
# # # # # #     param($logPath)
# # # # # #     $archiveLog = Join-Path $config.BaseDir "Logs\install_$(Get-Date -Format 'yyyyMMdd').log"
# # # # # #     if (Test-Path $logPath) {
# # # # # #         Move-Item $logPath $archiveLog -Force
# # # # # #     }
# # # # # #     New-Item -Path (Split-Path $logPath) -ItemType Directory -Force | Out-Null
# # # # # # }

# # # # # # # Enhanced logging with encouragement
# # # # # # function Write-Log {
# # # # # #     param($Message, $Level = "INFO")
# # # # # #     $logEntry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')][$Level] $Message"
# # # # # #     Add-Content -Path $config.LogFile -Value $logEntry -Encoding UTF8
    
# # # # # #     $emoji = switch ($Level) {
# # # # # #         "INFO"    { "ℹ️" }
# # # # # #         "WARN"    { "⚠️" }
# # # # # #         "ERROR"   { "❌" }
# # # # # #         "SUCCESS" { "✅" }
# # # # # #     }
    
# # # # # #     Write-Host "$emoji [$Level] $Message" -ForegroundColor @{
# # # # # #         "INFO"    = "Cyan"
# # # # # #         "WARN"    = "Yellow"
# # # # # #         "ERROR"   = "Red"
# # # # # #         "SUCCESS" = "Green"
# # # # # #     }[$Level]
# # # # # # }

# # # # # # # File integrity verification
# # # # # # function Test-FileIntegrity {
# # # # # #     param($Path, $ExpectedHash)
# # # # # #     try {
# # # # # #         $actualHash = (Get-FileHash $Path -Algorithm SHA256).Hash
# # # # # #         return $actualHash -eq $ExpectedHash
# # # # # #     } catch {
# # # # # #         Write-Log "File verification failed: $_" -Level ERROR
# # # # # #         return $false
# # # # # #     }
# # # # # # }

# # # # # # # Smart downloader with encouragement
# # # # # # function Get-IntelligentDownload {
# # # # # #     param($FileName, $Urls, $ExpectedHash)
    
# # # # # #     $localPath = Join-Path $config.BaseDir "Downloads\$FileName"
    
# # # # # #     # Local file check
# # # # # #     if (Test-Path $localPath) {
# # # # # #         if ((Get-Item $localPath).Length -gt ($config.MinFileSizeMB * 1MB)) {
# # # # # #             if (Test-FileIntegrity $localPath $ExpectedHash) {
# # # # # #                 Write-Log "🌈 Valid local file detected: $FileName" -Level SUCCESS
# # # # # #                 return $true
# # # # # #             }
# # # # # #             Write-Log "🔄 Local file verification failed, re-downloading..." -Level WARN
# # # # # #         }
# # # # # #     }

# # # # # #     # Multi-source download
# # # # # #     foreach ($baseUrl in $Urls) {
# # # # # #         $attempt = 1
# # # # # #         while ($attempt -le $config.RetryCount) {
# # # # # #             try {
# # # # # #                 $fullUrl = $baseUrl.TrimEnd('/') + "/" + $FileName
# # # # # #                 Write-Log "🚀 Attempting download from $($baseUrl.Split('/')[2]) (Attempt $attempt)" -Level INFO
                
# # # # # #                 (New-Object Net.WebClient).DownloadFile($fullUrl, $localPath)
                
# # # # # #                 if (Test-FileIntegrity $localPath $ExpectedHash) {
# # # # # #                     Write-Log "🎉 Download verification successful!" -Level SUCCESS
# # # # # #                     return $true
# # # # # #                 }
# # # # # #                 Write-Log "⚠️ Downloaded file verification failed" -Level WARN
# # # # # #             } catch {
# # # # # #                 Write-Log "🌧️ Download attempt failed: $($_.Exception.Message)" -Level WARN
# # # # # #             }
# # # # # #             $attempt++
# # # # # #         }
# # # # # #     }
    
# # # # # #     Write-Log "💔 All download sources failed, manual download required:" -Level ERROR
# # # # # #     Write-Log "💡 Please download $FileName from NVIDIA website" -Level WARN
# # # # # #     Write-Log "🔗 CUDA: https://developer.nvidia.com/cuda-downloads" -Level WARN
# # # # # #     Write-Log "🔗 cuDNN: https://developer.nvidia.com/cudnn" -Level WARN
# # # # # #     Write-Log "💪 You've got this! Place the file in: $localPath and try again!" -Level SUCCESS
# # # # # #     return $false
# # # # # # }

# # # # # # # CUDA Installation Module
# # # # # # function Install-CUDA {
# # # # # #     $fileName = "cuda_$($config.CudaVersion).exe"
# # # # # #     if (-not (Get-IntelligentDownload -FileName $fileName -Urls ($config.Sources.Official.Cuda + $config.Sources.Mirror.Cuda) -ExpectedHash $config.FileHashes.Cuda)) {
# # # # # #         throw "🚨 CUDA installation file acquisition failed"
# # # # # #     }

# # # # # #     try {
# # # # # #         Write-Log "⚙️ Starting CUDA installation..." -Level INFO
# # # # # #         $process = Start-Process -FilePath (Join-Path $config.BaseDir "Downloads\$fileName") -ArgumentList @("-s") -Wait -PassThru
# # # # # #         if ($process.ExitCode -ne 0) {
# # # # # #             throw "Installer returned error code: $($process.ExitCode)"
# # # # # #         }
        
# # # # # #         # Environment verification
# # # # # #         if (-not $env:CUDA_PATH) {
# # # # # #             $cudaPath = "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v$($config.CudaVersion)"
# # # # # #             [Environment]::SetEnvironmentVariable("CUDA_PATH", $cudaPath, "Machine")
# # # # # #             $env:CUDA_PATH = $cudaPath
# # # # # #         }
# # # # # #         Write-Log "🎊 CUDA installation validated!" -Level SUCCESS
# # # # # #     } catch {
# # # # # #         Write-Log "😟 CUDA installation failed: $_" -Level ERROR
# # # # # #         throw
# # # # # #     }
# # # # # # }

# # # # # # # cuDNN Configuration Module
# # # # # # function Install-cuDNN {
# # # # # #     $fileName = "cudnn.zip"
# # # # # #     if (-not (Get-IntelligentDownload -FileName $fileName -Urls ($config.Sources.Official.Cudnn + $config.Sources.Mirror.Cudnn) -ExpectedHash $config.FileHashes.Cudnn)) {
# # # # # #         throw "🚨 cuDNN installation file acquisition failed"
# # # # # #     }

# # # # # #     try {
# # # # # #         Write-Log "⚙️ Configuring cuDNN..." -Level INFO
# # # # # #         $extractPath = Join-Path $config.BaseDir "Software\cuDNN"
# # # # # #         Expand-Archive -Path (Join-Path $config.BaseDir "Downloads\$fileName") -DestinationPath $extractPath -Force
        
# # # # # #         # File deployment
# # # # # #         Get-ChildItem "$extractPath\*" | ForEach-Object {
# # # # # #             $subDir = $_.FullName
# # # # # #             Copy-Item "$subDir\bin\*" "$env:CUDA_PATH\bin" -Force
# # # # # #             Copy-Item "$subDir\include\*" "$env:CUDA_PATH\include" -Force
# # # # # #             Copy-Item "$subDir\lib\*" "$env:CUDA_PATH\lib" -Force
# # # # # #         }
# # # # # #         Write-Log "🎉 cuDNN configuration complete!" -Level SUCCESS
# # # # # #     } catch {
# # # # # #         Write-Log "😟 cuDNN configuration failed: $_" -Level ERROR
# # # # # #         throw
# # # # # #     }
# # # # # # }

# # # # # # # Python Environment Setup
# # # # # # function Initialize-PythonEnv {
# # # # # #     try {
# # # # # #         Write-Log "🐍 Creating Python virtual environment..." -Level INFO
# # # # # #         $venvPath = Join-Path $config.BaseDir "PythonEnv"
# # # # # #         & python -m venv $venvPath
# # # # # #         if (-not (Test-Path "$venvPath\Scripts\python.exe")) {
# # # # # #             throw "Virtual environment creation failed"
# # # # # #         }
# # # # # #         Write-Log "🎉 Python environment ready!" -Level SUCCESS
# # # # # #     } catch {
# # # # # #         Write-Log "😟 Python environment initialization failed: $_" -Level ERROR
# # # # # #         throw
# # # # # #     }
# # # # # # }

# # # # # # # Final Validation
# # # # # # function Invoke-Validation {
# # # # # #     try {
# # # # # #         Write-Log "🔍 Running final checks..." -Level INFO
# # # # # #         $venvPython = Join-Path $config.BaseDir "PythonEnv\Scripts\python.exe"
# # # # # #         $output = & $venvPython -c @"
# # # # # # import torch
# # # # # # print(f"PyTorch Version|{torch.__version__}")
# # # # # # print(f"CUDA Available|{torch.cuda.is_available()}")
# # # # # # if torch.cuda.is_available():
# # # # # #     print(f"GPU Name|{torch.cuda.get_device_name(0)}")
# # # # # #     print(f"CUDA Version|{torch.version.cuda}")
# # # # # #     print(f"cuDNN Version|{torch.backends.cudnn.version()}")
# # # # # # "@

# # # # # #         $results = $output | ConvertFrom-Csv -Delimiter "|" -Header "Component", "Value"
# # # # # #         $results | Format-Table -AutoSize
        
# # # # # #         if ($results.Where{ $_.Component -eq "CUDA Available" }.Value -ne "True") {
# # # # # #             throw "CUDA not available"
# # # # # #         }
# # # # # #         Write-Log "🎉 All components validated successfully!" -Level SUCCESS
# # # # # #     } catch {
# # # # # #         Write-Log "😟 Validation failed: $_" -Level ERROR
# # # # # #         throw
# # # # # #     }
# # # # # # }

# # # # # # # Main Workflow
# # # # # # try {
# # # # # #     # Initialization
# # # # # #     $config.LogFile = Join-Path $config.BaseDir "Logs\$($config.LogFile)"
# # # # # #     Initialize-Logging -logPath $config.LogFile
# # # # # #     $directories | ForEach-Object { New-Item -Path $_ -ItemType Directory -Force | Out-Null }

# # # # # #     Write-Host @"

# # # # # #     ██████╗ ██████╗ ██╗   ██╗ █████╗     ██████╗ ██████╗  ██████╗ 
# # # # # #     ██╔══██╗██╔══██╗██║   ██║██╔══██╗    ██╔══██╗██╔══██╗██╔════╝ 
# # # # # #     ██║  ██║██████╔╝██║   ██║███████║    ██║  ██║██████╔╝██║  ███╗
# # # # # #     ██║  ██║██╔═══╝ ██║   ██║██╔══██║    ██║  ██║██╔═══╝ ██║   ██║
# # # # # #     ██████╔╝██║     ╚██████╔╝██║  ██║    ██████╔╝██║     ╚██████╔╝
# # # # # #     ╚═════╝ ╚═╝      ╚═════╝ ╚═╝  ╚═╝    ╚═════╝ ╚═╝      ╚═════╝ 
# # # # # #     NVIDIA Environment Automation System v7.0
# # # # # # "@ -ForegroundColor Cyan

# # # # # #     # Installation Process
# # # # # #     Install-CUDA
# # # # # #     Install-cuDNN
# # # # # #     Initialize-PythonEnv
# # # # # #     Invoke-Validation

# # # # # #     Write-Log "🎉🎉 Environment setup completed successfully! 🎉🎉" -Level SUCCESS
# # # # # # }
# # # # # # catch {
# # # # # #     Write-Log "💥 Critical error in main workflow: $($_.Exception.Message)" -Level ERROR
# # # # # #     Write-Log "🛠️ Troubleshooting suggestions:" -Level WARN
# # # # # #     Write-Log "1. Check internet connection" -Level WARN
# # # # # #     Write-Log "2. Verify local file integrity" -Level WARN
# # # # # #     Write-Log "3. Confirm system requirements" -Level WARN
# # # # # #     Write-Log "4. Review detailed log: $($config.LogFile)" -Level WARN
# # # # # #     exit 1
# # # # # # }
# # # # # # finally {
# # # # # #     Write-Host "`n🏁 Operation completed. Log file location: " -NoNewline
# # # # # #     Write-Host $config.LogFile -ForegroundColor Cyan
# # # # # # }

# # # # # <#
# # # # # .SYNOPSIS
# # # # # Non-C Drive GPU Setup Assistant
# # # # # .DESCRIPTION
# # # # # Version: 10.0.0
# # # # # Features:
# # # # # - Avoids C drive for large files 🚫💾
# # # # # - Flexible file name detection 🔍
# # # # # - Clear storage guidance 📊
# # # # # - Progress visualization 📈
# # # # # #>

# # # # # # Configuration
# # # # # $config = @{
# # # # #     BaseDir         = "F:\GPU_Setup"  # All large files stay here
# # # # #     TargetCuda      = "12.1"          # Version flexible
# # # # #     MinFileSizeMB   = @{
# # # # #         CUDA  = 2500      # ~2.5GB
# # # # #         cuDNN = 300       # ~300MB
# # # # #     }
# # # # # }

# # # # # # Derived paths (all on F: drive)
# # # # # $paths = @{
# # # # #     Downloads = Join-Path $config.BaseDir "Downloads"
# # # # #     Software  = Join-Path $config.BaseDir "Software"
# # # # #     CUDAHome  = Join-Path $config.BaseDir "NVIDIA\CUDA"
# # # # #     Logs      = Join-Path $config.BaseDir "Logs"
# # # # # }

# # # # # # Initialize directories
# # # # # $paths.Values | ForEach-Object {
# # # # #     if (-not (Test-Path $_)) { New-Item -Path $_ -ItemType Directory -Force | Out-Null }
# # # # # }

# # # # # # Visual Logging System
# # # # # function Write-VisualLog {
# # # # #     param($Message, $Level = "INFO")
# # # # #     $color = switch ($Level) {
# # # # #         "INFO"    { "Cyan" }
# # # # #         "WARN"    { "Yellow" }
# # # # #         "ERROR"   { "Red" }
# # # # #         "SUCCESS" { "Green" }
# # # # #         "TIP"     { "Magenta" }
# # # # #     }
    
# # # # #     $logEntry = "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Message"
# # # # #     Add-Content -Path (Join-Path $paths.Logs "install.log") -Value $logEntry
    
# # # # #     Write-Host $logEntry -ForegroundColor $color
# # # # # }

# # # # # # Smart File Finder
# # # # # function Find-GPUFile {
# # # # #     param($Type)
    
# # # # #     $patterns = @{
# # # # #         CUDA  = @('cuda_*_windows.exe', 'cuda_*_win.exe')
# # # # #         cuDNN = @('cudnn-*.zip', 'cudnn-windows-*.zip')
# # # # #     }

# # # # #     $minSize = $config.MinFileSizeMB[$Type] * 1MB
    
# # # # #     Get-ChildItem $paths.Downloads -File | Where-Object {
# # # # #         $_.Length -ge $minSize -and
# # # # #         ($patterns[$Type] | Where-Object { $_.Name -like $_ })
# # # # #     } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
# # # # # }

# # # # # # CUDA Installation with Custom Path
# # # # # function Install-CUDANonC {
# # # # #     Write-VisualLog "Starting CUDA setup on F: drive" -Level INFO
    
# # # # #     $cudaInstaller = Find-GPUFile -Type CUDA
# # # # #     if (-not $cudaInstaller) {
# # # # #         Write-VisualLog "Let's get CUDA installer:" -Level TIP
# # # # #         Write-VisualLog "1. Visit https://developer.nvidia.com/cuda-downloads" -Level TIP
# # # # #         Write-VisualLog "2. Download CUDA $($config.TargetCuda)" -Level TIP
# # # # #         Write-VisualLog "3. Save to: $($paths.Downloads)" -Level TIP
# # # # #         throw "CUDA installer needed - you're doing great! 👍"
# # # # #     }

# # # # #     try {
# # # # #         Write-VisualLog "Installing CUDA from: $($cudaInstaller.Name)" -Level INFO
# # # # #         $installArgs = @(
# # # # #             "-s",
# # # # #             "nvcc_$($config.TargetCuda)",
# # # # #             "visual_studio_integration=0",  # Skip VS integration
# # # # #             "installpath=$($paths.CUDAHome)"
# # # # #         )
        
# # # # #         $process = Start-Process -FilePath $cudaInstaller.FullName -ArgumentList $installArgs -Wait -PassThru
        
# # # # #         if ($process.ExitCode -ne 0) {
# # # # #             throw "Installer exited with code: $($process.ExitCode)"
# # # # #         }
        
# # # # #         # Verify installation
# # # # #         $cudaExe = Join-Path $paths.CUDAHome "bin\nvcc.exe"
# # # # #         if (-not (Test-Path $cudaExe)) {
# # # # #             throw "CUDA installation verification failed"
# # # # #         }
        
# # # # #         Write-VisualLog "CUDA successfully installed on F: drive!" -Level SUCCESS
# # # # #     }
# # # # #     catch {
# # # # #         Write-VisualLog "Installation challenge: $_" -Level ERROR
# # # # #         Write-VisualLog "Check these solutions:" -Level TIP
# # # # #         Write-VisualLog "- Run as Administrator" -Level TIP
# # # # #         Write-VisualLog "- Disable antivirus temporarily" -Level TIP
# # # # #         throw
# # # # #     }
# # # # # }

# # # # # # cuDNN Configuration
# # # # # function Install-cuDNNNonC {
# # # # #     Write-VisualLog "Starting cuDNN configuration" -Level INFO
    
# # # # #     $cudnnPackage = Find-GPUFile -Type cuDNN
# # # # #     if (-not $cudnnPackage) {
# # # # #         Write-VisualLog "Let's get cuDNN package:" -Level TIP
# # # # #         Write-VisualLog "1. Visit https://developer.nvidia.com/cudnn" -Level TIP
# # # # #         Write-VisualLog "2. Download for CUDA $($config.TargetCuda)" -Level TIP
# # # # #         Write-VisualLog "3. Save to: $($paths.Downloads)" -Level TIP
# # # # #         throw "cuDNN package needed - almost there! 🏁"
# # # # #     }

# # # # #     try {
# # # # #         Write-VisualLog "Processing cuDNN package: $($cudnnPackage.Name)" -Level INFO
# # # # #         $extractPath = Join-Path $paths.Software "cuDNN"
# # # # #         Expand-Archive -Path $cudnnPackage.FullName -DestinationPath $extractPath -Force
        
# # # # #         # Copy files to CUDA installation
# # # # #         $cudaTarget = Join-Path $paths.CUDAHome "v$($config.TargetCuda)"
# # # # #         Get-ChildItem "$extractPath\*" | ForEach-Object {
# # # # #             $subDir = $_.FullName
# # # # #             Copy-Item "$subDir\bin\*" "$cudaTarget\bin" -Force
# # # # #             Copy-Item "$subDir\include\*" "$cudaTarget\include" -Force
# # # # #             Copy-Item "$subDir\lib\*" "$cudaTarget\lib" -Force
# # # # #         }
        
# # # # #         Write-VisualLog "cuDNN configured successfully on F: drive!" -Level SUCCESS
# # # # #     }
# # # # #     catch {
# # # # #         Write-VisualLog "Configuration error: $_" -Level ERROR
# # # # #         Write-VisualLog "Potential fixes:" -Level TIP
# # # # #         Write-VisualLog "- Check file permissions" -Level TIP
# # # # #         Write-VisualLog "- Verify zip file integrity" -Level TIP
# # # # #         throw
# # # # #     }
# # # # # }

# # # # # # Main Installation Flow
# # # # # try {
# # # # #     Write-Host @"
    
# # # # #     ░██████╗░██████╗░██╗░░░██╗  ░██████╗░██████╗░███████╗
# # # # #     ██╔════╝░██╔══██╗██║░░░██║  ██╔════╝░██╔══██╗██╔════╝
# # # # #     ██║░░██╗░██████╔╝██║░░░██║  ██║░░██╗░██████╔╝█████╗░░
# # # # #     ██║░░╚██╗██╔═══╝░██║░░░██║  ██║░░╚██╗██╔═══╝░██╔══╝░░
# # # # #     ╚██████╔╝██║░░░░░╚██████╔╝  ╚██████╔╝██║░░░░░███████╗
# # # # #     ░╚═════╝░╚═╝░░░░░░╚═════╝░  ░╚═════╝░╚═╝░░░░░╚══════╝
# # # # #                 Non-C Drive Installation Specialist
# # # # # "@ -ForegroundColor Cyan

# # # # #     # Installation Process
# # # # #     Install-CUDANonC
# # # # #     Install-cuDNNNonC

# # # # #     Write-VisualLog "All components installed successfully! 🎉" -Level SUCCESS
# # # # #     Write-VisualLog "Final Steps:" -Level TIP
# # # # #     Write-VisualLog "1. Add to PATH: $($paths.CUDAHome)\bin" -Level TIP
# # # # #     Write-VisualLog "2. Restart your system" -Level TIP
# # # # # }
# # # # # catch {
# # # # #     Write-VisualLog "Setup paused: $($_.Exception.Message)" -Level ERROR
# # # # #     Write-VisualLog "Remember:" -Level TIP
# # # # #     Write-VisualLog "- You can retry anytime!" -Level TIP
# # # # #     Write-VisualLog "- Check F:\GPU_Setup\Logs\install.log" -Level TIP
# # # # #     exit 1
# # # # # }
# # # # # finally {
# # # # #     Write-Host "`n💾 Storage Summary (F: drive usage):"
# # # # #     Get-ChildItem $paths.BaseDir -Recurse | 
# # # # #         Measure-Object -Property Length -Sum | 
# # # # #         ForEach-Object {
# # # # #             $totalGB = [math]::Round($_.Sum / 1GB, 2)
# # # # #             Write-Host "Total space used: $totalGB GB" -ForegroundColor Yellow
# # # # #         }
# # # # # }



# # # # <#
# # # # .SYNOPSIS
# # # # Flexible GPU Setup Assistant
# # # # .DESCRIPTION
# # # # Version: 10.1.0
# # # # Features:
# # # # - Enhanced file pattern matching
# # # # - Clear installation guidance
# # # # - Better error diagnostics
# # # # #>

# # # # $config = @{
# # # #     BaseDir         = "F:\GPU_Setup"
# # # #     TargetCuda      = "12.1"
# # # #     MinFileSizeMB   = @{
# # # #         CUDA  = 2500
# # # #         cuDNN = 300
# # # #     }
# # # # }

# # # # $paths = @{
# # # #     Downloads = Join-Path $config.BaseDir "Downloads"
# # # #     Software  = Join-Path $config.BaseDir "Software"
# # # #     CUDAHome  = Join-Path $config.BaseDir "NVIDIA\CUDA"
# # # #     Logs      = Join-Path $config.BaseDir "Logs"
# # # # }

# # # # # Initialize directories
# # # # $paths.Values | ForEach-Object {
# # # #     if (-not (Test-Path $_)) { New-Item -Path $_ -ItemType Directory -Force | Out-Null }
# # # # }

# # # # function Write-InstallLog {
# # # #     param($Message, $Level = "INFO")
# # # #     $color = @{
# # # #         "INFO"    = "Cyan"
# # # #         "WARN"    = "Yellow"
# # # #         "ERROR"   = "Red"
# # # #         "SUCCESS" = "Green"
# # # #         "TIP"     = "Magenta"
# # # #     }[$Level]
    
# # # #     $logEntry = "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Message"
# # # #     Add-Content -Path (Join-Path $paths.Logs "install.log") -Value $logEntry
# # # #     Write-Host $logEntry -ForegroundColor $color
# # # # }

# # # # function Find-InstallationFile {
# # # #     param($Type)
    
# # # #     try {
# # # #         $patterns = @{
# # # #             CUDA  = @("cuda_*windows*.exe", "cuda_*win*.exe")
# # # #             cuDNN = @("cudnn*.zip", "*cuda12-archive.zip")
# # # #         }

# # # #         $minSize = $config.MinFileSizeMB[$Type] * 1MB
        
# # # #         $foundFiles = Get-ChildItem $paths.Downloads -File | Where-Object {
# # # #             $_.Length -ge $minSize -and
# # # #             ($patterns[$Type] | Where-Object { $_.Name -like $_ })
# # # #         }

# # # #         if ($foundFiles) {
# # # #             Write-InstallLog "Found potential files:" -Level INFO
# # # #             $foundFiles | ForEach-Object {
# # # #                 Write-InstallLog " - $($_.Name)" -Level INFO
# # # #             }
# # # #             return $foundFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1
# # # #         }
        
# # # #         Write-InstallLog "No valid $Type files found matching patterns: $($patterns[$Type])" -Level WARN
# # # #         return $null
# # # #     }
# # # #     catch {
# # # #         Write-InstallLog "File search error: $_" -Level ERROR
# # # #         return $null
# # # #     }
# # # # }

# # # # function Install-CUDA {
# # # #     Write-InstallLog "Starting CUDA setup..." -Level INFO
    
# # # #     $cudaFile = Find-InstallationFile -Type CUDA
# # # #     if (-not $cudaFile) {
# # # #         Write-InstallLog "Please ensure you have:" -Level TIP
# # # #         Write-InstallLog "1. Downloaded CUDA installer from:" -Level TIP
# # # #         Write-InstallLog "   https://developer.nvidia.com/cuda-downloads" -Level TIP
# # # #         Write-InstallLog "2. Saved it to: $($paths.Downloads)" -Level TIP
# # # #         Write-InstallLog "3. File name should look like: cuda_12.1.0_531.14_windows.exe" -Level TIP
# # # #         throw "CUDA installer not found in downloads folder"
# # # #     }

# # # #     try {
# # # #         Write-InstallLog "Using installer: $($cudaFile.Name)" -Level SUCCESS
# # # #         $installArgs = @(
# # # #             "-s",
# # # #             "installpath=$($paths.CUDAHome)",
# # # #             "nvcc_$($config.TargetCuda)"
# # # #         )
        
# # # #         $process = Start-Process -FilePath $cudaFile.FullName -ArgumentList $installArgs -Wait -PassThru
        
# # # #         if ($process.ExitCode -ne 0) {
# # # #             throw "Installer failed with code: $($process.ExitCode)"
# # # #         }
        
# # # #         Write-InstallLog "CUDA installed successfully at: $($paths.CUDAHome)" -Level SUCCESS
# # # #     }
# # # #     catch {
# # # #         Write-InstallLog "Installation failed: $_" -Level ERROR
# # # #         throw
# # # #     }
# # # # }

# # # # try {
# # # #     Write-Host @"

# # # #     ░██████╗░██████╗░██╗░░░██╗  ███████╗██╗░░░░░███████╗████████╗
# # # #     ██╔════╝░██╔══██╗██║░░░██║  ██╔════╝██║░░░░░██╔════╝╚══██╔══╝
# # # #     ██║░░██╗░██████╔╝██║░░░██║  █████╗░░██║░░░░░█████╗░░░░░██║░░░
# # # #     ██║░░╚██╗██╔═══╝░██║░░░██║  ██╔══╝░░██║░░░░░██╔══╝░░░░░██║░░░
# # # #     ╚██████╔╝██║░░░░░╚██████╔╝  ██║░░░░░███████╗███████╗░░░██║░░░
# # # #     ░╚═════╝░╚═╝░░░░░░╚═════╝░  ╚═╝░░░░░╚══════╝╚══════╝░░░╚═╝░░░
# # # #                 Flexible GPU Installation Assistant
# # # # "@ -ForegroundColor Cyan

# # # #     Install-CUDA
# # # #     Write-InstallLog "Setup completed successfully!" -Level SUCCESS
# # # # }
# # # # catch {
# # # #     Write-InstallLog "Setup failed: $($_.Exception.Message)" -Level ERROR
# # # #     Write-InstallLog "Check these solutions:" -Level TIP
# # # #     Write-InstallLog "1. Verify file exists in Downloads folder" -Level TIP
# # # #     Write-InstallLog "2. Check filename matches patterns:" -Level TIP
# # # #     Write-InstallLog "   - cuda_*windows*.exe" -Level TIP
# # # #     Write-InstallLog "   - cuda_*win*.exe" -Level TIP
# # # #     Write-InstallLog "3. Ensure file size > $($config.MinFileSizeMB.CUDA)MB" -Level TIP
# # # # }
# # # # finally {
# # # #     Write-Host "`n💡 Need help? Check: $($paths.Logs)\install.log" -ForegroundColor Yellow
# # # # }


# # # <#
# # # .SYNOPSIS
# # # Enhanced GPU Setup Script with File Verification
# # # .DESCRIPTION
# # # Version: 10.2.0
# # # Features:
# # # - Improved file pattern matching
# # # - Detailed file verification
# # # - Clear path diagnostics
# # # #>

# # # $config = @{
# # #     BaseDir         = "F:\GPU_Setup"
# # #     TargetCuda      = "12.1"
# # #     MinFileSizeMB   = @{
# # #         CUDA  = 3000  # Increased to 3GB
# # #         cuDNN = 300
# # #     }
# # # }

# # # $paths = @{
# # #     Downloads = Join-Path $config.BaseDir "Downloads"
# # #     Software  = Join-Path $config.BaseDir "Software"
# # #     CUDAHome  = Join-Path $config.BaseDir "NVIDIA\CUDA"
# # #     Logs      = Join-Path $config.BaseDir "Logs"
# # # }

# # # # Initialize directories
# # # $paths.Values | ForEach-Object {
# # #     if (-not (Test-Path $_)) { New-Item -Path $_ -ItemType Directory -Force | Out-Null }
# # # }

# # # function Write-InstallLog {
# # #     param($Message, $Level = "INFO")
# # #     $color = @{
# # #         "INFO"    = "Cyan"
# # #         "WARN"    = "Yellow"
# # #         "ERROR"   = "Red"
# # #         "SUCCESS" = "Green"
# # #         "TIP"     = "Magenta"
# # #     }[$Level]
    
# # #     $logEntry = "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Message"
# # #     Add-Content -Path (Join-Path $paths.Logs "install.log") -Value $logEntry
# # #     Write-Host $logEntry -ForegroundColor $color
# # # }

# # # function Find-InstallationFile {
# # #     param($Type)
    
# # #     try {
# # #         $patterns = @{
# # #             CUDA  = @("cuda_*_windows.exe", "cuda_*windows*.exe")
# # #             cuDNN = @("cudnn*.zip", "*cuda*-archive.zip")
# # #         }

# # #         $minSize = $config.MinFileSizeMB[$Type] * 1MB
        
# # #         Write-InstallLog "Searching for $Type files in: $($paths.Downloads)" -Level INFO
# # #         Write-InstallLog "Matching patterns: $($patterns[$Type])" -Level INFO
        
# # #         $foundFiles = Get-ChildItem $paths.Downloads -File | Where-Object {
# # #             $_.Length -ge $minSize -and
# # #             ($patterns[$Type] | Where-Object { $_.Name -like $_ })
# # #         }

# # #         if ($foundFiles) {
# # #             Write-InstallLog "Discovered matching files:" -Level SUCCESS
# # #             $foundFiles | ForEach-Object {
# # #                 Write-InstallLog " - $($_.Name) ($([math]::Round($_.Length/1MB)) MB)" -Level INFO
# # #             }
# # #             return $foundFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1
# # #         }
        
# # #         Write-InstallLog "No valid $Type files found" -Level WARN
# # #         return $null
# # #     }
# # #     catch {
# # #         Write-InstallLog "File search error: $_" -Level ERROR
# # #         return $null
# # #     }
# # # }

# # # function Install-CUDA {
# # #     Write-InstallLog "Starting CUDA installation process..." -Level INFO
    
# # #     $cudaFile = Find-InstallationFile -Type CUDA
# # #     if (-not $cudaFile) {
# # #         Write-InstallLog "Please verify your CUDA installer:" -Level TIP
# # #         Write-InstallLog "1. File location: $($paths.Downloads)" -Level TIP
# # #         Write-InstallLog "2. File pattern: cuda_*_windows.exe" -Level TIP
# # #         Write-InstallLog "3. Your actual files:" -Level TIP
# # #         Get-ChildItem $paths.Downloads | Format-Table Name, Length -AutoSize | Out-String | ForEach-Object {
# # #             Write-InstallLog "$_" -Level TIP
# # #         }
# # #         throw "CUDA installer validation failed"
# # #     }

# # #     try {
# # #         Write-InstallLog "Validated installer: $($cudaFile.FullName)" -Level SUCCESS
# # #         Write-InstallLog "File size verified: $([math]::Round($cudaFile.Length/1GB, 2)) GB" -Level INFO
        
# # #         $installArgs = @(
# # #             "-s",
# # #             "installpath=$($paths.CUDAHome)",
# # #             "nvcc_$($config.TargetCuda)"
# # #         )
        
# # #         Write-InstallLog "Starting installation with parameters:" -Level INFO
# # #         $installArgs | ForEach-Object { Write-InstallLog " - $_" -Level INFO }
        
# # #         $process = Start-Process -FilePath $cudaFile.FullName -ArgumentList $installArgs -Wait -PassThru
        
# # #         if ($process.ExitCode -ne 0) {
# # #             throw "Installer exited with code: $($process.ExitCode)"
# # #         }
        
# # #         Write-InstallLog "CUDA components installed successfully!" -Level SUCCESS
# # #         Write-InstallLog "Installation path: $($paths.CUDAHome)" -Level INFO
# # #     }
# # #     catch {
# # #         Write-InstallLog "Installation failed: $_" -Level ERROR
# # #         throw
# # #     }
# # # }

# # # try {
# # #     Write-Host @"

# # #     ░██████╗░██████╗░██╗░░░██╗  ░█████╗░██╗░░░██╗███████╗
# # #     ██╔════╝░██╔══██╗██║░░░██║  ██╔══██╗██║░░░██║██╔════╝
# # #     ██║░░██╗░██████╔╝██║░░░██║  ██║░░╚═╝██║░░░██║█████╗░░
# # #     ██║░░╚██╗██╔═══╝░██║░░░██║  ██║░░██╗██║░░░██║██╔══╝░░
# # #     ╚██████╔╝██║░░░░░╚██████╔╝  ╚█████╔╝╚██████╔╝███████╗
# # #     ░╚═════╝░╚═╝░░░░░░╚═════╝░  ░╚════╝░░╚═════╝░╚══════╝
# # #                 Verified Installation System
# # # "@ -ForegroundColor Cyan

# # #     Install-CUDA
# # #     Write-InstallLog "All components installed successfully!" -Level SUCCESS
# # # }
# # # catch {
# # #     Write-InstallLog "Setup failed: $($_.Exception.Message)" -Level ERROR
# # #     Write-InstallLog "Diagnostic information:" -Level TIP
# # #     Write-InstallLog "1. CUDA file path: $($paths.Downloads)" -Level TIP
# # #     Write-InstallLog "2. File exists: $(Test-Path "$($paths.Downloads)\cuda_12.1.0_531.14_windows.exe")" -Level TIP
# # #     Write-InstallLog "3. File size: $((Get-Item "$($paths.Downloads)\cuda_12.1.0_531.14_windows.exe").Length/1GB) GB" -Level TIP
# # # }
# # # finally {
# # #     Write-Host "`n💡 Installation Report: $($paths.Logs)\install.log" -ForegroundColor Yellow
# # # }


# # <#
# # .SYNOPSIS
# # Reliable GPU Setup Script
# # .DESCRIPTION
# # Version: 10.3.0
# # Features:
# # - Enhanced pattern matching
# # - Detailed file verification
# # - Comprehensive diagnostics
# # #>

# # $config = @{
# #     BaseDir         = "F:\GPU_Setup"
# #     TargetCuda      = "12.1"
# #     MinFileSizeGB   = @{
# #         CUDA  = 3.0  # Minimum 3GB
# #         cuDNN = 0.3  # Minimum 300MB
# #     }
# # }

# # $paths = @{
# #     Downloads = Join-Path $config.BaseDir "Downloads"
# #     Software  = Join-Path $config.BaseDir "Software"
# #     CUDAHome  = Join-Path $config.BaseDir "NVIDIA\CUDA"
# #     Logs      = Join-Path $config.BaseDir "Logs"
# # }

# # # Initialize directories
# # $paths.Values | ForEach-Object {
# #     if (-not (Test-Path $_)) { New-Item -Path $_ -ItemType Directory -Force | Out-Null }
# # }

# # function Write-InstallLog {
# #     param($Message, $Level = "INFO")
# #     $color = @{
# #         "INFO"    = "Cyan"
# #         "WARN"    = "Yellow"
# #         "ERROR"   = "Red"
# #         "SUCCESS" = "Green"
# #         "DEBUG"   = "Gray"
# #     }[$Level]
    
# #     $logEntry = "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Message"
# #     Add-Content -Path (Join-Path $paths.Logs "install.log") -Value $logEntry
# #     Write-Host $logEntry -ForegroundColor $color
# # }

# # function Find-CUDAInstaller {
# #     $patterns = @(
# #         "cuda_*_windows*.exe",
# #         "cuda_*windows*.exe",
# #         "cuda_*win*.exe"
# #     )

# #     $minSize = $config.MinFileSizeGB.CUDA * 1GB
    
# #     Write-InstallLog "Scanning for CUDA installers..." -Level DEBUG
# #     Write-InstallLog "Target patterns: $($patterns -join ', ')" -Level DEBUG
# #     Write-InstallLog "Minimum size: $($config.MinFileSizeGB.CUDA) GB" -Level DEBUG

# #     $allFiles = Get-ChildItem $paths.Downloads -File
# #     Write-InstallLog "Found $($allFiles.Count) files in directory" -Level DEBUG

# #     $matchedFiles = $allFiles | Where-Object {
# #         $file = $_
# #         $sizeValid = $_.Length -ge $minSize
# #         $nameValid = $patterns | Where-Object { $file.Name -like $_ }
        
# #         Write-InstallLog "Checking file: $($file.Name)" -Level DEBUG
# #         Write-InstallLog "Size valid: $sizeValid ($([math]::Round($file.Length/1GB,2)) GB)" -Level DEBUG
# #         Write-InstallLog "Name valid: $($null -ne $nameValid)" -Level DEBUG
        
# #         $sizeValid -and $nameValid
# #     }

# #     if ($matchedFiles) {
# #         Write-InstallLog "Valid CUDA installers found:" -Level SUCCESS
# #         $matchedFiles | ForEach-Object {
# #             Write-InstallLog " - $($_.Name) ($([math]::Round($_.Length/1GB,2)) GB)" -Level INFO
# #         }
# #         return $matchedFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1
# #     }

# #     Write-InstallLog "No valid CUDA installers found" -Level ERROR
# #     return $null
# # }

# # function Install-CUDA {
# #     try {
# #         $cudaFile = Find-CUDAInstaller
# #         if (-not $cudaFile) {
# #             throw "Valid CUDA installer not found in: $($paths.Downloads)"
# #         }

# #         Write-InstallLog "Selected installer: $($cudaFile.FullName)" -Level SUCCESS
# #         Write-InstallLog "Verification passed: File exists" -Level INFO

# #         $installArgs = @(
# #             "-s",
# #             "installpath=$($paths.CUDAHome)",
# #             "nvcc_$($config.TargetCuda)"
# #         )

# #         Write-InstallLog "Starting installation..." -Level INFO
# #         $process = Start-Process -FilePath $cudaFile.FullName -ArgumentList $installArgs -Wait -PassThru

# #         if ($process.ExitCode -ne 0) {
# #             throw "Installation failed with exit code: $($process.ExitCode)"
# #         }

# #         Write-InstallLog "CUDA components installed successfully!" -Level SUCCESS
# #         Write-InstallLog "Installation path: $($paths.CUDAHome)" -Level INFO
# #     }
# #     catch {
# #         Write-InstallLog "Installation failed: $_" -Level ERROR
# #         throw
# #     }
# # }

# # try {
# #     Write-Host @"

# #     ░██████╗░██████╗░██╗░░░██╗  ███████╗██╗░░░░░███████╗
# #     ██╔════╝░██╔══██╗██║░░░██║  ██╔════╝██║░░░░░██╔════╝
# #     ██║░░██╗░██████╔╝██║░░░██║  █████╗░░██║░░░░░█████╗░░
# #     ██║░░╚██╗██╔═══╝░██║░░░██║  ██╔══╝░░██║░░░░░██╔══╝░░
# #     ╚██████╔╝██║░░░░░╚██████╔╝  ██║░░░░░███████╗███████╗
# #     ░╚═════╝░╚═╝░░░░░░╚═════╝░  ╚═╝░░░░░╚══════╝╚══════╝
# #                 Reliable Installation System
# # "@ -ForegroundColor Cyan

# #     Install-CUDA
# #     Write-InstallLog "All components installed successfully!" -Level SUCCESS
# # }
# # catch {
# #     Write-InstallLog "Setup failed: $($_.Exception.Message)" -Level ERROR
# #     Write-InstallLog "Diagnostic Data:" -Level INFO
# #     Write-InstallLog "1. CUDA file path: $($paths.Downloads)" -Level INFO
# #     Write-InstallLog "2. File exists: $(Test-Path "$($paths.Downloads)\cuda_12.1.0_531.14_windows.exe")" -Level INFO
# #     Write-InstallLog "3. File size: $((Get-Item "$($paths.Downloads)\cuda_12.1.0_531.14_windows.exe").Length/1GB) GB" -Level INFO
# #     Write-InstallLog "4. Pattern match: $('cuda_12.1.0_531.14_windows.exe' -like 'cuda_*_windows.exe')" -Level INFO
# # }
# # finally {
# #     Write-Host "`n📘 Detailed report: $($paths.Logs)\install.log" -ForegroundColor Yellow
# # }



# <#
# .SYNOPSIS
# Robust GPU Installation Script
# .DESCRIPTION
# Version: 11.0.0
# Features:
# - 管理员权限自动提升
# - 安装前系统检查
# - 详细的错误恢复机制
# #>

# $config = @{
#     BaseDir         = "F:\GPU_Setup"
#     TargetCuda      = "12.1"
#     MinFileSizeGB   = @{
#         CUDA  = 3.0
#         cuDNN = 0.3
#     }
# }

# $paths = @{
#     Downloads = Join-Path $config.BaseDir "Downloads"
#     CUDAHome  = Join-Path $config.BaseDir "NVIDIA\CUDA"
#     Logs      = Join-Path $config.BaseDir "Logs"
# }

# # 自动请求管理员权限
# if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
#     Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
#     exit
# }

# # 初始化目录
# $paths.Values | ForEach-Object {
#     if (-not (Test-Path $_)) { New-Item -Path $_ -ItemType Directory -Force | Out-Null }
# }

# function Write-InstallLog {
#     param($Message, $Level = "INFO")
#     $logEntry = "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Message"
#     Add-Content -Path (Join-Path $paths.Logs "install.log") -Value $logEntry
#     Write-Host $logEntry -ForegroundColor (@{INFO='Cyan'; WARN='Yellow'; ERROR='Red'; SUCCESS='Green'}.$Level)
# }

# function Install-CUDA {
#     try {
#         $cudaFile = Get-Item "$($paths.Downloads)\cuda_12.1.0_531.14_windows.exe"
        
#         # 安装前清理
#         Write-InstallLog "Cleaning previous installations..." -Level INFO
#         Get-Process "setup*" | Stop-Process -Force -ErrorAction SilentlyContinue

#         # 安装参数优化
#         $installArgs = @(
#             "-s",
#             "installpath=$($paths.CUDAHome)",
#             "nvcc_$($config.TargetCuda)",
#             "include_samples=0",    # 不安装示例
#             "install_online=0"      # 禁用在线组件
#         )

#         # 安装过程
#         Write-InstallLog "Starting installation..." -Level INFO
#         $process = Start-Process -FilePath $cudaFile.FullName -ArgumentList $installArgs -Wait -PassThru

#         # 结果验证
#         if ($process.ExitCode -ne 0) {
#             throw "Installation failed with code: $($process.ExitCode). Common solutions:`n" +
#                   "1. Disable antivirus temporarily`n" +
#                   "2. Check disk space (Min 10GB free)`n" +
#                   "3. Install Visual C++ Redistributable"
#         }

#         # 验证关键文件
#         $requiredFiles = @(
#             "bin\nvcc.exe",
#             "lib\x64\cudart.lib",
#             "include\cuda_runtime.h"
#         )
        
#         $requiredFiles | ForEach-Object {
#             if (-not (Test-Path "$($paths.CUDAHome)\$_")) {
#                 throw "Critical file missing: $_"
#             }
#         }

#         Write-InstallLog "CUDA installation validated!" -Level SUCCESS
#     }
#     catch {
#         Write-InstallLog "Installation error: $_" -Level ERROR
#         throw
#     }
# }

# # Main
# try {
#     Write-Host @"

#     ██████╗ ██████╗ ██╗   ██╗ █████╗     ██████╗ ██████╗  ██████╗ 
#     ██╔══██╗██╔══██╗██║   ██║██╔══██╗    ██╔══██╗██╔══██╗██╔════╝ 
#     ██║  ██║██████╔╝██║   ██║███████║    ██║  ██║██████╔╝██║  ███╗
#     ██║  ██║██╔═══╝ ██║   ██║██╔══██║    ██║  ██║██╔═══╝ ██║   ██║
#     ██████╔╝██║     ╚██████╔╝██║  ██║    ██████╔╝██║     ╚██████╔╝
#     ╚═════╝ ╚═╝      ╚═════╝ ╚═╝  ╚═╝    ╚═════╝ ╚═╝      ╚═════╝ 
#                 Robust Installation System v11.0
# "@ -ForegroundColor Cyan

#     Install-CUDA

#     # cuDNN 安装部分
#     Write-InstallLog "Starting cuDNN configuration..." -Level INFO
#     $cudnnZip = Get-Item "$($paths.Downloads)\cudnn-windows-x86_64-8.9.7.29_cuda12-archive.zip"
#     Expand-Archive -Path $cudnnZip.FullName -DestinationPath "$($paths.CUDAHome)" -Force
#     Write-InstallLog "cuDNN files deployed successfully!" -Level SUCCESS

#     # 环境变量配置
#     $envPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
#     if (-not $envPath.Contains($paths.CUDAHome)) {
#         [Environment]::SetEnvironmentVariable("Path", "$envPath;$($paths.CUDAHome)\bin", "Machine")
#         Write-InstallLog "System PATH updated" -Level INFO
#     }

#     Write-InstallLog "All components installed successfully! 🎉" -Level SUCCESS
#     Write-Host "`n✅ Please reboot your system to complete the installation" -ForegroundColor Green
# }
# catch {
#     Write-InstallLog "Setup failed: $($_.Exception.Message)" -Level ERROR
#     Write-InstallLog "Troubleshooting checklist:" -Level WARN
#     Write-InstallLog "1. Disable antivirus/firewall" -Level WARN
#     Write-InstallLog "2. Run Windows Update" -Level WARN
#     Write-InstallLog "3. Verify installer checksum" -Level WARN
#     exit 1
# }


<#
.SYNOPSIS
CUDA/cuDNN 智能安装脚本
.DESCRIPTION
版本: 12.1.0
功能:
- 智能错误恢复机制
- 安装环境预检
- 多层级日志系统
#>

# 配置参数
$config = @{
    BaseDir         = "F:\GPU_Setup"
    CudaVersion     = "12.1"
    CudnnVersion    = "8.9.7"
    MinDiskSpaceGB  = 15  # 最小磁盘空间要求
    SystemCheck     = $true
    InstallTimeout  = 1800  # 30分钟超时
}

# 路径配置
$paths = @{
    Downloads       = Join-Path $config.BaseDir "Downloads"
    CUDAInstallDir  = Join-Path $config.BaseDir "NVIDIA\CUDA"
    Logs            = Join-Path $config.BaseDir "Logs"
    Temp            = Join-Path $env:TEMP "GPU_Install"
}

# 初始化日志系统
function Initialize-Logging {
    $global:LogFile = Join-Path $paths.Logs "install_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    New-Item -Path $paths.Logs -ItemType Directory -Force | Out-Null
    Start-Transcript -Path $LogFile -Append | Out-Null
}

function Write-InstallLog {
    param($Message, $Level="INFO")
    $logEntry = "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor @{INFO='Cyan'; WARN='Yellow'; ERROR='Red'; DEBUG='Gray'; SUCCESS='Green'}[$Level]
    Add-Content -Path $LogFile -Value $logEntry
}

# 系统预检模块
function Test-SystemReadiness {
    try {
        Write-InstallLog "正在执行系统环境检查..." -Level INFO

        # 磁盘空间检查
        $drive = Get-PSDrive -Name $config.BaseDir.Substring(0,1)
        if ($drive.Free / 1GB -lt $config.MinDiskSpaceGB) {
            throw "磁盘空间不足! 需要至少 $($config.MinDiskSpaceGB)GB, 当前可用: $([math]::Round($drive.Free/1GB,2))GB"
        }

        # 运行库检查
        $vcRedist = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
                    Where-Object DisplayName -match "Microsoft Visual C\+\+.*Redistributable"
        if (-not $vcRedist) {
            throw "未找到Visual C++ Redistributable"
        }

        # 安全软件检测
        $securityProducts = Get-Service | Where-Object {
            $_.DisplayName -match "Antivirus|Firewall|Endpoint Protection"
        }
        if ($securityProducts) {
            Write-InstallLog "检测到安全软件: $($securityProducts.DisplayName -join ', ')" -Level WARN
            Write-InstallLog "建议临时禁用安全软件后再继续" -Level WARN
        }

        Write-InstallLog "系统预检通过" -Level SUCCESS
    }
    catch {
        Write-InstallLog "系统检查失败: $($_.Exception.Message)" -Level ERROR
        throw
    }
}

# 智能安装模块
function Install-CUDA {
    param($InstallerPath)
    
    try {
        Write-InstallLog "启动CUDA安装进程..." -Level INFO
        
        # 创建安装参数
        $installArgs = @(
            "--silent",
            "--driver",          # 单独安装驱动
            "--toolkit",
            "--samples",
            "--installpath=`"$($paths.CUDAInstallDir)`"",
            "--override"         # 强制覆盖现有安装
        )

        # 启动安装进程
        $process = Start-Process -FilePath $InstallerPath -ArgumentList $installArgs -PassThru -NoNewWindow
        
        # 等待安装完成
        $process | Wait-Process -Timeout $config.InstallTimeout -ErrorAction Stop

        # 验证退出代码
        if ($process.ExitCode -ne 0) {
            throw "安装程序返回错误代码: 0x$($process.ExitCode.ToString('X8'))"
        }

        Write-InstallLog "CUDA安装验证通过" -Level SUCCESS
    }
    catch {
        Write-InstallLog "安装过程异常: $($_.Exception.Message)" -Level ERROR
        
        # 错误代码解析
        switch ($process.ExitCode) {
            -522190823 {
                $errorMsg = @"
检测到安装程序完整性错误，建议：
1. 重新下载安装包
2. 验证文件SHA256校验和
3. 禁用杀毒软件后重试
"@
                Write-InstallLog $errorMsg -Level WARN
            }
            default {
                Write-InstallLog "未知错误代码，请查看详细日志: $LogFile" -Level WARN
            }
        }
        throw
    }
}

# 主流程
try {
    # 初始化环境
    Initialize-Logging
    Write-InstallLog "=== 开始GPU环境部署 ===" -Level INFO

    # 自动提权
    if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-InstallLog "检测到非管理员权限，正在请求提权..." -Level WARN
        Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        exit
    }

    # 执行系统检查
    if ($config.SystemCheck) { Test-SystemReadiness }

    # 定位安装包
    $cudaInstaller = Get-Item "$($paths.Downloads)\cuda_12.1.0_531.14_windows.exe" -ErrorAction Stop
    Write-InstallLog "检测到CUDA安装包: $($cudaInstaller.FullName)" -Level SUCCESS

    # 执行安装
    Install-CUDA -InstallerPath $cudaInstaller.FullName

    # cuDNN部署
    Write-InstallLog "开始部署cuDNN..." -Level INFO
    $cudnnPackage = Get-Item "$($paths.Downloads)\cudnn-windows-x86_64-8.9.7.29_cuda12-archive.zip" -ErrorAction Stop
    Expand-Archive -Path $cudnnPackage.FullName -DestinationPath $paths.CUDAInstallDir -Force
    Write-InstallLog "cuDNN文件部署完成" -Level SUCCESS

    # 环境变量配置
    $envPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    if (-not $envPath.Contains($paths.CUDAInstallDir)) {
        [Environment]::SetEnvironmentVariable("Path", "$envPath;$($paths.CUDAInstallDir)\bin", "Machine")
        Write-InstallLog "系统PATH已更新" -Level INFO
    }

    Write-InstallLog "=== 安装成功完成 ===" -Level SUCCESS
    Write-Host "`n请重启系统使配置生效" -ForegroundColor Green
}
catch {
    Write-InstallLog "主流程异常: $($_.Exception.Message)" -Level ERROR
    Write-InstallLog "调试建议：" -Level WARN
    Write-InstallLog "1. 检查日志文件: $LogFile" -Level WARN
    Write-InstallLog "2. 手动运行安装程序: $($cudaInstaller.FullName)" -Level WARN
    exit 1
}
finally {
    Stop-Transcript | Out-Null
}