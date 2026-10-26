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
        };
    };
};
class CfgRemoteExec {
    class Functions {
        class PMCS_fnc_request {allowedTargets = 2; jip = 0;};
        class PMCS_fnc_receiveState {allowedTargets = 0; jip = 0;};
    };
};
#include "ui.hpp"
