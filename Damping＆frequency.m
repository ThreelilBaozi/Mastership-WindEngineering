%%%%%%%%%%%%%%  频率 阻尼比 识别 v2.0 %%%%%%%%%%%%%%%%
clear;clc;
close all;
%%%%%%%%%  修改以下参数
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
filename='0106.txt';    %文件名
Sf=256;               %采样频率 Hz
Nn=2;                 %采样通道数
Cu=20;                %电信号标定系数 20mV=1mm
mid=2;                %中间激光通道
sid=1;                %边上激光通道
d=55;                %激光间距 mm
dp_s=1024*0+1;               %要处理的开始数据点 一页1024个数据点
dp_e=1024*4;          %要处理的结束数据点 一页1024个数据点
iff=0;                %是否滤波 是为1
fmin1=0;fmax1=20;      %竖向模态 带通
fmin2=2;fmax2=4;      %扭转模态 带通
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 文件数据读取
fid=fopen(filename);
if Nn==2
    data=textscan(fid,'%f %f %f %f %f','HeaderLines',9);  % 2通道
elseif Nn==4
    data=textscan(fid,'%f %f %f %f %f %f %f','HeaderLines',11);  % 4通道
end
fclose(fid);
data=cell2mat(data);
% 提取位移时程
time=data(dp_s:dp_e,3)/1000;
datasid=data(dp_s:dp_e,sid+3)./Cu;  %边激光
datamid=data(dp_s:dp_e,mid+3)./Cu;  %中激光
vs=datamid;                         %竖向
as=(datasid-datamid)/d*180/pi;      %扭转
%% FFT变换
L=size(time,1);        %信号长度（偶数）
Y_v=fft(vs);Y_a=fft(as);
P2_v=abs(Y_v/L);P2_a=abs(Y_a/L);
P1_v=P2_v(1:L/2+1);P1_a=P2_a(1:L/2+1);
P1_v(2:end-1)=2*P1_v(2:end-1);P1_a(2:end-1)=2*P1_a(2:end-1);
f=Sf*(0:(L/2))/L;
%% 带通滤波 band-pass filter
if iff==1
    nmin1=round(fmin1*L/Sf+1);nmin2=round(fmin2*L/Sf+1); %最小截止频率对应数组元素的下标
    nmax1=round(fmax1*L/Sf+1);nmax2=round(fmax2*L/Sf+1); %最大截止频率对应数组元素的下标
    aa1=zeros(L,1);aa2=zeros(L,1);
    aa1(nmin1:nmax1)=Y_v(nmin1:nmax1); %将y的正频率带通内元素赋值给aa
    aa2(nmin2:nmax2)=Y_a(nmin2:nmax2); %将y的正频率带通内元素赋值给aa
    aa1(L-nmax1+1:L-nmin1+1)=Y_v(L-nmax1+1:L-nmin1+1); %将y的负频率带通内元素赋值给aa
    aa2(L-nmax2+1:L-nmin2+1)=Y_a(L-nmax2+1:L-nmin2+1); %将y的负频率带通内元素赋值给aa
    ivs=ifft(aa1);ias=ifft(aa2);  %傅里叶逆变换
    ivs=real(ivs);ias=real(ias);  %取实部
end
%% 模态频率提取
[ym1,ymc1]=max(P1_v(1:end));[ym2,ymc2]=max(P1_a(1:end));
freq1=f(ymc1);freq2=f(ymc2);     %找出卓越频率 下标1为竖向，2为扭转
if iff==1
    Y_iv=fft(ivs);Y_ia=fft(ias);
    P2_iv=abs(Y_iv/L);P2_ia=abs(Y_ia/L);
    P1_iv=P2_iv(1:L/2+1);P1_ia=P2_ia(1:L/2+1);
    P1_iv(2:end-1)=2*P1_iv(2:end-1);P1_ia(2:end-1)=2*P1_ia(2:end-1);
    [ymi1,ymci1]=max(P1_iv(1:end));[ymi2,ymci2]=max(P1_ia(1:end));
    freq1=f(ymci1);freq2=f(ymci2);     %找出卓越频率 下标1为竖向，2为扭转
end
%% 阻尼比计算
if iff==1
    vsd=ivs;asd=ias;
else
    vsd=vs;asd=as;
