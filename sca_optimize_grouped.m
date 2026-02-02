function [gamma_best, omega_best, best_val] = sca_optimize_grouped(P, S)
% Sine-Cosine Algorithm (unchanged update rule), grouped angles.
% Decision variables: [gamma1, omega1, gamma2, omega2, ..., gammaG, omegaG]

Na = P.SCA.N_agents;
T  = P.SCA.T_max;
a  = P.SCA.a;

G = S.N_groups;
D = 2*G;  % dimension

% Initialize agents in [-pi/2, pi/2]^D
agents = (rand(Na, D) - 0.5) * pi;
fitness = zeros(Na,1);
for n = 1:Na
    fitness(n) = obj_grouped(agents(n,:), P, S);
end
[best_val, idx] = min(fitness);
dest = agents(idx,:);

for t = 1:T
    r1 = a - (t * a / T);
    r3 = 2*rand();
    for n = 1:Na
        for v = 1:D
            r2 = 2*pi*rand();
            r4 = rand();
            if r4 < 0.5
                agents(n,v) = agents(n,v) + r1 * sin(r2) * abs(r3*dest(v) - agents(n,v));
            else
                agents(n,v) = agents(n,v) + r1 * cos(r2) * abs(r3*dest(v) - agents(n,v));
            end
        end
        % project
        agents(n,:) = max(-pi/2, min(pi/2, agents(n,:)));
        fitness(n)  = obj_grouped(agents(n,:), P, S);
    end

    [cur_best, idx] = min(fitness);
    if cur_best < best_val
        best_val = cur_best;
        dest = agents(idx,:);
    end
end

gamma_best = dest(1:2:end).';
omega_best = dest(2:2:end).';
end

function f = obj_grouped(x, P, S)
gamma = x(1:2:end);
omega = x(2:2:end);
Girs  = channel_IRS_NLoS_grouped(P, S, gamma, omega);
f = -Girs;
end