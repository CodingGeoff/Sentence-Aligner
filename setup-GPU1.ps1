# <#
# .SYNOPSIS
# GPU环境自动化配置脚本 - 国内镜像版
# .DESCRIPTION
# 版本：3.0.1
# 功能：使用国内镜像加速安装CUDA 12.1 + cuDNN 8.9 + PyTorch 2.5.1
# #>

# # 配置参数
# $config = @{
#     BaseDir         = "F:\GPU_Setup"       # 所有操作的基础目录
#     CudaVersion     = "12.1"               # CUDA版本
#     PythonVersion   = "3.10"               # Python版本
#     MirrorSettings  = @{
#         Pip         = "https://pypi.tuna.tsinghua.edu.cn/simple"
#         PipTrust    = "https://pypi.tuna.tsinghua.edu.cn"
#         Cuda        = "https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/nvidia/win-64/"
#         Cudnn       = "https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/nvidia/win-64/"
#     }
#     LogFile         = "F:\GPU_Setup\install.log"
# }

# # 初始化目录结构
# $directories = @(
#     "$($config.BaseDir)\Downloads",
#     "$($config.BaseDir)\Logs",
#     "$($config.BaseDir)\Software"
# )

# # 初始化日志系统
# function Write-Log {
#     param(
#         [Parameter(Mandatory=$true)]
#         [string]$Message,
#         [ValidateSet("INFO","WARN","ERROR","SUCCESS")]
#         [string]$Level = "INFO"
#     )
#     $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
#     $logEntry = "[$timestamp][$Level] $Message"
#     Add-Content -Path $config.LogFile -Value $logEntry
#     $color = switch ($Level) {
#         "INFO"    { "Cyan" }
#         "WARN"    { "Yellow" }
#         "ERROR"   { "Red" }
#         "SUCCESS" { "Green" }
#     }
#     Write-Host "[$Level] $Message" -ForegroundColor $color
# }

# # 带重试机制的下载函数
# function Download-FileWithRetry {
#     param(
#         [string]$Url,
#         [string]$Destination,
#         [int]$RetryCount = 3
#     )
#     $attempt = 1
#     while ($attempt -le $RetryCount) {
#         try {
#             Write-Log -Message "下载尝试 $attempt : $Url" -Level INFO
#             $webClient = New-Object System.Net.WebClient
#             $webClient.DownloadFile($Url, $Destination)
#             if (Test-Path $Destination) {
#                 Write-Log -Message "下载成功: $Destination" -Level SUCCESS
#                 return $true
#             }
#         }
#         catch {
#             Write-Log -Message "下载失败: $($_.Exception.Message)" -Level WARN
#             Start-Sleep -Seconds (10 * $attempt)
#         }
#         $attempt++
#     }
#     Write-Log -Message "无法完成下载: $Url" -Level ERROR
#     return $false
# }

# # CUDA安装函数
# function Install-CUDA {
#     $cudaPackage = "cudatoolkit-$($config.CudaVersion)*.exe"
#     $cudaUrl = "$($config.MirrorSettings.Cuda)$cudaPackage"
#     $localPath = "$($config.BaseDir)\Downloads\$cudaPackage"

#     if (-not (Download-FileWithRetry -Url $cudaUrl -Destination $localPath)) {
#         throw "CUDA下载失败"
#     }

#     Write-Log -Message "开始安装CUDA $($config.CudaVersion)" -Level INFO
#     $installArgs = @(
#         "-s",
#         "nvcc_$($config.CudaVersion)",
#         "visual_studio_integration",
#         "nsight_nvs",
#         "nsight_systems",
#         "nsight_compute"
#     )
#     Start-Process -FilePath $localPath -ArgumentList $installArgs -Wait -NoNewWindow
# }

# # cuDNN配置函数
# function Install-cuDNN {
#     $cudnnPackage = "cudnn-*.zip"
#     $cudnnUrl = "$($config.MirrorSettings.Cudnn)$cudnnPackage"
#     $localPath = "$($config.BaseDir)\Downloads\$cudnnPackage"

#     if (-not (Download-FileWithRetry -Url $cudnnUrl -Destination $localPath)) {
#         throw "cuDNN下载失败"
#     }

