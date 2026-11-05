// Stand-ins for the game: the UI base classes the addon config names, the module base,
// and a few weapons, magazines and a backpack the catalog and the tests use.
class RscText {};
class RscStructuredText {};
class RscPicture {};
class RscButton {};
class RscEdit {};
class RscCombo {};
class RscCheckBox {};
class RscListNBox {};
class RscControlsGroupNoHScrollbars {};
class CfgWeapons {
    class rhs_weap_ak74 {scope = 2; type = 1; displayName = "AK-74"; picture = "\rhs\ak74_ca.paa";};
    // Out of order on purpose: the catalog sorts what a pattern finds.
    class MMM_weap_AK74_H2S1 {scope = 2; type = 1; displayName = "AK-74 (plum)"; picture = "\mmm\ak74_2_ca.paa";};
    class MMM_weap_AK74_H1S1 {scope = 2; type = 1; displayName = "AK-74 (plum)"; picture = "\mmm\ak74_1_ca.paa";};
    class MMM_weap_AK74_H3S1_base {scope = 1; type = 1; displayName = "base";};
    class MMM_weap_AK74N_H1S1 {scope = 2; type = 1; displayName = "AK-74N"; picture = "";};
    class rhs_weap_akm {scope = 2; type = 1; displayName = "AKM"; picture = "\rhs\akm_ca.paa";};
    class rhs_weap_ak74_gp25 {scope = 2; type = 1; displayName = "AK-74 GP-25"; picture = "\rhs\ak74gp_ca.paa";};
    class MMM_weap_AK74_H2S1_GP25 {scope = 2; type = 1; displayName = "AK-74 (plum) GP-25"; picture = "\mmm\ak74gp_ca.paa";};
    class rhs_weap_ak74mr {scope = 2; type = 1; displayName = "AK-74MR"; picture = "\rhs\ak74mr_ca.paa";};
    class rhs_weap_ak74mr_gp25 {scope = 2; type = 1; displayName = "AK-74MR GP-25"; picture = "\rhs\ak74mrgp_ca.paa";};
    class rhs_weap_pkm {scope = 2; type = 1; displayName = "PKM"; picture = "\rhs\pkm_ca.paa";};
    class rhs_weap_svds {scope = 2; type = 1; displayName = "SVD-S"; picture = "\rhs\svds_ca.paa";};
    class uk3cb_saiga12k {scope = 2; type = 1; displayName = "Saiga 12K"; picture = "";};
    class rhs_weap_asval {scope = 2; type = 1; displayName = "AS Val"; picture = "\rhs\asval_ca.paa";};
    class ItemGPS {scope = 2; type = 131072; displayName = "GPS"; picture = "\a3\gps_ca.paa";};
};
class CfgMagazines {
    class MMM_mag_545x39_6L20_7N6M {displayName = "6L20 7N6M"; picture = "\mmm\6l20_ca.paa";};
    class MMM_mag_545x39_6L20_7T3M {displayName = "6L20 7T3M"; picture = "\mmm\6l20_t_ca.paa";};
    class MMM_mag_545x39_6L23_Plastic_7N6M {displayName = "6L23 7N6M"; picture = "\mmm\6l23_ca.paa";};
    class MMM_mag_545x39_6L23_Plastic_7N22 {displayName = "6L23 7N22"; picture = "\mmm\6l23_ap_ca.paa";};
    class rhs_100Rnd_762x54mmR {displayName = "PKM box"; picture = "\rhs\pk_ca.paa";};
};
class CfgVehicles {
    class Logic {};
    class Module_F: Logic {
        class AttributesBase {
            class Edit {};
            class ModuleDescription {};
        };
        class ModuleDescription {};
    };
    class B_AssaultPack_rgr {isbackpack = 1; displayName = "Assault Pack"; picture = "\a3\pack_ca.paa";};
};
