function OUT = plot_power_sweep_strip_position_only(varargin)


thisFolder = fileparts(mfilename('fullpath'));
addpath(genpath(thisFolder)); rehash;

ip = inputParser;
ip.addParameter('nReal', 30, @(x)isnumeric(x)&&isscalar(x)&&x>0);
ip.addParameter('PtxVec', 2:2:14, @(x)isnumeric(x)&&isvector(x));
ip.addParameter('zShifts', 0:0.5:2.0, @(x)isnumeric(x)&&isvector(x));
ip.addParameter('usePar', false, @(x)islogical(x)||isnumeric(x));
ip.addParameter('printEvery', 10, @(x)isnumeric(x)&&isscalar(x)&&x>0);
ip.parse(varargin{:});
OPT = ip.Results;
OPT.usePar = logical(OPT.usePar);

P = params();
P.verbose       = false;
P.R_target      = 30e6;
P.nRealizations = OPT.nReal;

PtxVec  = OPT.PtxVec(:).';
zShifts = OPT.zShifts(:).';
nP      = numel(PtxVec);
nZ      = numel(zShifts);
nReal   = P.nRealizations;

% Results: [nZ x nP]
ADR = zeros(nZ, nP);
OP  = zeros(nZ, nP);

% Common Random Numbers
sceneSeeds = randi(1e9, nReal, 1);
scaSeeds   = randi(1e9, nReal, nZ); % independent per zShift

% Optional parallel: disable progress printing clarity
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

    rates = zeros(nReal, nZ);

    fprintf('\n=== Strip vertical sweep | P_tx = %.1f W | nReal=%d | nZ=%d ===\n', ...
        P_local.P_tx, nReal, nZ);

    if OPT.usePar
        % Printing in parfor is not reliable; omit per-10 progress here.
        parfor r = 1:nReal
            rng(sceneSeeds(r), 'twister');
            S0 = generate_common_scene(P_local);

            for zi = 1:nZ
                % Build default four-wall strip (size fixed inside apply function)
                S = apply_irs_four_wall_strip(P_local, S0);

                % Shift IRS vertically (positive means move DOWN)
                S = shift_irs_in_z(P_local, S, zShifts(zi));

                rng(scaSeeds(r,zi), 'twister');
                [gBest, oBest] = sca_optimize_grouped(P_local, S);
                Girs = channel_IRS_NLoS_grouped(P_local, S, gBest, oBest);

                G_LoS = 0;
                rates(r,zi) = rate_lower_bound(P_local, G_LoS, Girs);
            end
        end
    else
        tP = tic;
        for r = 1:nReal
            rng(sceneSeeds(r), 'twister');
            S0 = generate_common_scene(P_local);

            for zi = 1:nZ
                S = apply_irs_four_wall_strip(P_local, S0);
                S = shift_irs_in_z(P_local, S, zShifts(zi));

                rng(scaSeeds(r,zi), 'twister');
                [gBest, oBest] = sca_optimize_grouped(P_local, S);
                Girs = channel_IRS_NLoS_grouped(P_local, S, gBest, oBest);

                G_LoS = 0;
                rates(r,zi) = rate_lower_bound(P_local, G_LoS, Girs);
            end

            if mod(r, OPT.printEvery)==0 || r==nReal
                fprintf('[P_tx=%.1f W] Scene %3d / %3d finished (%.1fs)\n', ...
                    P_local.P_tx, r, nReal, toc(tP));
                drawnow limitrate;
            end
        end
    end

    % Aggregate for this power point
    for zi = 1:nZ
        ADR(zi,iptx) = mean(rates(:,zi));
        OP(zi,iptx)  = mean(rates(:,zi) < P_local.R_target);
    end
end

% ---------- Plot ----------
% Use one color per zShift configuration; ADR solid, Outage dashed.
figure; hold on; grid on; box on;
cmap = lines(nZ);
mk = {'o','s','^','d','v','>'};

yyaxis left
for zi = 1:nZ
    plot(PtxVec, ADR(zi,:), '-', ...
        'Color', cmap(zi,:), 'LineWidth', 1.6, ...
        'Marker', mk{mod(zi-1,numel(mk))+1}, 'MarkerSize', 6, ...
        'DisplayName', sprintf('zShift=%.2f m : ADR', zShifts(zi)));
end
ylabel('Achievable data rate (bps)');

yyaxis right
for zi = 1:nZ
    plot(PtxVec, OP(zi,:), '--', ...
        'Color', cmap(zi,:), 'LineWidth', 1.6, ...
        'Marker', mk{mod(zi-1,numel(mk))+1}, 'MarkerSize', 6, ...
        'HandleVisibility', 'off');
end
ylabel('Outage probability');

xlabel('Transmit optical power (W)');
title('Four-wall strip: vertical position sweep (default strip size)');
legend('Location','best');
set(gca,'FontSize',12,'LineWidth',1.1);

OUT.PtxVec  = PtxVec;
OUT.zShifts = zShifts;
OUT.ADR     = ADR;
OUT.OP      = OP;
end

% ---- helper: shift IRS in z with clamping to room ----
function S = shift_irs_in_z(P, S, zShift)
if ~isfield(S,'IRS_tiles') || isempty(S.IRS_tiles)
    error('S.IRS_tiles not found. apply_irs_four_wall_strip must set it.');
end

L = P.IRS.tile;
zMin = L/2 + 1e-3;
zMax = P.roomZ - L/2 - 1e-3;

Z = S.IRS_tiles(:,3) - zShift;  % positive zShift => move DOWN
Z = min(zMax, max(zMin, Z));
S.IRS_tiles(:,3) = Z;
end