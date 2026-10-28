#include "ui_defines.hpp"

class CfgPatches {
    class pmc_bank {
        name = "PMC Bank";
        author = "LifeSim PMC project";
        units[] = {"PMCB_ModuleAtm", "PMCB_ModuleZeusAtm", "PMCB_ModuleZeusAdd", "PMCB_ModuleZeusRemove", "PMCB_ModuleZeusTreasurer", "PMCB_ModuleZeusJournal"};
        weapons[] = {};
        requiredVersion = 2.14;
        requiredAddons[] = {"A3_Ui_F", "3DEN", "A3_Modules_F", "A3_Modules_F_Curator", "cba_settings"};
        version = "0.1.1";
    };
};

class CfgFunctions {
    class PMCB {
        tag = "PMCB";
        class Init {
            file = "\pmc_bank\Init";
            class settings {preInit = 1;};
        };
        class Common {
            file = "\pmc_bank\Common";
            class notes {};
            class noteValue {};
            class compose {};
            class noteCounts {};
            class money {};
            class requestOwner {};
        };
        class Server {
            file = "\pmc_bank\Server";
            class serverInit {postInit = 1;};
            class serverLoad {};
            class save {};
            class caller {};
            class isZeus {};
            class atmNear {};
            class ensure {};
            class log {};
            class apply {};
            class parseComposition {};
            class state {};
            class push {};
            class pushGroup {};
            class requestState {};
            class closed {};
            class withdraw {};
            class depositStart {};
            class depositSettle {};
            class registerAtm {};
            class moduleAtm {};
            class zeusAdjust {};
            class zeusTreasurer {};
            class zeusAtm {};
            class zeusLog {};
        };
        class Client {
            file = "\pmc_bank\Client";
            class ui {};
            class open {};
            class receive {};
            class receiveLog {};
            class give {};
            class take {};
            class notify {};
            class export {};
            class atmInit {};
            class zeusTarget {};
            class moduleZeusAtm {};
            class moduleZeusAdd {};
            class moduleZeusRemove {};
            class moduleZeusTreasurer {};
            class moduleZeusJournal {};
        };
    };
};

// Effective when the mission whitelists remote execution (CfgRemoteExec mode 1).
class CfgRemoteExec {
    class Functions {
        class PMCB_fnc_requestState {allowedTargets = 2; jip = 0;};
        class PMCB_fnc_closed {allowedTargets = 2; jip = 0;};
        class PMCB_fnc_withdraw {allowedTargets = 2; jip = 0;};
        class PMCB_fnc_depositStart {allowedTargets = 2; jip = 0;};
        class PMCB_fnc_depositSettle {allowedTargets = 2; jip = 0;};
        class PMCB_fnc_zeusAdjust {allowedTargets = 2; jip = 0;};
        class PMCB_fnc_zeusTreasurer {allowedTargets = 2; jip = 0;};
        class PMCB_fnc_zeusAtm {allowedTargets = 2; jip = 0;};
        class PMCB_fnc_zeusLog {allowedTargets = 2; jip = 0;};
        class PMCB_fnc_receive {allowedTargets = 0; jip = 0;};
        class PMCB_fnc_receiveLog {allowedTargets = 0; jip = 0;};
        class PMCB_fnc_give {allowedTargets = 0; jip = 0;};
        class PMCB_fnc_take {allowedTargets = 0; jip = 0;};
        class PMCB_fnc_notify {allowedTargets = 0; jip = 0;};
        class PMCB_fnc_atmInit {allowedTargets = 0; jip = 1;};
    };
};

class CfgFactionClasses {
    class PMCB_Modules {
        displayName = "PMC Bank";
        priority = 2;
        side = 7;
    };
};

class CfgVehicles {
    class Logic;
    class Module_F: Logic {
        class AttributesBase {
            class ModuleDescription;
        };
        class ModuleDescription;
    };
    // Eden: synchronise objects with this module to make them ATMs.
    class PMCB_ModuleAtm: Module_F {
        scope = 2;
        scopeCurator = 0;
        displayName = "$STR_PMCB_MODULE_ATM";
        category = "PMCB_Modules";
        function = "PMCB_fnc_moduleAtm";
        functionPriority = 1;
        isGlobal = 0;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;
        class Attributes: AttributesBase {
            class ModuleDescription: ModuleDescription {};
        };
        class ModuleDescription: ModuleDescription {
            description = "$STR_PMCB_MODULE_ATM_DESC";
        };
    };
    // Zeus modules run on the Zeus who placed them.
    class PMCB_ModuleZeusBase: Module_F {
        scope = 1;
        scopeCurator = 1;
        category = "PMCB_Modules";
        functionPriority = 1;
        isGlobal = 1;
        isTriggerActivated = 0;
        curatorCanAttach = 0;
    };
    class PMCB_ModuleZeusAtm: PMCB_ModuleZeusBase {
        scopeCurator = 2;
        displayName = "$STR_PMCB_MODULE_ZEUS_ATM";
        function = "PMCB_fnc_moduleZeusAtm";
        curatorCanAttach = 1;
    };
    class PMCB_ModuleZeusAdd: PMCB_ModuleZeusBase {
        scopeCurator = 2;
        displayName = "$STR_PMCB_MODULE_ADD";
        function = "PMCB_fnc_moduleZeusAdd";
    };
    class PMCB_ModuleZeusRemove: PMCB_ModuleZeusBase {
        scopeCurator = 2;
        displayName = "$STR_PMCB_MODULE_REMOVE";
        function = "PMCB_fnc_moduleZeusRemove";
    };
    class PMCB_ModuleZeusTreasurer: PMCB_ModuleZeusBase {
        scopeCurator = 2;
        displayName = "$STR_PMCB_MODULE_TREASURER";
        function = "PMCB_fnc_moduleZeusTreasurer";
        curatorCanAttach = 1;
    };
    class PMCB_ModuleZeusJournal: PMCB_ModuleZeusBase {
        scopeCurator = 2;
        displayName = "$STR_PMCB_MODULE_JOURNAL";
        function = "PMCB_fnc_moduleZeusJournal";
    };
};

#include "ui.hpp"
