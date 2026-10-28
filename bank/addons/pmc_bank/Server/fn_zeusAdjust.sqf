// [Zeus unit, amount] -> nothing. Zeus module -> server. A positive amount is
// created on the group's account, a negative one removed from it; nothing is paid
// out or taken from anyone. Removing more than the balance is refused.
if (!isServer) exitWith {};
call PMCB_fnc_serverLoad;
params [["_zeus", objNull, [objNull]], ["_amount", 0, [0]]];
private _owner = [_zeus, false] call PMCB_fnc_caller;
if (_owner < 0 || {!([_zeus] call PMCB_fnc_isZeus)}) exitWith {};
if (_amount == 0 || {_amount != floor _amount} || {abs _amount >= 1e9}) exitWith {["STR_PMCB_ERR_AMOUNT", []] remoteExecCall ["PMCB_fnc_notify", _owner]};
if (_amount < 0 && {-_amount > PMCB_group}) exitWith {
    ["STR_PMCB_ERR_GROUP_FUNDS", [[PMCB_group] call PMCB_fnc_money]] remoteExecCall ["PMCB_fnc_notify", _owner];
};
private _balance = ["group", _amount, ["zeus_remove", "zeus_add"] select (_amount > 0), getPlayerUID _zeus, name _zeus] call PMCB_fnc_apply;
[["STR_PMCB_DONE_ZEUS_REMOVE", "STR_PMCB_DONE_ZEUS_ADD"] select (_amount > 0), [[abs _amount] call PMCB_fnc_money, [_balance] call PMCB_fnc_money]]
    remoteExecCall ["PMCB_fnc_notify", _owner];
[-1] call PMCB_fnc_pushGroup;
