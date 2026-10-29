// ACE stand-ins for the SQF-VM checks: the treatment and repair action classes the mod
// overrides, with ACE's own values (ACE 3 master), plus a class another mod might base on
// FieldDressing. TEST_parent names the parent class for the inheritsFrom adapter.
// Properties the addon overrides are left out: SQF-VM keeps the first definition when
// configs are merged, while Arma takes the later addon's.
class ace_medical_treatment_actions {
    class BasicBandage {
        treatmentTime = "ace_medical_treatment_fnc_getBandageTime";
        callbackSuccess = "ace_medical_treatment_fnc_bandage";
    };
    class FieldDressing: BasicBandage {TEST_parent = "BasicBandage";};
    class PackingBandage: BasicBandage {TEST_parent = "BasicBandage";};
    class ElasticBandage: BasicBandage {TEST_parent = "BasicBandage";};
    class QuikClot: BasicBandage {TEST_parent = "BasicBandage";};
    class ApplyTourniquet: BasicBandage {TEST_parent = "BasicBandage";};
    class CPR: BasicBandage {
        TEST_parent = "BasicBandage";
        callbackFailure = "ace_medical_treatment_fnc_cprFailure";
    };
    class Morphine: FieldDressing {
        TEST_parent = "FieldDressing";
        treatmentTime = "ace_medical_treatment_treatmentTimeAutoinjector";
        callbackSuccess = "ace_medical_treatment_fnc_medication";
    };
    class KAT_Bandage: FieldDressing {TEST_parent = "FieldDressing";};
    class Splint: BasicBandage {TEST_parent = "BasicBandage";};
    class BloodIV: BasicBandage {TEST_parent = "BasicBandage";};
    class BloodIV_500: BloodIV {TEST_parent = "BloodIV";};
    class PlasmaIV: BloodIV {TEST_parent = "BloodIV";};
    class SurgicalKit: FieldDressing {TEST_parent = "FieldDressing";};
};
class ACE_Repair {
    class Actions {
        class ReplaceWheel {};
        class RemoveWheel: ReplaceWheel {
            TEST_parent = "ReplaceWheel";
            callbackSuccess = "ace_repair_fnc_doRemoveWheel";
        };
        class MiscRepair: ReplaceWheel {TEST_parent = "ReplaceWheel";};
        class RepairTrack: MiscRepair {TEST_parent = "MiscRepair";};
        class RemoveTrack: MiscRepair {
            TEST_parent = "MiscRepair";
            callbackSuccess = "ace_repair_fnc_doRemoveTrack";
        };
        class ReplaceTrack: RemoveTrack {TEST_parent = "RemoveTrack";};
        class FullRepair: MiscRepair {
            TEST_parent = "MiscRepair";
            repairingTime = "ace_repair_fnc_getFullRepairTime";
            callbackSuccess = "ace_repair_fnc_doFullRepair";
        };
    };
};
class CfgWeapons {
    class ItemCore {};
    class ACE_fieldDressing: ItemCore {};
    class ACE_tourniquet: ItemCore {};
};
class CfgMagazines {
    class CA_Magazine {};
    class TEST_bandageMagazine: CA_Magazine {};
};
class CfgVehicles {
    class All {};
    class CAManBase: All {};
    class B_Soldier_F: CAManBase {};
    class C_Offroad_01_F: All {};
    class ACE_Wheel: All {};
    class ACE_Track: All {};
    class B_MBT_01_cannon_F: All {};
};
