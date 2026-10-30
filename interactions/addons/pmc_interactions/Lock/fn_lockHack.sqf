// [unit, box] -> nothing. Client: starts the hacking game of the box's lock (lockpick,
// terminal or safe), if the unit carries the tool it needs; the server is told the hack
// began (PMCI_fnc_lockOpen) and opens the box when the game is won (PMCI_fnc_finish).
params ["_unit", "_box"];
private _lock = _box getVariable ["PMCI_lock", []];
if (_lock isEqualTo [] || {!isNil "PMCI_board"}) exitWith {};
private _type = _lock select 0;
private _game = ["lockpick", "terminal", "safe"] param [["classic", "code", "safe"] find _type, ""];
if (_game == "") exitWith {};
private _tool = [_type] call PMCI_fnc_lockTool;
if (_tool != "" && {([_unit, _tool] call PMCI_fnc_itemCount) == 0}) exitWith {
    ["STR_PMCI_LOCK_NEED_TOOL", [[_tool] call PMCI_fnc_itemName]] call PMCI_fnc_lockNotify;
};
[_unit, _box, "begin"] remoteExecCall ["PMCI_fnc_lockOpen", 2];
[_game, [_unit, _box, "", ""], "lock"] call PMCI_fnc_boardOpen;
