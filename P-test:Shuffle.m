##这是用于将模型上测压点编号和Geometery中读取的测压点编号匹配顺序的程序

clear; clc;

% 加载MAT文件并获取所有变量
loadedData = load('geo.mat'); % 输入文件名

% 显示原始的pressurePoints和projPoints以帮助决定人工排序
disp('原始的pressurePoints:');
disp(loadedData.pressurePoints);
disp('原始的projPoints:');
disp(loadedData.projPoints);

% 指定新顺序
customOrder = [27, 30, 31, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 29, 28, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1];

% 确保 customOrder1 的长度和 pressurePoints 以及 projPoints 的行数匹配
if length(customOrder) ~= size(loadedData.pressurePoints, 1) || ...
   length(customOrder) ~= size(loadedData.projPoints, 1)
    error('自定义顺序的长度必须与 pressurePoints 和 projPoints 的行数匹配');
end

% 根据自定义顺序重新排列 pressurePoints 和 projPoints
sortedPressurePoints = loadedData.pressurePoints(customOrder, :);
sortedProjPoints = loadedData.projPoints(customOrder, :);

loadedData.pressurePoints = sortedPressurePoints;
loadedData.projPoints = sortedProjPoints;

% 显示最终排序后的结果
disp('最终排序后的pressurePoints:');
disp(sortedPressurePoints);
disp('最终排序后的projPoints:');
disp(sortedProjPoints);

% 保存
save('shuffled_geo.mat', '-struct', 'loadedData'); % 保存为新的MAT文件

% 显示完成信息
disp('数据已成功排序并保存到 shuffled_geo.mat 文件中。');
