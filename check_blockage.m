function blocked = check_blockage(AP, user_pos, P, S)
% Check_blockage
% Return true if LoS from AP to user is blocked (self or other blockers.)
% Indicator I : 0 if blocked.

blocked = false;

% Line segment from AP to user
p1 = AP; p2 = user_pos;

% (a) Self-block: 
body_center = S.user_body_center;
body_h = P.blocker_h;
if segment_cylinder_intersect(p1, p2, body_center, P.user_body_r, [0, body_h])
    blocked = true; 
    return;
end

% (b) Non-user blockers
if ~isempty(S.blockers)
    for i=1:size(S.blockers,1)
        c = S.blockers(i,:);
        if segment_cylinder_intersect(p1, p2, c, P.blocker_r, [0, P.blocker_h])
            blocked = true; 
            return;
        end
    end
end
end
