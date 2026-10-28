// postInit: reports in the RPT any taken-over ACE action this ACE version lacks, or whose
// original callback is missing (then the action cannot be completed: update the mod).
{
    _y params ["_game", "_time", "", "_success"];
    private _root = [configFile >> "ace_medical_treatment_actions", configFile >> "ACE_Repair" >> "Actions"] select (_game == "wheel");
    if (!isClass (_root >> _x) || {isNil _success} || {isNil _time}) then {
        diag_log text format ["[PMCI] WARNING: ACE action %1 does not match this mod (class, %2 or %3 missing)", _x, _time, _success];
    };
} forEach (call PMCI_fnc_table);
