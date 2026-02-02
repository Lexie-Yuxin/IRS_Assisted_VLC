function OUT = plot_power_sweep_compare_layouts(varargin)
% Compare multiple IRS layouts under the SAME common scene (user + blockers).
%


thisFolder = fileparts(mfilename('fullpath'));
addpath(genpath(thisFolder)); rehash;

ip = inputParser;
ip.addParameter('layouts', ["single_wall","four_wall","ceiling_disc","corner_L"]);
ip.addParameter('nReal', 30, @(x)isnumeric(x)&&isscalar(x)&&x>0);
ip.addParameter('PtxVec', 2:2:14, @(x)isnumeric(x)&&isvector(x));
ip.addParameter('usePar', false, @(x)islogical(x)||isnumeric(x));
ip.addParameter('fixIrsGeometryAcrossLayouts', true, @(x)islogical(x)||isnumeric(x));
ip.parse(varargin{:});
OPT = ip.Results;
OPT.usePar = logical(OPT.usePar);
OPT.fixIrsGeometryAcrossLayouts = logical(OPT.fixIrsGeometryAcrossLayouts);


layouts = string(OPT.layouts(:).');
L = numel(layouts);

P = params();
P.verbose       = false;
P.R_target      = 30e6;
P.nRealizations = OPT.nReal;

PtxVec = OPT.PtxVec(:).';
nP = numel(PtxVec);
nReal = P.nRealizations;

% Result arrays: [L x nP]
ADR = zeros(L, nP);
OP  = zeros(L, nP);

% Common seeds per realization (common scene)
sceneSeeds = randi(1e9, nReal, 1);

% SCA seeds per (realization, layout)
scaSeeds = randi(1e9, nReal, L);

irsSeeds = randi(1e9, nReal, L);

% Parallel pool
if OPT.usePar
    try
        if isempty(gcp('nocreate')), parpool('threads'); end
    catch
        warning('Parallel pool not available. Falling back to serial.');
        OPT.usePar = false;
    end
end

for iptx = 1:nP
    P_local = P;
    P_local.P_tx = PtxVec(iptx);

    rate_layout = zeros(nReal, L);
    rate_wall   = zeros(nReal, 1);

    if OPT.usePar
        fprintf('par');
        parfor r = 1:nReal
            % --- common scene fixed per r ---
            rng(sceneSeeds(r), 'twister');
            S0 = generate_common_scene(P_local);

            % Wall baseline (same for all layouts)
            G_LoS = 0;
            G_wall = channel_wall_NLoS(P_local, S0);
            rate_wall(r) = rate_lower_bound(P_local, G_LoS, G_wall);

            for li = 1:L
                % IRS geometry seed (optional)
                if OPT.fixIrsGeometryAcrossLayouts
                    rng(irsSeeds(r,li), 'twister');
                end
                S = apply_irs_layout(P_local, S0, layouts(li));

                % SCA seed (independent)
                rng(scaSeeds(r,li), 'twister');
                [gBest, oBest] = sca_optimize_grouped(P_local, S);
                G_irs = channel_IRS_NLoS_grouped(P_local, S, gBest, oBest);
                rate_layout(r,li) = rate_lower_bound(P_local, G_LoS, G_irs);
            end

            if mod(r,10)==0 || r==nReal
            fprintf('[P_tx=%.1f W]  Scene %3d / %3d finished\n', ...
                P_local.P_tx, r, nReal);
            drawnow limitrate;
            end
        end
    else
        for r = 1:nReal
            rng(sceneSeeds(r), 'twister');
            S0 = generate_common_scene(P_local);

            G_LoS = 0;
            G_wall = channel_wall_NLoS(P_local, S0);
            rate_wall(r) = rate_lower_bound(P_local, G_LoS, G_wall);

            for li = 1:L
                if OPT.fixIrsGeometryAcrossLayouts
                    rng(irsSeeds(r,li), 'twister');
                end
                S = apply_irs_layout(P_local, S0, layouts(li));

                rng(scaSeeds(r,li), 'twister');
                [gBest, oBest] = sca_optimize_grouped(P_local, S);
                G_irs = channel_IRS_NLoS_grouped(P_local, S, gBest, oBest);
                rate_layout(r,li) = rate_lower_bound(P_local, G_LoS, G_irs);
            end
            if mod(r,10)==0 || r==nReal
            fprintf('[P_tx=%.1f W]  Scene %3d / %3d finished\n', ...
                P_local.P_tx, r, nReal);
            drawnow limitrate;
            end
        end
    end

    % Aggregate per layout
    for li = 1:L
        ADR(li, iptx) = mean(rate_layout(:,li));
        OP(li,  iptx) = mean(rate_layout(:,li) < P_local.R_target);
    end

    % (Optional) also return wall baseline if you want
    ADR_wall(iptx) = mean(rate_wall); 
    OP_wall(iptx)  = mean(rate_wall < P_local.R_target); 
end

% Plot
figure; hold on; grid on; box on;

L = numel(layouts);


colorMap = lines(L);   

markerSet = {'o','s','^','d','v','>'}; 

% ----- Left axis: Achievable Data Rate -----
yyaxis left
for li = 1:L
    plot(PtxVec, ADR(li,:), ...
        '-','LineWidth',1.6, ...
        'Color', colorMap(li,:), ...
        'Marker', markerSet{mod(li-1,numel(markerSet))+1}, ...
        'MarkerSize',6, ...
        'DisplayName', sprintf('%s : ADR', layouts(li)));
end
ylabel('Achievable data rate (bps)');

% ----- Right axis: Outage Probability -----
yyaxis right
for li = 1:L
    plot(PtxVec, OP(li,:), ...
        '--','LineWidth',1.6, ...
        'Color', colorMap(li,:), ...
        'Marker', markerSet{mod(li-1,numel(markerSet))+1}, ...
        'MarkerSize',6, ...
        'HandleVisibility','off'); 
end
ylabel('Outage probability');

xlabel('Transmit optical power (W)');
title('ADR and Outage vs Transmit Power (Same scenes, different IRS layouts)');
legend('Location','best');
set(gca,'FontSize',12,'LineWidth',1.1);