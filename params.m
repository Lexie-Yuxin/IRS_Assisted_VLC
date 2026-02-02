function P = params()
% All tunable parameters live here (room, optics, SCA, etc.)

% --- Geometry (room) ---
P.roomX = 5;           % m
P.roomY = 5;           % m
P.roomZ = 3;           % m
P.AP = [P.roomX/2, P.roomY/2, P.roomZ];  % LED AP at ceiling center
P.user_h = 0.75;       % photodetector height above floor (m)
P.user_body_r = 0.18;  % user body radius (self-block approx) (m)
P.user_body_offset = 0.36; % PD distance from body center (m)

% --- IRS panel (mirror array) on a wall ---
P.IRS.Kx = 10;         % mirrors along x
P.IRS.Ky = 30;         % mirrors along z (height)
P.IRS.tile = 0.1;      % mirror size (m)
P.IRS.rho = 0.95;       % reflection coefficient ρ_IRS (0..1)
% Place IRS on y = roomY wall, centered (x,z):
P.IRS.wallY = P.roomY; 
P.IRS.center = [P.roomX/2, P.IRS.wallY-1e-3, P.roomZ/2]; % tiny inset from wall to avoid zero distance

% --- Wall reflector (baseline) ---
P.wall.rho = 0.6;      % wall reflection coefficient ρ_wall
% Effective patching of the same footprint as IRS for fair comparison:
P.wall.Kx = 10;  P.wall.Ky = 30;  P.wall.tile = 0.1; 
P.wall.y = P.roomY-1e-3;

% --- Photodetector / optics (Komine-Nakagawa model) ---
P.A_PD    = 1e-4;      % PD area (m^2)
P.FoV     = deg2rad(85); % Field of view (rad)
P.n_refr  = 1.5;       % refractive index -> concentrator gain
P.T_opt   = 1.0;       % optical filter gain T(ξ)
P.Phi_half= deg2rad(70); % LED half-power angle
P.m = -log(2)/log(cos(P.Phi_half)); % Lambertian order (m)


% --- Link budget & noise ---
P.q       = 3;         % optical-to-electrical (IM/DD) constant
P.R_PD    = 0.53;       % PD responsivity (A/W)
P.N0      = 1e-21;     % noise PSD at PD (A^2/Hz)
P.BW      = 200e6;      % system bandwidth (Hz)
P.P_tx    = 20;         % optical transmit power (W) (can sweep)
P.R_target= 30e6;      % outage threshold (bps)

% --- Blockers ---
P.N_blockers = 5;      % number of non-user blockers
P.blocker_r  = 0.15;   % radius (m)
P.blocker_h  = 1.65;   % height (m)

% --- Random orientation (Soltani et al.) ---
P.alpha_mu  = deg2rad(41); 
P.alpha_sig = deg2rad(9);   % Laplace std approx (rad)
P.beta_minmax = [-pi, pi];

% --- SCA optimizer ---
P.SCA.N_agents = 10;
P.SCA.T_max    = 50;       
P.SCA.a        = 2;      % see r1 = a - t*(a/T)

% --- Monte Carlo ---
P.nRealizations = 500;
P.verbose = true;
end
