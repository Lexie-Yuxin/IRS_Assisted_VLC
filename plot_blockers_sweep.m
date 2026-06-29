function plot_blockers_sweep(varargin)
% y1: Outage Probability
% y2: ADR
% x: transmitted Power (2 ~ 14)
% @ Nb=2, 8, 20

    % Path & args
    thisFolder = fileparts(mfilename('fullpath'));
    addpath(genpath(thisFolder)); rehash;

    ip = inputParser;
    % Monte Carlo realisation times
    ip.addParameter('nReal', 100, @(x)isnumeric(x)&&isscalar(x)&&x>0); 
    ip.addParameter('usePar', false, @(x)islogical(x)||isnumeric(x));
    % transmitted Power (2, 4, 6, 8, 10, 12, 14)
    ip.addParameter('PtxVec', 2:2:14, @(x)isnumeric(x)&&isvector(x));
    % Nb: Number of blockages
    ip.addParameter('NbList', [2 8 20], @(x)isnumeric(x)&&isvector(x)&&all(x>=0));
    ip.parse(varargin{:});
    OPT = ip.Results;
    OPT.usePar = logical(OPT.usePar);

    % Base params
    Pbase = params();
    Pbase.verbose       = false;
    Pbase.R_target      = 30e6;     % outage threshold (bps)
    Pbase.nRealizations = OPT.nReal;

    PtxVec = OPT.PtxVec(:).';
    NbList = OPT.NbList(:).';
    nP  = numel(PtxVec);
    nNb = numel(NbList);
    nR  = OPT.nReal;

    % Storage: rows = Nb, cols = power points
    ADR_IRS  = zeros(nNb, nP);
    ADR_noI  = zeros(nNb, nP);
    OP_IRS   = zeros(nNb, nP);
    OP_noI   = zeros(nNb, nP);

    fprintf('\n=== Start blocker sweep (IRS-aided vs no IRS) ===\n');

    % Loop over blocker counts
    for ib = 1:nNb
        Nb = NbList(ib);
        fprintf('\n[Blockers %d/%d] N_b = %d\n', ib, nNb, Nb);

        % Common Random Numbers per Nb: same scenes/seeds across power points
        sceneSeeds = randi(1e9, nR, 1);
        scaSeeds   = randi(1e9, nR, 1);

        % Optional parallel pool
        usePar = OPT.usePar;
        if usePar
            try
                if isempty(gcp('nocreate')), parpool('threads'); end
            catch
                warning('Parallel pool not available. Falling back to serial.');
                usePar = false;
            end
        end

        for iptx = 1:nP
            P = Pbase;
            P.P_tx        = PtxVec(iptx);
            P.N_blockers  = Nb;     % key: set number of blockers for this run

            fprintf('  [Power %2d/%2d] P_tx = %.1f W ... ', iptx, nP, P.P_tx);
            tP = tic;

            rate_IRS = zeros(nR,1);
            rate_noI = zeros(nR,1);

            if usePar
                parfor r = 1:nR
                    rng(sceneSeeds(r), 'twister');
                    S = generate_scenario(P);

                    % LoS (blocked or not per geometry), Wall and IRS channels
                    G_LoS  = channel_LoS(P, S);
                    
                    G_wall = channel_wall_NLoS(P, S);

                    % no IRS: LoS + Wall
                    R_noI = rate_lower_bound(P, G_LoS, G_wall);

                    % IRS-aided: LoS + IRS (shared angles)
                    rng(scaSeeds(r), 'twister');

                    [gBest, oBest] = sca_optimize(P, S);
                    G_irs = channel_IRS_NLoS(P, S, gBest, oBest);
                    R_IRS = rate_lower_bound(P, G_LoS, G_irs);
                    
                    
                    rate_IRS(r) = R_IRS;
                    rate_noI(r) = R_noI;

                    % fprintf("G_LoS=%e, G_wall=%e, G_IRS=%e\n", G_LoS, G_wall, G_irs);
                end
            else
                for r = 1:nR
                    rng(sceneSeeds(r), 'twister');
                    S = generate_scenario(P);

                    G_LoS  = channel_LoS(P, S);
                    % display("G_LoS" + G_LoS)

                    G_wall = channel_wall_NLoS(P, S);
                    rate_noI(r) = rate_lower_bound(P, G_LoS, G_wall);

                    rng(scaSeeds(r), 'twister');

                    [gBest, oBest] = sca_optimize(P, S);
                    G_irs = channel_IRS_NLoS(P, S, gBest, oBest);
                    rate_IRS(r) = rate_lower_bound(P, G_LoS, G_irs);

                    
                    % fprintf("G_LoS=%e, G_wall=%e, G_IRS=%e\n", G_LoS, G_wall, G_irs);

                    if mod(r,100)==0 || r==nR
                        fprintf('\n     scene %3d/%3d (%.1fs)', r, nR, toc(tP));
                        % fprintf(" G_LoS=%e, G_wall=%e, G_IRS=%e\n", G_LoS, G_wall, G_irs);
                        drawnow limitrate;
                    end
                end
               
            end
        
            ADR_IRS(ib, iptx) = mean(rate_IRS);
            ADR_noI(ib, iptx) = mean(rate_noI);
            OP_IRS( ib, iptx) = mean(rate_IRS < P.R_target);
            OP_noI( ib, iptx) = mean(rate_noI < P.R_target);

            fprintf(' done in %.1fs | ADR_IRS=%.2f Mbps, OP_IRS=%.2f%%\n', ...
                toc(tP), ADR_IRS(ib,iptx)/1e6, 100*OP_IRS(ib,iptx));
        end
    end

    % Figure Plotting: ADR vs power for different Nb
    figure; hold on; grid on; box on;
    cmapIRS = lines(nNb);                % for IRS-aided
    cmapNoI = gray(nNb+2); cmapNoI = cmapNoI(2:end-1,:); % for no IRS (dashed)
    for ib = 1:nNb
        plot(PtxVec, ADR_IRS(ib,:)/1e8,  '-o', 'Color', cmapIRS(ib,:), 'LineWidth',1.4, ...
            'DisplayName', sprintf('IRS-aided, N_b=%d', NbList(ib)));
        plot(PtxVec, ADR_noI(ib,:)/1e8,  '--s', 'Color', cmapNoI(ib,:), 'LineWidth',1.4, ...
            'DisplayName', sprintf('no IRS, N_b=%d', NbList(ib)));
    end
    xlabel('Transmit optical power (W)');
    ylabel('Achievable data rate (×10^8 bps)');
    title('ADR vs Transmit Power for different number of blockers');
    legend('Location','northwest');
    set(gca,'FontSize',12,'LineWidth',1);

    % Figure: OP vs power for different Nb
    figure; hold on; grid on; box on;
    for ib = 1:nNb
        plot(PtxVec, OP_noI(ib,:),  '--s', 'Color', cmapNoI(ib,:), 'LineWidth',1.4, ...
            'DisplayName', sprintf('no IRS, N_b=%d', NbList(ib)));
        plot(PtxVec, OP_IRS(ib,:),  '-o',  'Color', cmapIRS(ib,:), 'LineWidth',1.4, ...
            'DisplayName', sprintf('IRS-aided, N_b=%d', NbList(ib)));
    end
    xlabel('Transmit optical power (W)');
    ylabel('Outage performance');
    title('Outage vs Transmit Power for different number of blockers');
    legend('Location','northeast');
    set(gca,'FontSize',12,'LineWidth',1);

end