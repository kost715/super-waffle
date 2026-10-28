// [owner, claim, abort] -> nothing. Server. Settles one arsenal session.
// Stock follows the inventory the server itself observes: what appeared since the
// session opened is taken from stock, what disappeared is returned to it. The
// client's final state (claim) can only raise a take or lower a return, so an
// item dropped before the server saw it never creates stock out of nothing.
// A take that stock or permissions cannot cover restores the state at opening.
// Abort (disconnect) settles nothing and restores an emptied container.
params ["_owner", "_claim", ["_abort", false]];
if (!isServer || {isNil "PMCA_sessions"}) exitWith {};
private _session = PMCA_sessions getOrDefault [_owner, createHashMap];
if (count _session == 0) exitWith {};
private _token = _session get "token";
private _id = _session get "storage";
private _isUnit = (_session get "kind") == "arsenal";
private _subject = [_session get "container", _session get "unit"] select _isUnit;
// Still taking the opening snapshot: nothing was shown, so nothing to settle.
if (_session getOrDefault ["opening", false]) exitWith {
    isNil {
        if (((PMCA_sessions getOrDefault [_owner, createHashMap]) getOrDefault ["token", -1]) == _token) then {PMCA_sessions deleteAt _owner};
    };
    if (!_isUnit && {!isNull _subject}) then {_subject lockInventory false};
};
private _view = {
    if (_isUnit) then {[getUnitLoadout _subject] call PMCA_fnc_loadoutItems} else {[_subject] call PMCA_fnc_cargoItems}
};
private _same = {
    params ["_a", "_b"];
    count _a == count _b && {((keys _a) findIf {(_b getOrDefault [_x, -1]) != (_a get _x)}) < 0}
};
private _claimed = createHashMap;
private _hasClaim = false;
if (!isNil "_claim" && {!_abort}) then {
    if (_isUnit) then {
        if (_claim isEqualType [] && {count _claim >= 10}) then {_claimed = [_claim] call PMCA_fnc_loadoutItems; _hasClaim = true};
    } else {
        // The container arsenal reports its 27-tab list, magazines in rounds.
        if (_claim isEqualType [] && {count _claim == 27}) then {
            {
                if (_x isEqualType []) then {
                    {
                        if (_x isEqualType [] && {count _x == 2} && {(_x select 0) isEqualType ""} && {(_x select 1) isEqualType 0} && {(_x select 1) > 0}) then {
                            private _key = [_x select 0] call PMCA_fnc_itemKey;
                            if (_key != "") then {_claimed set [_key, (_claimed getOrDefault [_key, 0]) + (_x select 1)]};
                        };
                    } forEach _x;
                };
            } forEach _claim;
            _hasClaim = true;
        };
    };
};
// Inventory changes reach the server over the network: wait briefly until the
// server sees the state the client closed with.
private _after = if (isNull _subject) then {createHashMap} else {call _view};
if (_hasClaim && {canSuspend}) then {
    private _until = diag_tickTime + 5;
    while {!([_after, _claimed] call _same) && {diag_tickTime < _until} && {!isNull _subject}} do {
        sleep 0.25;
        _after = call _view;
    };
};
private _settled = false;
private _revert = _abort;
private _missing = [];
isNil {
    // A disconnect handler or a newer request may have settled it meanwhile.
    if (((PMCA_sessions getOrDefault [_owner, createHashMap]) getOrDefault ["token", -1]) != _token) exitWith {};
    _settled = true;
    PMCA_sessions deleteAt _owner;
    private _storage = PMCA_storages getOrDefault [_id, createHashMap];
    private _items = _storage getOrDefault ["items", createHashMap];
    private _before = _session get "before";
    private _delta = createHashMap;
    if (!_abort && {!isNull _subject}) then {
        private _keys = (keys _before) + (keys _after) + (keys _claimed);
        {
            private _was = _before getOrDefault [_x, 0];
            private _change = (_after getOrDefault [_x, 0]) - _was;
            if (_hasClaim) then {_change = _change max ((_claimed getOrDefault [_x, 0]) - _was)};
            if (_change != 0) then {_delta set [_x, _change]};
        } forEach (_keys arrayIntersect _keys);
        private _tabs = _session get "tabs";
        {
            if (_y > 0) then {
                private _have = _items getOrDefault [_x, 0];
                if !((_x call PMCA_fnc_arsenal_itemType) in _tabs && {_have == -1 || {_have >= _y}}) then {_missing pushBack _x};
            };
        } forEach _delta;
        _revert = _missing isNotEqualTo [];
    };
    private _applied = createHashMap;
    if (!_revert) then {
        _applied = _delta;
        {
            private _have = _items getOrDefault [_x, 0];
            if (_have != -1) then {
                private _left = _have - _y;
                if (_left > 0) then {_items set [_x, _left]} else {_items deleteAt _x};
            };
        } forEach _delta;
        if (count _delta > 0 && {_storage getOrDefault ["persist", true]}) then {PMCA_dirty = true};
    };
    // Others saw this session's picks at once; correct them to what was settled.
    private _preview = _session get "preview";
    private _adds = [];
    private _removes = [];
    private _keys = (keys _preview) + (keys _applied);
    {
        private _diff = (_preview getOrDefault [_x, 0]) - (_applied getOrDefault [_x, 0]);
        if (_diff > 0) then {_adds pushBack [_x, _diff]};
        if (_diff < 0) then {_removes pushBack [_x, -_diff]};
    } forEach (_keys arrayIntersect _keys);
    [_id, _adds, true, []] call PMCA_fnc_broadcast;
    [_id, _removes, false, []] call PMCA_fnc_broadcast;
};
if (!_settled) exitWith {};
if (_revert && {!isNull _subject}) then {
    if (_isUnit) then {
        if (!_abort) then {[_session get "loadout"] remoteExecCall ["PMCA_fnc_applyLoadout", _owner]};
    } else {
        [_subject, _session get "before"] call PMCA_fnc_restoreCargo;
    };
};
if (!_isUnit && {!isNull _subject}) then {_subject lockInventory false};
if (_missing isNotEqualTo []) then {
    private _names = (_missing select [0, 5]) apply {
        private _class = _x;
        private _name = "";
        {
            private _cfg = configFile >> _x >> _class;
            if (isClass _cfg) exitWith {_name = getText (_cfg >> "displayName")};
        } forEach ["CfgWeapons", "CfgMagazines", "CfgVehicles", "CfgGlasses"];
        [_name, _class] select (_name == "")
    };
    ["STR_PMCA_ERR_STOCK", [_names joinString ", "]] remoteExecCall ["PMCA_fnc_notify", _owner];
};
