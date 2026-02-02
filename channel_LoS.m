function G = channel_LoS(P, S)
%CHANNEL_LOS  LoS gain with FoV gating and blockage indicator (Eq. (1)&(2))

    AP = P.AP; 
    U  = S.user_pos;
    d  = norm(AP - U);           % AP -> user 距离

    % DEBUG
    % alpha = 0;   % PD normal pointing upward
    % beta  = 0;
    % S.alpha = alpha;
    % S.beta  = beta;

    % ---------- AP -> user：Lambertian 发射 cos^m(Phi) ----------
    % cos_irradiance(发射源位置, 接收点位置, m)
    Phi_cos = cos_irradiance(AP, U, P.m);  
    if Phi_cos <= 0
        G = 0;
        return;
    end
    %
    % 对 LoS，光线是从 AP -> 用户，所以第一个参数应该是 AP，第二个是 U：
    xi_cos = cos_incidence_from(AP, U, S.alpha, S.beta);

    % 如果你检查后发现 cos_incidence_from 的定义相反（即第一个是 user，第二个是光源）
    % 那就改成：
    % xi_cos = cos_incidence_from(U, AP, S.alpha, S.beta);

    if xi_cos <= 0
        G = 0;
        return;
    end

    % ---------- FoV & 聚光器增益 ----------
    Gc = concentrator_gain(P, xi_cos);   % 超出 FoV 时返回 0
    theta = acos(max(-1,min(1,xi_cos)));
    FoV_gate = (theta <= P.FoV) & (xi_cos > 0) & (Gc > 0);

    if ~FoV_gate
        G = 0;
        return;
    end

    % ---------- LoS 通道增益（未考虑阻挡） ----------
    G_los = ((P.m + 1) * P.A_PD) / (2*pi*d^2) ...
            * (Phi_cos.^P.m) ...
            * P.T_opt ...
            * Gc ...
            * xi_cos;

    % ---------- 阻挡指示函数 I ----------
    blocked = check_blockage(AP, U, P, S);
    I = ~blocked;     % I=1 表示未被阻挡

    G = double(I) * G_los;

    % 调试输出
    % fprintf("Phi_cos=%f, xi_u_cos=%f, Gc=%f, G_LoS=%e\n", ...
    %     Phi_cos, xi_cos, Gc, G);
end


