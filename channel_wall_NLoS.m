function G = channel_wall_NLoS(P, S)
% First-order wall reflection (NLoS) per Eq. (4)

    U  = S.user_pos;      
    AP = P.AP;            
    K  = size(S.wall_tiles,1);

    acc = 0;

    for k = 1:K
        wk = S.wall_tiles(k,:);   % 第 k 块墙面小块 [1x3]

        % 距离
        d = norm(AP - U);
        da = norm(AP - wk);       % AP -> wall
        du = norm(U  - wk);       % wall -> user
        if da < 1e-12 || du < 1e-12
            continue;
        end

        % 固定墙法向（指向房间内部）
        n_wall = [0, -1, 0];      % 例如 y 轴向内

        % ----- LED -> wall：Lambertian cos^m(Phi_a^k) -----
        Phi_a_cos = cos_irradiance(AP, wk, P.m);
        if Phi_a_cos <= 0
            continue;             % 这块墙不在 LED 主瓣内
        end

        % ----- 入射到墙：cos(xi_a^k) -----
        dir_aw   = (AP - wk) / da;             % wall -> AP
        xi_a_cos = max(0, dot(dir_aw, n_wall));
        if xi_a_cos <= 0
            continue;
        end

        % ----- 墙 -> 用户：cos(Phi_u^k) -----
        dir_wu   = (U - wk) / du;             % wall -> user
        Phi_u_cos = max(0, dot(dir_wu, n_wall));
        if Phi_u_cos <= 0
            continue;
        end

        % ----- 用户端入射角 & FoV -----
        xi_u_cos = cos_incidence_from(wk, U, S.alpha, S.beta);
        if xi_u_cos <= 0
            continue;
        end

        Gc = concentrator_gain(P, xi_u_cos);  % FoV gating
        if Gc == 0
            continue;
        end

        % ----- 单块墙面的 NLoS 增益（Eq. (4)） -----
        term = P.wall.rho * ((P.m+1)*P.A_PD)/(2*pi^2*da^2*du^2) * d * S.tile_area * ...
               (Phi_a_cos.^P.m) * xi_a_cos * Phi_u_cos * xi_u_cos * P.T_opt * Gc;

        acc = acc + term;
    end

    G = acc;
end


