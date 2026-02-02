function d = dist3(p,q)
%DIST3  Euclidean distance between two 3D points.
d = sqrt(sum((p-q).^2));
end
