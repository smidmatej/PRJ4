clear all
p = tf('p')
F = 2.3192/(p^2 + 3.274*p + 124.2)
Ts = 0.1
Fd = c2d(F,Ts,'zoh')
plant_ss = ss(Fd)

%% offset-free tracking with sumator
%pouziva stavovy popis rozsireny o pozadovanou hodnotu a o sumator 
% A = [plant_ss.A [0;0]]
% A = [A;0 0 1]

%rozsireni o sumator
As=[plant_ss.A  plant_ss.B ;zeros(1,2) 1]
Bs = [plant_ss.B;1]
Cs = [plant_ss.C 0]

%rozsireni o pozadovanou hodnotu
Ae = [[As [0;0;0]]; [0 0 0 1]] % ref hodnota je konstantni
Be = [Bs;0] %neovlivnena vstupem
Ce = [Cs -1] % vystupni matice pro regulacni odchylku

C = [Cs 0] %vystupni matice pro regulovanou velicinu
D = plant_ss.D

% zdrojovy pdf tvrdi, ze v pravym dolnim rohu A ma byt 1 a ze posledni
% prvek B ma byt 0

%parameters
np = 5
nc = 2
% constraints
ub = 100*ones(nc,1)
lb = -100*ones(nc,1)

% weights
yW = 1 %output weight
uW = 1 %input weight

Q = yW*eye(size(Ce,1))
R = uW*eye(size(Be,2))
cQ = cell(1,np)
cR = cell(1,nc)
cQ(:) = {Q}
cR(:) = {R}
Q = blkdiag(cQ{:})
R = blkdiag(cR{:})


%delta u matrices
K = eye(nc)-triu(ones(nc),-1)+triu(ones(nc),0)
M = zeros(nc,1)
M(1) = -1
L = [0 0 0 0] 


% prediction matrices for regulator problem
Px = []
Hx = []
P = []
H = []
for r = 1:np
    Hx_row = []
    H_row = []
    for c = 1:np
        Hx_row = [Hx_row mat_pow(Ae, r-c)*Be]
        H_row = [H_row Ce*mat_pow(Ae,r-c-1)*Be]
    end
    Hx = [Hx ; Hx_row]
    H = [H ; H_row]
    Px = [Px ; Ae^r]   
    P = [P ; Ce*mat_pow(Ae,r-1)]
end

H = H - diag(diag(H))+eye(length(H))*D %uprava prvku na diagonale

% Move blocking
% Mb lze aplikovat na uk nebo na Hx a H (ja to aplikuju na Hx a H)
Mb = [eye(nc);[zeros(np-nc,nc-1) ones(np-nc,1)]]
Hbx = Hx*Mb
Hb = H*Mb

w0 = 1


% predictions
x(:,1) = [0;0;0;w0] %stavovy vektor rozsireny o referencni hodnotu
y(1) = C*x(:,1)
e(1) = Ce*x(:,1)
du(:,1) = K*zeros(nc,1)+M*L*x(:,1)

for k = 1:1000
%     xk = Px*x(:,k) + Hbx*uk
%     x(:,k+1) = xk([1 2],1)
%     yk = P*x(:,k)+Hb*uk
%     y(k+1) = yk(1)
    G = (Hb'*Q*Hb + K'*R*K)
    f = (x(:,k)'*(P'*Q*Hb + L'*M'*R*K))'
    c = 1/2*x(:,k)'*(P'*Q'*P + L'*M'*R*M*L)*x(:,k)
    %c = 0
    uk = quadprog(G,f,[],[],[],[],lb,ub)
    %uk = quadprog(G,f,[],[],[],[])
    
    J(k) = 1/2*(uk'*G*uk + f'*uk + c)
    
    u(k) = uk(1)
    
    x(:,k+1) = Ae*x(:,k)+Be*u(k)
    y(k+1) = C*x(:,k+1)
    e(k+1) = Ce*x(:,k+1)
    ek(:,k+1) = P*x(:,k)+Hb*uk
    du(:,k+1) = K*uk+M*u(k)
