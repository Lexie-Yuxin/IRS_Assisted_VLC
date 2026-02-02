function c = cos_incidence_from(src_point, user_pos, alpha, beta)
%COS_INCIDENCE_FROM  cos(xi): incidence at PD given a source at src_point and PD orientation (alpha,beta).
%
% src_point : 光源/反射点位置（AP、墙面、IRS tile 等）
% user_pos  : 用户位置
% alpha,beta: 用户设备（PD）姿态角

    % 方向：用户 -> 光源/反射点
    v = src_point - user_pos;
    d = norm(v); 
    if d < 1e-12
        c = 0; 
        return; 
    end
    vhat = v / d;

    % PD 法向（在用户坐标系下）
    n = [sin(alpha)*cos(beta), ...
         sin(alpha)*sin(beta), ...
         cos(alpha)];

    % 入射角余弦：光线（用户->光源） 与 PD 法向的夹角
    c = max(0, dot(vhat, n));
end

% function c = cos_incidence_from(src_point, user_pos, alpha, beta)
% %COS_INCIDENCE_FROM  cos(xi): incidence at PD given a source at src_point and PD orientation (alpha,beta).
% v = user_pos - src_point;
% d = norm(v); 
% if d<1e-12
%     c = 0; 
%     return; 
% end
% vhat = v / d;
% % PD normal vector
% n = [sin(alpha)*cos(beta), sin(alpha)*sin(beta), cos(alpha)];
% c = max(0, dot(vhat, n));
% end
