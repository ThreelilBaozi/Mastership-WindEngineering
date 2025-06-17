### 这个是用于将2000版本dxf文件中的点和线提取到matlab图中的代码（注意，使用这个代码的必须函数是f_LectDxf.m）

clear; clc;

% --------------------- 参数设置 ---------------------

% 指定 DXF 文件路径
geometryFile = 'D:\1MastershipWorks\ReaserchProjects\SevernBridges\Second Try\模型细节\deck_geo1.dxf'; % 边界实际路径
pressureFile = 'D:\1MastershipWorks\ReaserchProjects\SevernBridges\Second Try\模型细节\tap_geo.dxf'  ; % 测压点实际路径

% f_LectDxf 函数路径
addpath('D:\1MastershipWorks\ReaserchProjects\SevernBridges\Second Try\新-测压处理\');                 % 替换为 f_LectDxf 函数所在的实际路径（文件夹路径）

% -----------------------------------------------------

% 读取几何边界 DXF 文件
[c_Line, c_Poly, c_Cir, c_Arc, c_Poi] = f_LectDxf(geometryFile);

% 读取测压点 DXF 文件
[c_Line_Pressure, c_Poly_Pressure, c_Cir_Pressure, c_Arc_Pressure, c_Poi_Pressure] = f_LectDxf(pressureFile);

% 提取 LINE 实体的坐标
if ~isempty(c_Line)
    mat_line = cell2mat(c_Line(:,1));
    if size(mat_line,2) >=6
        lineStart = mat_line(:,1:3);
        lineEnd = mat_line(:,4:6);
    else
        error('LINE entities do not have at least 6 coordinates.');
    end
else
    lineStart = [];
    lineEnd = [];
    disp('No LINE entities found.');
end

% 提取 POINT 实体的坐标
if ~isempty(c_Poi_Pressure)
    validPoints = cellfun(@(x) isnumeric(x) && length(x) >= 3, c_Poi_Pressure(:,1));
    validPressurePoints = c_Poi_Pressure(validPoints, 1);
    if ~isempty(validPressurePoints)
        mat_pressure = cell2mat(validPressurePoints);
        pressurePoints = mat_pressure(:,1:2); % [x, y]
    else
        pressurePoints = [];
        disp('没有有效的测压点数据。');
    end
else
    pressurePoints = [];
    disp('No POINT entities found.');
end

% --------------------- 数据平移 ---------------------

% 平移测压点
dx_pressure = -117.62 - 3358.5;   %（确定特征点，平移点至原点）
dy_pressure = -287.01 - 1024.35;  %（确定特征点，平移点至原点）
if ~isempty(pressurePoints)
    pressurePoints = pressurePoints + [dx_pressure, dy_pressure];
end

% 平移线段
dx_line = -3358.5;   % （确定特征点，平移线至原点）
dy_line = -1024.35;  % （确定特征点，平移线至原点）
if ~isempty(lineStart)
    for i = 1:size(lineStart, 1)
        lineStart(i,1) = lineStart(i,1) + dx_line;
        lineStart(i,2) = lineStart(i,2) + dy_line;
        lineEnd(i,1) = lineEnd(i,1) + dx_line;
        lineEnd(i,2) = lineEnd(i,2) + dy_line;
    end
end

% ------------------ 更新 c_Line 数据 ------------------

if ~isempty(c_Line) && ~isempty(lineStart) && ~isempty(lineEnd)
    % 合并平移后的坐标
    new_mat_line = [lineStart, lineEnd];
    
    % 更新 c_Line 中的坐标
    for i = 1:size(c_Line,1)
        c_Line{i,1} = new_mat_line(i, :);
    end
else
    disp('c_Line 或线段数据为空，无法更新 c_Line。');
end

% --------------------- 投影计算 ---------------------

% 找到每个点到最近的线段并计算投影点
if ~isempty(pressurePoints) && ~isempty(lineStart) && ~isempty(lineEnd)
    nearestLines = cell(size(pressurePoints, 1), 1);
    projPoints = zeros(size(pressurePoints, 1), 2);
    
    for pIdx = 1:size(pressurePoints, 1)
        minDist = Inf;
        bestLineIdx = -1;
        projPoint = [];
    
        for lIdx = 1:size(lineStart, 1)
            startPt = lineStart(lIdx, 1:2);
            endPt = lineEnd(lIdx, 1:2);
            point = pressurePoints(pIdx, :);
    
            v = endPt - startPt;
            w = point - startPt;
            c1 = dot(w, v);
            if c1 <= 0
                dist = norm(w);
                proj = startPt;
            else
                c2 = dot(v, v);
                if c2 <= c1
                    w = point - endPt;
                    dist = norm(w);
                    proj = endPt;
                else
                    b = c1 / c2;
                    proj = startPt + b * v;
                    dist = norm(point - proj);
                end
            end
    
            if dist < minDist
                minDist = dist;
                bestLineIdx = lIdx;
                projPoint = proj;
            end
        end
    
        nearestLines{pIdx} = [bestLineIdx, minDist];
        projPoints(pIdx,:) = projPoint;
    end
else
    projPoints = [];
    nearestLines = {};
    disp('压力点或线段数据为空，无法计算投影点。');
end

% --------------------- 变量交换 ---------------------

% 旧变量
oldVar1 = pressurePoints;
oldVar2 = projPoints;

% 新变量名
pressurePoints = oldVar2; % 原 projPoints
projPoints = oldVar1;     % 原 pressurePoints

% --------------------- 绘制结果 ---------------------

figure('Color', 'white');
hold on;
axis equal;
title('几何边界和测压点与投影点');
xlabel('X 坐标');
ylabel('Y 坐标');

% 绘制 LINE 实体
if ~isempty(lineStart)
    for i = 1:size(lineStart, 1)
        plot([lineStart(i,1), lineEnd(i,1)], [lineStart(i,2), lineEnd(i,2)], 'k-', 'LineWidth', 1.5);
    end
end

% 绘制原始测压点（现在是 projPoints）
if ~isempty(pressurePoints)
    scatter(pressurePoints(:,1), pressurePoints(:,2), 50, 'b', 'filled'); % 蓝色实心点
end

% 绘制投影点（现在是 pressurePoints）
if ~isempty(projPoints)
    scatter(projPoints(:,1), projPoints(:,2), 30, 'r', 'filled'); % 红色实心点
end

% 添加连线从原始点到投影点
if ~isempty(pressurePoints) && ~isempty(projPoints)
    for i = 1:size(pressurePoints, 1)
        plot([pressurePoints(i,1), projPoints(i,1)], [pressurePoints(i,2), projPoints(i,2)], 'g--', 'LineWidth', 1);
    end
end

% 添加图例
legend({'LINE', '投影点', '原始测压点'}, 'Location', 'best');

hold off;

% --------------------- 保存数据 ---------------------

% 保存更新后的数据为 MAT 文件
save('geo.mat', 'c_Line', 'pressurePoints', 'projPoints', 'nearestLines');

% --------------------- 完成 ---------------------
disp('数据处理完成，已保存到 geo.mat');
