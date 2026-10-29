class RscText;
class RscStructuredText;
class RscButton;
class RscProgress;
class RscPicture;
class RscControlsGroupNoScrollbars;

class PMCI_Text: RscText {
    sizeEx = safezoneH * 0.024;
};
class PMCI_Picture: RscPicture {
    idc = -1;
    x = 0;
    y = 0;
    w = 0.1;
    h = 0.1;
    text = "";
    colorText[] = {1, 1, 1, 1};
    colorBackground[] = {0, 0, 0, 0};
};
class PMCI_Button: RscButton {
    sizeEx = safezoneH * 0.022;
    colorBackground[] = {0.18, 0.3, 0.42, 0.95};
    colorBackgroundActive[] = {0.25, 0.42, 0.58, 1};
    colorFocused[] = {0.25, 0.42, 0.58, 1};
};
// Invisible click area over a nut picture; only a faint highlight under the mouse.
class PMCI_HitButton: RscButton {
    x = 0;
    y = 0;
    w = 0.1;
    h = 0.1;
    text = "";
    colorText[] = {0, 0, 0, 0};
    colorDisabled[] = {0, 0, 0, 0};
    colorBackground[] = {0, 0, 0, 0};
    colorBackgroundDisabled[] = {0, 0, 0, 0};
    colorBackgroundActive[] = {1, 1, 1, 0.12};
    colorFocused[] = {0, 0, 0, 0};
    colorShadow[] = {0, 0, 0, 0};
    colorBorder[] = {0, 0, 0, 0};
    offsetPressedX = 0;
    offsetPressedY = 0;
};

