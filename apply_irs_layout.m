function S = apply_irs_layout(P, S0, layoutName)
% Attach IRS geometry to an existing common scene S0.
% layoutName: "four_wall", "ceiling_disc", "corner_L"

S = S0;

switch string(layoutName)
    case "four_wall"
        S = apply_irs_four_wall_strip(P, S);

    case "ceiling_disc"
        S = apply_irs_ceiling_disc(P, S);

    case "corner_L"
        S = apply_irs_corner_L(P, S);
    
    case "single_wall"
        S = apply_irs_single_wall_rect(P, S);

    otherwise
        error("Unknown layoutName: %s", layoutName);
end
end