class CfgPatches {
    class pmc_drugs {
        name = "PMC Drugs";
        author = "LifeSim PMC project";
        units[] = {"PMCD_ModuleMuscle"};
        weapons[] = {"PMCD_Stim1f"};
        requiredVersion = 2.14;
        requiredAddons[] = {"A3_Ui_F", "A3_Modules_F", "A3_Modules_F_Curator", "cba_settings", "cba_events", "ace_common", "ace_interact_menu",
            "ace_advanced_fatigue"};
        version = "0.1.0";
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
            class loadClass {};
            class unitLoad {};
            class stimDose {};
            class effects {};
            class duty {};
            class step {};
            class tick {};
            class takeStim {};
            class overdose {};
            class thirst {};
            class canTake {};
            class notify {};
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
    // Combat stimulant, self-injected (ACE self-interaction, Equipment). The autoinjector
    // model and picture are ACE's (medical_treatment).
    class PMCD_Stim1f: ACE_ItemCore {
        scope = 2;
        author = "LifeSim PMC project";
        displayName = "$STR_PMCD_STIM_NAME";
        descriptionShort = "$STR_PMCD_STIM_DESC";
        picture = "\z\ace\addons\medical_treatment\ui\epinephrine_ca.paa";
        model = "\z\ace\addons\medical_treatment\data\epinephrine.p3d";
        class ItemInfo: CBA_MiscItem_ItemInfo {
            mass = 11; // 0.5 kg (22 mass units per kg)
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
