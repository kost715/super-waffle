class CfgPatches {
    class pmc_shop {
        name = "PMC Shop";
        author = "LifeSim PMC project";
        units[] = {"PMCS_ModuleShop", "PMCS_ModuleAdmin", "PMCS_ModulePoint"};
        weapons[] = {};
        requiredVersion = 2.14;
        requiredAddons[] = {"A3_Ui_F", "A3_Modules_F", "cba_xeh", "cba_settings", "pmc_bank"};
        version = "0.1.0";
    };
};

// CBA settings come from CBA's preInit, which also runs in Eden and the main menu.
class Extended_PreInit_EventHandlers {
    class pmc_shop {
        init = "call compile preprocessFileLineNumbers '\pmc_shop\Init\fn_settings.sqf'";
    };
};

class CfgFunctions {
    class PMCS {
        tag = "PMCS";
        class Init {
            file = "\pmc_shop\Init";
            class settings {};
        };
        class Common {
            file = "\pmc_shop\Common";
            class catalog {};
            class itemInfo {};
            class itemName {};
            class marketNew {};
            class marketPack {};
            class marketUnpack {};
            class match {};
            class money {};
            class price {};
            class quote {};
            class requestOwner {};
        };
        class Server {
            file = "\pmc_shop\Server";
            class admin {};
            class bankState {};
            class broadcast {};
            class buy {};
            class caller {};
            class closed {};
            class deliver {};
            class isZeus {};
            class log {};
            class marketKey {};
            class moduleAdmin {};
            class modulePoint {};
            class moduleShop {};
            class push {};
            class registerPoint {};
            class registerTerminal {};
            class requestState {};
            class save {};
            class serverInit {postInit = 1;};
            class serverLoad {};
            class terminalNear {};
        };
        class Client {
            file = "\pmc_shop\Client";
            class notify {};
            class open {};
            class receive {};
            class terminalInit {};
            class ui {};
            class uiAdmin {};
            class uiCartAdd {};
            class uiCartLine {};
            class uiClear {};
            class uiColor {};
            class uiMake {};
            class uiShop {};
            class uiShopList {};
        };
    };
};

// Effective when the mission whitelists remote execution (CfgRemoteExec mode 1).
class CfgRemoteExec {
    class Functions {
        class PMCS_fnc_requestState {allowedTargets = 2; jip = 0;};
        class PMCS_fnc_closed {allowedTargets = 2; jip = 0;};
        class PMCS_fnc_buy {allowedTargets = 2; jip = 0;};
        class PMCS_fnc_admin {allowedTargets = 2; jip = 0;};
        class PMCS_fnc_receive {allowedTargets = 0; jip = 0;};
        class PMCS_fnc_notify {allowedTargets = 0; jip = 0;};
        class PMCS_fnc_terminalInit {allowedTargets = 0; jip = 1;};
    };
};

class CfgFactionClasses {
    class PMCS_Modules {
        displayName = "PMC Shop";
        priority = 2;
        side = 7;
    };
};

class CfgVehicles {
    class Logic;
    class Module_F: Logic {
        class AttributesBase {
            class Edit;
            class ModuleDescription;
        };
        class ModuleDescription;
    };
    // Eden: synchronise laptops; goods go to the delivery point with the same ID.
    class PMCS_ModuleShop: Module_F {
        scope = 2;
        scopeCurator = 0;
        displayName = "$STR_PMCS_MODULE_SHOP";
        category = "PMCS_Modules";
        icon = "\pmc_shop\data\icon_browser_ca.paa";
        function = "PMCS_fnc_moduleShop";
        functionPriority = 1;
        isGlobal = 0;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;
        class Attributes: AttributesBase {
            class PointID: Edit {
                property = "PMCS_ModuleShop_PointID";
                displayName = "$STR_PMCS_MODULE_POINT_ID";
                tooltip = "$STR_PMCS_MODULE_POINT_ID_TIP";
                typeName = "STRING";
                defaultValue = """base""";
            };
            class ModuleDescription: ModuleDescription {};
        };
        class ModuleDescription: ModuleDescription {
            description = "$STR_PMCS_MODULE_SHOP_DESC";
        };
    };
    // Eden: synchronise laptops where a Zeus manages this mission's market.
    class PMCS_ModuleAdmin: Module_F {
        scope = 2;
        scopeCurator = 0;
        displayName = "$STR_PMCS_MODULE_ADMIN";
        category = "PMCS_Modules";
        icon = "\pmc_shop\data\icon_browser_ca.paa";
        function = "PMCS_fnc_moduleAdmin";
        functionPriority = 1;
        isGlobal = 0;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;
        class Attributes: AttributesBase {
            class ModuleDescription: ModuleDescription {};
        };
        class ModuleDescription: ModuleDescription {
            description = "$STR_PMCS_MODULE_ADMIN_DESC";
        };
    };
    // Eden: synchronise the box that receives the goods of this point.
    class PMCS_ModulePoint: Module_F {
        scope = 2;
        scopeCurator = 0;
        displayName = "$STR_PMCS_MODULE_POINT";
        category = "PMCS_Modules";
        icon = "\A3\ui_f\data\map\vehicleicons\iconCrateAmmo_ca.paa";
        function = "PMCS_fnc_modulePoint";
        functionPriority = 1;
        isGlobal = 0;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;
        class Attributes: AttributesBase {
            class PointID: Edit {
                property = "PMCS_ModulePoint_PointID";
                displayName = "$STR_PMCS_MODULE_POINT_ID";
                tooltip = "$STR_PMCS_MODULE_POINT_ID_TIP";
                typeName = "STRING";
                defaultValue = """base""";
            };
            class ModuleDescription: ModuleDescription {};
        };
        class ModuleDescription: ModuleDescription {
            description = "$STR_PMCS_MODULE_POINT_DESC";
        };
    };
};

#include "catalog.hpp"
#include "ui.hpp"
