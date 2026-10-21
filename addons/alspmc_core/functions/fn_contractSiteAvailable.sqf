// Recheck changing native ownership/reservations even when the site list is cached.
params ["_kind", "_site"];
if !(_kind in ["commercial", "government"]) exitWith {true};
private _key = if (_kind == "commercial") then {_site select 1} else {
    if (isNull (_site select 2)) then {""} else {[getPosASL (_site select 2)] call ALS_fnc_houseKey}
};
if (_key == "" || {_key in ALS_owned} || {_key in (missionNamespace getVariable ["ALS_reserved", []])}) exitWith {false};
if (_kind == "government") exitWith {!isNull (_site select 2) && {alive (_site select 2)}};
private _h = ALS_houses getOrDefault [_key, []];
count _h >= 8 && {(_h select 6) in ["Shop", "Industrial"]} && {(_h select 7) != "Wrecked"}
