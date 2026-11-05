// The laptop: one dialog, everything inside is created by PMCS_fnc_ui (desktop, browser,
// shop, market management). These are the base classes it creates controls from; sizes
// and colours are set when they are created.
class RscText;
class RscStructuredText;
class RscPicture;
class RscButton;
class RscEdit;
class RscCombo;
class RscCheckBox;
class RscListNBox;
class RscControlsGroupNoHScrollbars;

class PMCS_Text: RscText {
    font = "RobotoCondensed";
    sizeEx = 0.03;
    shadow = 0;
    colorText[] = {0.114, 0.129, 0.145, 1};
    colorBackground[] = {0, 0, 0, 0};
};
class PMCS_TextBold: PMCS_Text {
    font = "RobotoCondensedBold";
};
class PMCS_TextRight: PMCS_Text {
    style = 1;
};
class PMCS_TextBoldRight: PMCS_TextBold {
    style = 1;
};
class PMCS_TextCenter: PMCS_Text {
    style = 2;
};
class PMCS_Struct: RscStructuredText {
    size = 0.03;
    shadow = 0;
    colorBackground[] = {0, 0, 0, 0};
    class Attributes {
        font = "RobotoCondensed";
        color = "#1d2125";
        align = "left";
        shadow = 0;
    };
};
class PMCS_Picture: RscPicture {
    style = 2096; // picture, keep aspect ratio
    colorText[] = {1, 1, 1, 1};
    colorBackground[] = {0, 0, 0, 0};
};
class PMCS_Button: RscButton {
    font = "RobotoCondensed";
    sizeEx = 0.03;
    shadow = 0;
    borderSize = 0;
    offsetX = 0;
    offsetY = 0;
    offsetPressedX = 0;
    offsetPressedY = 0;
    colorText[] = {1, 1, 1, 1};
    colorDisabled[] = {0.55, 0.58, 0.6, 1};
    colorBackground[] = {0.122, 0.165, 0.2, 1};
    colorBackgroundDisabled[] = {0.86, 0.87, 0.85, 1};
    colorBackgroundActive[] = {0.2, 0.26, 0.31, 1};
    colorFocused[] = {0.122, 0.165, 0.2, 1};
    colorShadow[] = {0, 0, 0, 0};
    colorBorder[] = {0, 0, 0, 0};
};
// The hover colour of a button comes from its class only: light and accent buttons have
// their own (PMCS_fnc_uiMake picks the class by the background).
class PMCS_ButtonLight: PMCS_Button {
    colorText[] = {0.114, 0.129, 0.145, 1};
    colorBackground[] = {0.949, 0.953, 0.937, 1};
    colorBackgroundActive[] = {0.851, 0.863, 0.839, 1};
    colorFocused[] = {0.949, 0.953, 0.937, 1};
};
class PMCS_ButtonAccent: PMCS_Button {
    colorBackground[] = {0.851, 0.51, 0.169, 1};
    colorBackgroundActive[] = {0.78, 0.43, 0.13, 1};
    colorFocused[] = {0.851, 0.51, 0.169, 1};
};
// Invisible: lies over a card or an icon and takes the click.
class PMCS_ButtonClear: PMCS_Button {
    colorBackground[] = {0, 0, 0, 0};
    colorBackgroundActive[] = {1, 1, 1, 0.08};
    colorFocused[] = {0, 0, 0, 0};
    colorBackgroundDisabled[] = {0, 0, 0, 0};
};
class PMCS_Edit: RscEdit {
    font = "RobotoCondensed";
    sizeEx = 0.03;
    shadow = 0;
    colorText[] = {0.114, 0.129, 0.145, 1};
    colorBackground[] = {1, 1, 1, 1};
    colorSelection[] = {0.851, 0.51, 0.169, 0.6};
    colorDisabled[] = {0.4, 0.4, 0.4, 1};
};
class PMCS_Combo: RscCombo {
    font = "RobotoCondensed";
    sizeEx = 0.03;
    shadow = 0;
    colorText[] = {0.114, 0.129, 0.145, 1};
    colorBackground[] = {1, 1, 1, 1};
    colorSelect[] = {1, 1, 1, 1};
    colorSelectBackground[] = {0.122, 0.165, 0.2, 1};
};
class PMCS_Check: RscCheckBox {};
class PMCS_List: RscListNBox {
    font = "RobotoCondensed";
    sizeEx = 0.03;
    shadow = 0;
    colorText[] = {0.114, 0.129, 0.145, 1};
    colorBackground[] = {1, 1, 1, 1};
    colorSelect[] = {1, 1, 1, 1};
    colorSelectBackground[] = {0.122, 0.165, 0.2, 1};
    colorSelectBackground2[] = {0.122, 0.165, 0.2, 1};
    columns[] = {0};
};
class PMCS_Group: RscControlsGroupNoHScrollbars {};

class PMCS_RscLaptop {
    idd = 88700;
    movingEnable = 0;
    onLoad = "['onLoad', _this] call PMCS_fnc_ui";
    onUnload = "['onUnload', []] call PMCS_fnc_ui";
    class controlsBackground {};
    class controls {};
};
