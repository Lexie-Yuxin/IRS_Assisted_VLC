function hit = segment_cylinder_intersect(p1, p2, c, r, zrange)
% SEGMENT_CYLINDER_INTERSECT  
% Check if 3D segment [p1,p2] intersects a vertical cylinder.
% Cylinder: infinite along z, centered at (c(1),c(2)), radius r; also require z-overlap with zrange=[zmin zmax].

hit = false;

% Quick reject on z-overlap
zmin = min(p1(3), p2(3)); 
zmax = max(p1(3), p2(3));
if (zmax < zrange(1)) || (zmin > zrange(2))
    return;
end

% Project to XY and compute min distance from segment to cylinder center
v  = p2 - p1;
px = p1(1); py = p1(2);
vx = v(1);  vy = v(2);
wx = c(1) - px; wy = c(2) - py;
seglen2 = vx*vx + vy*vy;
if seglen2 < 1e-14
    d2 = (c(1)-px)^2 + (c(2)-py)^2;
    hit = (d2 <= r*r); 
    return;
end
t = (wx*vx + wy*vy) / seglen2;
t = max(0, min(1, t));
closest = [px + t*vx, py + t*vy];
d2 = (closest(1)-c(1))^2 + (closest(2)-c(2))^2;
if d2 <= r*r
    hit = true;
end
end
