params ["_unit"];
private _base = [_unit] call ALSPMC_fnc_contractBase;
if (_base isEqualTo []) exitWith {[]};
// Bounded search through native flatSpot; no water, roads, buildings or players
// at the spawn. Keep a short test journey instead of random ocean/map corners.
private _min = (getNumber (configFile >> "ALSPMC_Settings" >> "questMinDistance")) max 300;
private _max = (getNumber (configFile >> "ALSPMC_Settings" >> "questMaxDistance")) max (_min + 100) max 6000;
private _center = getPosATL _unit;
private _found = [];
for "_try" from 1 to 64 do {
    private _candidate = _center getPos [_min + random (_max - _min), random 360];
    if ((_candidate select 0) > 30 && {(_candidate select 1) > 30} && {
        (_candidate select 0) < worldSize - 30 && {(_candidate select 1) < worldSize - 30}
    }) then {
        private _pos = [_candidate, 30, 3, true, 5, 0.94] call ALS_fnc_flatSpot;
        if (_pos isNotEqualTo [] && {[_base, _pos, 100] call ALSPMC_fnc_contractFar} && {_unit distance2D _pos >= _min} && {_unit distance2D _pos <= _max} && {
            (allPlayers findIf {alive _x && {_x distance2D _pos < 250}}) < 0
        } && {(nearestObjects [_pos, ["CAManBase"], 100]) isEqualTo []}) exitWith {
            _found = [_pos select 0, _pos select 1, 0];
        };
    };
    if (_found isNotEqualTo []) exitWith {};
};
_found
