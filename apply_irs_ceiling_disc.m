function S = apply_irs_ceiling_disc(P, S)
L  = P.IRS.tile;
K  = P.IRS.Kx * P.IRS.Ky;

R  = 0.3 * min(P.roomX, P.roomY); % tune if needed
zc = P.roomZ - L/2 - 1e-3;

tiles = zeros(K,3);
cnt = 0;
while cnt < K
    x = (rand()*2-1)*R + P.roomX/2;
    y = (rand()*2-1)*R + P.roomY/2;
    if (x - P.roomX/2)^2 + (y - P.roomY/2)^2 <= R^2
        cnt = cnt + 1;
        tiles(cnt,:) = [x, y, zc];
    end
end

S.IRS_tiles = tiles;
S.IRS_group_id = ones(K,1);
S.N_groups = 1;
S.tile_area = L*L;
end