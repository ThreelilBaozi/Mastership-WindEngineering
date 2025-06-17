#... 提供了一种快速折线图可视化方法 

% 编辑：陈子豪

clear; clc;

%% --------------------- 参数设置 ---------------------

% 定义每组要提取的列号
extractColsPerGroup = {
    [17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47]+1     ,    % Group 1 853
    [13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43]+1+64  ,    % Group 2 855
    [17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47]+1+64*2,    % Group 3 856
    [13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43]+1+64*3,    % Group 4 854
    [13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43]+1+64*4     % Group 5 852
};

% 用户可调整的画布大小
figureWidth = 1000; % 图框宽度
figureHeight = 400; % 图框高度

% 用户可修改的风速和空气密度
windSpeed = 10; % 风速（单位：m/s）
airDensity = 1.225; % 空气密度（单位：kg/m^3）

% 缩放因子
scalingFactor = 100;
adjustedValues = adjustedValues * scalingFactor;

%% --------------------- 用户输入 ---------------------

% 输入 MAT 文件路径
sortedMatPath = 'D:\1MastershipWorks\ReaserchProjects\SevernBridges\Second Try\Extract\shuffled_geo.mat';

% 输入 CSV 文件路径
csvFilePath = 'D:\1MastershipWorks\ReaserchProjects\SevernBridges\Second Try\Data\csv\0\0010.csv';

% 输入要处理的组号（每次处理一个组）
groupNumber = 2;

% 输入行范围
startRow = 7680;
endRow   = 15616;

% 输入两点断开的连线对（可以包含多对）
disconnectPairs = [2,3; 17,18]; % 每行表示一对起点和终点的索引，断开它们之间的连线

% 输入输出 CSV 文件的路径
%outputCSVPath = 'D:\1MastershipWorks\ReaserchProjects\SevernBridges\Second Try\test';
%outputFolder = fileparts(outputCSVPath);
%if ~exist(outputFolder, 'dir')
%    mkdir(outputFolder);
%    fprintf('已创建输出文件夹：%s\n', outputFolder);
%end

%% --------------------- 数据加载 ---------------------

% 加载 sorted_geo.mat
sortedData = load(sortedMatPath);

c_Line = sortedData.c_Line;                  % 几何边界的 LINE 实体
pressurePoints = sortedData.pressurePoints;  % [x, y] 测压点

% 读取 CSV 文件
try
    csvData = readmatrix(csvFilePath);
catch ME
    error('读取 CSV 文件时出错：%s', ME.message);
end

% 提取指定行范围的数据
extractedData = csvData(startRow:endRow, :);

% 提取指定组的列
cols = extractColsPerGroup{groupNumber};
% 确保列号不超过数据列数
validCols = cols(cols <= size(extractedData,2)); 
if length(validCols) < length(cols)
    warning('组 %d 中有 %d 列超出 CSV 数据的列数 (%d)。将只提取有效列。', groupNumber, length(cols) - length(validCols), size(extractedData,2));
end

selectedCols = validCols;

if isempty(selectedCols)
    error('组 %d 没有有效的提取列。', groupNumber);
end

% 提取数据
groupData = extractedData(:, selectedCols);

% 平均值
averageValues = mean(groupData, 1, 'omitnan'); % [1, numPressurePoints]
adjustedValues = (averageValues / 0.5) / airDensity / (windSpeed^2);

% 转置为列向量
adjustedValues = adjustedValues';
projPoints = sortedData.projPoints; % [x, y] 原始测压点

% 计算法线方向（从投影点到测压点）
normals = projPoints - pressurePoints; % [x, y]
normLengths = vecnorm(normals, 2, 2);
normLengths(normLengths == 0) = 1; % 避免除以零
normalizedNormals = normals ./ normLengths;

% 计算法线终点（箭头尖端）
arrowEndPoints = pressurePoints + normalizedNormals .* adjustedValues;

%% --------------------- 绘图 ---------------------

% 创建图形窗口并设置大小
figure('Color', 'white', 'Position', [100, 100, figureWidth, figureHeight]);
hold on;
axis equal;
title('连接法线终点折线图（含断开点）');

% 绘制几何边界的 LINE 实体
if ~isempty(c_Line)
    for i = 1:size(c_Line, 1)
        lineData = c_Line{i,1}; % [x1, y1, z1, x2, y2, z2]
        x = lineData([1,4]);
        y = lineData([2,5]);
        plot(x, y, 'k-', 'LineWidth', 1.5);
    end
end

% 绘制折线，按递增顺序连接所有点，断开指定的连线
numPoints = size(arrowEndPoints, 1);
for i = 1:numPoints
    nextIndex = mod(i, numPoints) + 1; % 下一个点（循环连接）
    % 检查是否需要断开当前连线
    if any(all(disconnectPairs == sort([i, nextIndex]), 2)) % 判断是否为需要断开的连线
        continue; % 跳过断开的连线
    end
    % 绘制连线
    plot([arrowEndPoints(i, 1), arrowEndPoints(nextIndex, 1)], ...
         [arrowEndPoints(i, 2), arrowEndPoints(nextIndex, 2)], 'r--', 'LineWidth', 1.5); % 统一为红色
end

% 移除 X 和 Y 坐标轴
axis off;
hold off;

%% --------------------- 导出结果 ---------------------

% 创建一个表格，包含原始测压点、投影点、平均值和法线方向终点
%resultTable = table();
%resultTable.Original_X = projPoints(:,1);
%resultTable.Original_Y = projPoints(:,2);
%resultTable.Pressure_X = pressurePoints(:,1);
%resultTable.Pressure_Y = pressurePoints(:,2);
%resultTable.Average_Value = averageValues;
%resultTable.Adjusted_Value = adjustedValues; % 新的替代值
%resultTable.Arrow_X = normalizedNormals(:,1) .* adjustedValues;
%resultTable.Arrow_Y = normalizedNormals(:,2) .* adjustedValues;

% 写入 CSV 文件
%writetable(resultTable, outputCSVPath);
%fprintf('已成功将结果导出到 %s\n', outputCSVPath);
