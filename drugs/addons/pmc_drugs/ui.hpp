#include "ui_defines.hpp"
class RscText;
class RscButton;
class RscEdit;
class RscPicture;
class RscStructuredText;

class PMCD_Text: RscText {
    sizeEx = safezoneH * 0.024;
};
class PMCD_Button: RscButton {
    sizeEx = safezoneH * 0.022;
    colorBackground[] = {0.18, 0.3, 0.42, 0.95};
    colorBackgroundActive[] = {0.25, 0.42, 0.58, 1};
    colorFocused[] = {0.25, 0.42, 0.58, 1};
};
// Zeus module "Muscle damage" (PMCD_fnc_muscleUi).
class PMCD_RscMuscle {
    idd = PMCD_IDD_MUSCLE;
    movingEnable = 0;
    onLoad = "['onLoad', _this select 0] call PMCD_fnc_muscleUi";
    onUnload = "['onUnload'] call PMCD_fnc_muscleUi";
    class controlsBackground {
        class Back: PMCD_Text {
            idc = -1;
            PMCD_BOX(0, 0, 0.24, 0.24);
            colorBackground[] = {0.07, 0.08, 0.09, 0.94};
        };
    };
    class controls {
        class Title: PMCD_Text {
            idc = PMCD_IDC_TITLE;
            PMCD_BOX(0, 0, 0.24, 0.04);
            colorBackground[] = {0.14, 0.26, 0.38, 0.95};
            text = "";
        };
        class Value: PMCD_Text {
            idc = PMCD_IDC_VALUE;
            PMCD_BOX(0.01, 0.05, 0.22, 0.04);
            text = "";
        };
        class SetLabel: PMCD_Text {
            idc = -1;
            PMCD_BOX(0.01, 0.1, 0.12, 0.04);
            text = "$STR_PMCD_MUSCLE_NEW";
        };
        class Edit: RscEdit {
            idc = PMCD_IDC_EDIT;
            PMCD_BOX(0.13, 0.1, 0.1, 0.04);
            sizeEx = safezoneH * 0.024;
            colorBackground[] = {0, 0, 0, 0.6};
            text = "";
        };
        class Check: PMCD_Button {
            idc = -1;
            PMCD_BOX(0.01, 0.16, 0.07, 0.045);
            text = "$STR_PMCD_MUSCLE_CHECK";
            onButtonClick = "['check'] call PMCD_fnc_muscleUi";
        };
        class Set: Check {
            PMCD_BOX(0.085, 0.16, 0.07, 0.045);
            text = "$STR_PMCD_MUSCLE_SET";
            onButtonClick = "['set'] call PMCD_fnc_muscleUi";
        };
        class Close: Check {
            idc = 2;
            PMCD_BOX(0.16, 0.16, 0.07, 0.045);
            text = "$STR_PMCD_CLOSE";
            onButtonClick = "closeDialog 2";
        };
    };
};

// Drug icons, placed by PMCD_fnc_hud from the player's CBA settings: a light plate under
// each so a black icon still shows.
class RscTitles {
    class PMCD_RscHud {
        idd = -1;
        duration = 1e9;
        fadeIn = 0;
        fadeOut = 0;
        movingEnable = 0;
        onLoad = "uiNamespace setVariable ['PMCD_hudDisplay', _this select 0]";
        onUnload = "uiNamespace setVariable ['PMCD_hudDisplay', displayNull]";
        class controls {
            class MusclePlate: RscPicture {
                idc = PMCD_IDC_MUSCLE_PLATE;
                x = 0; y = 0; w = 0.05; h = 0.05;
                text = "\pmc_drugs\data\hud_plate_ca.paa";
                colorText[] = {1, 1, 1, 0.45};
            };
            class Muscle: MusclePlate {
                idc = PMCD_IDC_MUSCLE;
                text = "\pmc_drugs\data\hud_muscle_ca.paa";
                colorText[] = {1, 1, 1, 1};
            };
            class TiredPlate: MusclePlate {
                idc = PMCD_IDC_TIRED_PLATE;
            };
            class Tired: MusclePlate {
                idc = PMCD_IDC_TIRED;
                text = "\pmc_drugs\data\hud_tired_ca.paa";
                colorText[] = {1, 1, 1, 1};
            };
        };
    };
    // Debug panel (PMCD_fnc_debug): everything, top left, over a dark background.
    class PMCD_RscDebug {
        idd = -1;
        duration = 1e9;
        fadeIn = 0;
        fadeOut = 0;
        movingEnable = 0;
        onLoad = "uiNamespace setVariable ['PMCD_debugDisplay', _this select 0]";
        onUnload = "uiNamespace setVariable ['PMCD_debugDisplay', displayNull]";
        class controls {
            class Text: RscStructuredText {
                idc = PMCD_IDC_DEBUG;
                x = safezoneX + safezoneW * 0.005;
                y = safezoneY + safezoneH * 0.05;
                w = safezoneW * 0.5;
                h = safezoneH * 0.9;
                size = safezoneH * 0.022;
                colorBackground[] = {0, 0, 0, 0.55};
                text = "";
            };
        };
    };
};
