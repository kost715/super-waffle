// [unit] -> what the ATM shows this player: [personal balance, group balance,
// is treasurer, is Zeus, personal history, group history, group name]. Server.
// Histories are newest first, as [time, operation, amount, balance after, who];
// Zeus operations are never shown to players.
params [["_unit", objNull, [objNull]]];
private _uid = getPlayerUID _unit;
private _hidden = ["zeus_add", "zeus_remove", "treasurer_add", "treasurer_remove"];
private _personal = [];
private _group = [];
private _i = count PMCB_log - 1;
while {_i >= 0 && {count _personal < 20 || {count _group < 50}}} do {
    (PMCB_log select _i) params ["", "_time", "_account", "", "_op", "_amount", "_balance", "", "_actorName"];
    if !(_op in _hidden) then {
        private _row = [_time, _op, _amount, _balance, _actorName];
        if (_account == _uid && {count _personal < 20}) then {_personal pushBack _row};
        if (_account == "group" && {count _group < 50}) then {_group pushBack _row};
    };
    _i = _i - 1;
};
[(PMCB_accounts getOrDefault [_uid, [0, ""]]) select 0, PMCB_group, _uid in PMCB_treasurers, [_unit] call PMCB_fnc_isZeus,
    _personal, _group, missionNamespace getVariable ["PMCB_groupName", "Group"]]
