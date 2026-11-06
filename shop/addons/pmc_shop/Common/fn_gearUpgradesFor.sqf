// [vest class] -> the upgrades this vest can take: [[vest upgrade, target class], ...]
// (only targets the game has).
params [["_vest", "", [""]]];
private _out = [];
if (_vest == "") exitWith {_out};
{
    private _cfg = configFile >> "CfgWeapons" >> (_x select 4);
    if ((toLower (_x select 3)) == toLower _vest && {isClass _cfg}) then {_out pushBack [_x, configName _cfg]};
} forEach (call PMCS_fnc_gearUpgrades);
_out
