// Loads this mission's market once. Server. A damaged record is kept untouched on disk,
// the market starts from the catalog and this session does not save (fail closed).
if (!isServer || {!isNil "PMCS_market"}) exitWith {};
PMCS_dirty = false;
PMCS_saveBlocked = false;
PMCS_terminals = [];
PMCS_points = createHashMap;
PMCS_viewers = createHashMap;
PMCS_market = call PMCS_fnc_marketNew;
private _saved = profileNamespace getVariable [call PMCS_fnc_marketKey, []];
if (_saved isNotEqualTo []) then {
    private _market = [_saved] call PMCS_fnc_marketUnpack;
    if (isNil "_market") then {
        PMCS_saveBlocked = true;
        diag_log text format ["[PMCS] ERROR: saved market %1 is invalid; it is kept untouched and this session will not save", call PMCS_fnc_marketKey];
    } else {PMCS_market = _market};
};
