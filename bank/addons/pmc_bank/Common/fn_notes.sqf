// -> [[class, value], ...], largest value first. Banknotes from the CBA setting
// PMCB_notes, written "class:value, class:value". A class must exist as an item
// (CfgWeapons) or a magazine (CfgMagazines); other entries, and a second entry
// for a class or a value already listed, are skipped.
private _setting = missionNamespace getVariable ["PMCB_notes", ""];
if (_setting isEqualTo (missionNamespace getVariable ["PMCB_notesSource", -1])) exitWith {+PMCB_notesCache};
private _clean = (_setting splitString toString [32, 9, 10, 13]) joinString "";
private _byValue = [];
{
    private _pair = _x splitString ":";
    private _class = "";
    private _value = 0;
    if (count _pair == 2) then {
        _value = parseNumber (_pair select 1);
        {
            private _cfg = configFile >> _x >> (_pair select 0);
            if (_class == "" && {isClass _cfg}) then {_class = configName _cfg};
        } forEach ["CfgWeapons", "CfgMagazines"];
    };
    if (_class != "" && {_value > 0} && {_value == floor _value} && {_value < 1e7} && {
        (_byValue findIf {(_x select 0) == _value || {(_x select 1) == _class}}) < 0}) then {
        _byValue pushBack [_value, _class];
    } else {
        diag_log text format ["[PMCB] banknote setting: skipped ""%1"" (unknown class, bad value, or class or value repeated)", _x];
    };
} forEach (_clean splitString ",");
// Largest value first; a handful of notes, so a plain selection is enough.
private _sorted = [];
while {_byValue isNotEqualTo []} do {
    private _best = 0;
    {
        if ((_x select 0) > ((_byValue select _best) select 0)) then {_best = _forEachIndex};
    } forEach _byValue;
    private _note = _byValue deleteAt _best;
    _sorted pushBack [_note select 1, _note select 0];
};
PMCB_notesCache = _sorted;
PMCB_notesSource = _setting;
+PMCB_notesCache
