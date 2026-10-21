if (!isServer || {!(missionNamespace getVariable ["ALSPMC_workstationsReady", false])}) exitWith {};
{
    if !(_x in ALSPMC_bases) then {[_x] call ALSPMC_fnc_terminalRemove};
} forEach ((keys ALSPMC_terminals) + (keys ALSPMC_workstations));
{
    private _old = ALSPMC_terminals getOrDefault [_x, [objNull, []]];
    private _incomplete = isNull (_old select 0) || {count (_old select 1) != 4} || {((_old select 1) findIf {isNull _x}) >= 0};
    if (_incomplete && {diag_tickTime >= (ALSPMC_terminalRetry getOrDefault [_x, -1])}) then {
        ALSPMC_terminalRetry set [_x, diag_tickTime + 30];
        [_x] call ALSPMC_fnc_terminalEnsure;
    };
} forEach (keys ALSPMC_bases);
