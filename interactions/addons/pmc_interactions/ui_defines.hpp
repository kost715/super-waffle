// Board display and control IDs shared by the dialog config and the board functions.
#define PMCI_IDD_BOARD 87600
#define PMCI_IDC_TITLE 87601
#define PMCI_IDC_TEXT 87602
#define PMCI_IDC_STATUS 87603
#define PMCI_IDC_ICON 87604
#define PMCI_IDC_GAUGE 87610
#define PMCI_IDC_BAND 87611
#define PMCI_IDC_FILL 87612
#define PMCI_IDC_MARKER 87613
#define PMCI_IDC_FRAME 87615
// Scene: a controls group that clips its pictures; the IDCs below live inside it.
#define PMCI_IDC_SCENE 87650
#define PMCI_IDC_SCENE_PIC 87651
#define PMCI_IDC_HANDS 87652
#define PMCI_IDC_BEAT 87614
#define PMCI_IDC_WINDLASS 87653
#define PMCI_IDC_GAUZE 87654
#define PMCI_IDC_WHEEL 87655
#define PMCI_IDC_NUTPIC0 87656
#define PMCI_IDC_NUTPIC1 87657
#define PMCI_IDC_NUTPIC2 87658
#define PMCI_IDC_NUTPIC3 87659
#define PMCI_IDC_NUTPIC4 87660
#define PMCI_IDC_NUT0 87621
#define PMCI_IDC_NUT1 87622
#define PMCI_IDC_NUT2 87623
#define PMCI_IDC_NUT3 87624
#define PMCI_IDC_NUT4 87625
#define PMCI_IDC_SWAP 87626
#define PMCI_IDC_TIME 87630
#define PMCI_IDC_HOLD 87640
#define PMCI_IDC_FIX 87641
#define PMCI_IDC_CANCEL 87642
// Board window: 0.58 x 0.8 of the safe zone, centred.
#define PMCI_WIN_X 0.21
#define PMCI_WIN_Y 0.1
#define PMCI_BOX(px,py,pw,ph) x = safezoneX + safezoneW * (PMCI_WIN_X + (px)); y = safezoneY + safezoneH * (PMCI_WIN_Y + (py)); w = safezoneW * (pw); h = safezoneH * (ph)
// Scene area inside the window. The 1024 x 512 scene picture keeps its 2:1 shape on any
// screen: PMCI_fnc_boardLayout fits it into this area and places the sprites on it.
#define PMCI_SCENE_X 0.015
#define PMCI_SCENE_Y 0.12
#define PMCI_SCENE_W 0.55
#define PMCI_SCENE_H 0.47
// Gauge geometry (fractions of the safe zone), used to place band, fill and marker.
#define PMCI_GAUGE_X (PMCI_WIN_X + 0.04)
#define PMCI_GAUGE_Y (PMCI_WIN_Y + 0.64)
#define PMCI_GAUGE_W 0.5
#define PMCI_GAUGE_H 0.05