end
time_v = (0:length(y)-1)*Ts
figure
subplot(3,2,1)
hold on
stairs(time_v,y)
plot(time_v,ones(1,length(time_v))*w0,'r')
hold off
title('y')
subplot(3,2,2)
stairs(time_v,e)
title('e')
subplot(3,2,3)
stairs(time_v(1:length(J)),J)
title('J')
subplot(3,2,4)
stairs(time_v(1:length(u)),u)
title('u')
subplot(3,2,[5 6])
stairs(time_v(1:length(du(1,:))),du(1,:))
title('delta u')

% %% offset-free tracking
% %pouziva stavovy popis rozsireny o pozadovanou hodnotu
% % A = [plant_ss.A [0;0]]
% % A = [A;0 0 1]
% A = [[plant_ss.A [0;0] [0;0]]; [0 0 1 0];[0 0 0 0]]
% B = [plant_ss.B; 0; 1]
% C = [plant_ss.C 0 0]
% Ce = [plant_ss.C -1 0]
% D = plant_ss.D
% 
% % zdrojovy pdf tvrdi, ze v pravym dolnim rohu A ma byt 1 a ze posledni
% % prvek B ma byt 0
% 
% %parameters
% np = 5
% nc = 2
% % constraints
% ub = 100*ones(nc,1)
% lb = -100*ones(nc,1)
% 
% % weights
% yW = 1 %output weight
% uW = 0.01 %input weight
% 
% Q = yW*eye(size(C,1))
% R = uW*eye(size(B,2))
% cQ = cell(1,np)
% cR = cell(1,nc)
% cQ(:) = {Q}
% cR(:) = {R}
% Q = blkdiag(cQ{:})
% R = blkdiag(cR{:})
% 
% 
% %delta u matrices
% K = eye(nc)-triu(ones(nc),-1)+triu(ones(nc),0)
% M = zeros(nc,1)
% M(1) = -1
% L = [0 0 0 1]
% 
% 
% % prediction matrices for regulator problem
% Px = []
% Hx = []
% P = []
% H = []
% for r = 1:np
%     Hx_row = []
%     H_row = []
%     for c = 1:np
%         Hx_row = [Hx_row mat_pow(A, r-c)*B]
%         H_row = [H_row Ce*mat_pow(A,r-c-1)*B]
%     end
%     Hx = [Hx ; Hx_row]
%     H = [H ; H_row]
%     Px = [Px ; A^r]   
%     P = [P ; Ce*mat_pow(A,r-1)]
% end
% 
% H = H - diag(diag(H))+eye(length(H))*D %uprava prvku na diagonale
% 
% % Move blocking
% % Mb lze aplikovat na uk nebo na Hx a H (ja to aplikuju na Hx a H)
% Mb = [eye(nc);[zeros(np-nc,nc-1) ones(np-nc,1)]]
% Hbx = Hx*Mb
% Hb = H*Mb
% 
% w0 = 1
% 
% 
% % predictions
% x(:,1) = [0;0;w0;0] %stavovy vektor rozsireny o referencni hodnotu
% y(1) = C*x(:,1)
% e(1) = Ce*x(:,1)
% du(:,1) = K*zeros(nc,1)+M*L*x(:,1)
% 
% for k = 1:100
% %     xk = Px*x(:,k) + Hbx*uk
% %     x(:,k+1) = xk([1 2],1)
% %     yk = P*x(:,k)+Hb*uk
% %     y(k+1) = yk(1)
%     G = (Hb'*Q*Hb + K'*R*K)
%     f = (x(:,k)'*(P'*Q*Hb + L'*M'*R*K))'
%     c = 1/2*x(:,k)'*(P'*Q'*P + L'*M'*R*M*L)*x(:,k)
%     %c = 0
%     uk = quadprog(G,f,[],[],[],[],lb,ub)
%     %uk = quadprog(G,f,[],[],[],[])
%     
%     J(k) = 1/2*(uk'*G*uk + f'*uk + c)
%     
%     u(k) = uk(1)
%     
%     x(:,k+1) = A*x(:,k)+B*u(k)
%     y(k+1) = C*x(:,k+1)
%     e(k+1) = Ce*x(:,k+1)
%     ek(:,k+1) = P*x(:,k)+Hb*uk
%     du(:,k+1) = K*uk+M*L*x(:,k)
% end
% time_v = (0:length(y)-1)*Ts
% figure
% subplot(3,2,1)
% hold on
% stairs(time_v,y)
% plot(time_v,ones(1,length(time_v))*w0,'r')
% hold off
% title('y')
% subplot(3,2,2)
% stairs(time_v,e)
% title('e')
% subplot(3,2,3)
% stairs(time_v(1:length(J)),J)
% title('J')
% subplot(3,2,4)
% stairs(time_v(1:length(u)),u)
% title('u')
% subplot(3,2,[5 6])
% stairs(time_v(1:length(du(1,:))),du(1,:))
% title('delta u')

