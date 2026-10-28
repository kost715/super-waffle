// Zeus stock window: 0.5 x 0.66 of the safe zone, centred.
#define PMCA_BOX(px,py,pw,ph) x = safezoneX + safezoneW * (0.25 + (px)); y = safezoneY + safezoneH * (0.17 + (py)); w = safezoneW * (pw); h = safezoneH * (ph)

class RscText;
class RscStructuredText;
class RscButton;
class RscEdit;
class RscListNBox;

class PMCA_Text: RscText {
    sizeEx = safezoneH * 0.024;
};
class PMCA_Button: RscButton {
    sizeEx = safezoneH * 0.022;
    colorBackground[] = {0.3, 0.27, 0.16, 0.9};
    colorBackgroundActive[] = {0.42, 0.37, 0.2, 1};
    colorFocused[] = {0.42, 0.37, 0.2, 1};
};

class PMCA_RscStock {
    idd = PMCA_IDD_STOCK;
    movingEnable = 0;
    onLoad = "['onLoad', _this] call PMCA_fnc_stockUi";
    onUnload = "['onUnload'] call PMCA_fnc_stockUi";
    class controlsBackground {
        class Back: PMCA_Text {
            idc = -1;
            PMCA_BOX(0, 0, 0.5, 0.66);
            colorBackground[] = {0.07, 0.08, 0.09, 0.94};
        };
    };
    class controls {
        class Title: PMCA_Text {
            idc = PMCA_IDC_TITLE;
            PMCA_BOX(0, 0, 0.5, 0.045);
            colorBackground[] = {0.3, 0.27, 0.16, 1};
            sizeEx = safezoneH * 0.03;
            text = "";
        };
        class FilterAll: PMCA_Button {
            idc = -1;
            PMCA_BOX(0.01, 0.055, 0.092, 0.04);
            text = "$STR_PMCA_STOCK_ALL";
            onButtonClick = "['filter', 'all'] call PMCA_fnc_stockUi";
        };
        class FilterWeapons: FilterAll {
            idc = -1;
            PMCA_BOX(0.107, 0.055, 0.092, 0.04);
            text = "$STR_PMCA_STOCK_WEAPONS";
            onButtonClick = "['filter', 'weapons'] call PMCA_fnc_stockUi";
        };
        class FilterLaunchers: FilterAll {
            idc = -1;
            PMCA_BOX(0.204, 0.055, 0.092, 0.04);
            text = "$STR_PMCA_STOCK_LAUNCHERS";
            onButtonClick = "['filter', 'launchers'] call PMCA_fnc_stockUi";
        };
        class FilterExplosives: FilterAll {
            idc = -1;
            PMCA_BOX(0.301, 0.055, 0.092, 0.04);
            text = "$STR_PMCA_STOCK_EXPLOSIVES";
            onButtonClick = "['filter', 'explosives'] call PMCA_fnc_stockUi";
        };
        class FilterEquipment: FilterAll {
            idc = -1;
            PMCA_BOX(0.398, 0.055, 0.092, 0.04);
            text = "$STR_PMCA_STOCK_EQUIPMENT";
            onButtonClick = "['filter', 'equipment'] call PMCA_fnc_stockUi";
        };
        class SearchLabel: PMCA_Text {
            idc = -1;
            PMCA_BOX(0.01, 0.105, 0.08, 0.04);
            text = "$STR_PMCA_STOCK_SEARCH";
        };
        class Search: RscEdit {
            idc = PMCA_IDC_SEARCH;
            PMCA_BOX(0.095, 0.105, 0.395, 0.04);
            sizeEx = safezoneH * 0.024;
            text = "";
            onKeyUp = "['draw'] call PMCA_fnc_stockUi";
        };
        class List: RscListNBox {
            idc = PMCA_IDC_LIST;
            PMCA_BOX(0.01, 0.155, 0.48, 0.37);
            sizeEx = safezoneH * 0.022;
            rowHeight = safezoneH * 0.03;
            columns[] = {0, 0.6, 0.8};
            colorBackground[] = {0, 0, 0, 0.35};
        };
        class Info: RscStructuredText {
            idc = PMCA_IDC_INFO;
            PMCA_BOX(0.01, 0.53, 0.48, 0.04);
            size = safezoneH * 0.022;
            text = "";
        };
        class AmountLabel: PMCA_Text {
            idc = -1;
            PMCA_BOX(0.01, 0.575, 0.1, 0.04);
            text = "$STR_PMCA_STOCK_AMOUNT";
        };
        class Amount: RscEdit {
            idc = PMCA_IDC_AMOUNT;
            PMCA_BOX(0.115, 0.575, 0.1, 0.04);
            sizeEx = safezoneH * 0.024;
            text = "1";
        };
        class Remove: PMCA_Button {
            idc = -1;
            PMCA_BOX(0.225, 0.575, 0.085, 0.04);
            text = "$STR_PMCA_STOCK_REMOVE";
            onButtonClick = "['do', 'remove'] call PMCA_fnc_stockUi";
        };
        class Set: Remove {
            PMCA_BOX(0.315, 0.575, 0.085, 0.04);
            text = "$STR_PMCA_STOCK_SET";
            onButtonClick = "['do', 'set'] call PMCA_fnc_stockUi";
        };
        class Unlimited: Remove {
            PMCA_BOX(0.405, 0.575, 0.085, 0.04);
            text = "$STR_PMCA_STOCK_UNLIMITED";
            onButtonClick = "['do', 'unlimited'] call PMCA_fnc_stockUi";
        };
        class Clear: Remove {
            PMCA_BOX(0.01, 0.62, 0.15, 0.035);
            text = "$STR_PMCA_STOCK_CLEAR";
            onButtonClick = "['do', 'clear'] call PMCA_fnc_stockUi";
        };
        class Refresh: Remove {
            PMCA_BOX(0.165, 0.62, 0.12, 0.035);
            text = "$STR_PMCA_STOCK_REFRESH";
            onButtonClick = "['refresh'] call PMCA_fnc_stockUi";
        };
        class Close: Remove {
            PMCA_BOX(0.39, 0.62, 0.1, 0.035);
            text = "$STR_PMCA_STOCK_CLOSE";
            onButtonClick = "closeDialog 0";
        };
    };
};
