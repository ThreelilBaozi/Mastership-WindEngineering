#这个程序可以计算曲线的瞬时阻尼比
#使用方法：在origin中用平滑（3阶20点，不够平滑增加点数）平滑曲线
#然后用包络（10点，不够平滑增加点数）
#然后用多项式拟合包络曲线，然后将多项式x，y复制到一个excel中

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy.optimize import curve_fit

# ==== 从Excel读取数据 ====
# 假设Excel文件结构，第一列是x，第二列是y
excel_file = "ITRt2.xlsx"  # 这里可以替换成你的Excel文件路径
data = pd.read_excel(excel_file)

# 读取x和y数据
x_data = data.iloc[:, 0].to_numpy()
y_data = data.iloc[:, 1].to_numpy()

# ==== 瞬时阻尼计算 ====
# 计算瞬时阻尼比，假设使用对数递减法
def compute_instantaneous_damping(x, y):
    dampings = []
    for i in range(1, len(y)):
        # 计算相邻两个峰值之间的阻尼比
        if y[i-1] > 0 and y[i] > 0:
            delta_t = x[i] - x[i-1]  # 时间间隔
            delta_y = np.log(y[i-1] / y[i])  # 对数递减
            damping = delta_y / delta_t  # 阻尼比
            dampings.append(damping)
    return np.array(dampings)

# 计算瞬时阻尼比
instantaneous_damping = compute_instantaneous_damping(x_data, y_data)



# ==== 绘图 ====
plt.figure(figsize=(12, 6))

# 时变阻尼比图
plt.subplot(1, 2, 1)
plt.plot(x_data[1:], instantaneous_damping, label="Instantaneous Damping")
plt.title("Instantaneous Damping Ratio")
plt.xlabel("Time (s)")
plt.ylabel("Damping Ratio")
plt.grid(True)
plt.legend()


# 展示图像
plt.tight_layout()
plt.show()

# ==== 输出CSV文件 ====
output_data = pd.DataFrame({
    'Time': x_data[1:],  # 时间（与瞬时阻尼和涡基力对应）
    'Instantaneous Damping': instantaneous_damping,
})

output_data.to_csv("ITRt2_out.csv", index=False)
print("CSV file 'output_data.csv' has been saved. You can use it for plotting in Origin.")
