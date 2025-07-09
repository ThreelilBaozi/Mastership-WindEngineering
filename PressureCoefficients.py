#这是一个JupyterNotebook代码，用来首先批量转换测压结果data文件，然后进行某个测压阀的时程可视化和fft，最后完成平均压力系数和脉动压力系数的计算

##########################################################################################################################################Cell 1#########################################################################################################################
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


##########################################################################################################################################Cell 2#########################################################################################################################
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# ========== 参数设置 ==========
file_path = r'D:\1MastershipWorks\ReaserchProjects\SevernBridges\Thrid Try\ceya\test\0083.csv'  # 修改为你的csv文件路径
col_index = 17   # 压力数据所在列（0为第一列，1为第二列...）
fs = 256        # 采样频率Hz

# ========== 数据读取 ==========
data = pd.read_csv(file_path, header=None)
count = data.iloc[:, 0].to_numpy()
pressure = data.iloc[:, col_index].to_numpy()

# ========== 计算时间轴 ==========
t = (count - 1) / fs

# ========== FFT 计算 ==========
N = len(pressure)
fft_vals = np.fft.rfft(pressure - np.mean(pressure))
fft_freqs = np.fft.rfftfreq(N, d=1/fs)
amplitude = np.abs(fft_vals) / N * 2   # 归一化幅值（单边）

# ========== 绘图 ==========
fig, axs = plt.subplots(2, 1, figsize=(10, 7))

# 时程图
axs[0].plot(t, pressure, lw=1)
axs[0].set_xlabel('Time [s]')
axs[0].set_ylabel('Pressure [Pa]')
axs[0].set_title(f'Pressure Time History (Column {col_index})')
axs[0].grid(True)

# FFT 频谱图
axs[1].plot(fft_freqs, amplitude, lw=1)
axs[1].set_xlim(0, fs/2)
axs[1].set_xlabel('Frequency [Hz]')
axs[1].set_ylabel('Amplitude')
axs[1].set_title('FFT Spectrum')
axs[1].grid(True)

plt.tight_layout()
plt.show()


##########################################################################################################################################Cell 3#########################################################################################################################
import pandas as pd
import numpy as np

# ========== 参数输入 ==========
file_path = r'D:\1MastershipWorks\ReaserchProjects\SevernBridges\Thrid Try\ceya\test\0083.csv'
col_indices = [5, 6, 7]   # 需要分析的压力列（可任意多个）
row_start = 115           # 行区间起点（从1开始，含）
row_end = 500             # 行区间终点（含）

micro_pressure = 145.0    # 输入微压计示数，单位：Pa（你实验中的微压值）
rho = 1.225               # 空气密度 kg/m³
p_atm = 101325            # 标准大气压 Pa（如你有实验室气压可以改）

# ========== 由微压自动计算风速和自由流静压 ==========
U = np.sqrt(2 * micro_pressure / rho)  # 风速 m/s


print(f"Micro-pressure (动压): {micro_pressure:.2f} Pa")
print(f"Free-stream velocity (U): {U:.3f} m/s")


# ========== 数据读取 ==========
data = pd.read_csv(file_path, header=None)
segment = data.iloc[row_start-1:row_end]   # pandas按0开始，所以-1

results = []

for idx in col_indices:
    p_arr = segment.iloc[:, idx].to_numpy()

    # 计算平均压力、rms脉动
    p_mean = np.mean(p_arr)
    p_rms = np.sqrt(np.mean((p_arr - p_mean)**2))

    # 无量纲压力系数
    Cp_mean = (p_mean) / (0.5 * rho * U**2)
    Cp_rms = p_rms / (0.5 * rho * U**2)

    results.append({
        'Column': idx,
        'Cp_mean': Cp_mean,
        'Cp_rms': Cp_rms
    })

# 输出结果
df_results = pd.DataFrame(results)
print(df_results)

# 可选：保存结果为 csv
df_results.to_csv('Cp_results.csv', index=False)
