if (!hasInterface) exitWith {};
if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
if (!isRemoteExecuted && {!isServer}) exitWith {};
params [["_state", createHashMap, [createHashMap]]];
uiNamespace setVariable ["PMCS2_state", _state];
call PMCS_fnc_s2Render;
