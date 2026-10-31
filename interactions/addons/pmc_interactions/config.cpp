#include "ui_defines.hpp"

class CfgPatches {
    class pmc_interactions {
        name = "PMC Interactions";
        author = "LifeSim PMC project";
        units[] = {"PMCI_ModuleLock"};
        weapons[] = {};
        requiredVersion = 2.14;
        requiredAddons[] = {"A3_Ui_F", "A3_Modules_F", "A3_Modules_F_Curator", "cba_settings", "cba_events", "ace_common", "ace_interact_menu",
            "ace_medical_damage", "ace_medical_treatment", "ace_repair"};
        version = "0.7.0";
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
            class stitchCount {};
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
            class weldSeams {};
            class trackModel {};
            class lockpickModel {};
            class terminalModel {};
            class safeModel {};
        };
        class Lock {
            file = "\pmc_interactions\Lock";
            class moduleLock {};
            class lockSetup {};
            class lockSet {};
            class lockClear {};
            class lockApply {};
            class lockActions {};
            class lockOpen {};
            class lockHack {};
            class lockKeypad {};
            class lockNotify {};
            class lockKeys {};
            class lockTool {};
            class lockPins {};
            class codeValid {};
            class itemCount {};
            class itemName {};
            class itemTake {};
            class terminalDump {};
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
// ACE's own time and result. Inheritance is declared exactly as in ACE. Both times are
// set: ACE takes "treatmentTimeTrained" for a medic whenever the class has one (another
// mod may add it), and its own time would come before the game.
class ace_medical_treatment_actions {
    class BasicBandage;
    class FieldDressing: BasicBandage {
        treatmentTime = "PMCI_fnc_timeNormal";
        treatmentTimeTrained = "PMCI_fnc_timeTrained";
        callbackSuccess = "PMCI_fnc_treatmentSuccess";
    };
    class PackingBandage: BasicBandage {
        treatmentTime = "PMCI_fnc_timeNormal";
        treatmentTimeTrained = "PMCI_fnc_timeTrained";
        callbackSuccess = "PMCI_fnc_treatmentSuccess";
    };
    class ElasticBandage: BasicBandage {
        treatmentTime = "PMCI_fnc_timeNormal";
        treatmentTimeTrained = "PMCI_fnc_timeTrained";
        callbackSuccess = "PMCI_fnc_treatmentSuccess";
    };
    class QuikClot: BasicBandage {
        treatmentTime = "PMCI_fnc_timeNormal";
        treatmentTimeTrained = "PMCI_fnc_timeTrained";
        callbackSuccess = "PMCI_fnc_treatmentSuccess";
    };
    class ApplyTourniquet: BasicBandage {
        treatmentTime = "PMCI_fnc_timeNormal";
        treatmentTimeTrained = "PMCI_fnc_timeTrained";
        callbackSuccess = "PMCI_fnc_treatmentSuccess";
    };
    class CPR: BasicBandage {
        treatmentTime = "PMCI_fnc_timeNormal";
        treatmentTimeTrained = "PMCI_fnc_timeTrained";
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
        treatmentTimeTrained = "PMCI_fnc_timeTrained";
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
        class RemoveWheel: ReplaceWheel {
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

// Effective when the mission whitelists remote execution (CfgRemoteExec mode 1).
class CfgRemoteExec {
    class Functions {
        class PMCI_fnc_lockSet {allowedTargets = 2; jip = 0;};
        class PMCI_fnc_lockOpen {allowedTargets = 2; jip = 0;};
        class PMCI_fnc_lockApply {allowedTargets = 0; jip = 1;};
        class PMCI_fnc_lockNotify {allowedTargets = 1; jip = 0;};
    };
};
class CfgFactionClasses {
    class PMCI_Modules {
        displayName = "PMC Interactions";
        priority = 2;
        side = 7;
    };
};
class CfgVehicles {
    class Logic;
    class Module_F: Logic {};
    // Zeus: place on a box to lock it (PMCI_fnc_moduleLock), or to change or remove its lock.
    class PMCI_ModuleLock: Module_F {
        scope = 1;
        scopeCurator = 2;
        displayName = "$STR_PMCI_MODULE_LOCK";
        category = "PMCI_Modules";
        icon = "\pmc_interactions\data\icon_lock_ca.paa";
        portrait = "\pmc_interactions\data\icon_lock_ca.paa";
        function = "PMCI_fnc_moduleLock";
        functionPriority = 1;
        isGlobal = 1;
        isTriggerActivated = 0;
        curatorCanAttach = 1;
    };
};

#include "ui.hpp"
