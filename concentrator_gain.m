function Gc = concentrator_gain(P, xi_cos)
%CONCENTRATOR_GAIN  Non-imaging concentrator gain with FoV clipping.

    % if xi <= P.FoV
    % Gc = (P.n_refr^2)/(sin(P.FoV)^2);
    % else
    %     Gc = 0;
    % end
    
    xi = acos(max(-1,min(1,xi_cos)));
    Gc = zeros(size(xi));
    inside = xi <= P.FoV;
    Gc(inside) = (P.n_refr^2)/(sin(P.FoV)^2);
end
