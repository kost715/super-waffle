// Display name for a UID: the live name when online, else the last one the
// company tick recorded, else the UID itself. Engine strings cross as toArray.
params ["_uid"];
private _p = [_uid] call ALS_fnc_findPlayer;
if (!isNull _p) exitWith {toArray name _p};
(missionNamespace getVariable ["ALSPMC_playerNames", createHashMap]) getOrDefault [_uid, toArray _uid]
