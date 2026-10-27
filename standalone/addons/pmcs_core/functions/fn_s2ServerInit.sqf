// S2 state-machine stand (Override GDD). Fixed side table, set once and never
// changed: a runtime setFriend would act on the whole map. Every "local
// recolouring" is done by moving a player's group to another side's group or by
// the captive flag. Decision of 27 Oct 2026: WEST (government) and EAST
// (corporate defence) are allies; both are hostile to GUER; CIV is friendly to all.
if (!isServer || {missionNamespace getVariable ["PMCS2_started", false]}) exitWith {};
PMCS2_started = true;
private _cfg = missionConfigFile >> "PMCS_S2";
private _zone = getArray (_cfg >> "zone");
PMCS2_zone = if (count _zone == 2) then {[_zone select 0, _zone select 1, 0]} else {[14500, 16500, 0]};
PMCS2_zoneIn = (getNumber (_cfg >> "zoneRadius")) max 50;
// Leaving needs a larger radius than entering: no flapping on the border.
PMCS2_zoneOut = PMCS2_zoneIn + 30;
// Gang control zone: entering it strips civilian cover (Override GDD, decision 5).
private _gang = getArray (_cfg >> "gangZone");
PMCS2_gangZone = if (count _gang == 2) then {[_gang select 0, _gang select 1, 0]} else {[14750, 16300, 0]};
PMCS2_gangIn = (getNumber (_cfg >> "gangRadius")) max 30;
PMCS2_gangOut = PMCS2_gangIn + 20;
PMCS2_records = createHashMap;
// Main undercover method: civilian side (decision 4); captive only for comparison.
PMCS2_settings = createHashMapFromArray [["undercover", "side"], ["aura", 300], ["forget", true]];
PMCS2_posts = createHashMap;
PMCS2_events = [];
{createCenter _x} forEach [west, east, resistance, civilian];
{
    _x params ["_a", "_b", "_value"];
    _a setFriend [_b, _value]; _b setFriend [_a, _value];
} forEach [[west, east, 1], [west, resistance, 0], [east, resistance, 0],
    [west, civilian, 1], [east, civilian, 1], [resistance, civilian, 1]];
private _marker = createMarker ["PMCS2_zone", PMCS2_zone];
_marker setMarkerShape "ELLIPSE";
_marker setMarkerSize [PMCS2_zoneIn, PMCS2_zoneIn];
_marker setMarkerColor "ColorOrange";
_marker setMarkerBrush "Border";
private _label = createMarker ["PMCS2_zoneLabel", PMCS2_zone];
_label setMarkerType "mil_warning";
_label setMarkerColor "ColorOrange";
_label setMarkerText "S2 combat zone";
private _gangMarker = createMarker ["PMCS2_gang", PMCS2_gangZone];
_gangMarker setMarkerShape "ELLIPSE";
_gangMarker setMarkerSize [PMCS2_gangIn, PMCS2_gangIn];
_gangMarker setMarkerColor "ColorGUER";
_gangMarker setMarkerBrush "Border";
private _gangLabel = createMarker ["PMCS2_gangLabel", PMCS2_gangZone];
_gangLabel setMarkerType "mil_warning";
_gangLabel setMarkerColor "ColorGUER";
_gangLabel setMarkerText "Gang control zone";
["gang"] call PMCS_fnc_s2Post;
addMissionEventHandler ["EntityKilled", {
    params ["_unit", "_killer", ["_instigator", objNull]];
    private _by = if (isNull _instigator) then {_killer} else {_instigator};
    private _role = _unit getVariable ["PMCS2_role", ""];
    if (_role == "") then {_role = (group _unit) getVariable ["PMCS2_uid", ""]};
    if (_role != "") then {
        [format ["killed %1 (%2) by %3 side %4", _role, typeOf _unit, typeOf _by, side group _by]] call PMCS_fnc_s2Log;
    };
}];
addMissionEventHandler ["PlayerDisconnected", {
    params ["", "_uid"];
    private _r = PMCS2_records getOrDefault [_uid, createHashMap];
    {if (!isNull _x && {!isPlayer _x}) then {deleteVehicle _x}} forEach (_r getOrDefault ["bots", []]);
    PMCS2_records deleteAt _uid;
}];
// Atomic tick: a console request cannot interleave with a half-applied state.
[] spawn {while {true} do {isNil {call PMCS_fnc_s2Tick}; sleep 1}};
PMCS2_ready = true; publicVariable "PMCS2_ready";
["ready: WEST-EAST allied, GUER hostile to both, CIV friendly to all"] call PMCS_fnc_s2Log;
