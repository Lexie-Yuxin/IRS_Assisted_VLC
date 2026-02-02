function S = generate_scenario(P)
% Randomize user position, device orientation, blockers, and discretize IRS/wall tiles.

% --- User position (uniform in room footprint) ---
% xu = rand()*P.roomX;
% yu = rand()*P.roomY;

xu = P.roomX/2 + (rand()-0.5)*1.0;  %  +-0.5 m
yu = P.roomY/2 + (rand()-0.5)*1.0;

% xu = 2.5;
% yu = 1.5;
zu = P.user_h;
S.user_pos = [xu, yu, zu];


% User body center (behind the PD by offset toward room center as a crude model)
center_dir = [P.roomX/2 - xu, P.roomY/2 - yu, 0];
if norm(center_dir) < 1e-9, center_dir = [1,0,0]; end
center_dir = center_dir / norm(center_dir);
S.user_body_center = S.user_pos - center_dir * P.user_body_offset;

% --- Device orientation angles ---
alpha = laplace_clip(P.alpha_mu, P.alpha_sig, 0, pi/2);
beta  = (P.beta_minmax(2)-P.beta_minmax(1))*rand() + P.beta_minmax(1);
S.alpha = alpha; S.beta = beta;

% --- Blockers ---
S.blockers = zeros(P.N_blockers, 3); % x, y, z_base (floor)
for i=1:P.N_blockers
    % bx = rand()*P.roomX;
    % by = rand()*P.roomY;
    bx = P.roomX/2 + (rand()-0.5)*1.0;  %  +-0.5 m
    by = P.roomY/2 + (rand()-0.5)*1.0;
    S.blockers(i,:) = [bx, by, 0];
end

% --- IRS tiles coordinates (K rectangular grid on y = wall) ---
kx = P.IRS.Kx; kz = P.IRS.Ky; L = P.IRS.tile;
xs = linspace(P.IRS.center(1) - (kx*L)/2 + L/2, P.IRS.center(1) + (kx*L)/2 - L/2, kx);
zs = linspace(P.IRS.center(3) - (kz*L)/2 + L/2, P.IRS.center(3) + (kz*L)/2 - L/2, kz);
[Xk, Zk] = meshgrid(xs, zs);
Yk = P.IRS.wallY * ones(size(Xk));
S.IRS_tiles = [Xk(:), Yk(:), Zk(:)]; % K x 3

% --- Wall patches (same grid) ---
xs2 = linspace(P.AP(1) - (kx*L)/2 + L/2, P.AP(1) + (kx*L)/2 - L/2, kx);
zs2 = zs;
[Xw, Zw] = meshgrid(xs2, zs2);
Yw = P.wall.y * ones(size(Xw));
S.wall_tiles = [Xw(:), Yw(:), Zw(:)];
S.tile_area = L*L;
end

function a = laplace_clip(mu, b, lo, hi)
% Sample from a Laplace-like distribution (approx via difference of exponentials) and clip.
% MATLAB doesn't have laprnd by default; we emulate quickly.
u = rand() - 0.5;
x = mu - b * sign(u) * log(1 - 2*abs(u));
a = min(hi, max(lo, x));

end
