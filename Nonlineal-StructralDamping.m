%%用于非线性结构阻尼:比非风致气动阻尼 + 机械阻尼识别和快速可视化

%%%%%%%%% 参数输入 %%%%%%%%%%%%%
clear; clc;
close all;
filename = 'v1.txt';    % 文件名
Sf = 256;               % 采样频率 Hz
Nn = 2;                 % 采样通道数
Cu = 20;                % 电信号标定系数 20mV=1mm
mid = 2;                % 中间激光通道
sid = 1;                % 边上激光通道
d = 375;                % 激光间距 mm
dp_s = 1024*0 + 1;      % 要处理的开始数据点 一页1024个数据点
dp_e = 1024*8;          % 要处理的结束数据点 一页1024个数据点
iff = 0;                % 是否滤波 是为1
fmin2 = 3; fmax2 = 6;   % 扭转模态 带通

%% 文件数据读取
fid = fopen(filename);
if Nn == 2
    data = textscan(fid, '%f %f %f %f %f', 'HeaderLines', 9);  % 2通道
elseif Nn == 4
    data = textscan(fid, '%f %f %f %f %f %f %f', 'HeaderLines', 11);  % 4通道
end
fclose(fid);
data = cell2mat(data);

% 提取位移时程
time = data(dp_s:dp_e, 3) / 1000;
datasid = data(dp_s:dp_e, sid + 3) ./ Cu;     % 边激光
datamid = data(dp_s:dp_e, mid + 3) ./ Cu;     % 中激光
as = (datasid - datamid) / d * 180 / pi;      % 扭转

%% FFT变换
L = size(time, 1);        % 信号长度
Y_a = fft(as);            % 扭转位移
P2_a = abs(Y_a / L);
P1_a = P2_a(1:L / 2 + 1);
P1_a(2:end - 1) = 2 * P1_a(2:end - 1); % 扭转位移单侧谱
f = Sf * (0:(L / 2)) / L;

%% 带通滤波 band-pass filter
if iff == 1
    nmin2 = round(fmin2 * L / Sf + 1); % 最小截止频率对应数组元素的下标
    nmax2 = round(fmax2 * L / Sf + 1); % 最大截止频率对应数组元素的下标
    aa2 = zeros(L, 1);
    aa2(nmin2:nmax2) = Y_a(nmin2:nmax2); % 将y的正频率带通内元素赋值给aa
    aa2(L - nmax2 + 1:L - nmin2 + 1) = Y_a(L - nmax2 + 1:L - nmin2 + 1); % 将y的负频率带通内元素赋值给aa
    ias = ifft(aa2);  % 傅里叶逆变换
    ias = real(ias);  % 取实部
end

%% 模态频率提取
[ym2, ymc2] = max(P1_a(1:end));  % 找到扭转位移频谱中的最大值
freq2 = f(ymc2);  % 提取对应的频率

%% 提取包络线
if iff == 1
    asd = ias;  % 如果进行了滤波，使用滤波后的信号
else
    asd = as;   % 否则，使用原始信号
end

% 查找极大值
in = 0;
for i = 11:L-10
    if asd(i) >= asd(i-1) && asd(i) >= asd(i+1) && asd(i) >= asd(i-2) && asd(i) >= asd(i+2) && ...
       asd(i) >= asd(i-3) && asd(i) >= asd(i+3) && asd(i) >= asd(i-4) && asd(i) >= asd(i+4) && ...
       asd(i) >= asd(i-5) && asd(i) >= asd(i+5) && asd(i) >= asd(i-6) && asd(i) >= asd(i+6) && ...
       asd(i) >= asd(i-7) && asd(i) >= asd(i+7) && asd(i) >= asd(i-8) && asd(i) >= asd(i+8) && ...
       asd(i) >= asd(i-9) && asd(i) >= asd(i+9) && asd(i) >= asd(i-10) && asd(i) >= asd(i+10)
        in = in + 1;
        indexa(in) = i;  % 扭转极值序列位置索引
    end
end

% 删除首尾不合理极值
dsua = 0; deua = 0;  % 删除扭转极大值首尾点数 ##### 可修改
indexa = indexa(1 + dsua:end - deua);
dtimea = time(indexa);
peaka = asd(indexa);

