params ["_unit", "_level", ["_index", 0]];
// Discover installed 3CB/RHS weapons, with matching magazines. No launchers,
// additional GL muzzles or inherited explosives survive this equip operation.
removeAllWeapons _unit;
{_unit removeMagazine _x} forEach magazines _unit;
removeBackpack _unit;
private _pool = [
    [["hgun_ACPC2_F", "9Rnd_45ACP_Mag"], ["hgun_Pistol_heavy_02_F", "6Rnd_45ACP_Cylinder"]],
    [["SMG_02_F", "30Rnd_9x21_Mag_SMG_02"], ["arifle_TRG21_F", "30Rnd_556x45_Stanag"]],
    [["arifle_MX_F", "30Rnd_65x39_caseless_mag"], ["srifle_EBR_F", "20Rnd_762x51_Mag"]],
    [["arifle_MX_F", "30Rnd_65x39_caseless_mag"], ["LMG_Mk200_F", "200Rnd_65x39_cased_Box"], ["srifle_EBR_F", "20Rnd_762x51_Mag"]],
    [["arifle_MX_F", "30Rnd_65x39_caseless_mag"], ["LMG_Mk200_F", "200Rnd_65x39_cased_Box"], ["srifle_EBR_F", "20Rnd_762x51_Mag"]]
] select ((_level max 1 min 5) - 1);
private _assets = call ALSPMC_fnc_contractAssets;
private _modPools = _assets get "weapons";
private _modPool = switch (_level) do {
    case 1: {+(_modPools select 0)};
    case 2: {(_modPools select 1) + (_modPools select 2)};
    case 3: {+(_modPools select 2)};
    default {(_modPools select 2) + (_modPools select 3)};
};
if (_modPool isNotEqualTo []) then {_pool = _modPool};
private _load = selectRandom _pool;
if !(isClass (configFile >> "CfgWeapons" >> (_load select 0))) then {_load = ["hgun_ACPC2_F", "9Rnd_45ACP_Mag"]};
_unit addMagazines [_load select 1, 6];
_unit addWeapon (_load select 0);
_unit selectWeapon (_load select 0);
_unit setSkill (0.2 + _level * 0.08);
_unit allowFleeing 0;
_unit setVariable ["ALSPMC_loadout", +_load];
