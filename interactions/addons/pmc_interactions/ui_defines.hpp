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
// Scene layers: picture k (0-31) of PMCI_fnc_boardLook has IDC PMCI_IDC_LAYER + k.
#define PMCI_IDC_LAYER 87700
#define PMCI_IDC_SCENE_PIC 87700
#define PMCI_IDC_HANDS 87701
#define PMCI_IDC_BEAT 87702
#define PMCI_IDC_WINDLASS 87703
#define PMCI_IDC_GAUZE 87704
#define PMCI_IDC_WHEEL 87705
#define PMCI_IDC_NUTPIC0 87706
#define PMCI_IDC_NUTPIC1 87707
#define PMCI_IDC_NUTPIC2 87708
#define PMCI_IDC_NUTPIC3 87709
#define PMCI_IDC_NUTPIC4 87710
#define PMCI_IDC_PRESS_HAND 87711
#define PMCI_IDC_SEEP 87712
#define PMCI_IDC_PAD 87713
#define PMCI_IDC_SWAB 87714
#define PMCI_IDC_SEG0 87715
#define PMCI_IDC_SEG1 87716
#define PMCI_IDC_SEG2 87717
#define PMCI_IDC_SEG3 87718
#define PMCI_IDC_SEG4 87719
#define PMCI_IDC_SEG5 87720
#define PMCI_IDC_SEG6 87721
#define PMCI_IDC_SEG7 87722
#define PMCI_IDC_DIRT0 87723
#define PMCI_IDC_DIRT1 87724
#define PMCI_IDC_DIRT2 87725
#define PMCI_IDC_DIRT3 87726
#define PMCI_IDC_DIRT4 87727
#define PMCI_IDC_DIRT5 87728
#define PMCI_IDC_DIRT6 87729
#define PMCI_IDC_DIRT7 87730
#define PMCI_IDC_RUNNER 87731
#define PMCI_LAYERS 32
#define PMCI_IDC_SCRUB 87627
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
