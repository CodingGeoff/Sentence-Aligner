# import torch
# if torch.cuda.is_available():
#     print("GPU可用！型号:", torch.cuda.get_device_name(0))
# else:
#     print("GPU不可用，请检查驱动和CUDA安装。")


import torch
print("PyTorch版本:", torch.__version__)
print("CUDA是否可用:", torch.cuda.is_available())
if torch.cuda.is_available():
    print("GPU型号:", torch.cuda.get_device_name(0))
    print("CUDA版本:", torch.version.cuda)
else:
    print("错误详情:", torch.cuda.get_arch_list())  # 显示底层错误