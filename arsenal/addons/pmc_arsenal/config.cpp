class CfgPatches {
    class pmc_arsenal {
        name = "PMC Arsenal";
        author = "LifeSim PMC project; arsenal interface by Jeroen Notenbomer (Antistasi)";
        units[] = {};
        weapons[] = {};
        requiredVersion = 2.14;
        // Vanilla only. ACE, TFAR and ACRE are detected at runtime when loaded.
        requiredAddons[] = {"A3_Ui_F", "3DEN"};
        version = "0.1.0";
    };
};

class CfgFunctions {
    class PMCA {
        tag = "PMCA";
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
        };
        class Client {
            file = "\pmc_arsenal\Client";
            class clientInit {postInit = 1;};
            class applyLoadout {};
            class notify {};
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
