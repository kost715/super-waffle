disableSerialization;
private _d = uiNamespace getVariable ["PMCS2_console", displayNull];
if (isNull _d) exitWith {};
private _s = uiNamespace getVariable ["PMCS2_state", createHashMap];
if (count _s == 0) exitWith {};
private _name = {
    params ["_key"];
    if (_key == "") exitWith {localize "STR_PMCS2_M_AUTO"};
    localize (createHashMapFromArray [["none", "STR_PMCS2_C_NONE"], ["west", "STR_PMCS2_SIDE_WEST"], ["east", "STR_PMCS2_SIDE_EAST"],
        ["guer", "STR_PMCS2_SIDE_GUER"], ["civ", "STR_PMCS2_SIDE_CIV"]] getOrDefault [_key, "STR_PMCS2_C_NONE"])
};
private _yes = {localize (["STR_PMCS2_NO", "STR_PMCS2_YES"] select _this)};
private _shot = {if (_this < 0) then {"-"} else {str _this}};
(_d displayCtrl 4001) ctrlSetStructuredText parseText format [localize "STR_PMCS2_SUMMARY",
    [_s get "color"] call _name, (_s get "captive") call _yes, _s get "reason",
    [_s get "contract"] call _name, [_s get "manual"] call _name, (_s get "inZone") call _yes, _s get "distance", _s get "auraLeft",
    _s get "changedAgo", (_s get "firstShot") call _shot, (_s get "lastShot") call _shot,
    localize (["STR_PMCS2_U_SIDE", "STR_PMCS2_U_CAPTIVE"] select ((_s get "undercover") == "captive")), _s get "aura",
    (_s get "forget") call _yes, if ((_s get "posts") isEqualTo []) then {"-"} else {(_s get "posts") joinString ", "},
    (_s getOrDefault ["inGang", false]) call _yes];
// Highlight current choices.
private _mark = {
    params ["_idcs", "_values", "_current"];
    {(_d displayCtrl _x) ctrlSetTextColor ([[1, 1, 1, 1], [0.4, 1, 0.4, 1]] select ((_values select _forEachIndex) isEqualTo _current))} forEach _idcs;
};
[[4100, 4101, 4102, 4103], ["none", "west", "east", "guer"], _s get "contract"] call _mark;
[[4110, 4111, 4112, 4113, 4114], ["", "west", "east", "guer", "civ"], _s get "manual"] call _mark;
[[4120, 4121], ["side", "captive"], _s get "undercover"] call _mark;
[[4122, 4123], [30, 300], _s get "aura"] call _mark;
[[4124], [true], _s get "forget"] call _mark;
private _admin = _s get "admin";
{(_d displayCtrl _x) ctrlEnable _admin} forEach [4120, 4121, 4122, 4123, 4124, 4130, 4131, 4132, 4133, 4134, 4135];
private _events = _s get "events";
if ((_d getVariable ["PMCS2_events", []]) isNotEqualTo _events) then {
    private _list = _d displayCtrl 4200; lbClear _list;
    {_list lbAdd _x} forEach (+_events call {reverse _this; _this});
    _d setVariable ["PMCS2_events", +_events];
};
