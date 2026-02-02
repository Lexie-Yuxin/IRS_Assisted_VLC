function [gamma_best, omega_best, best_val] = sca_optimize(P, S)
% Sine-Cosine Algorithm to maximize sum_k G_NLoS^IRS(gamma,omega)
% We minimize negative channel gain.


Na = P.SCA.N_agents; T = P.SCA.T_max; a = P.SCA.a;
% Initialize agents uniformly in feasible box [-pi/2, +pi/2]^2
agents = (rand(Na,2)-0.5)*pi; % columns: gamma, omega
fitness = zeros(Na,1);
for n=1:Na
    fitness(n) = obj(agents(n,1), agents(n,2), P, S);
end
[best_val, idx] = min(fitness);
dest = agents(idx,:);
rateHist = zeros(T,1);

for t=1:T
    r1 = a - (t * a / T);
    r3 = 2*rand();
    for n=1:Na
        for v=1:2
            r2 = 2*pi*rand(); r4 = rand();
            if r4 < 0.5
                agents(n,v) = agents(n,v) + r1 * sin(r2) * abs(r3*dest(v) - agents(n,v));
            else
                agents(n,v) = agents(n,v) + r1 * cos(r2) * abs(r3*dest(v) - agents(n,v));
            end
        end
        % project to box
        agents(n,:) = max(-pi/2, min(pi/2, agents(n,:)));
        fitness(n) = obj(agents(n,1), agents(n,2), P, S);
    end
    [cur_best, idx] = min(fitness);
    if cur_best < best_val
        best_val = cur_best; dest = agents(idx,:);
    end
    G_IRS_iter = channel_IRS_NLoS(P, S, dest(1), dest(2));
    G_LoS_iter = channel_LoS(P, S);
    G_LoS_iter = max(G_LoS_iter, 1e-12);
    % disp("Start SCA, G_LoS = " + G_LoS_iter);

    rateHist(t) = rate_lower_bound(P, G_LoS_iter, G_IRS_iter);

end
gamma_best = dest(1); omega_best = dest(2);
end

function f = obj(gamma, omega, P, S)
G = channel_IRS_NLoS(P, S, gamma, omega);
f = -G; % minimize negative gain

end
