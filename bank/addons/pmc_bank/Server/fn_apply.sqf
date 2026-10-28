// [account, change, operation, actor UID, actor name] -> balance after. Server.
// The only place balances change; every change is journalled. Account "group" is
// the group's account, anything else a player's UID.
params ["_account", "_delta", "_op", "_actorUid", "_actorName"];
private _balance = 0;
private _name = "";
if (_account == "group") then {
    PMCB_group = PMCB_group + _delta;
    _balance = PMCB_group;
    _name = missionNamespace getVariable ["PMCB_groupName", "Group"];
} else {
    private _row = PMCB_accounts getOrDefault [_account, [0, _actorName]];
    _balance = (_row select 0) + _delta;
    _name = _row select 1;
    PMCB_accounts set [_account, [_balance, _name]];
};
[_account, _name, _op, abs _delta, _balance, _actorUid, _actorName] call PMCB_fnc_log;
_balance
