# # 增强版 CUDA 环境检测脚本（支持动态路径检测）
# Write-Host "=== CUDA 环境自动检测脚本 ===" -ForegroundColor Cyan

# # 1. 检查 NVIDIA 显卡是否存在
# $hasNvidiaGPU = (Get-WmiObject Win32_VideoController | Where-Object { $_.Name -match "NVIDIA" }) -ne $null
# if (-not $hasNvidiaGPU) {
#     Write-Host "[需步骤1] 错误：未检测到 NVIDIA 显卡！" -ForegroundColor Red
#     exit
# } else {
#     Write-Host "[通过] NVIDIA 显卡已检测到" -ForegroundColor Green
# }

# # 2. 修复操作系统检测逻辑（兼容中文系统）
# $osInfo = Get-WmiObject Win32_OperatingSystem
# $is64Bit = $osInfo.OSArchitecture -eq "64-bit"
# $isWin10Or11 = ($osInfo.Version -match "^10\.0\.2[2-9]|^10\.0\.1[89]")  # Windows 11=10.0.22xxx+, Windows 10=10.0.19xxx+

# if (-not ($is64Bit -and $isWin10Or11)) {
#     Write-Host "[需步骤1] 错误：系统需为 64 位 Windows 10/11，当前系统：$($osInfo.Caption) $($osInfo.OSArchitecture)" -ForegroundColor Red
#     exit
# } else {
#     Write-Host "[通过] 操作系统支持：$($osInfo.Caption) $($osInfo.OSArchitecture)" -ForegroundColor Green
# }


# # 3. 检查 Visual Studio 的 C++ 工具集（动态路径检测）
# $vsInstalled = $false
# $requiredVSToolset = "MSVC"

# # 方法1：通过注册表查找 Visual Studio 安装路径
# $regPaths = @(
#     "HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\SxS\VS7",
#     "HKLM:\SOFTWARE\Microsoft\VisualStudio\SxS\VS7"
# )
# foreach ($regPath in $regPaths) {
#     if (Test-Path $regPath) {
#         $vsVersions = Get-ItemProperty $regPath | Select-Object -ExpandProperty Property | Where-Object { $_ -match "^[0-9]+" }
#         foreach ($version in $vsVersions) {
#             $vsPath = (Get-ItemProperty $regPath).$version
#             if (Test-Path "$vsPath\VC\Tools\MSVC") {
#                 Write-Host "[通过] 检测到 Visual Studio $version 开发工具（路径: $vsPath）" -ForegroundColor Green
#                 $vsInstalled = $true
#                 break
#             }
#         }
#     }
# }

# # 方法2：使用 vswhere 工具查找（如果注册表未找到）
# if (-not $vsInstalled) {
#     $vswherePath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
#     if (Test-Path $vswherePath) {
#         $vsInfo = & $vswherePath -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -format json | ConvertFrom-Json
#         if ($vsInfo) {
#             $vsPath = $vsInfo[0].installationPath
#             Write-Host "[通过] 检测到 Visual Studio 开发工具（路径: $vsPath）" -ForegroundColor Green
#             $vsInstalled = $true
#         }
#     }
# }

# if (-not $vsInstalled) {
#     Write-Host "[需步骤2] 错误：未检测到 Visual Studio 或 C++ 工具集！" -ForegroundColor Red
#     Write-Host "  请安装 Visual Studio 并勾选 '使用 C++ 的桌面开发' 工作负载。" -ForegroundColor Yellow
#     exit
# }

# # 4. 检查 CUDA 工具包是否安装（动态查找版本）
# $cudaRoot = "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA"
# $cudaVersions = Get-ChildItem -Path $cudaRoot -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "^v\d+\.\d+" }
# if (-not $cudaVersions) {
#     Write-Host "[需步骤3-4] 错误：未检测到 CUDA 工具包！" -ForegroundColor Red
#     Write-Host "  请从 NVIDIA 官网下载并安装 CUDA Toolkit。" -ForegroundColor Yellow
#     exit
# } else {
#     $latestCUDAPath = $cudaVersions | Sort-Object Name -Descending | Select-Object -First 1
#     Write-Host "[通过] 检测到 CUDA 版本：$($latestCUDAPath.Name)（路径: $($latestCUDAPath.FullName)）" -ForegroundColor Green
# }

# # 5. 检查环境变量是否包含 CUDA 路径
# $cudaBinPath = Join-Path -Path $latestCUDAPath.FullName -ChildPath "bin"
# $envPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
# if ($envPath -notcontains $cudaBinPath) {
#     Write-Host "[需步骤5] 警告：CUDA bin 目录未添加到系统环境变量！" -ForegroundColor Yellow
#     Write-Host "  手动添加路径: $cudaBinPath" -ForegroundColor Yellow
# } else {
#     Write-Host "[通过] 环境变量已配置" -ForegroundColor Green
# }

# 6. 验证 nvcc 和 nvidia-smi
try {
    $nvccVersion = nvcc -V 2>&1 | Select-String "release"
    if ($nvccVersion) {
        Write-Host "[通过] nvcc 版本：$($nvccVersion.Line.Trim())" -ForegroundColor Green
    } else {
        Write-Host "[需步骤4-5] 错误：nvcc 不可用，请重新安装 CUDA！" -ForegroundColor Red
    }
} catch {
    Write-Host "[需步骤4-5] 错误：未找到 nvcc 命令！" -ForegroundColor Red
}

try {
    $nvidiaSmi = nvidia-smi 2>&1 | Select-String "CUDA Version"
    if ($nvidiaSmi) {
        Write-Host "[通过] GPU 驱动支持的 CUDA 版本：$($nvidiaSmi.Line.Trim())" -ForegroundColor Green
    } else {
        Write-Host "[需步骤4] 警告：无法获取 CUDA 版本，请更新显卡驱动！" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[需步骤4] 错误：未找到 nvidia-smi 命令！" -ForegroundColor Red
}

Write-Host "=== 检测结束 ===" -ForegroundColor Cyan