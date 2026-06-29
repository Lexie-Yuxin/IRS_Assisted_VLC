
function R = rate_lower_bound(P, G_LoS, G_NLoS)
% Lower bound of Achievable Data Rate
SNR_eff = ((exp(1)/(2*pi)) * ((P.P_tx ./ P.q) * P.R_PD)^2 * (G_LoS + G_NLoS)^2 ) / (P.N0 * P.BW);
%
R = P.BW * log2(1 + SNR_eff);
end
