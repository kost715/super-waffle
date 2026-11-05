// Writes this mission's market (with its journal) to the server profile.
if (!isServer || {isNil "PMCS_market"} || {PMCS_saveBlocked}) exitWith {false};
profileNamespace setVariable [call PMCS_fnc_marketKey, [PMCS_market, true] call PMCS_fnc_marketPack];
saveProfileNamespace;
PMCS_dirty = false;
true
