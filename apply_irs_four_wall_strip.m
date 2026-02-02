function S = apply_irs_four_wall_strip(P, S)

L = P.IRS.tile; % 0.1m side length


kLenX   = 10;   % length in x-direction for y-walls (y=0, y=Y) kLenX(max)=30
kLenY   = 15;   % length in y-direction for x-walls (x=0, x=X) kLenY(max)=50
kHeight = 5;    % height in z-direction (all walls)

% Safety: clip if exceeding
kLenX = min(kLenX, floor(P.roomX / L));
kLenY = min(kLenY, floor(P.roomY / L));
kHeight = min(kHeight, floor(P.roomZ / L));

z_top = P.roomZ - L/2 - 1e-3;
z_bot = z_top - (kHeight*L) + L;
z_bot = max(L/2, z_bot);
zs = linspace(z_bot, z_top, kHeight);

xs = linspace(P.roomX/2 - (kLenX*L)/2 + L/2, P.roomX/2 + (kLenX*L)/2 - L/2, kLenX);

ys = linspace(P.roomY/2 - (kLenY*L)/2 + L/2, P.roomY/2 + (kLenY*L)/2 - L/2, kLenY);

tiles = [];
gids  = [];

% group 1: y=0 wall (strip runs along x)
[X1, Z1] = meshgrid(xs, zs); Y1 = (0 + 1e-3)*ones(size(X1));
tiles = [tiles; [X1(:), Y1(:), Z1(:)]];
gids  = [gids;  1*ones(numel(X1),1)];

% group 2: y=Y wall (strip runs along x)
[X2, Z2] = meshgrid(xs, zs); Y2 = (P.roomY - 1e-3)*ones(size(X2));
tiles = [tiles; [X2(:), Y2(:), Z2(:)]];
gids  = [gids;  2*ones(numel(X2),1)];

% group 3: x=0 wall (strip runs along y)
[Y3, Z3] = meshgrid(ys, zs); X3 = (0 + 1e-3)*ones(size(Y3));
tiles = [tiles; [X3(:), Y3(:), Z3(:)]];
gids  = [gids;  3*ones(numel(Y3),1)];

% group 4: x=X wall (strip runs along y)
[Y4, Z4] = meshgrid(ys, zs); X4 = (P.roomX - 1e-3)*ones(size(Y4));
tiles = [tiles; [X4(:), Y4(:), Z4(:)]];
gids  = [gids;  4*ones(numel(Y4),1)];

S.IRS_tiles    = tiles;
S.IRS_group_id = gids;
S.N_groups     = 4;
S.tile_area    = L*L;
end


% function S = apply_irs_four_wall_strip(P, S)
% L  = P.IRS.tile; % 0.1m side length
% kL = ; % Number of tiles on horizontal direction
% kz = ; % Number of tiles on vertical direction
% 
% z_top = P.roomZ - L/2 - 1e-3;
% z_bot = max(L/2, z_top - kz*L + L);
% zs = linspace(z_bot, z_top, kz);
% 
% xs = linspace(P.roomX/2 - (kL*L)/2 + L/2, P.roomX/2 + (kL*L)/2 - L/2, kL);
% ys = linspace(P.roomY/2 - (kL*L)/2 + L/2, P.roomY/2 + (kL*L)/2 - L/2, kL);
% 
% tiles = [];
% gids  = [];
% 
% % group 1: y=0
% [X1, Z1] = meshgrid(xs, zs); Y1 = (0 + 1e-3)*ones(size(X1));
% tiles = [tiles; [X1(:), Y1(:), Z1(:)]];
% gids  = [gids;  ones(numel(X1),1)];
% 
% % group 2: y=Y
% [X2, Z2] = meshgrid(xs, zs); Y2 = (P.roomY - 1e-3)*ones(size(X2));
% tiles = [tiles; [X2(:), Y2(:), Z2(:)]];
% gids  = [gids;  2*ones(numel(X2),1)];
% 
% % group 3: x=0
% [Y3, Z3] = meshgrid(ys, zs); X3 = (0 + 1e-3)*ones(size(Y3));
% tiles = [tiles; [X3(:), Y3(:), Z3(:)]];
% gids  = [gids;  3*ones(numel(Y3),1)];
% 
% % group 4: x=X
% [Y4, Z4] = meshgrid(ys, zs); X4 = (P.roomX - 1e-3)*ones(size(Y4));
% tiles = [tiles; [X4(:), Y4(:), Z4(:)]];
% gids  = [gids;  4*ones(numel(Y4),1)];
% 
% S.IRS_tiles = tiles;
% S.IRS_group_id = gids;
% S.N_groups = 4;
% 
% S.tile_area = L*L;
% end