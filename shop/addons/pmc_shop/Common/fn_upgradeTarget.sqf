// [weapon class, upgrade pairs] -> the class the weapon becomes, or "" when the upgrade
// does not take this weapon or the game has no such class. A pattern pair keeps what the
// "*" stood for: "MMM_weap_AK74_H2S1" by ["MMM_weap_AK74_H*S*", "MMM_weap_AK74_H*S*_GP25"]
// becomes "MMM_weap_AK74_H2S1_GP25". A pattern takes only the classes it owns
// (PMCS_fnc_ownerPattern).
params [["_weapon", "", [""]], ["_pairs", [], [[]]]];
if (_weapon == "") exitWith {""};
private _target = "";
{
    _x params [["_from", "", [""]], ["_to", "", [""]]];
    ([_weapon, _from] call PMCS_fnc_matchCaptures) params ["_ok", "_caps"];
    // A pattern takes only the classes it owns (an AK-74 + GP-25 is not a plain AK-74).
    if (_ok && {"*" in _from} && {([_weapon] call PMCS_fnc_ownerPattern) != toLower _from}) then {_ok = false};
    if (_ok) exitWith {
        private _out = "";
        private _n = 0;
        {
            if (_x == "*") then {
                if (_n < count _caps) then {_out = _out + (_caps select _n)};
                _n = _n + 1;
            } else {_out = _out + _x};
        } forEach (_to splitString "");
        private _cfg = configFile >> "CfgWeapons" >> _out;
        if (isClass _cfg) then {_target = configName _cfg};
    };
} forEach _pairs;
_target
