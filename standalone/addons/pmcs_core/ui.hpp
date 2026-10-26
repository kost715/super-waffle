class RscText;
class RscStructuredText;
class RscButton;
class RscCombo;
class RscListbox;

class PMCS_Console {
    idd = 84200;
    movingEnable = 0;
    enableSimulation = 1;
    onLoad = "uiNamespace setVariable ['PMCS_console',_this select 0]; call PMCS_fnc_renderConsole";
    onUnload = "uiNamespace setVariable ['PMCS_console',displayNull]; uiNamespace setVariable ['PMCS_pending',[]]";
    class ControlsBackground {
        class Panel: RscText {
            idc = -1; text = "";
            x = safeZoneX + safeZoneW * 0.19; y = safeZoneY + safeZoneH * 0.10;
            w = safeZoneW * 0.62; h = safeZoneH * 0.81;
            colorBackground[] = {0.04,0.08,0.10,0.98};
        };
    };
    class Controls {
        class Title: RscText {
            idc = 1000; text = "$STR_PMCS_TITLE";
            x = safeZoneX + safeZoneW * 0.21; y = safeZoneY + safeZoneH * 0.12;
            w = safeZoneW * 0.58; h = safeZoneH * 0.04;
            sizeEx = 0.035;
        };
        class Summary: RscStructuredText {
            idc = 1100; text = "$STR_PMCS_LOADING";
            x = safeZoneX + safeZoneW * 0.21; y = safeZoneY + safeZoneH * 0.18;
            w = safeZoneW * 0.58; h = safeZoneH * 0.065;
            size = 0.028;
        };
        class Notice: Summary {idc = 1101; text = ""; y = safeZoneY + safeZoneH * 0.25; h = safeZoneH * 0.06;};
        class Relations: RscListbox {
            idc = 1500;
            x = safeZoneX + safeZoneW * 0.21; y = safeZoneY + safeZoneH * 0.32;
            w = safeZoneW * 0.58; h = safeZoneH * 0.12;
            sizeEx = 0.028;
        };
        class PairLabel: Title {idc = -1; text = "$STR_PMCS_PAIR_LABEL"; y = safeZoneY + safeZoneH * 0.46; sizeEx = 0.027;};
        class CompanyA: RscCombo {
            idc = 2100;
            x = safeZoneX + safeZoneW * 0.21; y = safeZoneY + safeZoneH * 0.50;
            w = safeZoneW * 0.28; h = safeZoneH * 0.04;
            sizeEx = 0.028;
        };
        class CompanyB: CompanyA {idc = 2101; x = safeZoneX + safeZoneW * 0.51;};
        class Neutral: RscButton {
            idc = 3100; text = "$STR_PMCS_SET_NEUTRAL";
            x = safeZoneX + safeZoneW * 0.21; y = safeZoneY + safeZoneH * 0.56;
            w = safeZoneW * 0.28; h = safeZoneH * 0.045;
            sizeEx = 0.027;
            action = "['relation','neutral'] call PMCS_fnc_uiAction";
        };
        class Hostile: Neutral {idc = 3101; text = "$STR_PMCS_SET_HOSTILE"; x = safeZoneX + safeZoneW * 0.51; action = "['relation','hostile'] call PMCS_fnc_uiAction";};
        class AllNeutral: Neutral {idc = 3102; text = "$STR_PMCS_ALL_NEUTRAL"; y = safeZoneY + safeZoneH * 0.62; action = "['preset','neutral'] call PMCS_fnc_uiAction";};
        class AlphaBravo: Hostile {idc = 3103; text = "$STR_PMCS_AB_HOSTILE"; y = safeZoneY + safeZoneH * 0.62; action = "['preset','ab'] call PMCS_fnc_uiAction";};
        class Reset: Neutral {idc = 3104; text = "$STR_PMCS_RESET"; y = safeZoneY + safeZoneH * 0.68; action = "['reset',''] call PMCS_fnc_uiAction";};
        class WorldToggle: Hostile {idc = 3106; text = "$STR_PMCS_WORLD_START"; y = safeZoneY + safeZoneH * 0.68; action = "['world',''] call PMCS_fnc_uiAction";};
        class ProbeStatus: Summary {idc = 1102; text = ""; y = safeZoneY + safeZoneH * 0.74; h = safeZoneH * 0.10; size = 0.024;};
        class Close: Neutral {idc = 3105; text = "$STR_PMCS_CLOSE"; y = safeZoneY + safeZoneH * 0.85; w = safeZoneW * 0.58; action = "closeDialog 0";};
    };
};