#     Expand-Archive -Path $localPath -DestinationPath "$($config.BaseDir)\Software\cuDNN" -Force
#     Get-ChildItem "$($config.BaseDir)\Software\cuDNN\*" | ForEach-Object {
#         Copy-Item "$_\bin\*" "$env:CUDA_PATH\bin" -Force
#         Copy-Item "$_\include\*" "$env:CUDA_PATH\include" -Force
#         Copy-Item "$_\lib\*" "$env:CUDA_PATH\lib" -Force
#     }
# }

# # 主流程
# try {
#     # 初始化环境
#     New-Item -Path $directories -ItemType Directory -Force | Out-Null
#     Start-Transcript -Path $config.LogFile -Append

#     Write-Host @"

#     ██████╗ ██████╗ ██╗   ██╗ █████╗ 
#     ██╔══██╗██╔══██╗██║   ██║██╔══██╗
#     ██║  ██║██████╔╝██║   ██║███████║
#     ██║  ██║██╔═══╝ ██║   ██║██╔══██║
#     ██████╔╝██║     ╚██████╔╝██║  ██║
#     ╚═════╝ ╚═╝      ╚═════╝ ╚═╝  ╚═╝
#      GPU环境自动化配置工具 v3.0
#            基础目录：$($config.BaseDir)
# "@ -ForegroundColor Magenta

#     # 安装CUDA
#     Install-CUDA

#     # 配置cuDNN
#     Install-cuDNN

#     # 配置Python环境
#     Write-Log -Message "配置Python虚拟环境" -Level INFO
#     $venvPath = "$($config.BaseDir)\PythonEnv"
#     python -m venv $venvPath

#     # 安装PyTorch
#     Write-Log -Message "使用国内镜像安装PyTorch" -Level INFO
#     & "$venvPath\Scripts\pip.exe" install torch torchvision torchaudio `
#         --index-url $config.MirrorSettings.Pip `
#         --trusted-host $config.MirrorSettings.PipTrust

#     # 验证安装
#     $validation = & "$venvPath\Scripts\python.exe" -c @"
# import torch
# print(f"PyTorch版本|{torch.__version__}")
# print(f"CUDA可用|{torch.cuda.is_available()}")
# if torch.cuda.is_available():
#     print(f"GPU型号|{torch.cuda.get_device_name(0)}")
#     print(f"CUDA版本|{torch.version.cuda}")
#     print(f"cuDNN版本|{torch.backends.cudnn.version()}")
# "@

#     # 显示验证结果
#     $validation | ConvertFrom-Csv -Delimiter "|" -Header "项目", "值" | Format-Table -AutoSize

#     Write-Log -Message "所有组件安装完成" -Level SUCCESS
# }
# catch {
#     Write-Log -Message "安装失败: $($_.Exception.Message)" -Level ERROR
#     Write-Log -Message "请检查日志文件: $($config.LogFile)" -Level WARN
# }
# finally {
#     Stop-Transcript
#     Write-Host "`n操作完成！详细日志请查看：" -NoNewline
#     Write-Host $config.LogFile -ForegroundColor Cyan
# }



<#
.SYNOPSIS
Auto GPU Environment Setup Script
.DESCRIPTION
Version: 3.1.0
Features: 
- CUDA 12.1 with Chinese mirrors
- cuDNN 8.9.7
- PyTorch 2.5.1
#>

# Configuration
$config = @{
    BaseDir         = "F:\GPU_Setup"
    CudaVersion     = "12.1"
    PythonVersion   = "3.10"
    MirrorSettings  = @{
        Pip         = "https://pypi.tuna.tsinghua.edu.cn/simple"
        PipTrust    = "https://pypi.tuna.tsinghua.edu.cn"
        Cuda        = "https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/nvidia/win-64/"
        Cudnn       = "https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/nvidia/win-64/"
    }
    LogFile         = "F:\GPU_Setup\install.log"
}

# Initialize directories
$directories = @(
    "$($config.BaseDir)\Downloads",
    "$($config.BaseDir)\Logs",
    "$($config.BaseDir)\Software"
)

# Logging system
function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [ValidateSet("INFO","WARN","ERROR","SUCCESS")]
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp][$Level] $Message"
    Add-Content -Path $config.LogFile -Value $logEntry
    $color = switch ($Level) {
        "INFO"    { "Cyan" }
        "WARN"    { "Yellow" }
        "ERROR"   { "Red" }
        "SUCCESS" { "Green" }
    }
    Write-Host "[$Level] $Message" -ForegroundColor $color
}

