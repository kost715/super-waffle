#include "ui_defines.hpp"

class CfgPatches {
    class pmc_interactions {
        name = "PMC Interactions";
        author = "LifeSim PMC project";
        units[] = {};
        weapons[] = {};
        requiredVersion = 2.14;
        requiredAddons[] = {"A3_Ui_F", "cba_settings", "cba_events", "ace_common", "ace_medical_damage", "ace_medical_treatment", "ace_repair"};
        version = "0.5.0";
    };
};

class CfgFunctions {
    class PMCI {
        tag = "PMCI";
        class Init {
            file = "\pmc_interactions\Init";
            class settings {preInit = 1;};
            class events {postInit = 1;};
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
            class woundOf {};
            class woundGame {};
            class repairGame {};
            class partOf {};
            class stitch {};
            class stitchProgress {};
            class check {postInit = 1;};
        };
        class Games {
            file = "\pmc_interactions\Games";
            class cprModel {};
            class tourniquetModel {};
            class bandageModel {};
            class wheelModel {};
            class pressureModel {};
            class edgesModel {};
            class cleanModel {};
            class ivModel {};
            class sutureModel {};
            class splintModel {};
            class diagnoseModel {};
            class weldModel {};
            class trackModel {};
        };
        class Board {
            file = "\pmc_interactions\Board";
            class boardOpen {};
            class boardEvent {};
            class boardTick {};
            class boardLayout {};
            class boardLook {};
            class boardMarks {};
            class boardMouse {};
            class cprRibs {};
            class keysOf {};
            class keyIs {};
            class keyName {};
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
    class Splint: BasicBandage {
        treatmentTime = "PMCI_fnc_timeNormal";
        treatmentTimeTrained = "PMCI_fnc_timeTrained";
        callbackSuccess = "PMCI_fnc_treatmentSuccess";
    };
    // The 500 and 250 ml bags, plasma and saline inherit these from BloodIV.
    class BloodIV: BasicBandage {
        treatmentTime = "PMCI_fnc_timeNormal";
        treatmentTimeTrained = "PMCI_fnc_timeTrained";
        callbackSuccess = "PMCI_fnc_treatmentSuccess";
    };
    // ACE stitches during its bar: the progress callback holds that back while a game will follow.
    class SurgicalKit: FieldDressing {
        treatmentTime = "PMCI_fnc_timeNormal";
        callbackSuccess = "PMCI_fnc_treatmentSuccess";
        callbackProgress = "PMCI_fnc_stitchProgress";
    };
};
// A rib broken by too fast CPR compressions (PMCI_fnc_cprRibs): one bruise on the chest,
// no bleeding, a little more pain than an ordinary bruise.
class ACE_Medical_Injuries {
    class damageTypes {
        class pmci_ribs {
            thresholds[] = {{0, 1}};
            selectionSpecific = 1;
            noBlood = 1;
            class Contusion {
                weighting[] = {{0, 1}};
                painMultiplier = 1.5;
            };
        };
    };
};
class ACE_Repair {
    class Actions {
        class ReplaceWheel {
            repairingTime = "PMCI_fnc_repairTime";
            callbackSuccess = "PMCI_fnc_repairSuccess";
        };
        // RemoveTrack and FullRepair are ACE's own: PMCI_fnc_repairTime gives them ACE's time.
        class MiscRepair: ReplaceWheel {
            repairingTime = "PMCI_fnc_repairTime";
            callbackSuccess = "PMCI_fnc_repairSuccess";
        };
        class RepairTrack: MiscRepair {
            callbackSuccess = "PMCI_fnc_repairSuccess";
        };
        class RemoveTrack: MiscRepair {};
        class ReplaceTrack: RemoveTrack {
            callbackSuccess = "PMCI_fnc_repairSuccess";
        };
    };
};

#include "ui.hpp"
