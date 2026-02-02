function S = generate_common_scene(P)
% Extended Simulation

% Generates ONLY common random parts: user, orientation, blockers, wall patches.
% IRS geometry is NOT generated here.

% --- User position (use your current distribution) ---
xu = P.roomX/2 + (rand()-0.5)*1.0;
yu = P.roomY/2 + (rand()-0.5)*1.0;
zu = P.user_h;
S.user_pos = [xu, yu, zu];

% --- User body center ---
center_dir = [P.roomX/2 - xu, P.roomY/2 - yu, 0];
if norm(center_dir) < 1e-9, center_dir = [1,0,0]; end
center_dir = center_dir / norm(center_dir);
S.user_body_center = S.user_pos - center_dir * P.user_body_offset;

% --- Device orientation ---
alpha = laplace_clip(P.alpha_mu, P.alpha_sig, 0, pi/2);
beta  = (P.beta_minmax(2)-P.beta_minmax(1))*rand() + P.beta_minmax(1);
S.alpha = alpha; S.beta = beta;

% --- Blockers ---
S.blockers = zeros(P.N_blockers, 3);
for i=1:P.N_blockers
    bx = P.roomX/2 + (rand()-0.5)*1.0;
    by = P.roomY/2 + (rand()-0.5)*1.0;
    S.blockers(i,:) = [bx, by, 0];
end

% --- Wall patches (baseline) ---
kx = P.wall.Kx; kz = P.wall.Ky; L = P.wall.tile;
xs2 = linspace(P.AP(1) - (kx*L)/2 + L/2, P.AP(1) + (kx*L)/2 - L/2, kx);
zs2 = linspace(P.roomZ/2 - (kz*L)/2 + L/2, P.roomZ/2 + (kz*L)/2 - L/2, kz);
[Xw, Zw] = meshgrid(xs2, zs2);
Yw = P.wall.y * ones(size(Xw));
S.wall_tiles = [Xw(:), Yw(:), Zw(:)];

S.tile_area = P.IRS.tile * P.IRS.tile; % default, can be overwritten by layout if needed
end

function a = laplace_clip(mu, b, lo, hi)
u = rand() - 0.5;
x = mu - b * sign(u) * log(1 - 2*abs(u));
a = min(hi, max(lo, x));
end
