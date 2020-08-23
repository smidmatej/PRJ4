s = tf('s')
T1 = 0.5
T2 = 1
P = (s+1)/((T1*s+1)*(T2*s+1))
stepinfo(P)
Pd = c2d(P,1.09/20.0,'zoh')
sim(mpc1,100,1)
%% MPC reguluje jiny system nez je v jeho internim modelu -> horsi regulace
Plant = Pd * 1.5
MPCopts = mpcsimopt;
MPCopts.Model = Plant;
sim(mpc1,100,1,MPCopts)