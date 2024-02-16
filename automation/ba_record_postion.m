function Plate = ba_record_postion(hw, Plate, n)

    if nargin < 3 || isempty(n)
        error('No well number inputted.');
    end
    
    Plate.fov(n) = stage_get_pos_Ludl(hw.ludl); 
    Plate.focus(n) = scope_get_focus(hw.scope);
    
end
