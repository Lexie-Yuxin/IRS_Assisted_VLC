function c = cos_irradiance(AP, point, m) 
%COS_IRRADIANCE  Cosine of irradiance from AP (LED pointing down along -z) to a point.
v = point - AP;
nv = norm(v);
if nv < 1e-12
    c = 0; 
    return;
end
v = v / nv;
axis = [0,0,-1]; % LED axis
c = max(0, dot(axis, v));
end
