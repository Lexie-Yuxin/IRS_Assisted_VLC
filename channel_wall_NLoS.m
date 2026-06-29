function G = channel_wall_NLoS(P, S)
% NLoS Gain: First-order wall reflection

    U  = S.user_pos;      
    AP = P.AP;            
    K  = size(S.wall_tiles,1);

    acc = 0;

    for k = 1:K
        wk = S.wall_tiles(k,:);   % the k-th wall tile [1x3]

        % distance
        d = norm(AP - U);
        da = norm(AP - wk);       % AP -> wall
        du = norm(U  - wk);       % wall -> user
        if da < 1e-12 || du < 1e-12
            continue;
        end

        n_wall = [0, -1, 0];      

        % LED -> wall:
        Phi_a_cos = cos_irradiance(AP, wk, P.m);
        if Phi_a_cos <= 0
            continue;             % out of the main lobe of LED
        end

        % Incident on wall
        dir_aw   = (AP - wk) / da;             % wall -> AP
        xi_a_cos = max(0, dot(dir_aw, n_wall));
        if xi_a_cos <= 0
            continue;
        end

        % wall -> User:
        dir_wu   = (U - wk) / du;             % wall -> user
        Phi_u_cos = max(0, dot(dir_wu, n_wall));
        if Phi_u_cos <= 0
            continue;
        end

        % Incident angle on user side & FoV
        xi_u_cos = cos_incidence_from(wk, U, S.alpha, S.beta);
        if xi_u_cos <= 0
            continue;
        end

        Gc = concentrator_gain(P, xi_u_cos);  % FoV gating
        if Gc == 0
            continue;
        end

        % Contribution of a single wall tile NLoS
        term = P.wall.rho * ((P.m+1)*P.A_PD)/(2*pi^2*da^2*du^2) * d * S.tile_area * ...
               (Phi_a_cos.^P.m) * xi_a_cos * Phi_u_cos * xi_u_cos * P.T_opt * Gc;

        acc = acc + term;
    end

    G = acc;
end


