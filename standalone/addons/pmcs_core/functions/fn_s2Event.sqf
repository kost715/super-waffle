// Client report: someone in the player's group fired. While hidden this demasks
// the group at once, without waiting for the next tick, so a first shot from
// cover is not answered by enemies that still see a civilian.
params [["_unit", objNull, [objNull]]];
if (!isServer || {isNull _unit} || {!isPlayer _unit}) exitWith {};
if (isRemoteExecuted && {remoteExecutedOwner != owner _unit}) exitWith {};
isNil {
    private _r = PMCS2_records getOrDefault [getPlayerUID _unit, createHashMap];
    if (count _r == 0 || {!([_r, "fired while hidden"] call PMCS_fnc_s2Demask)}) exitWith {};
    [_unit, _r, [_r, _r get "inZone", diag_tickTime, PMCS2_settings] call PMCS_fnc_s2Desired] call PMCS_fnc_s2Apply;
};
