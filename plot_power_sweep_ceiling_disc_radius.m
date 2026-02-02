function OUT = plot_power_sweep_ceiling_disc_radius(varargin)
% plot_power_sweep_ceiling_disc_radius( 'Rvec', [1.2:0.1:2.0] );

thisFolder = fileparts(mfilename('fullpath'));
addpath(genpath(thisFolder)); rehash;

ip = inputParser;
ip.addParameter('nReal', 300, @(x)isnumeric(x)&&isscalar(x)&&x>0);
ip.addParameter('PtxVec', 2:2:14, @(x)isnumeric(x)&&isvector(x));
ip.addParameter('Rvec', 1.2:0.2:2.0, @(x)isnumeric(x)&&isvector(x));

ip.addParameter('usePar', false, @(x)islogical(x)||isnumeric(x));
ip.addParameter('printEvery', 10, @(x)isnumeric(x)&&isscalar(x)&&x>0);
ip.parse(varargin{:});
OPT = ip.Results;
OPT.usePar = logical(OPT.usePar);

P = params();
P.verbose       = false;
P.R_target      = 30e6;
P.nRealizations = OPT.nReal;

PtxVec = OPT.PtxVec(:).';
Rvec   = OPT.Rvec(:).';
nP     = numel(PtxVec);
nR     = numel(Rvec);
nReal  = P.nRealizations;

ADR = zeros(nR, nP);
% OP  = zeros(nR, nP);

% Common random numbers
sceneSeeds = randi(1e9, nReal, 1);
scaSeeds   = randi(1e9, nReal, nR);

if OPT.usePar
    try
        if isempty(gcp('nocreate')), parpool('threads'); end
    catch
        warning('Parallel pool unavailable, falling back to serial.');
        OPT.usePar = false;
    end
end

for iptx = 1:nP
    P_local = P;
    P_local.P_tx = PtxVec(iptx);

    rates = zeros(nReal, nR);

    fprintf('\n=== Ceiling disc radius sweep | P_tx = %.1f W | nR=%d ===\n', ...
        P_local.P_tx, nR);

    if OPT.usePar
        parfor r = 1:nReal
            rng(sceneSeeds(r),'twister');
            S0 = generate_common_scene(P_local);

            for ri = 1:nR
                P2 = P_local;
                P2.IRS.radius = Rvec(ri);

                S = apply_irs_ceiling_disc(P2, S0);

                rng(scaSeeds(r,ri),'twister');
                [gBest, oBest] = sca_optimize_grouped(P2, S);
                Girs = channel_IRS_NLoS_grouped(P2, S, gBest, oBest);

                G_LoS = 0;
                rates(r,ri) = rate_lower_bound(P2, G_LoS, Girs);
            end
        end
    else
        tP = tic;
        for r = 1:nReal
            rng(sceneSeeds(r),'twister');
            S0 = generate_common_scene(P_local);

            for ri = 1:nR
                P2 = P_local;
                P2.IRS.radius = Rvec(ri);

                S = apply_irs_ceiling_disc(P2, S0);

                rng(scaSeeds(r,ri),'twister');
                [gBest, oBest] = sca_optimize_grouped(P2, S);
                Girs = channel_IRS_NLoS_grouped(P2, S, gBest, oBest);

                G_LoS = 0;
                rates(r,ri) = rate_lower_bound(P2, G_LoS, Girs);
            end

            if mod(r,OPT.printEvery)==0 || r==nReal
                fprintf('[P_tx=%.1f W] Scene %3d / %3d finished (%.1fs)\n', ...
                    P_local.P_tx, r, nReal, toc(tP));
                drawnow limitrate;
            end
        end
    end

    for ri = 1:nR
        ADR(ri,iptx) = mean(rates(:,ri));
        % OP(ri,iptx)  = mean(rates(:,ri) < P_local.R_target);
    end
end

% -------- Plot --------
figure; hold on; grid on; box on;
cmap = lines(nR);
mk = {'o','s','^','d','v','>'};

yyaxis left
for ri = 1:nR
    plot(PtxVec, ADR(ri,:), '-', 'Color', cmap(ri,:), ...
        'LineWidth',1.6, 'Marker', mk{mod(ri-1,numel(mk))+1}, ...
        'DisplayName', sprintf('R=%.1f m : ADR', Rvec(ri)));
end
ylabel('Achievable data rate (bps)');

% yyaxis right
% for ri = 1:nR
%     plot(PtxVec, OP(ri,:), '--', 'Color', cmap(ri,:), ...
%         'LineWidth',1.6, 'Marker', mk{mod(ri-1,numel(mk))+1}, ...
%         'HandleVisibility','off');
% end
% ylabel('Outage probability');

xlabel('Transmit optical power (W)');
title('Ceiling circular IRS: radius sweep');
legend('Location','best');
set(gca,'FontSize',12,'LineWidth',1.1);

OUT.PtxVec = PtxVec;
OUT.Rvec   = Rvec;
OUT.ADR    = ADR;
% OUT.OP     = OP;
end