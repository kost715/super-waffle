// First sight of a player: record plus two armed bots in the player's own group.
params ["_p"];
private _uid = getPlayerUID _p;
private _r = createHashMapFromArray [["uid", _uid], ["unit", _p], ["color", "civ"], ["captive", false],
    ["reason", "start"], ["contract", "none"], ["manual", ""], ["combat", "west"], ["auraUntil", 0],
    ["changedAt", diag_tickTime], ["inZone", false], ["distance", 0], ["firstShot", -1], ["lastShot", -1],
    ["captiveSentAt", -1e9], ["bots", []]];
PMCS2_records set [_uid, _r];
(group _p) setVariable ["PMCS2_uid", _uid, true];
private _temp = createGroup [civilian, true];
private _bots = [];
for "_i" from 1 to 2 do {
    private _at = (getPosATL _p) findEmptyPosition [2, 15, "C_man_1"];
    if (_at isEqualTo []) then {_at = _p getPos [3 + _i, random 360]};
    private _b = _temp createUnit ["C_man_1", _at, [], 0, "NONE"];
    if (!isNull _b) then {
        removeAllWeapons _b;
        _b addMagazines ["30Rnd_65x39_caseless_mag", 6];
        _b addWeapon "arifle_MX_F";
        _b allowFleeing 0;
        _b setVariable ["PMCS2_role", "bot of " + _uid, true];
        _bots pushBack _b;
    };
};
_bots joinSilent (group _p);
_r set ["bots", _bots];
[format ["registered %1 with %2 bots", _uid, count _bots]] call PMCS_fnc_s2Log;
_r