%% 拟合模型选择
% 拟合三种类型的函数：指数函数、对数函数和5阶多项式
% 定义拟合函数
func_exp = @(c, t) c(1) * exp(c(2) * t) + c(3) * exp(c(4) * t);   % 指数函数
func_log = @(c, t) c(1) * log(c(2) * t + 1) + c(3);                 % 对数函数
func_poly = @(c, t) c(1) * t.^5 + c(2) * t.^4 + c(3) * t.^3 + c(4) * t.^2 + c(5) * t + c(6);  % 5阶多项式

% 拟合
opts = optimset('MaxFunEvals', 1e5, 'MaxIter', 1e5);  % 设置最大迭代次数

% 尝试三种拟合方式，计算每种拟合方式的误差
error_exp = sum((log(peaka) - func_exp([0 0 0 0], dtimea)).^2);  % 指数函数误差
error_log = sum((log(peaka) - func_log([0 0 0], dtimea)).^2);    % 对数函数误差
error_poly = sum((log(peaka) - func_poly([0 0 0 0 0 0], dtimea)).^2);  % 多项式误差

% 选择最小误差对应的拟合方式
[~, best_fit_type] = min([error_exp, error_log, error_poly]);

switch best_fit_type
    case 1  % 指数函数拟合
        Coeda = lsqcurvefit(func_exp, [0 0 0 0], dtimea, log(peaka), [-inf -inf -inf -inf], [inf inf inf inf], opts);
        best_fit = exp(func_exp(Coeda, time));
        fit_label = '指数函数';
    case 2  % 对数函数拟合
        Coeda = lsqcurvefit(func_log, [0 0 0], dtimea, log(peaka), [-inf -inf -inf], [inf inf inf], opts);
        best_fit = exp(func_log(Coeda, time));
        fit_label = '对数函数';
    case 3  % 5阶多项式拟合
        Coeda = lsqcurvefit(func_poly, [0 0 0 0 0 0], dtimea, log(peaka), [-inf -inf -inf -inf -inf -inf], [inf inf inf inf inf inf], opts);
        best_fit = exp(func_poly(Coeda, time));
        fit_label = '5阶多项式';
end

% de_重新计算非线性阻尼比
switch best_fit_type
    case 1
        dfit = Coeda(1) * Coeda(2) * exp(Coeda(2) * time) + Coeda(3) * Coeda(4) * exp(Coeda(4) * time);
    case 2
        dfit = Coeda(1) * log(Coeda(2) * time + 1) + Coeda(3);
    case 3
        dfit = Coeda(1) * time.^5 + Coeda(2) * time.^4 + Coeda(3) * time.^3 + Coeda(4) * time.^2 + Coeda(5) * time + Coeda(6);
end

dampat = -dfit / freq2 / (2 * pi);  % 非线性阻尼比计算

%% 绘图
figure(1);
set(gcf, 'Position', [100 100 1000 500]);
subplot(211);
plot(time, as); hold on; grid on;
plot(dtimea, peaka, 'ro'); hold on; grid on;
plot(time, best_fit, 'k');  % 绘制拟合曲线
title(['扭转位移（' fit_label '拟合）']);  % 标题中添加拟合方式
xlabel('时间（s）');
ylabel('位移（°）');
if iff == 1
    plot(time, ias, 'r-');
    legend('滤波前', '滤波后');
end
subplot(212);
plot(f(1:round(L / 10)), P1_a(1:round(L / 10)), 'b-');
title('扭转位移频谱图');
xlabel('频率（Hz）');
ylabel('幅值（°/Hz）');
legend('滤波前');
grid on; hold on;
if iff == 1
    plot(f(1:round(L / 10)), P1_ia(1:round(L / 10)), 'r-');
    legend('滤波前', '滤波后');
end

figure(2);
set(gcf, 'Position', [100 100 500 500]);
subplot(211);
plot(time, dampat);
title('时变阻尼比');
xlabel('时间（s）');
ylabel('阻尼比');
hold on; grid on;
subplot(212);
plot(best_fit, dampat);
title('幅变阻尼比');
xlabel('振幅(°)');
ylabel('阻尼比');
grid on;
