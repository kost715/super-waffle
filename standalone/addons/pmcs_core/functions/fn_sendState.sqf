params ["_unit", ["_reply", ""], ["_ok", true], ["_notice", ""]];
if (!isServer || {isNull _unit}) exitWith {};
private _ackKey = str owner _unit;
if (_reply == "") then {
    private _ack = PMCS_replies getOrDefault [_ackKey, ["", true, ""]];
    _reply = _ack select 0; _ok = _ack select 1; _notice = _ack select 2;
} else {PMCS_replies set [_ackKey, [_reply, _ok, _notice]]};
private _state = [_unit, _reply, _ok, _notice] call PMCS_fnc_snapshot;
[_state] remoteExecCall ["PMCS_fnc_receiveState", _unit];
