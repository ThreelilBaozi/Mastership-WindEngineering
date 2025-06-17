%%%这是生成风速-振幅图的简便可视化程序
%%%注意，其中微压计风速.xlsx只有一列：竖向实桥风速

%%
clc;%清屏
clear;%清空工作空间
close all;%关闭图片
tic%开始
%%
CU=20;   %系数，峨眉20；犀浦50
D=50;

namelist = dir(['*.txt']);
L = length(namelist);
P = cell(1,L);%定义一个细胞数组，用于存放所有txt文件

for i = 1:L
 namelist(i).name;
 filename{i} = [namelist(i).name];
end

%  提取数据
delimiterIn = ' ';                       %列分隔符
headerlinesIn = 9;                      %读取从第 headerlinesIn+1 行开始的数值数据
for i=1:L
present{i}=importdata(filename{i},delimiterIn,headerlinesIn);
dataset{i}=present{i}.data;                 %导出的headerlinesIn行以后的数据
parameters{i}=present{i}.textdata;
 A1{i}=dataset{i}(1:4096,4);   %提取通道1的数据 迎风侧
 A2{i}=dataset{i}(1:4096,5);  %提取通道2的数据 背风侧
end

% 自身相减，隔直
for i=1:L
A1{i}=A1{i}-mean(A1{i});    
A2{i}=A2{i}-mean(A2{i});      
end

% 减去初值数据
for i=2:L
A1{i}=A1{i}-A1{1};    
A2{i}=A2{i}-A2{1};    
end
%% 

% % % 数据初值处理
% A1{1}=zeros(4096,1);      %激光
% A2{1}=zeros(4096,1);      %激光
%% 

for i= 1:L
R1{i}=rms(A1{i}/CU);M1{i}=max(abs(A1{i}/CU));ME1{i}=mean(A1{i}/CU);
R2{i}=rms(A2{i}/CU);M2{i}=max(abs(A2{i}/CU));ME2{i}=mean(A2{i}/CU);

RV{i}=rms(((A1{i}-A2{i})+A1{i})/CU/2);    MV{i}=max((A1{i}+A2{i})/CU/2);    MEV{i}=mean((A1{i}+A2{i})/CU/2);

rot{i}=atan(((A2{i}-A1{i})*2/CU)/D)*(180/3.14); 


Rrot{i}=rms(rot{i});Mrot{i}=max(rot{i});MErot{i}=mean(rot{i});

Rrotbzc{i}=std(rot{i});
end

%% cell换成矩阵
%%%% RMS值
R1j=cell2mat(R1')*40;        %迎风竖向乘以缩尺比
R2j=cell2mat(R2')*40;        %截面中竖向乘以缩尺比
RVj=cell2mat(RV')*40;            %竖向均值乘以缩尺比
Rrotj=cell2mat(Rrot')*40;        %扭转乘以缩尺比

%%%% MAX值
M1j=cell2mat(M1');        %迎风竖向
M2j=cell2mat(M2');     %截面中竖向
MVj=cell2mat(MV');            %竖向均值
Mrotj=cell2mat(Mrot');        %扭转

%%%% MEAN值
ME1j=cell2mat(ME1');        %迎风竖向
ME2j=cell2mat(ME2');     %截面中竖向
MEVj=cell2mat(MEV');            %竖向均值
MErotj=cell2mat(MErot');        %扭转


%%%%扭转标准差
Rrotbzcj=cell2mat(Rrotbzc');

dd1=xlsread('微压计风速.xlsx');

d1=dd1';

HZ1=[dd1 RVj Rrotj];


% %% 线性差值 找软颤振临界风速
% DD=25;
% RR=0.5;
% 
% %删去小于25m/s的数据
% Dd=dd1-DD;
% Dd=(abs(Dd));
% [c,d]=find(Dd==min(Dd));
% Dc1=dd1(c,1);
% Dc2=dd2(c,1);
% 
% %重新排列数据
% [e,f]=size(dd1);
% DD1=dd1(c:e,1);
% DD2=dd2(c:e,1);
% Rrotjj=Rrotj(c:e,1);
% 
% 
% Rr=Rrotjj-RR;
% Rr=(abs(Rr));
% [row,column]=find(Rr==min(Rr));
% Rr1=Rrotjj(row,1);
% 
% if Rr1<RR;
%     Rr2=Rrotjj(row+1);
%     m=row;
%     n=row+1;
%     P=1;
% else
%     Rr1=Rrotjj(row-1,1);
%     Rr2=Rrotjj(row,1);
%     m=row-1;
%     n=row;
%     P=2;
% end
% 
% % 提取扭转位移均方根值0.5附近点的矩阵
% Rrr=[Rr1 Rr2]';
% Dd1=DD1(m:n,1);
% Dd2=DD2(m:n,1);
% 
% %线性差值
% DL1=interp1(Rrr,Dd1,RR,'linear');
% DL2=interp1(Rrr,Dd2,RR,'linear');
% DL=[DL1 DL2]

%% 画图
%%%% RMS值
% figure
OO=figure(1);
set(OO,'position',[400 400 400 800]);

subplot(2,1,1);
% %d=linspace(1,L,L);
plot(dd1,R1j,'-r*');
hold on
plot(dd1,R2j,'-ko');
hold on
plot(dd1,RVj,'-bsquare');
grid on
xlabel('实桥风速');
ylabel('竖向位移均方根值（mm）');
title('均方根值');
legend('迎风竖向','截面中竖向','竖向','location','northwest');

subplot(2,1,2);
% %d=linspace(1,L,L);
plot(dd1,Rrotj,'-r*');
grid on
xlabel('实桥风速');
ylabel('扭转位移均方根值（°）');
legend('扭转','location','northwest');

% subplot(3,1,3);
% % %d=linspace(1,L,L);
% plot(dd1,Rrotbzcj,'-r*');
% grid on
% xlabel('微压计风速');
% ylabel('扭转位移标准差值（°）');
% legend('扭转','location','northwest');


%%%% MAX值
% figure
%PP=figure(2);
%set(PP,'position',[810 400 400 800]);

%subplot(2,1,1);
% %d=linspace(1,L,L);
%plot(dd1,M1j,'-r*');
%hold on
%plot(dd1,M2j,'-ko');
%hold on
%plot(dd1,MVj,'-bsquare');
%grid on
%xlabel('微压计风速');
%ylabel('竖向位移最大值（mm）');
%title('最大值');
%legend('迎风竖向','截面中竖向','竖向','location','northwest');

%subplot(2,1,2);
% %d=linspace(1,L,L);
%plot(dd1,Mrotj,'-r*');
%grid on
%xlabel('微压计风速');
%ylabel('扭转位移最大值（°）');
%legend('扭转','location','northwest');



%% 求峰值因子
KPC=1024*4;
L=4;
A11{L}=dataset{L}(1:KPC,4);   %提取通道1的数据 迎风侧
A21{L}=dataset{L}(1:KPC,5);  %提取通道2的数据 截面中
RRR=atan(((A11{L}-A21{L})/CU)/D)*(180/3.14); 
VVV=(A11{L})/CU;
MMM1=max(RRR);
MMM2=min(RRR);
RRRm=rms(RRR);
KP=(MMM1-MMM2)/(2*RRRm)


CC=1:KPC;
ZZC=figure(6);
set(ZZC,'position',[100 100 1000 600]);
subplot(2,1,1);
plot(CC,RRR,'-k');
grid on
xlabel('采样点');
ylabel('扭转振幅（°）');
subplot(2,1,2);
plot(CC,VVV,'-r');
grid on
xlabel('采样点');
ylabel('竖向振幅（mm）');
