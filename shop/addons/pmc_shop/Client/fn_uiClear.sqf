// [regions] -> nothing. Client. Deletes the controls of those parts of the laptop screen.
params [["_regions", [], [[], ""]]];
if (_regions isEqualType "") then {_regions = [_regions]};
private _all = PMCS_ui get "regions";
{
    {ctrlDelete _x} forEach (_all getOrDefault [_x, []]);
    _all deleteAt _x;
} forEach _regions;
