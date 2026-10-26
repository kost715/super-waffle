params ["_unit"];
private _uid = getPlayerUID _unit;
if (_uid == "" && {!isMultiplayer} && {owner _unit == 2}) then {_uid = "local-host"};
if (_uid == "") exitWith {[]};
private _known = PMCS_members getOrDefault [_uid, []];
if (_known isEqualTo []) then {
    private _slot = (PMCS_plan select {(_x select 2) == side group _unit}) param [0, []];
    if (_slot isNotEqualTo []) then {
        _known = [_uid, _slot select 0, _slot select 2];
        PMCS_members set [_uid, _known];
    };
};
_known
