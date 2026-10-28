// Board window: 0.44 x 0.56 of the safe zone, centred. Gauge controls are placed again at
// run time by PMCI_fnc_boardDraw.
#define PMCI_BOX(px,py,pw,ph) x = safezoneX + safezoneW * (0.28 + (px)); y = safezoneY + safezoneH * (0.22 + (py)); w = safezoneW * (pw); h = safezoneH * (ph)

class RscText;
class RscStructuredText;
class RscButton;
class RscProgress;

class PMCI_Text: RscText {
    sizeEx = safezoneH * 0.024;
};
class PMCI_Button: RscButton {
    sizeEx = safezoneH * 0.022;
    colorBackground[] = {0.18, 0.3, 0.42, 0.95};
    colorBackgroundActive[] = {0.25, 0.42, 0.58, 1};
    colorFocused[] = {0.25, 0.42, 0.58, 1};
};

class PMCI_RscBoard {
    idd = PMCI_IDD_BOARD;
    movingEnable = 0;
    onLoad = "['onLoad', _this select 0] call PMCI_fnc_boardEvent";
    onUnload = "['onUnload'] call PMCI_fnc_boardEvent";
    onKeyDown = "['keyDown', _this] call PMCI_fnc_boardEvent";
    onKeyUp = "['keyUp', _this] call PMCI_fnc_boardEvent";
    class controlsBackground {
        class Back: PMCI_Text {
            idc = -1;
            PMCI_BOX(0, 0, 0.44, 0.56);
            colorBackground[] = {0.06, 0.08, 0.1, 0.94};
        };
    };
    class controls {
        class Title: PMCI_Text {
            idc = PMCI_IDC_TITLE;
            PMCI_BOX(0, 0, 0.44, 0.045);
            colorBackground[] = {0.14, 0.26, 0.38, 1};
            sizeEx = safezoneH * 0.03;
            text = "";
        };
        class Help: RscStructuredText {
            idc = PMCI_IDC_TEXT;
            PMCI_BOX(0.015, 0.055, 0.41, 0.09);
            size = safezoneH * 0.022;
            text = "";
        };
        class Status: RscStructuredText {
            idc = PMCI_IDC_STATUS;
            PMCI_BOX(0.015, 0.15, 0.41, 0.045);
            size = safezoneH * 0.024;
            text = "";
        };
        class Gauge: PMCI_Text {
            idc = PMCI_IDC_GAUGE;
            PMCI_BOX(0.03, 0.21, 0.38, 0.06);
            colorBackground[] = {0.15, 0.15, 0.17, 1};
        };
        class Band: PMCI_Text {
            idc = PMCI_IDC_BAND;
            PMCI_BOX(0.03, 0.21, 0.1, 0.06);
            colorBackground[] = {0.2, 0.55, 0.25, 0.7};
        };
        class Fill: PMCI_Text {
            idc = PMCI_IDC_FILL;
            PMCI_BOX(0.03, 0.222, 0.1, 0.036);
            colorBackground[] = {0.85, 0.3, 0.25, 0.85};
        };
        class Marker: PMCI_Text {
            idc = PMCI_IDC_MARKER;
            PMCI_BOX(0.2, 0.21, 0.004, 0.06);
            colorBackground[] = {1, 1, 1, 1};
        };
        class Beat: PMCI_Text {
            idc = PMCI_IDC_BEAT;
            PMCI_BOX(0.19, 0.29, 0.06, 0.07);
            colorBackground[] = {0.2, 0.2, 0.2, 1};
        };
        class Hub: PMCI_Text {
            idc = PMCI_IDC_HUB;
            PMCI_BOX(0.19, 0.305, 0.06, 0.045);
            style = 2;
            colorBackground[] = {0.12, 0.12, 0.14, 1};
            text = "";
        };
        class Nut0: PMCI_Button {
            idc = PMCI_IDC_NUT0;
            PMCI_BOX(0.1975, 0.2, 0.045, 0.06);
            text = "1";
            onButtonClick = "['nut', 0] call PMCI_fnc_boardEvent";
        };
        class Nut1: Nut0 {
            idc = PMCI_IDC_NUT1;
            PMCI_BOX(0.2641, 0.2629, 0.045, 0.06);
            text = "2";
            onButtonClick = "['nut', 1] call PMCI_fnc_boardEvent";
        };
        class Nut2: Nut0 {
            idc = PMCI_IDC_NUT2;
            PMCI_BOX(0.2386, 0.3671, 0.045, 0.06);
            text = "3";
            onButtonClick = "['nut', 2] call PMCI_fnc_boardEvent";
        };
        class Nut3: Nut0 {
            idc = PMCI_IDC_NUT3;
            PMCI_BOX(0.1564, 0.3671, 0.045, 0.06);
            text = "4";
            onButtonClick = "['nut', 3] call PMCI_fnc_boardEvent";
        };
        class Nut4: Nut0 {
            idc = PMCI_IDC_NUT4;
            PMCI_BOX(0.1309, 0.2629, 0.045, 0.06);
            text = "5";
            onButtonClick = "['nut', 4] call PMCI_fnc_boardEvent";
        };
        class Swap: PMCI_Button {
            idc = PMCI_IDC_SWAP;
            PMCI_BOX(0.32, 0.3, 0.105, 0.05);
            text = "$STR_PMCI_WHEEL_SWAP_BUTTON";
            onButtonClick = "['swap'] call PMCI_fnc_boardEvent";
        };
        class Time: RscProgress {
            idc = PMCI_IDC_TIME;
            PMCI_BOX(0.03, 0.465, 0.38, 0.02);
            colorBar[] = {0.3, 0.55, 0.8, 1};
            colorFrame[] = {0.4, 0.4, 0.4, 1};
        };
        class Hold: PMCI_Button {
            idc = PMCI_IDC_HOLD;
            PMCI_BOX(0.015, 0.505, 0.15, 0.045);
            text = "$STR_PMCI_HOLD";
            onMouseButtonDown = "['holdDown'] call PMCI_fnc_boardEvent";
            onMouseButtonUp = "['holdUp'] call PMCI_fnc_boardEvent";
        };
        class Fix: PMCI_Button {
            idc = PMCI_IDC_FIX;
            PMCI_BOX(0.17, 0.505, 0.13, 0.045);
            text = "$STR_PMCI_FIX";
            onButtonClick = "['fix'] call PMCI_fnc_boardEvent";
        };
        class Cancel: PMCI_Button {
            idc = PMCI_IDC_CANCEL;
            PMCI_BOX(0.305, 0.505, 0.12, 0.045);
            text = "$STR_PMCI_CANCEL";
            onButtonClick = "['cancel'] call PMCI_fnc_boardEvent";
        };
    };
};
