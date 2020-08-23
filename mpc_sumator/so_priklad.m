%Priklad na MPC pro system druheho radu
clear all;
close all;

s=zpk('s');

w=10;
xi=0.1;
Ks=20;

Ts=0.1;

P=Ks*w^2/(s^2+2*xi*w*s+w^2);

Pd=c2d(P,Ts);

step(P,Pd)


Pss=ss(Pd)

%Diskretni stavovy model
[A,B,C,D]=ssdata(Pss)



%Rozsireny system se sumatorem

Ae=[A B;zeros(1,2) 1];
Be=[B;1];
Ce=[C 0];
De=0;

Psse=ss(Ae,Be,Ce,De,Ts)
