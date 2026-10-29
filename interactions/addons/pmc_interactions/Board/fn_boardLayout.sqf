#include "..\ui_defines.hpp"
// [display] -> nothing. Client, once when the board opens: fits the 1024 x 512 scene into
// the scene area without stretching it, places the sprites on it in scene pixels, shows the
// game's icon and tints the gauge.
params ["_display"];
if (isNil "PMCI_board") exitWith {};
private _game = PMCI_board get "game";
private _group = _display displayCtrl PMCI_IDC_SCENE;
// Widest 2:1 rectangle (in screen pixels) that fits the area, centred in it.
private _areaW = safezoneW * PMCI_SCENE_W;
private _areaH = safezoneH * PMCI_SCENE_H;
private _w = _areaW;
private _h = _w / pixelW / 2 * pixelH;
if (_h > _areaH) then {
    _h = _areaH;
    _w = _h / pixelH * 2 * pixelW;
};
private _x0 = (_areaW - _w) / 2;
private _y0 = (_areaH - _h) / 2;
private _places = [
    [PMCI_IDC_SCENE_PIC, 0, 0, 1024, 512],
    [PMCI_IDC_WHEEL, 256, 0, 512, 512],
    [PMCI_IDC_GAUZE, 256, 122, 512, 256],     // gauze centre on the wound centre (512, 250)
    [PMCI_IDC_WINDLASS, 342, 16, 256, 256],   // windlass centre on the clip (470, 144)
    [PMCI_IDC_HANDS, 352, 106, 256, 512],     // heel of the hand (128, 150) on the sternum (480, 256)
    [PMCI_IDC_BEAT, 896, 16, 112, 112],
    [PMCI_IDC_SWAP, 790, 220, 220, 72]
];
for "_k" from 0 to 4 do {
    // Nuts on the wheel's studs: radius 150 px, -90 + 72 * k degrees, clockwise from the top.
    private _cx = 512 + 150 * cos (-90 + 72 * _k);
    private _cy = 256 + 150 * sin (-90 + 72 * _k);
    _places pushBack [PMCI_IDC_NUTPIC0 + _k, _cx - 64, _cy - 64, 128, 128];
    _places pushBack [PMCI_IDC_NUT0 + _k, _cx - 48, _cy - 48, 96, 96];
};
{
    _x params ["_idc", "_px", "_py", "_pw", "_ph"];
    private _ctrl = _group controlsGroupCtrl _idc;
    _ctrl ctrlSetPosition [_x0 + _w * _px / 1024, _y0 + _h * _py / 512, _w * _pw / 1024, _h * _ph / 512];
    _ctrl ctrlCommit 0;
} forEach _places;
(_display displayCtrl PMCI_IDC_ICON) ctrlSetText format ["\pmc_interactions\data\icon_%1_ca.paa", _game];
(_display displayCtrl PMCI_IDC_FILL) ctrlSetTextColor (switch (_game) do {
    case "tourniquet": {[0.95, 0.55, 0.2, 0.95]};
    case "bandage": {[0.45, 0.7, 0.95, 0.95]};
    default {[0.9, 0.3, 0.25, 0.95]};
});
