tolk 0.6

import "pool/amm.tolk"
import "pool/errors.tolk"
import "pool/get.tolk"
import "pool/getter.tolk"
import "pool/jetton-utils.tolk"
import "pool/lp_account-utils.tolk"
import "pool/op.tolk"
import "pool/params.tolk"
import "pool/router-calls.tolk"
import "pool/storage.tolk"
import "pool/utils.tolk"
import "common/gas.tolk"
import "common/messages.tolk"

fun onInternalMessage(myBalance: int, msgValue: int, msgFull: cell, msgBody: slice) {
    if (msgBody.isEndOfSlice()) {
        return;
    }

    var cs = msgFull.beginParse();
    val flags = cs.loadUint(4);
    
    if (flags & 1) {
        return;
    }

    loadStorage();

    val senderAddress = cs.loadAddress();

    val op = msgBody.loadUint(32);
    val queryId = msgBody.loadUint(64);

    if (op == OP_BURN_NOTIFICATION) { 
        // Sent by LP wallet after burning LP jettons to release liquidity.
        val jettonAmount = msgBody.loadCoins();
        val fromAddress = msgBody.loadAddress();
        val responseAddress = msgBody.loadAddress();
        val gasRequired = getGasFee(25000, WORKCHAIN);
        cs.loadAddress(); 
        cs.loadCoins(); 
        cs.skipBits(1); 
        cs.loadCoins();
        val fwdFee = cs.loadCoins();
        assert((msgValue > gasRequired) && (msgValue > fwdFee * 6), INSUFFICIENT_GAS);

        assert(isSliceBitsEqual(calculateUserJettonLpWalletAddress(fromAddress, getMyAddress(), STORAGE_JETTON_LP_WALLET_CODE), senderAddress), INVALID_CALLER);
        assert(jettonAmount > 0, ZERO_OUTPUT); 

        // Get shares.
        val amount0Out = (jettonAmount * STORAGE_RESERVE_0) / STORAGE_TOTAL_SUPPLY_LP; 
        val amount1Out = (jettonAmount * STORAGE_RESERVE_1) / STORAGE_TOTAL_SUPPLY_LP; 
        
        // Both are positive.
        assert((amount0Out > 0) && (amount1Out > 0), ZERO_OUTPUT);

        STORAGE_RESERVE_0 -= amount0Out;
        STORAGE_RESERVE_1 -= amount1Out;
        STORAGE_TOTAL_SUPPLY_LP -= jettonAmount;

        var gas = 0;
        var mode = CARRY_REMAINING_GAS;
        if (responseAddress.preloadUint(2) != 0) {
            gas = (msgValue - gasRequired) / 2;
            mode = NORMAL;
            var body = beginCell()
                .storeUint(OP_EXCESSES, 32)
                .storeUint(queryId, 64);
            sendMessageNobounce(gas, responseAddress, body.endCell(), IGNORE_ERRORS);
        }
        callPayTo(gas, mode, queryId, fromAddress, OP_BURN_OK, amount0Out, amount1Out);
        saveStorage();
        return;
    }

    if (op == OP_CB_ADD_LIQUIDITY) {
        // Sent by user's lpAccount after adding liquidity.
        // Not throwable.
        val totAm0 = msgBody.loadCoins();
        val totAm1 = msgBody.loadCoins();
        val userAddress = msgBody.loadAddress();
        val minLpOut = msgBody.loadCoins();
        val accStateInit = calculateLpAccountStateInit(userAddress, getMyAddress(), STORAGE_LP_ACCOUNT_CODE); 
        assert(isSliceBitsEqual(calculateLpAccountAddress(accStateInit), senderAddress), INVALID_CALLER);

        var liquidity = 0;
        var to = "";

        if (STORAGE_TOTAL_SUPPLY_LP == 0) { 
            // Handle initial liquidity.
            liquidity = sqrt(totAm0 * totAm1) / REQUIRED_MIN_LIQUIDITY;
            // Lock the initial liquidity, so it will be impossible to fully drain the pool.
            to = addrNone();
        } else {
            val toMint0 = (totAm0 * STORAGE_TOTAL_SUPPLY_LP) / STORAGE_RESERVE_0;
            val toMint1 = (totAm1 * STORAGE_TOTAL_SUPPLY_LP) / STORAGE_RESERVE_1;
            // Mint the minimum amount of liquidity, excesses will be shared proportionally across the pool.
            liquidity = min(toMint0, toMint1);
            to = userAddress;
        }

        STORAGE_RESERVE_0 += totAm0;
        STORAGE_RESERVE_1 += totAm1;
        STORAGE_TOTAL_SUPPLY_LP += liquidity;

        // Checks if:
        // - The user will get less than the minimum amount of liquidity
        // - Reserves exceeds max supply
        if ((liquidity < minLpOut) || ((STORAGE_RESERVE_0 > MAX_COINS) || (STORAGE_RESERVE_1 > MAX_COINS))) {      
            var body = beginCell()
                .storeUint(OP_ADD_LIQUIDITY, 32)
                .storeUint(queryId, 64)
                .storeCoins(totAm0)
                .storeCoins(totAm1)
                // Hardencode to zero to avoid minting loop between pool and lp_account.
                .storeCoins(0);
            // state_init needed since lp_account might be already destroyed
            sendMessageWithStateInit(0, senderAddress, accStateInit, body.endCell(), CARRY_REMAINING_GAS + IGNORE_ERRORS);
        } else {
            mintLp(queryId, to, liquidity);
            saveStorage();
        }
        return;
    }

    if (op == OP_CB_REFUND_ME) {
        // Sent by user's lp_account after adding liquidity.
        // Throwable.
        val totAm0 = msgBody.loadCoins();
        val totAm1 = msgBody.loadCoins();
        val userAddress = msgBody.loadAddress();
        assert(isSliceBitsEqual(calculateUserLpAccountAddress(userAddress, getMyAddress(), STORAGE_LP_ACCOUNT_CODE), senderAddress), INVALID_CALLER);
        callPayTo(0, CARRY_REMAINING_GAS, queryId, userAddress, OP_REFUND_OK, totAm0, totAm1);
        return;
    }

    // Handle swap, provide_lp and governance messages.
    if (isSliceBitsEqual(senderAddress, STORAGE_ROUTER_ADDRESS)) {
        handleRouterMessages(op, queryId, myBalance, msgValue, msgBody);
        return;
    }

    // Called by anyone.
    if (op == OP_COLLECT_FEES) {
        // Throwable.
        assert(STORAGE_TOTAL_SUPPLY_LP > REQUIRED_MIN_LIQUIDITY, NO_LIQUIDITY);
        assert((STORAGE_COLLECTED_TOKEN_0_PROTOCOL_FEE > REQUIRED_MIN_COLLECT_FEES) && (STORAGE_COLLECTED_TOKEN_1_PROTOCOL_FEE > REQUIRED_MIN_COLLECT_FEES), LOW_LIQUIDITY);
        assert(!isSliceBitsEqual(STORAGE_PROTOCOL_FEE_ADDRESS, HOLE_ADDRESS), INVALID_RECIPIENT);
        val gasRequired = getGasFee(40000, WORKCHAIN);

        // 1 ton
        assert((msgValue - gasRequired) > 1000000000, INSUFFICIENT_GAS);
        val gas = (msgValue - gasRequired) / 4;
        val reward0 = STORAGE_COLLECTED_TOKEN_0_PROTOCOL_FEE / 1000;
        val reward1 = STORAGE_COLLECTED_TOKEN_1_PROTOCOL_FEE / 1000;
        STORAGE_COLLECTED_TOKEN_0_PROTOCOL_FEE -= reward0;
        STORAGE_COLLECTED_TOKEN_1_PROTOCOL_FEE -= reward1;

        assert((reward0 > 0) && (reward1 > 0), ZERO_OUTPUT);
        assert((STORAGE_COLLECTED_TOKEN_0_PROTOCOL_FEE > 0) && (STORAGE_COLLECTED_TOKEN_1_PROTOCOL_FEE > 0), ZERO_OUTPUT);

        // Revert if fails.
        callPayTo(gas * 3, NORMAL, queryId, STORAGE_PROTOCOL_FEE_ADDRESS, 0, STORAGE_COLLECTED_TOKEN_0_PROTOCOL_FEE, STORAGE_COLLECTED_TOKEN_1_PROTOCOL_FEE);
        callPayTo(gas, IGNORE_ERRORS, queryId, senderAddress, 0, reward0, reward1);

        STORAGE_COLLECTED_TOKEN_0_PROTOCOL_FEE = 0;
        STORAGE_COLLECTED_TOKEN_1_PROTOCOL_FEE = 0;
        saveStorage();
        return;
    }

    cs.loadAddress();
    cs.loadCoins();
    cs.skipBits(1);
    cs.loadCoins();
    // Make sure that the message has a valid opcode.
    if (handleGetterMessages(msgValue, cs.loadCoins(), op, queryId, senderAddress, msgBody)) {
        return; 
    }

    throw WRONG_OP;
}
