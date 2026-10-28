// [unit] -> the player's account key (Steam UID). Server. Opens the personal
// account with the starting balance on first use and keeps the name current.
params [["_unit", objNull, [objNull]]];
private _uid = getPlayerUID _unit;
if (_uid == "") exitWith {""};
if (_uid in PMCB_accounts) then {
    (PMCB_accounts get _uid) set [1, name _unit];
} else {
    PMCB_accounts set [_uid, [round (missionNamespace getVariable ["PMCB_startBalance", 0]), name _unit]];
    PMCB_dirty = true;
};
_uid
