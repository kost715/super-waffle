// [token] -> nothing. Client -> server after handing notes over. Credits the value
// of the notes that actually left the player's inventory as the server sees it,
// never more than was announced; waits up to 5 s for the inventory to sync.
if (!isServer || {isNil "PMCB_pending"}) exitWith {};
params [["_token", -1, [0]]];
private _owner = call PMCB_fnc_requestOwner;
private _pending = PMCB_pending getOrDefault [_owner, []];
if (_pending isEqualTo [] || {(_pending select 0) != _token}) exitWith {};
PMCB_pending deleteAt _owner;
[_owner, _pending] spawn {
    params ["_owner", "_pending"];
    _pending params ["", "_unit", "_key", "_rows", "_before"];
    private _gone = {
        private _now = [_unit] call PMCB_fnc_noteCounts;
        _rows apply {
            private _class = toLowerANSI (_x select 0);
            [_x select 0, (_x select 1) min (0 max ((_before getOrDefault [_class, 0]) - (_now getOrDefault [_class, 0])))]
        }
    };
    private _got = call _gone;
    private _until = diag_tickTime + 5;
    while {_got isNotEqualTo _rows && {diag_tickTime < _until} && {!isNull _unit}} do {
        sleep 0.25;
        _got = call _gone;
    };
    private _total = 0;
    {_total = _total + (_x select 1) * ([_x select 0] call PMCB_fnc_noteValue)} forEach _got;
    if (_total <= 0) exitWith {["STR_PMCB_ERR_NOTHING", []] remoteExecCall ["PMCB_fnc_notify", _owner]};
    isNil {[_key, _total, "deposit", getPlayerUID _unit, name _unit] call PMCB_fnc_apply};
    ["STR_PMCB_DONE_DEPOSIT", [[_total] call PMCB_fnc_money]] remoteExecCall ["PMCB_fnc_notify", _owner];
    [_owner, _unit] call PMCB_fnc_push;
    if (_key == "group") then {[_owner] call PMCB_fnc_pushGroup};
};
