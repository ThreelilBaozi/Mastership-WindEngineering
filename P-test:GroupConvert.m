%%%这个命令流是用来把测压实验中的.dat输出文件批量转化为.csv文件的

% --------------------- 参数设置 ---------------------
% 设置输入和输出文件夹路径
inputFolder = 'D:\1MastershipWorks\ReaserchProjects\SevernBridges\Second Try\Data\12.05测压\0';    % 替换为 dat 文件所在文件夹路径
outputFolder = 'D:\1MastershipWorks\ReaserchProjects\SevernBridges\Second Try\Data\csv数据\0';  % 替换为保存 .csv 文件的文件夹路径

% 设置数据读取参数
groupSize = 323;                             % （64x你使用的阀数+3）
discardCount = 3;                          
keepSize = groupSize - discardCount;         
dataType = 'float32';                  

% -----------------------------------------------------


if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
    fprintf('已创建输出文件夹：%s\n', outputFolder);
end

datFiles = dir(fullfile(inputFolder, '*.dat'));
numFiles = length(datFiles);

if numFiles == 0
    disp('输入文件夹中未找到任何 .dat 文件。');
    return;
end

fprintf('在文件夹 %s 中找到 %d 个 .dat 文件。\n', inputFolder, numFiles);

% 遍历
for k = 1:numFiles
    datFileName = datFiles(k).name;
    fullDatPath = fullfile(inputFolder, datFileName);
    
    % 构建对应的 .csv 文件名
    [~, name, ~] = fileparts(datFileName);
    csvFileName = [name, '.csv'];
    fullCsvPath = fullfile(outputFolder, csvFileName);
    
    fprintf('正在处理文件 %d/%d：%s\n', k, numFiles, datFileName);
    
    % 读取二进制数据
    fid = fopen(fullDatPath, 'rb');
    if fid == -1
        warning('无法打开文件：%s。跳过此文件。', fullDatPath);
        continue;
    end
    data = fread(fid, inf, dataType);
    fclose(fid);
    
    % 计算数据组数
    numGroups = length(data) / groupSize;
    
    if mod(length(data), groupSize) ~= 0
        warning('文件 %s 的数据点数不是 %d 的倍数。将忽略不足一组的数据。', datFileName, groupSize);
        numGroups = floor(length(data) / groupSize);
        data = data(1:numGroups * groupSize);
    end
    
    dataMatrix = reshape(data, groupSize, numGroups);
    
    dataMatrix = dataMatrix(discardCount+1:end, :);  % 结果为 [320, numGroups]
    
    dataMatrix = dataMatrix';  % 结果为 [numGroups, 320]
    
    countColumn = (1:numGroups)';  % 结果为 [numGroups, 1]
    
    % 合并计数列和数据矩阵
    outputMatrix = [countColumn, dataMatrix];  % 结果为 [numGroups, 321]
    
    writematrix(outputMatrix, fullCsvPath, 'Delimiter', ',', 'WriteMode', 'overwrite');
    
    fprintf('已完成写入 %s，共 %d 行。\n', csvFileName, numGroups);
end

fprintf('所有文件已成功转换。\n');
