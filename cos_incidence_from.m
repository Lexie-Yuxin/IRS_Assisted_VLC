function c = cos_incidence_from(src_point, user_pos, alpha, beta)
% COS_INCIDENCE_FROM  
% cos(xi): incidence at PD given a source at src_point and PD orientation (alpha,beta).

% src_point : source（AP, wall, IRS tile, etc.）
% user_pos  : User position
% alpha,beta: Orientation of User's Device(PD)

    % 方向：用户 -> 光源/反射点
    v = src_point - user_pos;
    d = norm(v); 
    if d < 1e-12
        c = 0; 
        return; 
    end
    vhat = v / d;

    % PD normal
    n = [sin(alpha)*cos(beta), ...
         sin(alpha)*sin(beta), ...
         cos(alpha)];

    % cos of incident angle
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
