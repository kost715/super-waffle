#include "ui_defines.hpp"

class CfgPatches {
    class pmc_interactions {
        name = "PMC Interactions";
        author = "LifeSim PMC project";
        units[] = {};
        weapons[] = {};
        requiredVersion = 2.14;
        requiredAddons[] = {"A3_Ui_F", "cba_settings", "ace_common", "ace_medical_treatment", "ace_repair"};
        version = "0.2.0";
    };
};

class CfgFunctions {
    class PMCI {
        tag = "PMCI";
        class Init {
            file = "\pmc_interactions\Init";
            class settings {preInit = 1;};
        };
        class Hooks {
            file = "\pmc_interactions\Hooks";
            class table {};
            class hookOf {};
            class original {};
            class plays {};
            class treatmentTime {};
            class timeNormal {};
            class timeTrained {};
            class treatmentSuccess {};
            class repairTime {};
            class repairSuccess {};
            class check {postInit = 1;};
        };
        class Games {
            file = "\pmc_interactions\Games";
            class cprModel {};
            class tourniquetModel {};
            class bandageModel {};
            class wheelModel {};
        };
        class Board {
            file = "\pmc_interactions\Board";
            class boardOpen {};
            class boardEvent {};
            class boardTick {};
            class boardLayout {};
            class boardLook {};
            class boardDraw {};
            class boardValid {};
            class finish {};
        };
    };
};

// Taken-over ACE actions: a short preparation bar, then the game (PMCI_fnc_plays), or
// ACE's own time and result. Inheritance is declared exactly as in ACE.
class ace_medical_treatment_actions {
    class BasicBandage;
    class FieldDressing: BasicBandage {
        treatmentTime = "PMCI_fnc_timeNormal";
        callbackSuccess = "PMCI_fnc_treatmentSuccess";
    };
    class PackingBandage: BasicBandage {
        treatmentTime = "PMCI_fnc_timeNormal";
        callbackSuccess = "PMCI_fnc_treatmentSuccess";
    };
    class ElasticBandage: BasicBandage {
        treatmentTime = "PMCI_fnc_timeNormal";
        callbackSuccess = "PMCI_fnc_treatmentSuccess";
    };
    class QuikClot: BasicBandage {
        treatmentTime = "PMCI_fnc_timeNormal";
        callbackSuccess = "PMCI_fnc_treatmentSuccess";
    };
    class ApplyTourniquet: BasicBandage {
        treatmentTime = "PMCI_fnc_timeNormal";
        treatmentTimeTrained = "PMCI_fnc_timeTrained";
        callbackSuccess = "PMCI_fnc_treatmentSuccess";
    };
    class CPR: BasicBandage {
        treatmentTime = "PMCI_fnc_timeNormal";
        callbackSuccess = "PMCI_fnc_treatmentSuccess";
    };
};
class ACE_Repair {
    class Actions {
        class ReplaceWheel {
            repairingTime = "PMCI_fnc_repairTime";
            callbackSuccess = "PMCI_fnc_repairSuccess";
        };
    };
};

#include "ui.hpp"
