tolk 0.6

import "errors.tolk"
import "op.tolk"
import "params.tolk"
import "storage.tolk"
import "utils.tolk"
import "../common/messages.tolk"

// Messages from admin

@inline
fun handleAdminMessages(op: int, queryId: int, myBalance: int, msgValue: int, msgBody: slice) {
    if (op == OP_SET_FEES) {
        val newLpFee = msgBody.loadUint(8);
        val newProtocolFee = msgBody.loadUint(8);
        val newRefFee = msgBody.loadUint(8);
        val newProtocolFeeAddress = msgBody.loadAddress();
        var refDs = msgBody.loadRef().beginParse();
        val jettonWallet0 = refDs.loadAddress();
        val jettonWallet1 = refDs.loadAddress();
        val (_, poolAddress) = getPoolStateInitAndAddress(jettonWallet0, jettonWallet1);
        val body = beginCell()
            .storeUint(OP_SET_FEES, 32)
            .storeUint(queryId, 64)
            .storeUint(newLpFee, 8)
            .storeUint(newProtocolFee, 8)
            .storeUint(newRefFee, 8)
            .storeSlice(newProtocolFeeAddress);
        sendSimpleMessage(0, poolAddress, body.endCell(), CARRY_REMAINING_GAS);
        return;
    }

    if (op == OP_COLLECT_FEES){
        val jettonWallet0 = msgBody.loadAddress();
        val jettonWallet1 = msgBody.loadAddress();
        val (_, poolAddress) = getPoolStateInitAndAddress(jettonWallet0, jettonWallet1);
        val body = beginCell()
            .storeUint(OP_COLLECT_FEES, 32)
            .storeUint(queryId, 64);
        sendSimpleMessage(0, poolAddress, body.endCell(), CARRY_REMAINING_GAS);
        return;
    }

    if (op == OP_LOCK) { 
        // true == -1 but STORAGE_IS_LOCKED is uint
        STORAGE_IS_LOCKED = 1;
        saveStorage();
        return;
    }

    if (op == OP_UNLOCK) { 
        STORAGE_IS_LOCKED = false;
        saveStorage();
        return;
    }
    
    if (op == OP_INIT_CODE_UPGRADE) { 
        val (endCode, _, endAdmin, admin) = unpackTempUpgrade(STORAGE_TEMP_UPGRADE);
        // Upgrade already in progress.
        assert(endCode == 0, INVALID_CALL);
        STORAGE_TEMP_UPGRADE = packTempUpgrade(now() + SEVEN_DAYS, msgBody.loadRef(), endAdmin, admin);
        saveStorage();
        return;
    }

    if (op == OP_INIT_ADMIN_UPGRADE) { 
        val (endCode, newCode, endAdmin, _) = unpackTempUpgrade(STORAGE_TEMP_UPGRADE);
        // Upgrade already in progress.
        assert(endAdmin == 0, INVALID_CALL);
        STORAGE_TEMP_UPGRADE = packTempUpgrade(endCode, newCode, now() + TWO_DAYS, msgBody.loadAddress());
        saveStorage();
        return;
    }
    
    if (op == OP_CANCEL_ADMIN_UPGRADE) { 
        val (endCode, code, endAdmin, _) = unpackTempUpgrade(STORAGE_TEMP_UPGRADE);
        assert(endAdmin > 0, INVALID_CALL); 
        STORAGE_TEMP_UPGRADE = packTempUpgrade(endCode, code, 0, HOLE_ADDRESS);
        saveStorage();
        return;
    }

    if (op == OP_CANCEL_CODE_UPGRADE) { 
        val (endCode, _, endAdmin, admin) = unpackTempUpgrade(STORAGE_TEMP_UPGRADE);
        assert(endCode > 0, INVALID_CALL); 
        STORAGE_TEMP_UPGRADE = packTempUpgrade(0, emptyCell(), endAdmin, admin);
        saveStorage();
        return;
    }

    // Valid for both upgrades.
    if (op == OP_FINALIZE_UPGRADES) { 
        var (endCode, newCode, endAdmin, newAdmin) = unpackTempUpgrade(STORAGE_TEMP_UPGRADE);
        // Make sure at least one upgrade process is in progress.
        assert((endCode + endAdmin) > 0, INVALID_CALL);

        if ((endCode > 0) && (now() >= endCode)) {
            setContractCodePostponed(newCode);
            endCode = 0;
            newCode = emptyCell();
        }

        if ((endAdmin > 0) && (now() >= endAdmin)) {
            STORAGE_ADMIN_ADDRESS = newAdmin;
            endAdmin = 0;
            newAdmin = HOLE_ADDRESS;
        }

        STORAGE_TEMP_UPGRADE = packTempUpgrade(endCode, newCode, endAdmin, newAdmin);
        saveStorage();
        return;
    }

    if (op == OP_RESET_GAS) { 
        sendEmptyMessage(myBalance - REQUIRED_TON_RESERVE, STORAGE_ADMIN_ADDRESS, NORMAL);
        return;
    }

    if (op == OP_RESET_POOL_GAS) {
        val jettonWallet0 = msgBody.loadAddress();
        val jettonWallet1 = msgBody.loadAddress();
        val (_, poolAddress) = getPoolStateInitAndAddress(jettonWallet0, jettonWallet1);
        val body = beginCell().storeUint(OP_RESET_GAS, 32).storeUint(queryId, 64);
        sendSimpleMessage(0, poolAddress, body.endCell(), CARRY_REMAINING_GAS);
        return;
    }

    throw WRONG_OP;
}