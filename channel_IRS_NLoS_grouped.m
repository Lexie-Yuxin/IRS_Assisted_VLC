function G = channel_IRS_NLoS_grouped(P, S, gamma_vec, omega_vec)
% Grouped IRS NLoS gain. Each group shares (gamma, omega).
% Requires:
%   S.IRS_tiles, S.IRS_group_id, S.N_groups
%
% gamma_vec, omega_vec: [G x 1] or [1 x G]

U  = S.user_pos;
AP = P.AP;

K = size(S.IRS_tiles, 1);
Gg = S.N_groups;

gamma_vec = gamma_vec(:);
omega_vec = omega_vec(:);
assert(numel(gamma_vec) == Gg && numel(omega_vec) == Gg, 'Angle vector size mismatch');

% Precompute group normals in WORLD coordinates (special-case)
n_group = zeros(Gg,3);
for g = 1:Gg
    n_group(g,:) = [ ...
        sin(gamma_vec(g))*cos(omega_vec(g)), ...
        sin(gamma_vec(g))*sin(omega_vec(g)), ...
        cos(gamma_vec(g))];
end

acc = 0;
d = norm(AP - U); % AP->User distance (same across tiles)
if d < 1e-12, d = 1e-12; end

for k = 1:K
    tk  = S.IRS_tiles(k,:);
    gid = S.IRS_group_id(k);
    n_m = n_group(gid,:);

    da = norm(AP - tk);
    du = norm(U  - tk);
    if da < 1e-12 || du < 1e-12
        continue;
    end

    % LED -> tile Lambertian term
    Phi_a_cos = cos_irradiance(AP, tk, P.m);
    if Phi_a_cos <= 0
        continue;
    end

    % Incidence on IRS: cos(xi_a)
    dir_ta   = (AP - tk) / da;  % tile -> AP
    xi_a_cos = max(0, dot(dir_ta, n_m));
    if xi_a_cos <= 0
        continue;
    end

    % IRS -> user: cos(Phi_u)
    dir_su    = (U - tk) / du;  % tile -> user
    Phi_u_cos = max(0, dot(dir_su, n_m));
    if Phi_u_cos <= 0
        continue;
    end

    % Receiver incidence / FoV
    xi_u_cos = cos_incidence_from(tk, U, S.alpha, S.beta);
    if xi_u_cos <= 0
        continue;
    end

    Gc = concentrator_gain(P, xi_u_cos);
    if Gc == 0
        continue;
    end

    term = P.IRS.rho * ((P.m + 1) * P.A_PD) / (2 * pi^2 * da^2 * du^2) ...
           * d * S.tile_area ...
           * (Phi_a_cos.^P.m) ...
           * xi_a_cos ...
           * Phi_u_cos ...
           * xi_u_cos ...
           * P.T_opt ...
           * Gc;

    acc = acc + term;
end

G = acc;
end