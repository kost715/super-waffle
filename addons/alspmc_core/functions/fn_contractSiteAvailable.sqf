// Recheck changing native ownership/reservations even when the site list is cached.
params ["_kind", "_site"];
if !(_kind in ["commercial", "government"]) exitWith {true};
private _key = if (_kind == "commercial") then {_site select 1} else {
    if (isNull (_site select 2)) then {""} else {[getPosASL (_site select 2)] call ALS_fnc_houseKey}
};
if (_key == "" || {_key in ALS_owned}) exitWith {false};
private _reserved = _key in (missionNamespace getVariable ["ALS_reserved", []]);
if (_kind == "government") exitWith {
    private _building = _site select 2;
    // LifeSim also reserves the buildings it made a hospital/clinic (fn_clinicInit),
    // a town hall (fn_dealerSpots) or a police station (fn_lawInit). Those are the
    // government facilities themselves; cafes, rival HQs and shops stay excluded.
    alive _building && {!_reserved || {
        private _model = toLowerANSI ((ALS_houses getOrDefault [_key, []]) param [1, ""]);
        (["hospital", "medical", "clinic"] findIf {(_model find _x) >= 0}) >= 0 || {
            private _radius = ((boundingBoxReal _building) param [2, 8]) max 8;
            ((missionNamespace getVariable ["ALS_npcPublic", []]) findIf {
                ((_x select 1) in ["clerk", "police", "clinic"]) && {((_x select 0) distance2D _building) <= _radius}
            }) >= 0
        }
    }}
};
if (_reserved) exitWith {false};
private _h = ALS_houses getOrDefault [_key, []];
count _h >= 8 && {(_h select 6) in ["Shop", "Industrial"]} && {(_h select 7) != "Wrecked"}