% %% ne offset free
% %% Problém servo - snaha minimalizovat e
% %pouziva stavovy popis rozsireny o pozadovanou hodnotu
% A = [plant_ss.A [0;0]]
% A = [A;0 0 1]
% B = [plant_ss.B; 0]
% C = [plant_ss.C 0]
% D = plant_ss.D
% 
% %parameters
% np = 5
% nc = 3
% % constraints
% ub = 50*ones(nc,1)
% lb = -50*ones(nc,1)
% 
% % weights
% yW = 1 %output weight
% uW = 0 %input weight
% Q = yW*eye(size(C,1))
% R = uW*eye(size(B,2))
% cQ = cell(1,np)
% cR = cell(1,nc)
% cQ(:) = {Q}
% cR(:) = {R}
% Q = blkdiag(cQ{:})
% R = blkdiag(cR{:})
% 
% 
% Ce = [plant_ss.C -1] % matice pro vypocet e
% % prediction matrices for regulator problem
% Px = []
% Hx = []
% P = []
% H = []
% for r = 1:np
%     Hx_row = []
%     H_row = []
%     for c = 1:np
%         Hx_row = [Hx_row mat_pow(A, r-c)*B]
%         H_row = [H_row Ce*mat_pow(A,r-c-1)*B]
%     end
%     Hx = [Hx ; Hx_row]
%     H = [H ; H_row]
%     Px = [Px ; A^r]   
%     P = [P ; Ce*mat_pow(A,r-1)]
% end
% 
% H = H - diag(diag(H))+eye(length(H))*D %uprava prvku na diagonale
% 
% % Move blocking
% % Mb lze aplikovat na uk nebo na Hx a H (ja to aplikuju na Hx a H)
% Mb = [eye(nc);[zeros(np-nc,nc-1) ones(np-nc,1)]]
% Hbx = Hx*Mb
% Hb = H*Mb
% 
% w0 = 1
% 
% 
% % predictions
% x(:,1) = [0;0;w0] %stavovy vektor rozsireny o referencni hodnotu
% y(1) = C*x(:,1)
% e(1) = Ce*x(:,1)
% 
% 
% for k = 1:6
% %     xk = Px*x(:,k) + Hbx*uk
% %     x(:,k+1) = xk([1 2],1)
% %     yk = P*x(:,k)+Hb*uk
% %     y(k+1) = yk(1)
%     G = (Hb'*Q*Hb + R)
%     f = (x(:,k)'*P'*Q*Hb)'
%     %c = x(:,k)'*(Px'*Q'*Px)*x(:,k)
%     c = 0
%     uk = quadprog(G,f,[],[],[],[],lb,ub)
%     %uk = quadprog(G,f,[],[],[],[])
%     
%     J(k) = 1/2*(uk'*G*uk + f'*uk + c)
%     
%     u(k) = uk(1)
%     
%     x(:,k+1) = A*x(:,k)+B*u(k)
%     y(k+1) = C*x(:,k+1)
%     e(k+1) = Ce*x(:,k+1)
%     ek(:,k+1) = P*x(:,k)+Hb*uk
% end
% time_v = (0:length(y)-1)*Ts
% figure
% subplot(2,2,1)
% hold on
% stairs(time_v,y)
% plot(time_v,ones(1,length(time_v))*w0,'r')
% hold off
% title('y')
% subplot(2,2,2)
% stairs(time_v,e)
% title('e')
% subplot(2,2,3)
% stairs(time_v(1:length(J)),J)
% title('J')
% subplot(2,2,4)
% stairs(time_v(1:length(u)),u)
% title('u')
% %% Porovnani s mpcDesigner toolboxem
% load('MPCDesignerSession.mat')
% mpc1 = MPCDesignerSession.AppData.Controllers.MPC
% sim(mpc1,6,1)
% %% J plot
% %J = 1/2*[x y z q r]*G*[x y z q r]'+f'*[x y z q r]'+c
% % 
% % [X,Y] = meshgrid(-2000:500:15000);
% % xJ = X(:);
% % y = Y(:);
% % sx = size(X);
% % %G = [1 -0.5;-0.5 2]
% % a=0.5*diag([xJ y]*G*[xJ';y'])+(f'*[xJ';y'])';
% % %a=0.5*diag([xJ y]*G*[xJ';y'])';
% % Z = reshape(a,sx);
% % 
% % figure
% % surf(X,Y,Z)
% % uk = quadprog(G,f,[],[],[],[])
% %% cost function
% % e = wk-yk
% % Q = 100
% % Je = 0
% % for i = 1:np-1
% %     Je = Je + e(i)'*Q*e(i)
% % end
% % 
% % R = 0.1
% % Ju = 0
% % for i = 1:nc-1
% %     Ju = Ju + uk(i)'*R*uk(i)
% % end
% % J = Je+Ju
% 
% %%
% 
% 
% %% Problém regulace - snaha dostat x do nuly
% % A = plant_ss.A
% % B = plant_ss.B
% % C = plant_ss.C
% % D = plant_ss.D
% % 
% % % prediction matrices for regulator problem
% % Px = []
% % Hx = []
% % P = []
% % H = []
% % for r = 1:np
% %     Hx_row = []
% %     H_row = []
% %     for c = 1:np
% %         Hx_row = [Hx_row mat_pow(A, r-c)*B]
% %         H_row = [H_row C*mat_pow(A,r-c-1)*B]
% %     end
% %     Hx = [Hx ; Hx_row]
% %     H = [H ; H_row]
% %     Px = [Px ; A^r]   
% %     P = [P ; C*mat_pow(A,r-1)]
% % end
% % 
% % H = H - diag(diag(H))+eye(length(H))*D %uprava prvku na diagonale
% % 
% % % Move blocking
% % % Mb lze aplikovat na uk nebo na Hx a H (ja to aplikuju na Hx a H)
% % Mb = [eye(nc);[zeros(np-nc,2) ones(np-nc,1)]]
% % Hbx = Hx*Mb
% % Hb = H*Mb
% % 
% % u0 = 1
% % uk = ones(1,nc)'*u0
% % 
% % % predictions
% % x(:,1) = [1;1]
% % y(1) = C*x(:,1)
% % for k = 1:10
% %     xk = Px*x(:,k) + Hbx*uk
% %     x(:,k+1) = xk([1 2],1)
% %     yk = P*x(:,k)+Hb*uk
% %     y(k+1) = yk(1)
% %     G = (Hbx'*Q'*Hbx + R')
% %     f = (x(:,k)'*Px'*Q'*Hbx)'
% %     c = x(:,k)'*(Px'*Q'*Px)*x(:,k)
% %     J = 1/2*(uk'*G*uk + f'*uk + c)
% % 
% %     uk = quadprog(G,f)
% % end
% 
% 
% 
