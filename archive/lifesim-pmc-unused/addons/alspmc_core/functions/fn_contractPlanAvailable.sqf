params ["_plan"];
private _kind = _plan getOrDefault ["siteKind", ""];
if (_kind == "") exitWith {true};
private _source = [_plan get "site", _plan get "source", _plan getOrDefault ["building", objNull]];
if !([_kind, _source] call ALSPMC_fnc_contractSiteAvailable) exitWith {false};
private _dest = _plan getOrDefault ["destinationSite", []];
_dest isEqualTo [] || {[_plan get "destinationKind", _dest] call ALSPMC_fnc_contractSiteAvailable}
