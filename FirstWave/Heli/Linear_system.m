load('Linearization.mat')
LinearPlant = ss(LinearAnalysisToolProject.Results(1).Data.Value(:,:,1,1))
%%
syms l1 l2 l3 l4 l5 l6 l7 l8 s

L = [l1 l2 l3 l4;
    l5 l6 l7 l8]

Ar = LinearPlant.A - L'*LinearPlant.C
az = det(eye(4)*s-Ar)
az_star = (s+20)^4
coe_star = coeffs(az_star,s)
coe = coeffs(az,s)
az = az / coe(5)
coe = coeffs(az,s)
l = solve(coe_star==coe)
l(2)
%%
az_roots = eig(Ar)
az_star_roots = [-20;-20;-20;-20]
solve(az_roots==az_star_roots)