end
% 查找极大值
in=0;
for i=11:L-10
    if vsd(i)>=vsd(i-1)&&vsd(i)>=vsd(i+1)&&vsd(i)>=vsd(i-2)&&vsd(i)>=vsd(i+2)&&vsd(i)>=vsd(i-3)&&vsd(i)>=vsd(i+3)&&vsd(i)>=vsd(i-4)&&vsd(i)>=vsd(i+4)&&vsd(i)>=vsd(i-5)&&vsd(i)>=vsd(i+5)&&vsd(i)>=vsd(i-6)&&vsd(i)>=vsd(i+6)&&vsd(i)>=vsd(i-7)&&vsd(i)>=vsd(i+7)&&vsd(i)>=vsd(i-8)&&vsd(i)>=vsd(i+8)&&vsd(i)>=vsd(i-9)&&vsd(i)>=vsd(i+9)&&vsd(i)>=vsd(i-10)&&vsd(i)>=vsd(i+10)
        in=in+1;
        indexv(in)=i;  %竖向极值序列位置索引
    end
end
in=0;
for i=11:L-10
    if asd(i)>=asd(i-1)&&asd(i)>=asd(i+1)&&asd(i)>=asd(i-2)&&asd(i)>=asd(i+2)&&asd(i)>=asd(i-3)&&asd(i)>=asd(i+3)&&asd(i)>=asd(i-4)&&asd(i)>=asd(i+4)&&asd(i)>=asd(i-5)&&asd(i)>=asd(i+5)&&asd(i)>=asd(i-6)&&asd(i)>=asd(i+6)&&asd(i)>=asd(i-7)&&asd(i)>=asd(i+7)&&asd(i)>=asd(i-8)&&asd(i)>=asd(i+8)&&asd(i)>=asd(i-9)&&asd(i)>=asd(i+9)&&asd(i)>=asd(i-10)&&asd(i)>=asd(i+10)
        in=in+1;
        indexa(in)=i;  %扭转极值序列位置索引
    end
end
% 删除首尾不合理极值
dsuv=0;deuv=0;  %删除竖向极大值首尾点数 ##### 可修改
dsua=0;deua=0;  %删除扭转极大值首尾点数 ##### 可修改
indexv=indexv(1+dsuv:end-deuv);
indexa=indexa(1+dsua:end-deua);
dtimev=time(indexv);peakv=vsd(indexv);
dtimea=time(indexa);peaka=asd(indexa);
% 拟合
fitv=polyfit(dtimev,log(peakv),1);
fita=polyfit(dtimea,log(peaka),1);
% 计算阻尼比，单位：%
dampv=fitv(1)/(-2*pi*freq1)*100;
dampa=fita(1)/(-2*pi*freq2)*100;
% 拟合曲线计算
dampvs=exp(fitv(2)).*exp(fitv(1).*time);
dampas=exp(fita(2)).*exp(fita(1).*time);
%% 输出计算结果
disp('竖向频率Hz   竖向阻尼比%   扭转频率Hz   扭转阻尼比%');
disp([real(freq1) real(dampv) real(freq2) real(dampa)]);
%% 绘图
figure(1);
set(gcf,'Position',[100 100 1300 600]);

subplot(2,2,1);
plot(time,vs,'b-');
title('竖向位移');
xlabel('时间（s）');
ylabel('位移（mm）');
legend('滤波前');
grid on;hold on;
if iff==1
    plot(time,ivs,'r-');
    legend('滤波前','滤波后');
end

subplot(2,2,2);
plot(time,as,'b-');
title('扭转位移');
xlabel('时间（s）');
ylabel('位移（°）');
legend('滤波前');
grid on;hold on;
if iff==1
    plot(time,ias,'r-');
    legend('滤波前','滤波后');
end

subplot(2,2,3);
plot(f(1:round(L/10)),P1_v(1:round(L/10)),'b-');
title('竖向位移频谱图');
xlabel('频率（Hz）');
ylabel('幅值（mm/Hz）');
legend('滤波前');
grid on;hold on;
if iff==1
    plot(f(1:round(L/10)),P1_iv(1:round(L/10)),'r-');
    legend('滤波前','滤波后');
end

subplot(2,2,4);
plot(f(1:round(L/10)),P1_a(1:round(L/10)),'b-');
title('扭转位移频谱图');
xlabel('频率（Hz）');
ylabel('幅值（°/Hz）');
legend('滤波前');
grid on;hold on;
if iff==1
    plot(f(1:round(L/10)),P1_ia(1:round(L/10)),'r-');
    legend('滤波前','滤波后');
end

figure(2);
set(gcf,'Position',[100 100 1000 600]);

subplot(2,1,1);
plot(time,vsd,'b-');grid on;hold on;
plot(dtimev,peakv,'ro');
plot(time,dampvs,'g-');
title('竖向阻尼比拟合');
xlabel('时间（s）');
ylabel('位移（mm）');
legend('竖向位移','极大值点','拟合曲线');

subplot(2,1,2);
plot(time,asd,'b-');grid on;hold on;
plot(dtimea,peaka,'ro');
plot(time,dampas,'g-');
title('扭转阻尼比拟合');
xlabel('时间（s）');
ylabel('位移（°）');
legend('扭转位移','极大值点','拟合曲线');
