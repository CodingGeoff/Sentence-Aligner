版权所有（C） Microsoft Corporation。保留所有权利。

安装最新的 PowerShell，了解新功能和改进！https://aka.ms/PSWindows

加载个人及系统配置文件用了 1968 毫秒。
PS C:\Users\39932> Get-WmiObject Win32_VideoController | Format-List Name  # 列出所有显卡名称


Name : OrayIddDriver Device

Name : NVIDIA GeForce RTX 2050

Name : Intel(R) Iris(R) Xe Graphics



PS C:\Users\39932> nvcc --version  # 输出CUDA编译器版本（需安装CUDA Toolkit）
nvcc: NVIDIA (R) Cuda compiler driver
Copyright (c) 2005-2025 NVIDIA Corporation
Built on Wed_Jan_15_19:38:46_Pacific_Standard_Time_2025
Cuda compilation tools, release 12.8, V12.8.61
Build cuda_12.8.r12.8/compiler.35404655_0
PS C:\Users\39932>




import torch
if torch.cuda.is_available():
    print("GPU可用！型号:", torch.cuda.get_device_name(0))
else:
    print("GPU不可用，请检查驱动和CUDA安装。")

    (.venv) D:\对齐>d:/对齐/.venv/Scripts/python.exe d:/对齐/gpu.py
GPU不可用，请检查驱动和CUDA安装。
