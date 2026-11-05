// [weapon class] -> the upgrades this weapon can take: [[upgrade, target class], ...]
// (upgrade as PMCS_fnc_upgrades lists it).
params [["_weapon", "", [""]]];
private _out = [];
if (_weapon == "") exitWith {_out};
{
    private _target = [_weapon, _x select 7] call PMCS_fnc_upgradeTarget;
    if (_target != "") then {_out pushBack [_x, _target]};
} forEach (call PMCS_fnc_upgrades);
_out
