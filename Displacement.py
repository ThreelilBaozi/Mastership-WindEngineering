#这个程序可以批量得到一个文件夹下，激光位移计输出文件的平均振幅
import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

# === 参数区：手动设置 ===
data_folder = '.'  # 替换为你txt文件所在的文件夹路径
laser_spacing_mm = 270.0            # 激光间距（单位：mm）
center_column = 1                   # 中激光通道在哪里？ch1填1
edge_column = 2                     # 边激光通道在哪里？ch2填2
skip_samples = 3                  # 每个文件跳过前几个样本点进行计算

center_column += 2                 
edge_column += 2
# === 辅助函数 ===

def read_data_from_txt(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    # 找到数据起始行（跳过前8行设置）
    for i, line in enumerate(lines):
        if line.strip().startswith('0001'):
            data_lines = lines[i:]
            break

    # 将剩余数据读入DataFrame
    data = []
    for line in data_lines:
        parts = line.strip().split()
        if len(parts) >= 5:
            try:
                row = [float(p) for p in parts[-3:]]
                data.append(row)
            except ValueError:
                continue
    return pd.DataFrame(data, columns=['Time', 'Center', 'Edge'])

def process_file(file_path):
    df = read_data_from_txt(file_path)

    # 选定激光通道
    center = df.iloc[:, center_column - 2]  # 减去2是因为前两列是页数和点数
    edge = df.iloc[:, edge_column - 2]

    # 单位换算：除以20得到mm
    center_mm = center / 20.0
    edge_mm = edge / 20.0

    # 剔除前几个样本
    center_mm = center_mm[skip_samples:]
    edge_mm = edge_mm[skip_samples:]

    # 计算振幅（RMS）值
    vertical_mean = center_mm.abs().mean()

    # 计算扭转角（单位：度）
    twist_deg = np.arctan((edge_mm - center_mm) / laser_spacing_mm) * 180 / np.pi
    twist_mean = twist_deg.abs().mean()

    return vertical_mean, twist_mean

# === 主程序 ===

results = []

for filename in os.listdir(data_folder):
    if filename.endswith('.txt'):
        file_path = os.path.join(data_folder, filename)
        try:
            vertical_mean, twist_mean = process_file(file_path)
            results.append({
                '文件名': filename,
                '竖向位移均值 (mm)': round(vertical_mean, 4),
                '扭转角均值 (deg)': round(twist_mean, 4)
            })
        except Exception as e:
            print(f"❌ 文件 {filename} 处理失败：{e}")

# 输出结果
summary_df = pd.DataFrame(results)
print("\n📊 汇总振动均值：")
print(summary_df)

# 保存为CSV（可选）
summary_df.to_csv('振动汇总结果.csv', index=False)
print("\n✅ 已保存为 '振动汇总结果.csv'")








def plot_time_history(filename):
    """
    绘制指定文件的振幅时程图（竖向+扭转）
    """
    file_path = os.path.join(data_folder, filename)
    if not os.path.exists(file_path):
        print(f"⚠️ 文件不存在：{filename}")
        return

    df = read_data_from_txt(file_path)

    # 选定激光通道
    center = df.iloc[:, center_column - 2] / 20.0
    edge = df.iloc[:, edge_column - 2] / 20.0

    # 剔除前几个样本
    center = center[skip_samples:].reset_index(drop=True)
    edge = edge[skip_samples:].reset_index(drop=True)

    # 生成时间轴（采样频率：256 Hz）
    time = np.arange(len(center)) / 256.0  # 单位：秒

    # 计算扭转角（单位：度）
    twist_deg = np.arctan((edge - center) / laser_spacing_mm) * 180 / np.pi

    # 绘图
    plt.figure(figsize=(12, 5))

    # 竖向位移时程图
    plt.subplot(2, 1, 1)
    plt.plot(time, center, color='steelblue')
    plt.ylabel('Vertical Amplitude (mm)')
    plt.title(f' {filename} - Vertical Amplitude')
    plt.grid(True)

    # 扭转角时程图
    plt.subplot(2, 1, 2)
    plt.plot(time, twist_deg, color='darkorange')
    plt.xlabel('Time (s)')
    plt.ylabel('degree (deg)')
    plt.title(f' {filename} - Torsional Amplitude')
    plt.grid(True)

    plt.tight_layout()
    plt.show()

##########################################################这是一个指定文件时程图绘制的函数
plot_time_history('0083.txt')  # 替换为你想查看的文件名
