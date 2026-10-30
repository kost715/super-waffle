// [unit, box, how, code] -> nothing. Server, from a player at a locked box:
//   "key"   opens a classic lock if the unit carries the key set for it;
//   "code"  opens a code lock or safe if the code is right;
//   "begin" notes that the unit started hacking the box (PMCI_fnc_lockHack);
//   "hack"  opens it after a won hacking game: the hack began at least 0.5 s before (a lucky
//           pick opens in under a second) and the unit still carries the tool the lock needs.
// The box stays open for good (PMCI_fnc_lockClear); a refusal is told to the unit.
if (!isServer) exitWith {};
params [["_unit", objNull, [objNull]], ["_box", objNull, [objNull]], ["_how", "", [""]], ["_code", "", [""]]];
if (isNull _unit || {isNull _box} || {isRemoteExecuted && {owner _unit != remoteExecutedOwner}}) exitWith {};
private _lock = _box getVariable ["PMCI_lock", []];
if (_lock isEqualTo [] || {!alive _unit} || {_unit distance _box > 6}) exitWith {};
_lock params ["_type", "", "_key"];
if (_how == "begin") exitWith {_unit setVariable ["PMCI_hackStart", [_box, diag_tickTime]]};
private _refusal = switch (_how) do {
    case "key": {
        if (_type == "classic" && {_key != ""} && {([_unit, _key] call PMCI_fnc_itemCount) > 0}) then {""} else {"STR_PMCI_LOCK_NO_KEY"}
    };
    case "code": {
        private _right = _box getVariable ["PMCI_lockCode", ""];
        if (_type in ["code", "safe"] && {_right != ""} && {_code isEqualTo _right}) then {""} else {"STR_PMCI_LOCK_WRONG_CODE"}
    };
    case "hack": {
        (_unit getVariable ["PMCI_hackStart", [objNull, -1]]) params ["_on", "_at"];
        private _tool = [_type] call PMCI_fnc_lockTool;
        if (_on isEqualTo _box && {diag_tickTime - _at >= 0.5} && {_tool == "" || {([_unit, _tool] call PMCI_fnc_itemCount) > 0}}) then {""} else {"STR_PMCI_LOCK_HACK_REFUSED"}
    };
    default {"STR_PMCI_LOCK_HACK_REFUSED"};
};
if (_refusal != "") exitWith {[_refusal] remoteExecCall ["PMCI_fnc_lockNotify", _unit]};
_unit setVariable ["PMCI_hackStart", nil];
[_box, _unit, "STR_PMCI_LOCK_OPENED"] call PMCI_fnc_lockClear;
