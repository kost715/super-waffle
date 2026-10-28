// ATM window: one dialog, screens shown by PMCB_fnc_ui. Positions are fractions of
// the safe zone; the window is 0.46 x 0.6 of it, centred.
#define PMCB_X(v) safezoneX + safezoneW * (0.27 + (v))
#define PMCB_Y(v) safezoneY + safezoneH * (0.2 + (v))
#define PMCB_W(v) safezoneW * (v)
#define PMCB_H(v) safezoneH * (v)
#define PMCB_BOX(px,py,pw,ph) x = PMCB_X(px); y = PMCB_Y(py); w = PMCB_W(pw); h = PMCB_H(ph)

class RscText;
class RscStructuredText;
class RscButton;
class RscEdit;
class RscListNBox;

class PMCB_Text: RscText {
    sizeEx = safezoneH * 0.024;
};
class PMCB_Button: RscButton {
    sizeEx = safezoneH * 0.024;
    colorBackground[] = {0.16, 0.36, 0.26, 0.9};
    colorBackgroundActive[] = {0.22, 0.48, 0.34, 1};
    colorFocused[] = {0.22, 0.48, 0.34, 1};
};

class PMCB_RscATM {
    idd = PMCB_IDD_ATM;
    movingEnable = 0;
    onLoad = "['onLoad', _this] call PMCB_fnc_ui";
    onUnload = "['onUnload'] call PMCB_fnc_ui";
    class controlsBackground {
        class Back: PMCB_Text {
            idc = -1;
            PMCB_BOX(0, 0, 0.46, 0.6);
            colorBackground[] = {0.07, 0.09, 0.11, 0.94};
        };
    };
    class controls {
        class Title: PMCB_Text {
            idc = PMCB_IDC_TITLE;
            PMCB_BOX(0, 0, 0.46, 0.045);
            colorBackground[] = {0.13, 0.32, 0.22, 1};
            sizeEx = safezoneH * 0.03;
            text = "";
        };
        class Info: RscStructuredText {
            idc = PMCB_IDC_INFO;
            PMCB_BOX(0.015, 0.055, 0.43, 0.1);
            size = safezoneH * 0.025;
            text = "";
        };
        class Menu0: PMCB_Button {
            idc = PMCB_IDC_MENU0;
            PMCB_BOX(0.015, 0.17, 0.43, 0.05);
            onButtonClick = "['menu', 0] call PMCB_fnc_ui";
        };
        class Menu1: Menu0 {
            idc = PMCB_IDC_MENU1;
            PMCB_BOX(0.015, 0.23, 0.43, 0.05);
            onButtonClick = "['menu', 1] call PMCB_fnc_ui";
        };
        class Menu2: Menu0 {
            idc = PMCB_IDC_MENU2;
            PMCB_BOX(0.015, 0.29, 0.43, 0.05);
            onButtonClick = "['menu', 2] call PMCB_fnc_ui";
        };
        class Label: PMCB_Text {
            idc = PMCB_IDC_LABEL;
            PMCB_BOX(0.015, 0.165, 0.12, 0.04);
            text = "$STR_PMCB_UI_AMOUNT";
        };
        class Amount: RscEdit {
            idc = PMCB_IDC_EDIT;
            PMCB_BOX(0.14, 0.165, 0.17, 0.04);
            sizeEx = safezoneH * 0.024;
            text = "";
        };
        class Pick: PMCB_Button {
            idc = PMCB_IDC_PICK;
            PMCB_BOX(0.32, 0.165, 0.125, 0.04);
            text = "$STR_PMCB_UI_PICK";
            onButtonClick = "['pick'] call PMCB_fnc_ui";
        };
        class List: RscListNBox {
            idc = PMCB_IDC_LIST;
            PMCB_BOX(0.015, 0.215, 0.43, 0.27);
            sizeEx = safezoneH * 0.022;
            rowHeight = safezoneH * 0.03;
            columns[] = {0, 0.4, 0.7};
            colorBackground[] = {0, 0, 0, 0.35};
        };
        class Minus: PMCB_Button {
            idc = PMCB_IDC_MINUS;
            PMCB_BOX(0.015, 0.495, 0.06, 0.04);
            text = "-";
            onButtonClick = "['step', -1] call PMCB_fnc_ui";
        };
        class Plus: Minus {
            idc = PMCB_IDC_PLUS;
            PMCB_BOX(0.08, 0.495, 0.06, 0.04);
            text = "+";
            onButtonClick = "['step', 1] call PMCB_fnc_ui";
        };
        class All: PMCB_Button {
            idc = PMCB_IDC_ALL;
            PMCB_BOX(0.145, 0.495, 0.17, 0.04);
            text = "";
            onButtonClick = "['all'] call PMCB_fnc_ui";
        };
        class BackButton: PMCB_Button {
            idc = PMCB_IDC_BACK;
            PMCB_BOX(0.015, 0.545, 0.13, 0.045);
            text = "$STR_PMCB_UI_BACK";
            onButtonClick = "['back'] call PMCB_fnc_ui";
        };
        class Action: PMCB_Button {
            idc = PMCB_IDC_ACTION;
            PMCB_BOX(0.16, 0.545, 0.14, 0.045);
            text = "";
            onButtonClick = "['confirm'] call PMCB_fnc_ui";
        };
        class Close: PMCB_Button {
            idc = PMCB_IDC_CLOSE;
            PMCB_BOX(0.315, 0.545, 0.13, 0.045);
            text = "$STR_PMCB_UI_CLOSE";
            onButtonClick = "closeDialog 0";
        };
    };
};

// Zeus: amount to create on or remove from the group's account.
class PMCB_RscAmount {
    idd = PMCB_IDD_AMOUNT;
    movingEnable = 0;
    onLoad = "['amountLoad', _this] call PMCB_fnc_ui";
    class controlsBackground {
        class Back: PMCB_Text {
            idc = -1;
            x = safezoneX + safezoneW * 0.38; y = safezoneY + safezoneH * 0.4; w = safezoneW * 0.24; h = safezoneH * 0.17;
            colorBackground[] = {0.07, 0.09, 0.11, 0.94};
        };
    };
    class controls {
        class Title: PMCB_Text {
            idc = PMCB_IDC_AMOUNT_TITLE;
            x = safezoneX + safezoneW * 0.38; y = safezoneY + safezoneH * 0.4; w = safezoneW * 0.24; h = safezoneH * 0.04;
            colorBackground[] = {0.13, 0.32, 0.22, 1};
            text = "";
        };
        class Amount: RscEdit {
            idc = PMCB_IDC_AMOUNT_EDIT;
            x = safezoneX + safezoneW * 0.39; y = safezoneY + safezoneH * 0.455; w = safezoneW * 0.22; h = safezoneH * 0.045;
            sizeEx = safezoneH * 0.026;
            text = "";
        };
        class Ok: PMCB_Button {
            idc = -1;
            x = safezoneX + safezoneW * 0.39; y = safezoneY + safezoneH * 0.515; w = safezoneW * 0.105; h = safezoneH * 0.045;
            text = "$STR_PMCB_UI_OK";
            onButtonClick = "['amountOk'] call PMCB_fnc_ui";
        };
        class Cancel: Ok {
            x = safezoneX + safezoneW * 0.505;
            text = "$STR_PMCB_UI_CANCEL";
            onButtonClick = "closeDialog 2";
        };
    };
};
