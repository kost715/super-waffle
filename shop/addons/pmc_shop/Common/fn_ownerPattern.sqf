// [class] -> the table's class pattern this class belongs to (lower case), or "": of the
// patterns that fit it (CfgPMCShop >> patterns), the most specific one, the one with the
// most fixed characters. "MMM_weap_AK74_H1S1_GP25" fits both "MMM_weap_AK74_H*S*" and
// "MMM_weap_AK74_H*S*_GP25" and belongs to the second.
params [["_class", "", [""]]];
if (isNil "PMCS_owners") then {
    PMCS_owners = createHashMap;
    PMCS_patterns = getArray (configFile >> "CfgPMCShop" >> "patterns");
};
private _key = toLower _class;
if (_key in PMCS_owners) exitWith {PMCS_owners get _key};
private _best = "";
private _length = -1;
{
    if ([_class, _x] call PMCS_fnc_match) then {
        private _fixed = count ((_x splitString "*") joinString "");
        if (_fixed > _length) then {_best = toLower _x; _length = _fixed};
    };
} forEach PMCS_patterns;
PMCS_owners set [_key, _best];
_best
