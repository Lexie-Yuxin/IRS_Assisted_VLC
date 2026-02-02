function S = apply_irs_single_wall_rect(P, S)
% Single wall rectangular IRS on y = P.IRS.wallY (same as your original baseline)

kx = P.IRS.Kx;
kz = P.IRS.Ky;
L  = P.IRS.tile;

xs = linspace(P.IRS.center(1) - (kx*L)/2 + L/2, P.IRS.center(1) + (kx*L)/2 - L/2, kx);
zs = linspace(P.IRS.center(3) - (kz*L)/2 + L/2, P.IRS.center(3) + (kz*L)/2 - L/2, kz);
[Xk, Zk] = meshgrid(xs, zs);
Yk = P.IRS.wallY * ones(size(Xk));

S.IRS_tiles = [Xk(:), Yk(:), Zk(:)];
S.IRS_group_id = ones(size(S.IRS_tiles,1), 1);
S.N_groups = 1;
S.tile_area = L*L;
end