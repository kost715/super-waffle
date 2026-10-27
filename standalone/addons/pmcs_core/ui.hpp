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

// S2 state-machine stand console (own group state; settings and posts for host/admin).
class PMCS_S2Console {
    idd = 84300;
    movingEnable = 0;
    enableSimulation = 1;
    onLoad = "uiNamespace setVariable ['PMCS2_console',_this select 0]; call PMCS_fnc_s2Render";
    onUnload = "uiNamespace setVariable ['PMCS2_console',displayNull]";
    class ControlsBackground {
        class Panel: RscText {
            idc = -1; text = "";
            x = safeZoneX + safeZoneW * 0.15; y = safeZoneY + safeZoneH * 0.07; w = safeZoneW * 0.7; h = safeZoneH * 0.86;
            colorBackground[] = {0.04,0.08,0.10,0.98};
        };
    };
    class Controls {
        class S2Title: RscText {idc = 4000; text = "$STR_PMCS2_TITLE"; x = safeZoneX + safeZoneW * 0.17; y = safeZoneY + safeZoneH * 0.09; w = safeZoneW * 0.66; h = safeZoneH * 0.04; sizeEx = 0.035;};
        class S2Summary: RscStructuredText {idc = 4001; text = ""; x = safeZoneX + safeZoneW * 0.17; y = safeZoneY + safeZoneH * 0.14; w = safeZoneW * 0.66; h = safeZoneH * 0.17; size = 0.026;};
        class S2RowContract: RscText {idc = -1; text = "$STR_PMCS2_ROW_CONTRACT"; x = safeZoneX + safeZoneW * 0.17; y = safeZoneY + safeZoneH * 0.32; w = safeZoneW * 0.66; h = safeZoneH * 0.03; sizeEx = 0.026;};
        class S2Contract0: RscButton {idc = 4100; text = "$STR_PMCS2_C_NONE"; x = safeZoneX + safeZoneW * 0.17; y = safeZoneY + safeZoneH * 0.355; w = safeZoneW * 0.16; h = safeZoneH * 0.04; sizeEx = 0.025; action = "['contract','none'] call PMCS_fnc_s2Ui";};
        class S2Contract1: RscButton {idc = 4101; text = "$STR_PMCS2_C_WEST"; x = safeZoneX + safeZoneW * 0.335; y = safeZoneY + safeZoneH * 0.355; w = safeZoneW * 0.16; h = safeZoneH * 0.04; sizeEx = 0.025; action = "['contract','west'] call PMCS_fnc_s2Ui";};
        class S2Contract2: RscButton {idc = 4102; text = "$STR_PMCS2_C_EAST"; x = safeZoneX + safeZoneW * 0.5; y = safeZoneY + safeZoneH * 0.355; w = safeZoneW * 0.16; h = safeZoneH * 0.04; sizeEx = 0.025; action = "['contract','east'] call PMCS_fnc_s2Ui";};
        class S2Contract3: RscButton {idc = 4103; text = "$STR_PMCS2_C_GUER"; x = safeZoneX + safeZoneW * 0.665; y = safeZoneY + safeZoneH * 0.355; w = safeZoneW * 0.16; h = safeZoneH * 0.04; sizeEx = 0.025; action = "['contract','guer'] call PMCS_fnc_s2Ui";};
        class S2RowManual: RscText {idc = -1; text = "$STR_PMCS2_ROW_MANUAL"; x = safeZoneX + safeZoneW * 0.17; y = safeZoneY + safeZoneH * 0.405; w = safeZoneW * 0.66; h = safeZoneH * 0.03; sizeEx = 0.026;};
        class S2Manual0: RscButton {idc = 4110; text = "$STR_PMCS2_M_AUTO"; x = safeZoneX + safeZoneW * 0.17; y = safeZoneY + safeZoneH * 0.44; w = safeZoneW * 0.127; h = safeZoneH * 0.04; sizeEx = 0.025; action = "['manual',''] call PMCS_fnc_s2Ui";};
        class S2Manual1: RscButton {idc = 4111; text = "$STR_PMCS2_SIDE_WEST"; x = safeZoneX + safeZoneW * 0.302; y = safeZoneY + safeZoneH * 0.44; w = safeZoneW * 0.127; h = safeZoneH * 0.04; sizeEx = 0.025; action = "['manual','west'] call PMCS_fnc_s2Ui";};
        class S2Manual2: RscButton {idc = 4112; text = "$STR_PMCS2_SIDE_EAST"; x = safeZoneX + safeZoneW * 0.434; y = safeZoneY + safeZoneH * 0.44; w = safeZoneW * 0.127; h = safeZoneH * 0.04; sizeEx = 0.025; action = "['manual','east'] call PMCS_fnc_s2Ui";};
        class S2Manual3: RscButton {idc = 4113; text = "$STR_PMCS2_SIDE_GUER"; x = safeZoneX + safeZoneW * 0.566; y = safeZoneY + safeZoneH * 0.44; w = safeZoneW * 0.127; h = safeZoneH * 0.04; sizeEx = 0.025; action = "['manual','guer'] call PMCS_fnc_s2Ui";};
        class S2Manual4: RscButton {idc = 4114; text = "$STR_PMCS2_SIDE_CIV"; x = safeZoneX + safeZoneW * 0.698; y = safeZoneY + safeZoneH * 0.44; w = safeZoneW * 0.127; h = safeZoneH * 0.04; sizeEx = 0.025; action = "['manual','civ'] call PMCS_fnc_s2Ui";};
        class S2RowSettings: RscText {idc = -1; text = "$STR_PMCS2_ROW_SETTINGS"; x = safeZoneX + safeZoneW * 0.17; y = safeZoneY + safeZoneH * 0.49; w = safeZoneW * 0.66; h = safeZoneH * 0.03; sizeEx = 0.026;};
        class S2Setting0: RscButton {idc = 4120; text = "$STR_PMCS2_U_SIDE"; x = safeZoneX + safeZoneW * 0.17; y = safeZoneY + safeZoneH * 0.525; w = safeZoneW * 0.127; h = safeZoneH * 0.04; sizeEx = 0.025; action = "['undercover','side'] call PMCS_fnc_s2Ui";};
        class S2Setting1: RscButton {idc = 4121; text = "$STR_PMCS2_U_CAPTIVE"; x = safeZoneX + safeZoneW * 0.302; y = safeZoneY + safeZoneH * 0.525; w = safeZoneW * 0.127; h = safeZoneH * 0.04; sizeEx = 0.025; action = "['undercover','captive'] call PMCS_fnc_s2Ui";};
        class S2Setting2: RscButton {idc = 4122; text = "$STR_PMCS2_AURA_30"; x = safeZoneX + safeZoneW * 0.434; y = safeZoneY + safeZoneH * 0.525; w = safeZoneW * 0.127; h = safeZoneH * 0.04; sizeEx = 0.025; action = "['aura',30] call PMCS_fnc_s2Ui";};
        class S2Setting3: RscButton {idc = 4123; text = "$STR_PMCS2_AURA_300"; x = safeZoneX + safeZoneW * 0.566; y = safeZoneY + safeZoneH * 0.525; w = safeZoneW * 0.127; h = safeZoneH * 0.04; sizeEx = 0.025; action = "['aura',300] call PMCS_fnc_s2Ui";};
        class S2Setting4: RscButton {idc = 4124; text = "$STR_PMCS2_FORGET"; x = safeZoneX + safeZoneW * 0.698; y = safeZoneY + safeZoneH * 0.525; w = safeZoneW * 0.127; h = safeZoneH * 0.04; sizeEx = 0.025; action = "['forget', !((uiNamespace getVariable ['PMCS2_state', createHashMap]) getOrDefault ['forget', true])] call PMCS_fnc_s2Ui";};
        class S2RowPosts: RscText {idc = -1; text = "$STR_PMCS2_ROW_POSTS"; x = safeZoneX + safeZoneW * 0.17; y = safeZoneY + safeZoneH * 0.575; w = safeZoneW * 0.66; h = safeZoneH * 0.03; sizeEx = 0.026;};
        class S2Post0: RscButton {idc = 4130; text = "$STR_PMCS2_P_WEST"; x = safeZoneX + safeZoneW * 0.170; y = safeZoneY + safeZoneH * 0.61; w = safeZoneW * 0.105; h = safeZoneH * 0.04; sizeEx = 0.025; action = "['post','west'] call PMCS_fnc_s2Ui";};
        class S2Post1: RscButton {idc = 4131; text = "$STR_PMCS2_P_EAST"; x = safeZoneX + safeZoneW * 0.280; y = safeZoneY + safeZoneH * 0.61; w = safeZoneW * 0.105; h = safeZoneH * 0.04; sizeEx = 0.025; action = "['post','east'] call PMCS_fnc_s2Ui";};
        class S2Post2: RscButton {idc = 4132; text = "$STR_PMCS2_P_GUER"; x = safeZoneX + safeZoneW * 0.390; y = safeZoneY + safeZoneH * 0.61; w = safeZoneW * 0.105; h = safeZoneH * 0.04; sizeEx = 0.025; action = "['post','guer'] call PMCS_fnc_s2Ui";};
        class S2Post3: RscButton {idc = 4133; text = "$STR_PMCS2_P_CIV"; x = safeZoneX + safeZoneW * 0.500; y = safeZoneY + safeZoneH * 0.61; w = safeZoneW * 0.105; h = safeZoneH * 0.04; sizeEx = 0.025; action = "['post','civ'] call PMCS_fnc_s2Ui";};
        class S2Post4: RscButton {idc = 4134; text = "$STR_PMCS2_P_CLEAR"; x = safeZoneX + safeZoneW * 0.610; y = safeZoneY + safeZoneH * 0.61; w = safeZoneW * 0.105; h = safeZoneH * 0.04; sizeEx = 0.025; action = "['post','clear'] call PMCS_fnc_s2Ui";};
        class S2Post5: RscButton {idc = 4135; text = "$STR_PMCS2_P_GANG"; x = safeZoneX + safeZoneW * 0.72; y = safeZoneY + safeZoneH * 0.61; w = safeZoneW * 0.105; h = safeZoneH * 0.04; sizeEx = 0.025; action = "['post','gang'] call PMCS_fnc_s2Ui";};
        class S2Events: RscListbox {idc = 4200; x = safeZoneX + safeZoneW * 0.17; y = safeZoneY + safeZoneH * 0.66; w = safeZoneW * 0.66; h = safeZoneH * 0.2; sizeEx = 0.024;};
        class S2Close: RscButton {idc = 4199; text = "$STR_PMCS_CLOSE"; x = safeZoneX + safeZoneW * 0.17; y = safeZoneY + safeZoneH * 0.875; w = safeZoneW * 0.66; h = safeZoneH * 0.04; sizeEx = 0.026; action = "closeDialog 0";};
    };
};
