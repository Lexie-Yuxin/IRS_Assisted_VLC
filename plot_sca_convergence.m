
function plot_sca_convergence(P, S)
% Plot SCA convergence: Achievable data rate vs iteration index.
% No change to sca_optimize.m needed.

% ----- SCA params -----
Na = P.SCA.N_agents; 
T  = P.SCA.T_max; 
a  = P.SCA.a;

% Random init in [-pi/2, pi/2]^2
agents  = (rand(Na,2)-0.5)*pi;
fitness = zeros(Na,1);
for n=1:Na
    fitness(n) = -channel_IRS_NLoS(P, S, agents(n,1), agents(n,2)); % maximize channel -> minimize negative
end
[best_val, idx] = min(fitness);
dest = agents(idx,:);  
rateHist = zeros(T,1);

% Precompute LoS once for logging Eq.(7)
G_LoS_const = channel_LoS(P, S);

for t = 1:T
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
        agents(n,:) = max(-pi/2, min(pi/2, agents(n,:)));
        fitness(n)  = -channel_IRS_NLoS(P, S, agents(n,1), agents(n,2));
    end
    [cur_best, idx] = min(fitness);
    if t==1 || cur_best < best_val
        best_val = cur_best; 
        dest     = agents(idx,:);
    end

    % === Log achievable rate (Eq. 7) at current best (dest) ===
    G_IRS_best = channel_IRS_NLoS(P, S, dest(1), dest(2));
    rateHist(t) = rate_lower_bound(P, G_LoS_const, G_IRS_best);
end

% ----- Approximate global optimum via coarse grid search -----
gammaVals = linspace(-pi/2, pi/2, 50);
omegaVals = linspace(-pi/2, pi/2, 50);
bestGlobal = 0;
for g = gammaVals
    for o = omegaVals
        G_IRS = channel_IRS_NLoS(P, S, g, o);
        R = rate_lower_bound(P, G_LoS_const, G_IRS);
        if R > bestGlobal, bestGlobal = R; end
    end
end

% ----- Plot -----
figure; hold on; grid on; box on;
iters = 1:T;
plot(iters, rateHist, 'o-', 'LineWidth', 1.2, 'DisplayName','Algorithm 1');
yline(bestGlobal, 'r', 'LineWidth', 1.2, 'DisplayName','Global optimal solution');
xlabel('Iteration index');
ylabel('Achievable data rate (bps)');

legend('Location','southeast');
title('SCA Convergence');

end

%Run command
% P = params();
% S = generate_scenario(P);
% plot_sca_convergence(P, S);


