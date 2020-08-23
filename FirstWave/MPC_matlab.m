Ts = 0.5
Tmpc = 1
z = tf('z',Ts)
F = (z+0.8)/(z-0.3)/(z+0.5)
F = ss(F)
A = F.A
B = [2 0;
    0 1]
C = [0.5 0.8;
    1 0.5]
D = zeros(2)
Plant = ss(A,B,C,D,Ts)
S = stepinfo(Plant)
%% MPC parameters for T = 0.5
% lowest rise time = 0.5 => MPC sample time = 0.5/20 = 0.0250
% lowest setting time = 1.5 => MPC prediction horizon = 1.5/0.0250 = 60 
% control horizon = prediction horizon/5 = 12