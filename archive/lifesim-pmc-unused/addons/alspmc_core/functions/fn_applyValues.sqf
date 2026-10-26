// Run on server and each client, including JIP. Never touch unrelated houses.
private _next = createHashMapFromArray (missionNamespace getVariable ["ALSPMC_basesPublic", []]);
private _old = missionNamespace getVariable ["ALSPMC_appliedBases", createHashMap];
{
    if (!(_x in _next) && {_x in ALS_houses}) then {
        (ALS_houses get _x) set [5, _y select 1];
    };
} forEach _old;
{
    if (_x in ALS_houses) then {(ALS_houses get _x) set [5, _y select 2]};
} forEach _next;
ALSPMC_appliedBases = _next;
if (hasInterface) then {deleteMarkerLocal "ALSPMC_myBase"};
