// [[[tab, class, amount], ...], isAdd] -> nothing. Client -> server while browsing.
// Shows another player's pick at once; never changes stock. The net preview of a
// session is kept so the server can correct everyone's counts when it commits.
params [["_rows", [], [[]]], ["_add", false, [false]]];
if (!isServer || {isNil "PMCA_sessions"}) exitWith {};
private _owner = call PMCA_fnc_requestOwner;
private _session = PMCA_sessions getOrDefault [_owner, createHashMap];
if (count _session == 0) exitWith {};
private _preview = _session get "preview";
private _send = [];
{
    _x params [["_tab", -1, [0]], ["_class", "", [""]], ["_amount", 0, [0]]];
    private _key = [_class] call PMCA_fnc_itemKey;
    if (_tab >= 0 && {_key != ""} && {_amount > 0} && {_amount < 1e7}) then {
        _preview set [_key, (_preview getOrDefault [_key, 0]) + ([_amount, -_amount] select _add)];
        _send pushBack [_key, _amount];
    };
} forEach (_rows select [0, 300]);
[_session get "storage", _send, _add, []] call PMCA_fnc_broadcast;
