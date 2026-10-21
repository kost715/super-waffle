if (!isServer) exitWith {};
private _changed = false;
{
    private _owner = ALS_owned getOrDefault [_x, ""];
    private _founder = (ALSPMC_bases get _x) select 0;
    if (!(_x in ALS_houses) || {!([_founder, _owner] call ALS_fnc_canUse)}) then {
        if (_x in ALS_houses) then {(ALS_houses get _x) set [5, (ALSPMC_bases get _x) select 1]};
        ALSPMC_bases deleteAt _x;
        [_x] call ALSPMC_fnc_terminalRemove;
        _changed = true;
    };
} forEach (keys ALSPMC_bases);
if (_changed) then {call ALSPMC_fnc_save};
if (missionNamespace getVariable ["ALSPMC_workstationsReady", false]) then {call ALSPMC_fnc_terminalSync};
