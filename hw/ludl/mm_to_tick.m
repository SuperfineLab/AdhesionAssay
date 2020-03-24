function dist_tick = mm_to_tick(dist_mm)
% MM_TO_TICK converts millimeters to ludl tick marks

dist_tick = dist_mm / 5 / 10^(-5);