# Enhanced download with retry
function Download-FileWithRetry {
    param(
        [string]$Url,
        [string]$Destination,
        [int]$RetryCount = 3
    )
    $attempt = 1
    while ($attempt -le $RetryCount) {
        try {
            Write-Log -Message "Download attempt $attempt : $Url" -Level INFO
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($Url, $Destination)
            if (Test-Path $Destination) {
                Write-Log -Message "Download success: $Destination" -Level SUCCESS
                return $true
            }
        }
        catch {
            Write-Log -Message "Download failed: $($_.Exception.Message)" -Level WARN
            Start-Sleep -Seconds (10 * $attempt)
        }
        $attempt++
    }
    Write-Log -Message "Permanent download failure: $Url" -Level ERROR
    return $false
}

# CUDA installation
function Install-CUDA {
    $cudaPackage = "cudatoolkit-$($config.CudaVersion)*.exe"
    $cudaUrl = "$($config.MirrorSettings.Cuda)$cudaPackage"
    $localPath = "$($config.BaseDir)\Downloads\$cudaPackage"

    if (-not (Download-FileWithRetry -Url $cudaUrl -Destination $localPath)) {
        throw "CUDA download failed"
    }

    Write-Log -Message "Installing CUDA $($config.CudaVersion)" -Level INFO
    $installArgs = @(
        "-s",
        "nvcc_$($config.CudaVersion)",
        "visual_studio_integration",
        "nsight_nvs",
        "nsight_systems",
        "nsight_compute"
    )
    Start-Process -FilePath $localPath -ArgumentList $installArgs -Wait -NoNewWindow
}

# cuDNN configuration
function Install-cuDNN {
    $cudnnPackage = "cudnn-*.zip"
    $cudnnUrl = "$($config.MirrorSettings.Cudnn)$cudnnPackage"
    $localPath = "$($config.BaseDir)\Downloads\$cudnnPackage"

    if (-not (Download-FileWithRetry -Url $cudnnUrl -Destination $localPath)) {
        throw "cuDNN download failed"
    }

    Expand-Archive -Path $localPath -DestinationPath "$($config.BaseDir)\Software\cuDNN" -Force
    Get-ChildItem "$($config.BaseDir)\Software\cuDNN\*" | ForEach-Object {
        Copy-Item "$_\bin\*" "$env:CUDA_PATH\bin" -Force
        Copy-Item "$_\include\*" "$env:CUDA_PATH\include" -Force
        Copy-Item "$_\lib\*" "$env:CUDA_PATH\lib" -Force
    }
}

# Main workflow
try {
    # Environment setup
    New-Item -Path $directories -ItemType Directory -Force | Out-Null
    Start-Transcript -Path $config.LogFile -Append

    Write-Host @"

    ██████╗ ██████╗ ██╗   ██╗ █████╗ 
    ██╔══██╗██╔══██╗██║   ██║██╔══██╗
    ██║  ██║██████╔╝██║   ██║███████║
    ██║  ██║██╔═══╝ ██║   ██║██╔══██║
    ██████╔╝██║     ╚██████╔╝██║  ██║
    ╚═════╝ ╚═╝      ╚═════╝ ╚═╝  ╚═╝
     GPU Environment Setup Tool v3.1
         Base Directory: $($config.BaseDir)
"@ -ForegroundColor Magenta

    # CUDA installation
    Install-CUDA

    # cuDNN configuration
    Install-cuDNN

    # Python environment
    Write-Log -Message "Creating Python virtual environment" -Level INFO
    $venvPath = "$($config.BaseDir)\PythonEnv"
    python -m venv $venvPath

    # PyTorch installation
    Write-Log -Message "Installing PyTorch with mirror" -Level INFO
    & "$venvPath\Scripts\pip.exe" install torch torchvision torchaudio `
        --index-url $config.MirrorSettings.Pip `
        --trusted-host $config.MirrorSettings.PipTrust

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

    # Display results
    $validation | ConvertFrom-Csv -Delimiter "|" -Header "Item", "Value" | Format-Table -AutoSize

    Write-Log -Message "All components installed successfully" -Level SUCCESS
}
catch {
    Write-Log -Message "Installation failed: $($_.Exception.Message)" -Level ERROR
    Write-Log -Message "Check log file: $($config.LogFile)" -Level WARN
}
finally {
    Stop-Transcript
    Write-Host "`nProcess completed! Detailed log: " -NoNewline
    Write-Host $config.LogFile -ForegroundColor Cyan
}