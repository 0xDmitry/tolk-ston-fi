tolk 0.6

import "amm.tolk"
import "errors.tolk"
import "lp_account-utils.tolk"
import "op.tolk"
import "params.tolk"
import "storage.tolk"
import "utils.tolk"
import "../common/gas.tolk"
import "../common/messages.tolk"

@inline
fun handleRouterMessages(op: int, queryId: int, myBalance: int, msgValue: int, msgBody: slice) {
    if (op == OP_SWAP) {
        val fromUserAddress = msgBody.loadAddress();
        val tokenWallet = msgBody.loadAddress();
        val amount = msgBody.loadCoins();
        val minOut = msgBody.loadCoins();
        val hasRef = msgBody.loadUint(1);
        var refBodySlice = msgBody.loadRef().beginParse(); 
        // Parse who initialized the swap, always present.
        val fromRealUser = refBodySlice.loadAddress();

        var out = 0;
        var protocolFeeOut = 0;
        var refFeeOut = 0;
        var tmpAm0 = 0;
        var tmpAm1 = 0;
        var refAddress = addrNone();

        var mode = CARRY_REMAINING_GAS;
        var gas = 0;
    
        if (hasRef == 1) {
            mode = NORMAL;
            gas = (msgValue - getGasFee(25000, WORKCHAIN)) / 2;
            refAddress = refBodySlice.loadAddress();
        }

        if (isSliceBitsEqual(tokenWallet, STORAGE_TOKEN_0_ADDRESS)) { 
            (out, protocolFeeOut, refFeeOut) = getAmountOut(hasRef, amount, STORAGE_RESERVE_0, STORAGE_RESERVE_1);
            tmpAm0 = amount;
        } else {
            (out, protocolFeeOut, refFeeOut) = getAmountOut(hasRef, amount, STORAGE_RESERVE_1, STORAGE_RESERVE_0);
            tmpAm1 = amount;
        }

        // Refund if not enough liquidity or not enough output or output less than minOut.
        if ((STORAGE_TOTAL_SUPPLY_LP <= 0) || ((out <= 0) || (minOut >= out))) {
            callPayTo(0, CARRY_REMAINING_GAS, queryId, fromRealUser, OP_SWAP_REFUND_NO_LIQ, tmpAm0, tmpAm1);
            return;
        }

        if (tmpAm0) {
            // Swap token0 for token1.
            STORAGE_RESERVE_0 += amount;
            STORAGE_RESERVE_1 -= (out + protocolFeeOut + refFeeOut);
            STORAGE_COLLECTED_TOKEN_1_PROTOCOL_FEE += protocolFeeOut; 

            // Refund if not enough balance or exceed max balance.
            if ((STORAGE_RESERVE_0 > MAX_COINS) || (STORAGE_RESERVE_1 <= 0)) {
                callPayTo(0, CARRY_REMAINING_GAS, queryId, fromRealUser, OP_SWAP_REFUND_RESERVE_ERR, tmpAm0, tmpAm1);
                return;
            }

            if (mode == NORMAL) {
                // 2 messages, pay referral.
                callPayTo(gas, mode | IGNORE_ERRORS, queryId, refAddress, OP_SWAP_OK_REF, 0, refFeeOut); 
            }
            callPayTo(gas, mode, queryId, fromUserAddress, OP_SWAP_OK, 0, out); 
        } else {    
            // Swap token1 for token0.
            STORAGE_RESERVE_0 -= (out + protocolFeeOut + refFeeOut);
            STORAGE_RESERVE_1 += amount;
            STORAGE_COLLECTED_TOKEN_1_PROTOCOL_FEE += protocolFeeOut; 

            // Refund if not enough balance or exceed max balance.
            if ((STORAGE_RESERVE_1 > MAX_COINS) || (STORAGE_RESERVE_0 <= 0) ){
                callPayTo(0, CARRY_REMAINING_GAS, queryId, fromRealUser, OP_SWAP_REFUND_RESERVE_ERR, tmpAm0, tmpAm1);
                return;
            }

            if (mode == NORMAL) {
                // 2 messages, pay referral.
                callPayTo(gas, mode | IGNORE_ERRORS, queryId, refAddress, OP_SWAP_OK_REF, refFeeOut, 0); 
            }
            callPayTo(gas, mode, queryId, fromUserAddress, OP_SWAP_OK, out, 0); 
        }
        saveStorage();
        return;
    }

    if (op == OP_PROVIDE_LP) { 
        val ownerAddr = msgBody.loadAddress();
        val minLpOut = msgBody.loadCoins();
        val amount0 = msgBody.loadCoins();
        val amount1 = msgBody.loadCoins();

        val stateInit = calculateLpAccountStateInit(ownerAddr, getMyAddress(), STORAGE_LP_ACCOUNT_CODE); 
        val toLpAccountAddress = calculateLpAccountAddress(stateInit);

        // Route to lp_account.
        var body = beginCell()
            .storeUint(OP_ADD_LIQUIDITY, 32)
            .storeUint(queryId, 64)
            .storeCoins(amount0)
            .storeCoins(amount1)
            .storeCoins(minLpOut);
        sendMessageWithStateInit(0, toLpAccountAddress, stateInit, body.endCell(), CARRY_REMAINING_GAS);
        return;
    }


    if (op == OP_RESET_GAS) { 
        sendEmptyMessage(myBalance - REQUIRED_TON_RESERVE, STORAGE_ROUTER_ADDRESS, NORMAL);
        return;
    }

    if (op == OP_COLLECT_FEES) {
        assert((STORAGE_COLLECTED_TOKEN_0_PROTOCOL_FEE > 0) && (STORAGE_COLLECTED_TOKEN_1_PROTOCOL_FEE > 0), NO_LIQUIDITY);
        assert(!isSliceBitsEqual(STORAGE_PROTOCOL_FEE_ADDRESS, HOLE_ADDRESS), INVALID_RECIPIENT);
        callPayTo(0, CARRY_REMAINING_GAS, queryId, STORAGE_PROTOCOL_FEE_ADDRESS, 0, STORAGE_COLLECTED_TOKEN_0_PROTOCOL_FEE, STORAGE_COLLECTED_TOKEN_1_PROTOCOL_FEE);
        STORAGE_COLLECTED_TOKEN_0_PROTOCOL_FEE = 0;
        STORAGE_COLLECTED_TOKEN_1_PROTOCOL_FEE = 0;
        saveStorage();
        return;
    }

  
    if (op == OP_SET_FEES) { 
        val newLpFee = msgBody.loadUint(8);
        val newProtocolFee = msgBody.loadUint(8);
        val newRefFee = msgBody.loadUint(8);
        val newProtocolFeeAddress = msgBody.loadAddress();

        assert((MIN_FEE <= newLpFee) && (newLpFee <= MAX_FEE), FEE_OUT_RANGE);
        assert((MIN_FEE <= newProtocolFee) && (newProtocolFee <= MAX_FEE), FEE_OUT_RANGE);
        assert((MIN_FEE <= newRefFee) && (newRefFee <= MAX_FEE), FEE_OUT_RANGE);

        STORAGE_LP_FEE = newLpFee;
        STORAGE_PROTOCOL_FEE = newProtocolFee;
        STORAGE_REF_FEE = newRefFee;
        STORAGE_PROTOCOL_FEE_ADDRESS = newProtocolFeeAddress;
        saveStorage();
        return;
    }

    throw WRONG_OP;
}