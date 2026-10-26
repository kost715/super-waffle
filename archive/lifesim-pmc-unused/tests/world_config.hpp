// Fixture class names only. These are not model assets or production config.
class CfgVehicles {
    class CAManBase {};
    class Land_TableDesk_F {};
    class Land_PCSet_01_screen_F {};
    class Land_PCSet_01_case_F {};
    class Land_PCSet_01_keyboard_F {};
    class TestVan_F {displayName = "Test van";};
    class O_G_Soldier_F {};
    class C_man_1 {};
    class C_man_w_worker_F {};
    class C_Truck_02_transport_F {};
    class C_Offroad_01_F {};
    class I_G_Offroad_01_armed_F {};
    class Land_MetalCase_01_large_F {};
    class APERSMine {};
    class TestBuilding_F {};
    class TestPlayer_F {};
    class C_Man_formal_1_F {};
    class C_Nikos_aged {};
    class I_C_Soldier_Bandit_1_F: CAManBase {};
    class NativeGang_Rifleman: CAManBase {};
    class NativeGang_Scout: CAManBase {};
    class UK3CB_TEST_Militia_Rifleman: CAManBase {scope = 2; faction = "UK3CB_TKM_O"; weapons[] = {"rhs_weap_akm"};};
    class UK3CB_TEST_Militia_Scout: UK3CB_TEST_Militia_Rifleman {};
};
class CfgWeapons {
    class hgun_ACPC2_F {};
    class hgun_Pistol_heavy_02_F {};
    class SMG_02_F {};
    class arifle_TRG21_F {};
    class arifle_MX_F {};
    class LMG_Mk200_F {};
    class srifle_EBR_F {};
    class U_C_FormalSuit_01_black_F {};
    class U_C_FormalSuit_01_gray_F {};
    class U_NikosAgedBody {};
    class rhs_weap_akm {scope = 2; type = 1; cursor = "arifle"; muzzles[] = {"this"}; magazines[] = {"rhs_30Rnd_762x39mm"};};
    class rhs_weap_makarov_pm {scope = 2; type = 2; muzzles[] = {"this"}; magazines[] = {"rhs_8Rnd_9x18mm"};};
    class rhs_weap_pkm {scope = 2; type = 1; cursor = "mg"; muzzles[] = {"this"}; magazines[] = {"rhs_100Rnd_762x54mm"};};
    class rhs_weap_ak74_gp25: rhs_weap_akm {muzzles[] = {"this", "GP25Muzzle"};};
    class rhs_weap_rpg7: rhs_weap_akm {type = 4;};
};
class CfgMagazines {
    class rhs_30Rnd_762x39mm {};
    class rhs_8Rnd_9x18mm {};
    class rhs_100Rnd_762x54mm {};
};
