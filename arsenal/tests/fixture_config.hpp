// Minimal vanilla-like classes for the SQF-VM server checks. Only the config
// properties the arsenal reads are present; TEST_itemType stands in for
// BIS_fnc_itemType, which needs the full game config.
class CfgWeapons {
    class Default {};
    class Throw {
        muzzles[] = {"HandGrenadeMuzzle"};
        class HandGrenadeMuzzle {magazines[] = {"HandGrenade"};};
    };
    class Put {
        muzzles[] = {"DemoChargeMuzzle"};
        class DemoChargeMuzzle {magazines[] = {"DemoCharge_Remote_Mag"};};
    };
    class Rifle_Base_F {type = 1; muzzles[] = {"this"}; class WeaponSlotsInfo {}; TEST_itemType = "AssaultRifle";};
    class arifle_MX_F: Rifle_Base_F {displayName = "MX 6.5 mm"; baseWeapon = "arifle_MX_F";};
    class arifle_MX_ACO_F: arifle_MX_F {};
    class launch_RPG32_F: Rifle_Base_F {type = 4; displayName = "RPG-42"; baseWeapon = "launch_RPG32_F"; TEST_itemType = "RocketLauncher";};
    class hgun_P07_F: Rifle_Base_F {type = 2; displayName = "P07 9 mm"; baseWeapon = "hgun_P07_F"; TEST_itemType = "Handgun";};
    class ItemCore {type = 131072;};
    class optic_Aco: ItemCore {displayName = "ACO"; class ItemInfo {type = 201;};};
    class FirstAidKit: ItemCore {displayName = "First Aid Kit"; class ItemInfo {type = 401;};};
    class U_B_CombatUniform_mcam: ItemCore {displayName = "Combat Fatigues"; class ItemInfo {type = 801;};};
    class V_PlateCarrier1_rgr: ItemCore {displayName = "Carrier Lite"; class ItemInfo {type = 701;};};
    class H_HelmetB: ItemCore {displayName = "ECH"; class ItemInfo {type = 605;};};
    class ItemMap: ItemCore {simulation = "ItemMap";};
    class ItemCompass: ItemCore {simulation = "ItemCompass";};
    class ItemWatch: ItemCore {simulation = "ItemWatch";};
    class ItemRadio: ItemCore {simulation = "ItemRadio";};
};
class CfgMagazines {
    class Default {};
    class CA_Magazine {type = 256; count = 1;};
    class 30Rnd_65x39_caseless_mag: CA_Magazine {displayName = "6.5 mm 30Rnd Mag"; count = 30;};
    class HandGrenade: CA_Magazine {displayName = "RGO Grenade";};
    class DemoCharge_Remote_Mag: CA_Magazine {displayName = "Explosive Charge"; type = 512;};
};
class CfgVehicles {
    class All {};
    class AllVehicles: All {};
    class CAManBase: AllVehicles {};
    class B_Soldier_F: CAManBase {};
    class ReammoBox_F: All {transportMaxWeapons = 20; transportMaxMagazines = 100; transportMaxBackpacks = 5;};
    class Box_NATO_Ammo_F: ReammoBox_F {};
    class Land_Wall_F: All {};
    class Bag_Base: All {isBackpack = 1;};
    class B_AssaultPack_rgr: Bag_Base {displayName = "Assault Pack";};
};
class CfgGlasses {
    class None {};
    class G_Shades_Black: None {displayName = "Shades";};
};
