function debug_blockage_test()

% clc; clear; close all;

P = params();                   
P.verbose       = true;
P.nRealizations = 1;             
P.N_blockers    = 8;            
P.R_target      = 30e6;


% 
P.user_h = 1.2;                 % PD Height
user_x   = 2.5;             
user_y   = 1.5;             
U        = [user_x, user_y, P.user_h];


S = generate_scenario(P);

S.user_pos = U;

% Вывод
fprintf('\n================ DEBUG SCENE ================\n');
fprintf('User position U = [%.3f, %.3f, %.3f]\n', S.user_pos);

% ====== blocker  ======
S.blockers = zeros(P.N_blockers,3);
for i = 1:P.N_blockers
    S.blockers(i,1) = P.AP(1) + (rand()-0.5)*2;        
    S.blockers(i,2) = P.AP(2) + (rand()-0.5)*2;
    S.blockers(i,3) = 0;
end

fprintf('\nBlocker coordinates:\n');
disp(S.blockers);

% ====== 检查遮挡 ======
block_count = 0;
for i = 1:P.N_blockers
    c = S.blockers(i,:);
    if segment_cylinder_intersect(P.AP, S.user_pos, c, P.blocker_r, [0, P.blocker_h])
        block_count = block_count + 1;
        fprintf('  Blocker %d BLOCKS LoS  @ [%.3f %.3f]\n', i, c(1),c(2));
    end
end
fprintf('\nTotal blockers affecting LoS = %d / %d\n', block_count, P.N_blockers);

% ====== ======
G_LoS  = channel_LoS(P,S);
G_wall = channel_wall_NLoS(P,S);

% IRS: 
[gammaBest, omegaBest] = sca_optimize(P,S);
G_IRS = channel_IRS_NLoS(P,S,gammaBest,omegaBest);

% ======  ======
fprintf('\n========= CHANNEL GAINS =========\n');
fprintf('G_LoS         = %.6e\n', G_LoS);
fprintf('G_wall(NLoS)  = %.6e\n', G_wall);
fprintf('G_IRS(NLoS)   = %.6e\n', G_IRS);

% ======  ======
R_noIRS = rate_lower_bound(P, G_LoS, G_wall);
R_IRS   = rate_lower_bound(P, G_LoS, G_IRS);

fprintf('\n========= RATE RESULT =========\n');
fprintf('Rate no-IRS   = %.3f Mbps\n', R_noIRS/1e6);
fprintf('Rate IRS      = %.3f Mbps\n', R_IRS/1e6);

end

