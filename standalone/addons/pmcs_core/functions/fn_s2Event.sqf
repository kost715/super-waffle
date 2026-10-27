// Client report: someone in the player's group fired. Firing while hidden
// demasks: the group takes its combat colour (the contract's, or WEST without a
// contract - "government spy", Override GDD 4.4) and keeps it for the aura time.
params [["_unit", objNull, [objNull]]];
if (!isServer || {isNull _unit} || {!isPlayer _unit}) exitWith {};
if (isRemoteExecuted && {remoteExecutedOwner != owner _unit}) exitWith {};
private _r = PMCS2_records getOrDefault [getPlayerUID _unit, createHashMap];
if (count _r == 0 || {!((_r get "reason") in ["rear", "undercover"])}) exitWith {};
private _contract = _r get "contract";
_r set ["combat", if (_contract == "none") then {"west"} else {_contract}];
_r set ["auraUntil", diag_tickTime + (PMCS2_settings get "aura")];
[format ["demask %1: fired while %2, combat colour %3", _r get "uid", _r get "reason", _r get "combat"]] call PMCS_fnc_s2Log;
