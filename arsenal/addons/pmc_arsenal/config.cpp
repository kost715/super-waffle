class CfgPatches {
    class pmc_arsenal {
        name = "PMC Arsenal";
        author = "LifeSim PMC project; arsenal interface by Jeroen Notenbomer (Antistasi)";
        units[] = {"PMCA_ModuleStorage", "PMCA_ModuleDebugLoad"};
        weapons[] = {};
        requiredVersion = 2.14;
        // CBA for the mod settings. ACE, TFAR and ACRE are detected at runtime when loaded.
        requiredAddons[] = {"A3_Ui_F", "3DEN", "A3_Modules_F", "A3_Modules_F_Curator", "cba_settings"};
        version = "0.2.0";
    };
};

class CfgFunctions {
    class PMCA {
        tag = "PMCA";
        class Init {
            file = "\pmc_arsenal\Init";
            class settings {preInit = 1;};
        };
        class Common {
            file = "\pmc_arsenal\Common";
            class common_addActionSelect {};
            class common_addActionCancel {};
            class common_updateActionCancel {};
            class common_removeActionCancel {};
            class common_getActionCanceled {};
        };
        class Common_Vehicle {
            file = "\pmc_arsenal\Common\Vehicle";
            class common_vehicle_getSeatNames {};
            class common_vehicle_getVehicleType {};
        };
        class Common_Array {
            file = "\pmc_arsenal\Common\Array";
            class common_array_add {};
            class common_array_remove {};
        };
        class JNA {
            file = "\pmc_arsenal\JNA";
            class arsenal {};
            class arsenal_addItem {};
            class arsenal_addToArray {};
            class arsenal_cargoToArray {};
            class arsenal_cargoToArsenal {};
            class arsenal_handleAction {};
            class arsenal_init {};
            class arsenal_inList {};
            class arsenal_itemCount {};
            class arsenal_itemType {};
            class arsenal_loadInventory {};
            class arsenal_removeFromArray {};
            class arsenal_removeItem {};
            class arsenal_requestOpen {};
            class arsenal_requestClose {};
            class vehicleArsenal {};
        };
        class Server {
            file = "\pmc_arsenal\Server";
            class serverInit {postInit = 1;};
            class serverLoad {};
            class registerStorage {};
            class storageAdd {};
            class storageItems {};
            class storageList {};
            class allowedTabs {};
            class itemKey {};
            class loadoutItems {};
            class cargoItems {};
            class broadcast {};
            class preview {};
            class commit {};
            class restoreCargo {};
            class save {};
            class requestOwner {};
            class unlock {};
            class boxCargo {};
            class boxRestore {};
            class boxScan {};
            class boxLoad {};
            class debugLoad {};
            class moduleStorage {};
        };
        class Client {
            file = "\pmc_arsenal\Client";
            class clientInit {postInit = 1;};
            class applyLoadout {};
            class notify {};
            class moduleDebugLoad {};
        };
    };
};

// Effective when the mission whitelists remote execution (CfgRemoteExec mode 1).
class CfgRemoteExec {
    class Functions {
        class PMCA_fnc_arsenal_requestOpen {allowedTargets = 2; jip = 0;};
        class PMCA_fnc_arsenal_requestClose {allowedTargets = 2; jip = 0;};
        class PMCA_fnc_arsenal_cargoToArsenal {allowedTargets = 2; jip = 0;};
        class PMCA_fnc_preview {allowedTargets = 2; jip = 0;};
        class PMCA_fnc_debugLoad {allowedTargets = 2; jip = 0;};
        class PMCA_fnc_arsenal {allowedTargets = 0; jip = 0;};
        class PMCA_fnc_arsenal_init {allowedTargets = 0; jip = 1;};
        class PMCA_fnc_applyLoadout {allowedTargets = 0; jip = 0;};
        class PMCA_fnc_notify {allowedTargets = 0; jip = 0;};
    };
};

// Eden: any object with inventory can be marked as an arsenal storage.
class Cfg3DEN {
    class Object {
        class AttributeCategories {
            class PMCA_Arsenal {
                displayName = "PMC Arsenal";
                collapsed = 1;
                class Attributes {
                    class PMCA_storage {
                        displayName = "Storage ID";
                        tooltip = "Non-empty: this object opens the PMC arsenal backed by the persistent storage with this ID. Several objects may share one storage.";
                        property = "PMCA_storage";
                        control = "Edit";
                        expression = "if (isServer && {_value != ''}) then {[_this, _value] call PMCA_fnc_registerStorage};";
                        defaultValue = "''";
                        typeName = "STRING";
                        condition = "objectHasInventoryCargo";
                    };
                };
            };
        };
    };
};

class CfgFactionClasses {
    class PMCA_Modules {
        displayName = "PMC Arsenal";
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
    // Eden: synchronise objects with inventory to make them open this storage.
    class PMCA_ModuleStorage: Module_F {
        scope = 2;
        scopeCurator = 0;
        displayName = "$STR_PMCA_MODULE_STORAGE";
        category = "PMCA_Modules";
        icon = "\A3\ui_f\data\GUI\Rsc\RscDisplayArsenal\spaceArsenal_ca.paa";
        function = "PMCA_fnc_moduleStorage";
        functionPriority = 1;
        isGlobal = 0;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;
        class Attributes: AttributesBase {
            class StorageID: Edit {
                property = "PMCA_ModuleStorage_StorageID";
                displayName = "Storage ID";
                tooltip = "$STR_PMCA_MODULE_STORAGE_ID_TIP";
                typeName = "STRING";
                defaultValue = """base""";
            };
            class ModuleDescription: ModuleDescription {};
        };
        class ModuleDescription: ModuleDescription {
            description = "$STR_PMCA_MODULE_STORAGE_DESC";
        };
    };
    // Zeus, debug mode: place on a box near an arsenal to make its contents unlimited there.
    class PMCA_ModuleDebugLoad: Module_F {
        scope = 1;
        scopeCurator = 2;
        displayName = "$STR_PMCA_MODULE_DEBUG";
        category = "PMCA_Modules";
        function = "PMCA_fnc_moduleDebugLoad";
        functionPriority = 1;
        isGlobal = 1;
        isTriggerActivated = 0;
        curatorCanAttach = 1;
    };
};
