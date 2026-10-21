// Native property position of the founder, never the accepting player's position.
params ["_unit"];
private _uid = [_unit] call ALS_fnc_uid;
private _result = [];
{
    private _row = ALSPMC_bases get _x;
    private _house = ALS_houses getOrDefault [_x, []];
    if ((_row select 0) == _uid && {count _house >= 8} && {[_uid, ALS_owned getOrDefault [_x, ""]] call ALS_fnc_canUse}) exitWith {
        _result = ASLToATL (_house select 0);
    };
} forEach (keys ALSPMC_bases);
_result
