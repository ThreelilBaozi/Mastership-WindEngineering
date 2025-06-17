#这是用于转换三分力系数报告的Python文件

import csv

def convert_coefficients_out_to_csv(input_file, output_file):
    with open(input_file, 'r') as f:
        lines = f.readlines()

    # 找到字段名那一行
    header_line = None
    for line in lines:
        if "drag" in line and line.strip().startswith("("):
            header_line = line.strip()
            break

    if not header_line:
        raise ValueError("找不到包含 'drag' 的字段名行。")

    # 去掉括号，提取字段名
    header_line = header_line.strip("()")
    headers = [h.strip('"') for h in header_line.split('"') if h.strip() and h.strip() != " "]

    # 解析数据
    data_start = False
    data_rows = []
    for line in lines:
        if data_start:
            parts = line.strip().split()
            if len(parts) == len(headers):
                data_rows.append(parts)
        elif header_line in line:
            data_start = True  # 下一行开始是数据

    # 写入 CSV 文件
    with open(output_file, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(headers)
        writer.writerows(data_rows)

    print(f"转换完成，文件保存为：{output_file}")


#################################################################################


# 函数调用
convert_coefficients_out_to_csv("coeffiecents_105001.out", "coefficients7.csv")
