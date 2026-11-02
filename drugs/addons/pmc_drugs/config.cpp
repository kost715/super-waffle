class CfgPatches {
    class pmc_drugs {
        name = "PMC Drugs";
        author = "LifeSim PMC project";
        units[] = {"PMCD_ModuleMuscle"};
        weapons[] = {"PMCD_Stim1f", "PMCD_Fentropil", "PMCD_Meldonium"};
        requiredVersion = 2.14;
        requiredAddons[] = {"A3_Ui_F", "A3_Modules_F", "A3_Modules_F_Curator", "cba_settings", "cba_events", "ace_common", "ace_interact_menu",
            "ace_advanced_fatigue"};
        version = "0.6.0";
    };
};

class CfgFunctions {
    class PMCD {
        tag = "PMCD";
        class Init {
            file = "\pmc_drugs\Init";
            class settings {preInit = 1;};
            class init {postInit = 1;};
        };
        class Core {
            file = "\pmc_drugs\Core";
            class state {};
            class unitLoad {};
            class weightCoef {};
            class effects {};
            class duty {};
            class step {};
            class tick {};
            class takeStim {};
            class takeFen {};
            class fenLevel {};
            class fenApply {};
            class fenVisual {};
            class regenBoost {};
            class oxygen {};
            class aeSplit {};
            class takeMeld {};
            class meldLevel {};
            class meldApply {};
            class fenPain {};
            class currentWork {};
            class pulseEnd {};
            class thirst {};
            class canTake {};
            class notify {};
        };
        class Hud {
            file = "\pmc_drugs\Hud";
            class hud {};
            class hudColor {};
            class debug {};
            class debugText {};
        };
        class Zeus {
            file = "\pmc_drugs\Zeus";
            class moduleMuscle {};
            class muscleUi {};
            class muscleCheck {};
            class muscleSet {};
            class muscleShow {};
        };
    };
};

class CfgWeapons {
    class ACE_ItemCore;
    class CBA_MiscItem_ItemInfo;
    // Combat stimulant, self-injected (ACE self-interaction, Equipment). Its own picture, and
    // ACE's autoinjector model with its own texture: matte black, orange bands, "STIM-1F"
    // (tools/make_textures.py).
    class PMCD_Stim1f: ACE_ItemCore {
        scope = 2;
        author = "LifeSim PMC project";
        displayName = "$STR_PMCD_STIM_NAME";
        descriptionShort = "$STR_PMCD_STIM_DESC";
        picture = "\pmc_drugs\data\stim1f_ca.paa";
        model = "\pmc_drugs\data\stim1f.p3d";
        class ItemInfo: CBA_MiscItem_ItemInfo {
            mass = 11; // 0.5 kg (22 mass units per kg)
        };
    };
    // Cognitive modulator, self-injected the same way. White, teal bands, "FENTROPIL".
    class PMCD_Fentropil: ACE_ItemCore {
        scope = 2;
        author = "LifeSim PMC project";
        displayName = "$STR_PMCD_FEN_NAME";
        descriptionShort = "$STR_PMCD_FEN_DESC";
        picture = "\pmc_drugs\data\fentropil_ca.paa";
        model = "\pmc_drugs\data\fentropil.p3d";
        class ItemInfo: CBA_MiscItem_ItemInfo {
            mass = 7; // 0.3 kg
        };
    };
    // Metabolic optimizer, self-injected the same way. White, green bands, "MELDONIUM".
    class PMCD_Meldonium: ACE_ItemCore {
        scope = 2;
        author = "LifeSim PMC project";
        displayName = "$STR_PMCD_MELD_NAME";
        descriptionShort = "$STR_PMCD_MELD_DESC";
        picture = "\pmc_drugs\data\meldonium_ca.paa";
        model = "\pmc_drugs\data\meldonium.p3d";
        class ItemInfo: CBA_MiscItem_ItemInfo {
            mass = 4; // 0.2 kg
        };
    };
};

class CfgFactionClasses {
    class PMCD_Modules {
        displayName = "PMC Drugs";
        priority = 2;
        side = 7;
    };
};
class CfgVehicles {
    class Logic;
    class Module_F: Logic {};
    // Zeus: place on a player to check or set the muscle damage of that player.
    class PMCD_ModuleMuscle: Module_F {
        scope = 1;
        scopeCurator = 2;
        displayName = "$STR_PMCD_MODULE_MUSCLE";
        category = "PMCD_Modules";
        function = "PMCD_fnc_moduleMuscle";
        functionPriority = 1;
        isGlobal = 1;
        isTriggerActivated = 0;
        curatorCanAttach = 1;
    };
};

#include "ui.hpp"
