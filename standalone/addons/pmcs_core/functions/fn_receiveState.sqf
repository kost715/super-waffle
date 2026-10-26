if (!hasInterface) exitWith {};
if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
// Also support direct local delivery on a listening/SP server. A local client
// cannot use that path; server request authority remains independently checked.
if (!isRemoteExecuted && {!isServer}) exitWith {};
params [["_state", createHashMap, [createHashMap]]];
uiNamespace setVariable ["PMCS_state", _state];
if !(isNull (uiNamespace getVariable ["PMCS_console", displayNull])) then {call PMCS_fnc_renderConsole};
