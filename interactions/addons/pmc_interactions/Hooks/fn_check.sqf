// postInit: reports in the RPT any taken-over ACE action this ACE version lacks, or whose
// original callback is missing (then the action cannot be completed: update the mod),
// and any whose time or success callback another mod, loaded after this one, has set
// back (then ACE's own bar comes before the game, or no game starts).
{
    private _class = _x;
    _y params ["_game", "_time", "", "_success"];
    private _medical = !(_game in ["wheel", "repair", "track"]);
    private _root = [configFile >> "ACE_Repair" >> "Actions", configFile >> "ace_medical_treatment_actions"] select _medical;
    if (!isClass (_root >> _class) || {isNil _success} || {isNil _time}) then {
        diag_log text format ["[PMCI] WARNING: ACE action %1 does not match this mod (class, %2 or %3 missing)", _class, _time, _success];
    };
    private _ours = if (_medical) then {
        [["treatmentTime", "PMCI_fnc_timeNormal"], ["treatmentTimeTrained", "PMCI_fnc_timeTrained"], ["callbackSuccess", "PMCI_fnc_treatmentSuccess"]]
    } else {
        [["repairingTime", "PMCI_fnc_repairTime"], ["callbackSuccess", "PMCI_fnc_repairSuccess"]]
    };
    {
        _x params ["_entry", "_function"];
        private _set = getText (_root >> _class >> _entry);
        if (isClass (_root >> _class) && {_set != _function}) then {
            diag_log text format ["[PMCI] WARNING: %1 >> %2 is ""%3"", not ""%4"": another mod changes it after this one", _class, _entry, _set, _function];
        };
    } forEach _ours;
} forEach (call PMCI_fnc_table);
