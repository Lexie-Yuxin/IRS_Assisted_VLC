function S = apply_irs_corner_L(P, S)
L  = P.IRS.tile;
kL = P.IRS.Kx;
kz = P.IRS.Ky;

z_top = P.roomZ - L/2 - 1e-3;
z_bot = max(L/2, z_top - kz*L + L);
zs = linspace(z_bot, z_top, kz);

len = linspace(L/2, (kL*L) - L/2, kL);

tiles = [];
gids  = [];

% group 1: y=0 wall
[X1, Z1] = meshgrid(len, zs); Y1 = (0 + 1e-3)*ones(size(X1));
tiles = [tiles; [X1(:), Y1(:), Z1(:)]];
gids  = [gids;  ones(numel(X1),1)];

% group 2: x=0 wall
[Y2, Z2] = meshgrid(len, zs); X2 = (0 + 1e-3)*ones(size(Y2));
tiles = [tiles; [X2(:), Y2(:), Z2(:)]];
gids  = [gids;  2*ones(numel(Y2),1)];

S.IRS_tiles = tiles;
S.IRS_group_id = gids;
S.N_groups = 2;
S.tile_area = L*L;


end