class PMCI_RscBoard {
    idd = PMCI_IDD_BOARD;
    movingEnable = 0;
    onLoad = "['onLoad', _this select 0] call PMCI_fnc_boardEvent";
    onUnload = "['onUnload'] call PMCI_fnc_boardEvent";
    onKeyDown = "['keyDown', _this] call PMCI_fnc_boardEvent";
    onKeyUp = "['keyUp', _this] call PMCI_fnc_boardEvent";
    onMouseButtonUp = "['scrubUp'] call PMCI_fnc_boardEvent";
    class controlsBackground {
        class Back: PMCI_Picture {
            PMCI_BOX(0, 0, 0.58, 0.8);
            text = "\pmc_interactions\data\ui_board_bg_ca.paa";
        };
        class TitleBar: PMCI_Text {
            idc = -1;
            PMCI_BOX(0, 0, 0.58, 0.045);
            colorBackground[] = {0.14, 0.26, 0.38, 0.95};
        };
        class SceneBack: PMCI_Text {
            idc = -1;
            PMCI_BOX(PMCI_SCENE_X, PMCI_SCENE_Y, PMCI_SCENE_W, PMCI_SCENE_H);
            colorBackground[] = {0, 0, 0, 0.35};
        };
    };
    class controls {
        class Icon: PMCI_Picture {
            idc = PMCI_IDC_ICON;
            PMCI_BOX(0.006, 0.0045, 0.02, 0.036);
        };
        class Title: PMCI_Text {
            idc = PMCI_IDC_TITLE;
            PMCI_BOX(0.03, 0, 0.54, 0.045);
            sizeEx = safezoneH * 0.03;
            text = "";
        };
        class Help: RscStructuredText {
            idc = PMCI_IDC_TEXT;
            PMCI_BOX(0.015, 0.05, 0.55, 0.07);
            size = safezoneH * 0.022;
            text = "";
        };
        // Layers bottom to top; PMCI_fnc_boardLayout places the fixed ones, PMCI_fnc_boardDraw
        // picks the pictures (PMCI_fnc_boardLook) and moves the others (PMCI_fnc_boardMarks).
        class Scene: RscControlsGroupNoScrollbars {
            idc = PMCI_IDC_SCENE;
            PMCI_BOX(PMCI_SCENE_X, PMCI_SCENE_Y, PMCI_SCENE_W, PMCI_SCENE_H);
            class controls {
                class ScenePicture: PMCI_Picture {idc = PMCI_IDC_SCENE_PIC;};
                class Wheel: PMCI_Picture {idc = PMCI_IDC_WHEEL;};
                class Gauze: PMCI_Picture {idc = PMCI_IDC_GAUZE;};
                class Seep: PMCI_Picture {idc = PMCI_IDC_SEEP;};
                class PressHand: PMCI_Picture {idc = PMCI_IDC_PRESS_HAND;};
                class Windlass: PMCI_Picture {idc = PMCI_IDC_WINDLASS;};
                class Stretch0: PMCI_Picture {idc = PMCI_IDC_SEG0;};
                class Stretch1: PMCI_Picture {idc = PMCI_IDC_SEG1;};
                class Stretch2: PMCI_Picture {idc = PMCI_IDC_SEG2;};
                class Stretch3: PMCI_Picture {idc = PMCI_IDC_SEG3;};
                class Stretch4: PMCI_Picture {idc = PMCI_IDC_SEG4;};
                class Stretch5: PMCI_Picture {idc = PMCI_IDC_SEG5;};
                class Stretch6: PMCI_Picture {idc = PMCI_IDC_SEG6;};
                class Stretch7: PMCI_Picture {idc = PMCI_IDC_SEG7;};
                class Runner: PMCI_Picture {idc = PMCI_IDC_RUNNER;};
                class Dirt0: PMCI_Picture {idc = PMCI_IDC_DIRT0;};
                class Dirt1: PMCI_Picture {idc = PMCI_IDC_DIRT1;};
                class Dirt2: PMCI_Picture {idc = PMCI_IDC_DIRT2;};
                class Dirt3: PMCI_Picture {idc = PMCI_IDC_DIRT3;};
                class Dirt4: PMCI_Picture {idc = PMCI_IDC_DIRT4;};
                class Dirt5: PMCI_Picture {idc = PMCI_IDC_DIRT5;};
                class Dirt6: PMCI_Picture {idc = PMCI_IDC_DIRT6;};
                class Dirt7: PMCI_Picture {idc = PMCI_IDC_DIRT7;};
                class Pad: PMCI_Picture {idc = PMCI_IDC_PAD;};
                class Swab: PMCI_Picture {idc = PMCI_IDC_SWAB;};
                class Hands: PMCI_Picture {idc = PMCI_IDC_HANDS;};
                class Beat: PMCI_Picture {idc = PMCI_IDC_BEAT;};
                class NutPicture0: PMCI_Picture {idc = PMCI_IDC_NUTPIC0;};
                class NutPicture1: PMCI_Picture {idc = PMCI_IDC_NUTPIC1;};
                class NutPicture2: PMCI_Picture {idc = PMCI_IDC_NUTPIC2;};
                class NutPicture3: PMCI_Picture {idc = PMCI_IDC_NUTPIC3;};
                class NutPicture4: PMCI_Picture {idc = PMCI_IDC_NUTPIC4;};
                class Nut0: PMCI_HitButton {
                    idc = PMCI_IDC_NUT0;
                    onButtonClick = "['nut', 0] call PMCI_fnc_boardEvent";
                };
                class Nut1: Nut0 {
                    idc = PMCI_IDC_NUT1;
                    onButtonClick = "['nut', 1] call PMCI_fnc_boardEvent";
                };
                class Nut2: Nut0 {
                    idc = PMCI_IDC_NUT2;
                    onButtonClick = "['nut', 2] call PMCI_fnc_boardEvent";
                };
                class Nut3: Nut0 {
                    idc = PMCI_IDC_NUT3;
                    onButtonClick = "['nut', 3] call PMCI_fnc_boardEvent";
                };
                class Nut4: Nut0 {
                    idc = PMCI_IDC_NUT4;
                    onButtonClick = "['nut', 4] call PMCI_fnc_boardEvent";
                };
                class Swap: PMCI_Button {
                    idc = PMCI_IDC_SWAP;
                    x = 0;
                    y = 0;
                    w = 0.1;
                    h = 0.05;
                    text = "$STR_PMCI_WHEEL_SWAP_BUTTON";
                    onButtonClick = "['swap'] call PMCI_fnc_boardEvent";
                };
                // Covers the whole scene while an abrasion is cleaned: held mouse = scrubbing.
                class Scrub: PMCI_HitButton {
                    idc = PMCI_IDC_SCRUB;
                    colorBackgroundActive[] = {0, 0, 0, 0};
                    onMouseButtonDown = "['scrubDown'] call PMCI_fnc_boardEvent";
                    onMouseButtonUp = "['scrubUp'] call PMCI_fnc_boardEvent";
                };
            };
        };
        class Status: RscStructuredText {
            idc = PMCI_IDC_STATUS;
            PMCI_BOX(0.015, 0.595, 0.55, 0.04);
            size = safezoneH * 0.024;
            text = "";
        };
        // Gauge: dark trough, green zone, fill, frame, marker. The grey pictures are tinted
        // with ctrlSetTextColor; band, fill and marker are moved by PMCI_fnc_boardDraw.
        class Gauge: PMCI_Text {
            idc = PMCI_IDC_GAUGE;
            PMCI_BOX(0.04, 0.64, PMCI_GAUGE_W, PMCI_GAUGE_H);
            colorBackground[] = {0.05, 0.06, 0.07, 0.9};
        };
        class Band: PMCI_Picture {
            idc = PMCI_IDC_BAND;
            PMCI_BOX(0.04, 0.64, 0.1, PMCI_GAUGE_H);
            text = "\pmc_interactions\data\ui_gauge_band_ca.paa";
            colorText[] = {0.35, 0.85, 0.4, 0.8};
        };
        class Fill: PMCI_Picture {
            idc = PMCI_IDC_FILL;
            PMCI_BOX(0.04, 0.6525, 0.1, 0.025);
            text = "\pmc_interactions\data\ui_gauge_fill_ca.paa";
            colorText[] = {0.9, 0.35, 0.28, 0.95};
        };
        class Frame: PMCI_Picture {
            idc = PMCI_IDC_FRAME;
            PMCI_BOX(0.04, 0.64, PMCI_GAUGE_W, PMCI_GAUGE_H);
            text = "\pmc_interactions\data\ui_gauge_frame_ca.paa";
            colorText[] = {0.8, 0.84, 0.88, 1};
        };
        class Marker: PMCI_Picture {
            idc = PMCI_IDC_MARKER;
            PMCI_BOX(0.2, 0.64, 0.012, PMCI_GAUGE_H);
            text = "\pmc_interactions\data\ui_gauge_marker_ca.paa";
        };
        class Time: RscProgress {
            idc = PMCI_IDC_TIME;
            PMCI_BOX(0.04, 0.70, PMCI_GAUGE_W, 0.02);
            colorBar[] = {0.3, 0.55, 0.8, 1};
            colorFrame[] = {0.4, 0.4, 0.4, 1};
        };
        class Hold: PMCI_Button {
            idc = PMCI_IDC_HOLD;
            PMCI_BOX(0.015, 0.74, 0.2, 0.045);
            text = "$STR_PMCI_HOLD";
            onMouseButtonDown = "['holdDown'] call PMCI_fnc_boardEvent";
            onMouseButtonUp = "['holdUp'] call PMCI_fnc_boardEvent";
        };
        class Fix: PMCI_Button {
            idc = PMCI_IDC_FIX;
            PMCI_BOX(0.225, 0.74, 0.17, 0.045);
            text = "$STR_PMCI_FIX";
            onButtonClick = "['fix'] call PMCI_fnc_boardEvent";
        };
        class Cancel: PMCI_Button {
            idc = PMCI_IDC_CANCEL;
            PMCI_BOX(0.405, 0.74, 0.16, 0.045);
            text = "$STR_PMCI_CANCEL";
            onButtonClick = "['cancel'] call PMCI_fnc_boardEvent";
        };
    };
};
