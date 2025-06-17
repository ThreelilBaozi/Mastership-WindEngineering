#这是监测点压力报告转csv文件的Python代码

import csv

def fluent_out_to_csv(input_file, output_file):
    with open(input_file, 'r') as f:
        lines = f.readlines()

    # 找到字段名那一行（通常是以括号包裹的，且包含 "report-pressure"）
    header_line = None
    for line in lines:
        if "report-pressure" in line and line.strip().startswith("("):
            header_line = line.strip()
            break

    if not header_line:
        raise ValueError("找不到包含 'report-pressure' 的字段名行。")

    # 去掉首尾括号，按空格或双引号分隔字段名
    header_line = header_line.strip("()")
    headers = [h.strip('"') for h in header_line.split('"') if h.strip() and h.strip() != " "]

    # 找到数据开始的行（即包含数字的行）
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

    print(f"转换完成，已写入：{output_file}")



################################################################################################

# 函数调用
fluent_out_to_csv("pressure_105001.out", "pressure7.csv")
