import os
import numpy as np
import pandas as pd

# --------------------- 参数设置 ---------------------
input_folder = r'D:\1MastershipWorks\ReaserchProjects\SevernBridges\Thrid Try\ceya\test'    # .dat 文件所在文件夹路径
output_folder = r'D:\1MastershipWorks\ReaserchProjects\SevernBridges\Thrid Try\ceya\test'      # 保存 .csv 文件的文件夹路径

group_size = 67              # (64 x 阀数 + 3)
discard_count = 3             # 前3个点丢弃
keep_size = group_size - discard_count
data_type = np.float32        # 数据类型
# -----------------------------------------------------

if not os.path.exists(output_folder):
    os.makedirs(output_folder)
    print(f'已创建输出文件夹: {output_folder}')

dat_files = [f for f in os.listdir(input_folder) if f.endswith('.dat')]
num_files = len(dat_files)

if num_files == 0:
    print('输入文件夹中未找到任何 .dat 文件。')
    exit()

print(f'在文件夹 {input_folder} 中找到 {num_files} 个 .dat 文件。')

for k, dat_file in enumerate(dat_files, 1):
    full_dat_path = os.path.join(input_folder, dat_file)
    name, _ = os.path.splitext(dat_file)
    csv_file_name = name + '.csv'
    full_csv_path = os.path.join(output_folder, csv_file_name)

    print(f'正在处理文件 {k}/{num_files}: {dat_file}')

    # 读取二进制数据
    with open(full_dat_path, 'rb') as fid:
        data = np.fromfile(fid, dtype=data_type)

    num_groups = len(data) // group_size

    if len(data) % group_size != 0:
        print(f'警告: 文件 {dat_file} 的数据点数不是 {group_size} 的倍数，将忽略不足一组的数据。')
        data = data[:num_groups * group_size]

    data_matrix = data.reshape((num_groups, group_size)).T  # [group_size, num_groups]

    # 丢弃前 discard_count 行
    data_matrix = data_matrix[discard_count:, :]             # [keep_size, num_groups]

    data_matrix = data_matrix.T                              # [num_groups, keep_size]

    count_column = np.arange(1, num_groups + 1).reshape(-1, 1)  # 计数列 [num_groups, 1]

    output_matrix = np.hstack((count_column, data_matrix))       # [num_groups, keep_size+1]

    # 保存为 csv
    pd.DataFrame(output_matrix).to_csv(full_csv_path, header=False, index=False)

    print(f'已完成写入 {csv_file_name}，共 {num_groups} 行。')

print('所有文件已成功转换。')
