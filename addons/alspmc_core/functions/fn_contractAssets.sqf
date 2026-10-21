// Reuse LifeSim's resolved gang faction selection (including its WithMods).
// Cache discovery by faction men: a late native initialization cannot freeze a fallback.
private _men = ((missionNamespace getVariable ["ALS_factions", createHashMap]) getOrDefault ["Gangs", createHashMap]) getOrDefault ["men", []];
private _key = str _men;
private _cached = missionNamespace getVariable ["ALSPMC_contractAssets", createHashMap];
if (count _cached > 0 && {(_cached getOrDefault ["gangKey", ""]) == _key}) exitWith {_cached};
private _militia = _men select {isClass (configFile >> "CfgVehicles" >> _x) && {_x isKindOf "CAManBase"}};
// Same fallback as LifeSim's fn_gangTick, only when its Gangs pool is empty.
if (_militia isEqualTo []) then {
    _militia = ["I_C_Soldier_Bandit_1_F", "I_C_Soldier_Bandit_2_F", "I_C_Soldier_Bandit_3_F", "I_C_Soldier_Bandit_5_F"] select {isClass (configFile >> "CfgVehicles" >> _x)};
};
private _pools = [[],[],[],[]];
{
    private _name = configName _x;
    private _lower = toLowerANSI _name;
    private _mod = (_lower find "uk3cb") == 0 || {(_lower find "rhs") == 0};
    if (_mod && {getNumber (_x >> "scope") == 2} && {getNumber (_x >> "type") in [1,2]} && {
        ((getArray (_x >> "muzzles")) findIf {!(_x in ["this", "This"])}) < 0
    }) then {
        private _type = getNumber (_x >> "type");
        private _mags = (getArray (_x >> "magazines")) select {isClass (configFile >> "CfgMagazines" >> _x)};
        if (_mags isNotEqualTo []) then {
            private _bucket = if (_type == 2) then {0} else {
                private _cursor = toLowerANSI getText (_x >> "cursor");
                if (_cursor in ["mg", "srifle"]) then {3} else {if (_cursor == "smg") then {1} else {2}}
            };
            (_pools select _bucket) pushBack [_name, _mags select 0];
        };
    };
} forEach ("true" configClasses (configFile >> "CfgWeapons"));
_cached = createHashMapFromArray [["gangKey", _key], ["militia", _militia], ["weapons", _pools]];
ALSPMC_contractAssets = _cached;
_cached
