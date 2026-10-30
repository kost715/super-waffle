// [lock type] -> the class of the tool its hack needs (CBA settings), "" when none is needed:
// a lockpick for a classic lock (used up when it breaks), a terminal device for a code
// lock, a listening device for a safe (both kept).
params ["_type"];
private _setting = switch (_type) do {
    case "classic": {"PMCI_lockpickItem"};
    case "code": {"PMCI_terminalItem"};
    case "safe": {"PMCI_safeItem"};
    default {""};
};
if (_setting == "") exitWith {""};
private _class = missionNamespace getVariable [_setting, ""];
if !(_class isEqualType "") exitWith {""};
// CBA edit boxes keep what was typed, spaces and quotes included.
(_class splitString " ""'") joinString ""
