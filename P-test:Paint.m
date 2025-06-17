#...给出了一种快速可视化方案

% 编辑：陈子豪

clear; clc;

% --------------------- 参数设置 ---------------------

% 定义每组要提取的列号
% 根据 CSV 文件调整列号
extractColsPerGroup = {
    [17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47]+1     ,   % Group 1 853
    [13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43]+1+64  ,   % Group 2 855
    [17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47]+1+64*2,   % Group 3 856
    [13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43]+1+64*3,   % Group 4 854
    [13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43]+1+64*4    % Group 5 852
};

%% --------------------- 用户输入 ---------------------

% 输入 MAT 文件路径
sortedMatPath ='D:\1MastershipWorks\ReaserchProjects\SevernBridges\Second Try\Extract\shuffled_geo.mat';

% 输入 CSV 文件路径
csvFilePath ='D:\1MastershipWorks\ReaserchProjects\SevernBridges\Second Try\Data\csv\0\0000.csv';

% 输入要处理的组号（每次处理一个组）
groupNumber = 2;

% 输入行范围
startRow  =10000    ;
endRow    =15616     ;

% 输入输出 CSV 文件的路径
outputCSVPath = 'D:\1MastershipWorks\ReaserchProjects\SevernBridges\Second Try\测试\Amplitude'; %（精确到文件名）
outputFolder = fileparts(outputCSVPath);
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
    fprintf('已创建输出文件夹：%s\n', outputFolder);
end

% --------------------- 数据加载 ---------------------

% 加载 shuffled_geo.mat
sortedData = load(sortedMatPath);

c_Line = sortedData.c_Line;                  % 几何边界的 LINE 实体
pressurePoints = sortedData.pressurePoints;  % [x, y] 测压点
projPoints = sortedData.projPoints;          % [x, y] 原始测压点

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

selectedCols = validCols;

% 提取数据
groupData = extractedData(:, selectedCols);

numPressurePoints = size(pressurePoints,1);
numExtractedCols = size(groupData,2);

%% --------------------- 数据处理 ---------------------

% 计算测压点平均值
averageValues = mean(groupData, 1, 'omitnan'); % [1, numPressurePoints]
averageValues = averageValues'; % 转置为 [numPressurePoints, 1]

% 计算法线方向向量（从投影点到测压点）
normals = projPoints - pressurePoints; % [x, y]
normLengths = vecnorm(normals, 2, 2);
% 避免除以零
normLengths(normLengths == 0) = 1;
normalizedNormals = normals ./ normLengths;

%% --------------------- 绘图 ---------------------

% 绘制结果
figure('Color', 'white');
hold on;
axis equal;
title('测压点法线方向幅值');
xlabel('');
ylabel('');
set(gca, 'XTick', [], 'YTick', []); % 移除刻度
box on; % 添加图框

% 绘制 LINE 实体
if ~isempty(c_Line)
    for i = 1:size(c_Line, 1)
        lineData = c_Line{i,1}; % [x1, y1, z1, x2, y2, z2]
        x = lineData([1,4]);
        y = lineData([2,5]);
        plot(x, y, 'k-', 'LineWidth', 1.5);
    end
end

% 绘制测压点
scatter(pressurePoints(:,1), pressurePoints(:,2), 50, 'ro', 'filled'); % 红色实心点

% 定义一个缩放因子以便可视化
maxAvg = max(abs(averageValues));
if maxAvg == 0
    scalingFactor = 0;
else
    scalingFactor = 50 / maxAvg;  % 根据需要调整
end

% 定义颜色映射
cmap = jet; % 选择色图
numColors = size(cmap,1);
if maxAvg == min(averageValues)
    normValues = ones(size(averageValues)) * 1;
else
    normValues = (averageValues - min(averageValues)) / (max(averageValues) - min(averageValues));
end
normValues = max(normValues, 0); % 确保非负
c_normalized = ceil(normValues * (numColors-1)) + 1;
c_normalized(c_normalized > numColors) = numColors;

% 使用 quiver 绘制法线方向的幅值（箭头）并根据幅值改变颜色
for i = 1:numPressurePoints
    x = pressurePoints(i,1);
    y = pressurePoints(i,2);
    u = normalizedNormals(i,1) * averageValues(i) * scalingFactor;
    v = normalizedNormals(i,2) * averageValues(i) * scalingFactor;
    color = cmap(c_normalized(i), :);
    quiver(x, y, u, v, 0, 'Color', color, 'LineWidth', 1.5, 'MaxHeadSize', 2);
end

% 添加颜色条
colormap(cmap);
cbar = colorbar;
cbar.Label.String = '平均幅值';

% 添加图例
legend({'几何边界', '测压点', '法线幅值', '拟合曲线'}, 'Location', 'best');

hold off;

%% --------------------- 导出结果 ---------------------

% 创建一个表格，包含原始测压点、投影点、平均值和法线方向
resultTable = table();
resultTable.Original_X = projPoints(:,1);
resultTable.Original_Y = projPoints(:,2);
resultTable.Pressure_X = pressurePoints(:,1);
resultTable.Pressure_Y = pressurePoints(:,2);
resultTable.Average_Value = averageValues;
resultTable.Normal_X = normalizedNormals(:,1);
resultTable.Normal_Y = normalizedNormals(:,2);
resultTable.Arrow_X = normalizedNormals(:,1) .* averageValues;
resultTable.Arrow_Y = normalizedNormals(:,2) .* averageValues;

% 写入 CSV 文件
writetable(resultTable, outputCSVPath);
fprintf('已成功将结果导出到 %s\n', outputCSVPath);
