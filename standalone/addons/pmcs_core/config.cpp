class CfgPatches {
    class pmcs_core {
        name = "PMC Standalone - S1 technical prototype";
        author = "PMC project";
        requiredVersion = 2.20;
        requiredAddons[] = {"A3_Characters_F", "A3_Structures_F", "A3_UI_F"};
        units[] = {};
        weapons[] = {};
    };
};
class CfgFunctions {
    class PMCS {
        tag = "PMCS";
        class Core {
            file = "\pmcs_core\functions";
            class allowed {};
            class applyRelations {};
            class clientInit {};
            class isAdmin {};
            class openConsole {};
            class pairKey {};
            class postInit {postInit = 1;};
            class receiveState {};
            class registerPlayer {};
            class relationSet {};
            class renderConsole {};
            class request {};
            class resetActors {};
            class sendState {};
            class serverInit {};
            class sidePlan {};
            class snapshot {};
            class uiAction {};
            class s2ServerInit {};
            class s2Log {};
            class s2Desired {};
            class s2Tick {};
            class s2Register {};
            class s2Apply {};
            class s2Captive {};
            class s2Event {};
            class s2Request {};
            class s2Send {};
            class s2Post {};
            class s2PostFired {};
            class s2PostDetected {};
            class s2ClientInit {};
            class s2Open {};
            class s2Ui {};
            class s2Receive {};
            class s2Render {};
            class s2Demask {};
            class s2Regroup {};
        };
    };
};
// Test missions ship inside this PBO: Multiplayer -> Host server -> Altis.
class CfgMissions {
    class MPMissions {
        class PMCS_S1_1PMC {briefingName = "PMC Standalone S1 - 1 PMC"; directory = "pmcs_core\missions\PMCS_S1_1PMC.Altis";};
        class PMCS_S1_2PMC {briefingName = "PMC Standalone S1 - 2 PMC"; directory = "pmcs_core\missions\PMCS_S1_2PMC.Altis";};
        class PMCS_S1_3PMC {briefingName = "PMC Standalone S1 - 3 PMC"; directory = "pmcs_core\missions\PMCS_S1_3PMC.Altis";};
        class PMCS_S2_STATE {briefingName = "PMC Standalone S2 - state machine"; directory = "pmcs_core\missions\PMCS_S2_State.Altis";};
    };
};
class CfgRemoteExec {
    class Functions {
        class PMCS_fnc_request {allowedTargets = 2; jip = 0;};
        class PMCS_fnc_receiveState {allowedTargets = 0; jip = 0;};
        class PMCS_fnc_s2Request {allowedTargets = 2; jip = 0;};
        class PMCS_fnc_s2Event {allowedTargets = 2; jip = 0;};
        class PMCS_fnc_s2Captive {allowedTargets = 0; jip = 0;};
        class PMCS_fnc_s2Receive {allowedTargets = 0; jip = 0;};
        class PMCS_fnc_s2Regroup {allowedTargets = 0; jip = 0;};
    };
};
#include "ui.hpp"
