params [["_unit", objNull, [objNull]], ["_session", "", [""]], ["_id", "", [""]],
    ["_op", "", [""]], ["_expected", -1, [0]], ["_arg", [], [[]]], ["_computer", objNull, [objNull]]];
if !([_unit] call PMCS_fnc_allowed) exitWith {false};
if (count _id > 96 || {count _session > 128} || {count _op > 24} || {count _arg > 3}) exitWith {false};
if ((toArray _id findIf {_x < 32 || {_x > 126}}) >= 0) exitWith {false};
if (_op == "status") exitWith {[_unit] call PMCS_fnc_sendState; true};
if (_id == "") exitWith {false};
private _ok = false;
private _notice = "STR_PMCS_DENIED";
isNil {
    if (_session != PMCS_session) exitWith {_notice = "STR_PMCS_SESSION"};
    if !([_unit, true, _computer] call PMCS_fnc_allowed) exitWith {};
    private _member = [_unit] call PMCS_fnc_registerPlayer;
    if (_member isEqualTo [] || {side group _unit != (_member select 2)}) exitWith {};
    private _cacheKey = (str owner _unit) + ":" + (_member select 0);
    private _cache = PMCS_requests getOrDefault [_cacheKey, []];
    private _seen = _cache findIf {(_x select 0) == _id};
    if (_seen >= 0) exitWith {
        private _old = _cache select _seen;
        if ((_old select 1) isEqualTo [_op, _expected, _arg]) then {_ok = _old select 2; _notice = _old select 3};
    };
    if (_expected == PMCS_revision && {PMCS_revision < 1000000}) then {
        private _changed = false;
        _ok = switch (_op) do {
            case "relation": {
                if (count _arg != 3 || {(_arg findIf {!(_x isEqualType "")}) >= 0}) exitWith {false};
                _arg call PMCS_fnc_relationSet
            };
            case "preset": {
                if !(_arg in [["neutral"], ["ab"]]) exitWith {false};
                if (_arg isEqualTo ["ab"] && {count PMCS_plan < 2}) exitWith {false};
                PMCS_relations = createHashMap;
                if (_arg isEqualTo ["ab"]) then {["alpha", "bravo", "hostile"] call PMCS_fnc_relationSet};
                true
            };
            case "reset": {
                if (_arg isNotEqualTo []) exitWith {false};
                PMCS_relations = createHashMap;
                PMCS_worldHostile = false;
                call PMCS_fnc_applyRelations;
                _changed = true;
                call PMCS_fnc_resetActors
            };
            case "world": {
                if (PMCS_worldSide == sideUnknown || {!(_arg in [["neutral"], ["hostile"]])}) exitWith {false};
                PMCS_worldHostile = _arg isEqualTo ["hostile"];
                true
            };
            default {false};
        };
        if (_ok || {_changed}) then {
            PMCS_revision = PMCS_revision + 1;
            call PMCS_fnc_applyRelations;
            _notice = ["STR_PMCS_PARTIAL", "STR_PMCS_DONE"] select _ok;
            diag_log format ["[PMCS S1] %1 owner=%2 op=%3 rev=%4 payload=%5", _id, owner _unit, _op, PMCS_revision, _arg];
        };
    } else {_notice = "STR_PMCS_STALE"};
    _cache pushBack [_id, [_op, _expected, +_arg], _ok, _notice];
    if (count _cache > 64) then {_cache deleteAt 0};
    PMCS_requests set [_cacheKey, _cache];
};
[_unit, _id, _ok, _notice] call PMCS_fnc_sendState;
_ok
