params ["_founder", ["_mode", ""]];
private _xp = (missionNamespace getVariable ["ALSPMC_ratingXP", createHashMap]) getOrDefault [_founder, 0];
private _thresholds = getArray (configFile >> "ALSPMC_Settings" >> "ratingThresholds");
if (count _thresholds != 5 || {(_thresholds findIf {!(_x isEqualType 0) || {_x < 0}}) >= 0}) then {_thresholds = [0,100,300,700,1300]};
private _level = 1;
{if (_xp >= _x) then {_level = _forEachIndex + 1}} forEach _thresholds;
private _ranges = [[3,5], [6,8], [9,12], [12,18], [15,25]];
private _range = _ranges select (_level - 1);
if (_mode == "enemyPatrol") then {_range = [[3,5],[3,6],[3,6],[5,8],[7,10]] select (_level - 1)};
private _multipliers = getArray (configFile >> "ALSPMC_Settings" >> "contractRewardMultipliers");
if (count _multipliers != 5 || {(_multipliers findIf {!(_x isEqualType 0) || {_x < 0} || {_x > 4}}) >= 0}) then {_multipliers = [1,1.5,2,3,4]};
createHashMapFromArray [["level", _level], ["xp", _xp], ["next", _thresholds param [_level, -1]],
    ["min", _range select 0], ["max", _range select 1],
    ["multiplier", _multipliers select (_level - 1)],
    ["pickupChance", [0,0,0.25,0.75,1] select (_level - 1)]]
