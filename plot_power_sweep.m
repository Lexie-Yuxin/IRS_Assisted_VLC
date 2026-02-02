
function plot_power_sweep(varargin)
% Name-Value args:
%   nReal   : Monte Carlo runs per power point
%   usePar  : Use parallel pool if available (default false)
%   Nsamp   : #mirrors sampled for Baseline1/2 fast evaluation 
%   PtxVec  : Transmit optical power sweep (W) (default 2:2:14)
%
% Dependencies: params.m, generate_scenario.m, channel_* functions, sca_optimize.m

    % --- Path & arg parsing ---
    thisFolder = fileparts(mfilename('fullpath'));
    addpath(genpath(thisFolder)); rehash;

    ip = inputParser;
    ip.addParameter('nReal', 30, @(x)isnumeric(x)&&isscalar(x)&&x>0);
    ip.addParameter('usePar', false, @(x)islogical(x) || isnumeric(x));
    ip.addParameter('Nsamp', 30, @(x)isnumeric(x)&&isscalar(x)&&x>0);
    ip.addParameter('PtxVec', 2:2:14, @(x)isnumeric(x)&&isvector(x));
    ip.parse(varargin{:});
    OPT = ip.Results;
    OPT.usePar = logical(OPT.usePar);

    % --- Base params ---
    P = params();
    P.verbose       = false;
    P.R_target      = 30e6;         % 30 Mbps threshold
    P.nRealizations = OPT.nReal;


    PtxVec = OPT.PtxVec(:).';
    nP     = numel(PtxVec);

    ADR_prop = zeros(1,nP); ADR_b1 = ADR_prop; ADR_b2 = ADR_prop; ADR_wall = ADR_prop;
    OP_prop  = ADR_prop;    OP_b1  = ADR_prop;  OP_b2  = ADR_prop;  OP_wall  = ADR_prop;

    % --- Common Random Numbers (same scenes and SCA seeds across power points) ---
    nReal   = P.nRealizations;
    sceneSeeds = randi(1e9, nReal, 1);
    scaSeeds   = randi(1e9, nReal, 1);

    fprintf('\n=== Start power sweeping ===\n');
    tAll = tic;

    % Optional parallel pool
    if OPT.usePar
        try
            if isempty(gcp('nocreate')), parpool('threads'); end
        catch
            warning('Parallel pool not available. Falling back to serial.');
            OPT.usePar = false;
        end
    end

    % --- Power sweep loop ---
    for iptx = 1:nP
        P_local       = P;
        P_local.P_tx  = PtxVec(iptx);

        fprintf('\n[%d/%d] === P_tx = %.1f W ===\n', iptx, nP, P_local.P_tx);
        tP = tic;

        rate_wall = zeros(nReal,1);
        rate_prop = zeros(nReal,1);
        rate_b1   = zeros(nReal,1);
        rate_b2   = zeros(nReal,1);

        if OPT.usePar
            parfor r = 1:nReal
                % Fixed scene per r across all power points
                rng(sceneSeeds(r), 'twister');
                S = generate_scenario(P_local);

                % Assuming no IRS
                G_LoS = 0;

                % Wall only
                G_wall = channel_wall_NLoS(P_local, S);
                % dfprintf('G_Wall = %d \n',G_wall);

                rw = rate_lower_bound(P_local, G_LoS, G_wall);

                % Proposed (shared angles)
                rng(scaSeeds(r), 'twister');
                [gBest, oBest] = sca_optimize(P_local, S);
                G_irs_prop = channel_IRS_NLoS(P_local, S, gBest, oBest);
                rp = rate_lower_bound(P_local, G_LoS, G_irs_prop);

                % Baseline 1 fast (per-mirror optimization on a sampled subset)
                rng(scaSeeds(r)+1, 'twister');
                rb1 = baseline1_rate_fast(P_local, S, G_LoS, OPT.Nsamp);

                % Baseline 2 fast (per-mirror random angles on a sampled subset)
                rng(scaSeeds(r)+2, 'twister');
                rb2 = baseline2_rate_fast(P_local, S, G_LoS, OPT.Nsamp);

                rate_wall(r) = rw; rate_prop(r) = rp;
                rate_b1(r)   = rb1; rate_b2(r)  = rb2;
            end
            fprintf('   %d scenes done (elapsed %.1fs)\n', nReal, toc(tP));
        else
            for r = 1:nReal
                % Fixed scene per r across all power points
                rng(sceneSeeds(r), 'twister');
                S = generate_scenario(P_local);

                % Assuming no IRS
                G_LoS = 0;

                % Wall only
                G_wall = channel_wall_NLoS(P_local, S);
                % fprintf('G_Wall = %d \n',G_wall);

                rate_wall(r) = rate_lower_bound(P_local, G_LoS, G_wall);

                % Proposed (shared angles)
                rng(scaSeeds(r), 'twister');
                [gBest, oBest] = sca_optimize(P_local, S);
                G_irs_prop = channel_IRS_NLoS(P_local, S, gBest, oBest);
                rate_prop(r) = rate_lower_bound(P_local, G_LoS, G_irs_prop);

                % Baseline 1 fast
                rng(scaSeeds(r)+1, 'twister');
                rate_b1(r) = baseline1_rate_fast(P_local, S, G_LoS, OPT.Nsamp);

                % Baseline 2 fast
                rng(scaSeeds(r)+2, 'twister');
                rate_b2(r) = baseline2_rate_fast(P_local, S, G_LoS, OPT.Nsamp);

                if mod(r,100)==0 || r==nReal
                    fprintf('   Scene %3d / %3d done (elapsed %.1fs)\n', r, nReal, toc(tP));
                    drawnow limitrate;
                end
            end
        end

        % Aggregate
        ADR_prop(iptx) = mean(rate_prop);
        ADR_b1(iptx)   = mean(rate_b1);
        ADR_b2(iptx)   = mean(rate_b2);
        ADR_wall(iptx) = mean(rate_wall);

        OP_prop(iptx)  = mean(rate_prop < P_local.R_target);
        OP_b1(iptx)    = mean(rate_b1   < P_local.R_target);
        OP_b2(iptx)    = mean(rate_b2   < P_local.R_target);
        OP_wall(iptx)  = mean(rate_wall < P_local.R_target);

        fprintf('=== P_tx = %.1f W finished (%.1fs) | ADR_prop=%.2f Mbps, OP_prop=%.1f%% ===\n', ...
            P_local.P_tx, toc(tP), ADR_prop(iptx)/1e6, 100*OP_prop(iptx));
    end

    fprintf('\n=== All power points done, total time = %.1fs ===\n', toc(tAll));

    % --- Plot: left axis ADR (Mbps); 
    figure; hold on; grid on; box on;
    yyaxis left

    plot(PtxVec, ADR_prop,'-o','Color',[0 0.75 0.75],'Marker','o','LineWidth', 1.2,'DisplayName','IRS only: Proposed');
    plot(PtxVec, ADR_b1 ,'-o','Color',[0 0.45 0.74],'Marker','o','LineWidth', 1.2,'DisplayName','IRS only: Baseline 1');
    plot(PtxVec, ADR_b2 ,'--s','Color',[0,1,0],'Marker','s','LineWidth', 1.2,'DisplayName','IRS only: Baseline 2');
    plot(PtxVec, ADR_wall,'-d','Color',[0.47 0.67 0.19],'Marker','d','LineWidth', 1.2,'DisplayName','Wall only');

    ylabel('Achievable data rate (bps)');

    % right axis outage probability ---
    yyaxis right
    plot(PtxVec, OP_prop, '-s', 'Color', [0.64 0.08 0.18], 'Marker', 's', 'LineWidth', 1.2,'DisplayName','IRS only: Proposed');
    plot(PtxVec, OP_b1,'--v', 'Color', [0.85 0.33 0.10], 'Marker', 'v', 'LineWidth', 1.2,'DisplayName','IRS only: Baseline 1');
    plot(PtxVec, OP_b2,'-^','color',[0.49 0.18 0.56],'Marker','^','Linewidth',1.2,'DisplayName','IRS only: Baseline 2');
    plot(PtxVec, OP_wall,'-d','color',[0.25,0.13,0],'Marker','d','Linewidth',1.2,'DisplayName','Wall only');
    
    ylabel('Outage probability');
    % 'HandleVisibility','off'

    xlabel('Transmit optical power (W)');
    legend('Location','best');
    title('ADR & Outage vs Transmit Power (No LoS)');
    set(gca,'FontSize',12,'LineWidth',1);

    % Optional save:
    % print(gcf, 'fig3_power_sweep.png', '-dpng', '-r300');
