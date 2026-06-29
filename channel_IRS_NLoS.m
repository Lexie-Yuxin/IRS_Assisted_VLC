function G = channel_IRS_NLoS(P, S, gamma, omega)
% Channel gain of First-order NLoS Reflection

    U  = S.user_pos;          
    AP = P.AP;                
    K  = size(S.IRS_tiles, 1);

    % IRS tile (coordinated angle)
    n_m = [sin(gamma)*cos(omega), sin(gamma)*sin(omega), cos(gamma)];

    acc = 0;

    for k = 1:K
        tk = S.IRS_tiles(k,:);       % the centre of the k-th IRS tile

        % Distance
        d = norm(AP - U);
        da = norm(AP - tk);          % AP -> IRS tile
        du = norm(U  - tk);          % IRS tile -> user
        if da < 1e-12 || du < 1e-12
            continue;
        end

        % LED -> tile：Lambertian order cos^m(Phi_a^k)
        Phi_a_cos = cos_irradiance(AP, tk, P.m);
        if Phi_a_cos <= 0
            continue;
        end

        % Incident on IRS: cos(xi_a^k)
        dir_ta   = (AP - tk) / da;        % tile -> AP
        xi_a_cos = max(0, dot(dir_ta, n_m));
        if xi_a_cos <= 0
            continue;
        end

        % IRS -> user: cos(Phi_u^k)
        dir_su    = (U - tk) / du;        % tile -> user
        Phi_u_cos = max(0, dot(dir_su, n_m));
        if Phi_u_cos <= 0
            continue;
        end

        % User side incident angle（cos_incidence_from）
        xi_u_cos = cos_incidence_from(tk, U, S.alpha, S.beta);
        if xi_u_cos <= 0
            continue;
        end

        Gc = concentrator_gain(P, xi_u_cos);
        if Gc == 0
            continue;
        end

        % NLoS gain of a single IRS tile 的 NLoS
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


