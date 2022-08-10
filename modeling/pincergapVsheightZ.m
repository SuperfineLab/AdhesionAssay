syms F g z
syms m_s m_x
syms I I_s
syms B_g B_s B_x B_gs
z_g = 2*z/g;
B_g = B_gs * I / I_s;
m_x = m_s*(coth((B_x/B_s)-(B_s/B_x)));
F = 4 * B_g * m_x / (pi * g * (1 + (z_g)^2));
F = subs(F, [I, I_s, m_s, B_s, B_x, B_gs] , [1, 1, 214.36e-15, 0.019, 1, 0.5]);
FF = matlabFunction(F);

% grid = [1:250];
% [g,z] = meshgrid(grid, grid);
% foo = FF(g,z);
% fig = figure; 

grid = [1:250];
g = [50, 100:100:500, 750];
leg = join([repmat("g = ", numel(g), 1), string(g(:))], '');
z = grid(:);
fooG = NaN(numel(z),numel(g));
for k = 1:numel(g)
    bah = FF(g(k),z);   
    fooG(:,k) = bah;
end
fig = figure; 
ax = gca;
plot(ax, z, fooG);
legend(leg);
ax.XLabel.String = 'z';
ax.YLabel.String = 'F';
ax.XScale = 'log';
ax.YScale = 'log';

grid = [1:1000];
z = [50, 100:100:500];
leg = join([repmat("z = ", numel(z), 1), string(z(:))], '');
g = grid(:);
fooZ = NaN(numel(g),numel(z));
for k = 1:numel(z)
    bah = FF(g,z(k));   
    fooZ(:,k) = bah;
end
fig = figure; 
ax = gca;
plot(ax, g, fooZ);
legend(leg);
ax.XLabel.String = 'g';
ax.YLabel.String = 'F';
ax.XScale = 'log';
ax.YScale = 'log';
legend(leg);

% surf(grid, grid, foo);
% xlim([1 25]); ylim([1 25]);
% xlabel('g'), ylabel('z'),
% colorbar

%[soln, parameters, conditions] = solve(eqn, g, 'ReturnConditions', true)
% g_quant = subs(soln, B_gs, 0.5)
% g_quant = subs(g_quant, I_s, 1)
% g_quant = subs(g_quant, B_s, 0.019)
% g_quant = subs(g_quant, m_s, 214.36e-15)
