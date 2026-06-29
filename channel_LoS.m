function G = channel_LoS(P, S)
% LoS Gain with FoV gating and blockage indicator

    AP = P.AP; 
    U  = S.user_pos;
    d  = norm(AP - U);           % distance: AP -> user

    % DEBUG
    % alpha = 0;   % PD normal pointing upward
    % beta  = 0;
    % S.alpha = alpha;
    % S.beta  = beta;

    % AP -> user:
    % cos_irradiance(AP, User, m)
    Phi_cos = cos_irradiance(AP, U, P.m);  
    if Phi_cos <= 0
        G = 0;
        return;
    end
    
    % For LoS,Light AP -> User，so the first para should be AP, the 2nd U:
    xi_cos = cos_incidence_from(AP, U, S.alpha, S.beta);

    
    % xi_cos = cos_incidence_from(U, AP, S.alpha, S.beta);

    if xi_cos <= 0
        G = 0;
        return;
    end

    % ---------- FoV & Gc ----------
    Gc = concentrator_gain(P, xi_cos);   % return 0 when out of FoV
    theta = acos(max(-1,min(1,xi_cos)));
    FoV_gate = (theta <= P.FoV) & (xi_cos > 0) & (Gc > 0);

    if ~FoV_gate
        G = 0;
        return;
    end

    % -LoS Gain(unblocked)
    G_los = ((P.m + 1) * P.A_PD) / (2*pi*d^2) ...
            * (Phi_cos.^P.m) ...
            * P.T_opt ...
            * Gc ...
            * xi_cos;

    % Blockage indicator I
    blocked = check_blockage(AP, U, P, S);
    I = ~blocked;     % I=1 means unblocked

    G = double(I) * G_los;

    % output debug
    % fprintf("Phi_cos=%f, xi_u_cos=%f, Gc=%f, G_LoS=%e\n", ...
    %     Phi_cos, xi_cos, Gc, G);
end