end

% ===== Baseline 1 : per-mirror optimization on a sampled subset =====
function R = baseline1_rate_fast(P, S, G_LoS, Nsamp)
    K = size(S.IRS_tiles,1);
    Nsamp = min(Nsamp, K);
    idx = randperm(K, Nsamp);

    % lighter inner SCA
    P_fast = P;
    P_fast.SCA.T_max    = min(P.SCA.T_max, 20);
    P_fast.SCA.N_agents = min(P.SCA.N_agents, 12);

    acc = 0;
    for ii = 1:Nsamp
        k = idx(ii);
        S2 = S;
        S2.IRS_tiles = S.IRS_tiles(k,:);      % isolate a single mirror
        [gk, ok] = sca_optimize(P_fast, S2);  % optimize angles for that mirror
        Gk = channel_IRS_NLoS(P, S2, gk, ok); % contribution of that mirror
        acc = acc + Gk;
    end
    acc = acc * (K / Nsamp);                  % scale back to full array
    R = rate_lower_bound(P, G_LoS, acc);
end

% ===== Baseline 2 : per-mirror random angles on a sampled subset =====
function R = baseline2_rate_fast(P, S, G_LoS, Nsamp)
    if nargin < 4
        % Nsamp = 1;
    end

    R_acc = 0;
    for i = 1:Nsamp
        gamma_rand = (rand - 0.5) * pi;
        omega_rand = (rand - 0.5) * pi;

        G_IRS_rand = channel_IRS_NLoS(P, S, gamma_rand, omega_rand);
        R_i        = rate_lower_bound(P, G_LoS, G_IRS_rand);

        R_acc = R_acc + R_i;
    end

    R = R_acc / Nsamp;   
end





