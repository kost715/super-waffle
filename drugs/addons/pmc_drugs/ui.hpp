#include "ui_defines.hpp"
class RscText;
class RscButton;
class RscEdit;

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
