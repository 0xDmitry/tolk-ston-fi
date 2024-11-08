tolk 0.6

import "router/admin-calls.tolk"
import "router/errors.tolk"
import "router/get.tolk"
import "router/getter.tolk"
import "router/op.tolk"
import "router/params.tolk"
import "router/storage.tolk"
import "router/utils.tolk"
import "common/gas.tolk"
import "common/jetton-utils.tolk"
import "common/messages.tolk"
import "common/utils.tolk"

fun onInternalMessage(myBalance: int, msgValue: int, msgFull: cell, msgBody: slice) {
    // Ignore empty messages.
    if (msgBody.isEndOfSlice()) {
        return;
    }

    var cs = msgFull.beginParse();
    val flags = cs.loadUint(4);

    loadStorage();

    if (flags & 1) {
        return;
    }

    val senderAddress = cs.loadAddress();
    // Skip dst.
    cs.loadAddress();
    // Skip value.
    cs.loadCoins();
    // Skip extracurrency collection.
    cs.skipBits(1);
    // Skip ihr_fee.
    cs.loadCoins();
    val fwdFee = cs.loadCoins();

    forceChain(WORKCHAIN, senderAddress, WRONG_WORKCHAIN);

    val op = msgBody.loadUint(32);
    val queryId = msgBody.loadUint(64);

    // Send tokens, called from pools (on swap, liquidity providing, refund etc).
    if (op == OP_PAY_TO) {
        val gasRequired = getGasFee(20000, WORKCHAIN);
        assert(msgValue > gasRequired, INSUFFICIENT_GAS);
        val owner = msgBody.loadAddress();
        val exitCode = msgBody.loadUint(32);
        
        // Parse ref cell.
        var psd = msgBody.loadRef().beginParse();
        val amount0Out = psd.loadCoins();
        val token0Address = psd.loadAddress();
        val amount1Out = psd.loadCoins();
        val token1Address = psd.loadAddress();

        val (_, poolAddress) = getPoolStateInitAndAddress(token0Address, token1Address);
        // Check if it is a valid pool.
        assert(isSliceBitsEqual(poolAddress, senderAddress), INVALID_CALLER);
        
        var tonAmount = 0;
        var mode = CARRY_REMAINING_GAS;

        // Either one or both amounts must be non-zero.
        if ((amount0Out > 0) && (amount1Out > 0)) {
            // Divide remaining tonAmount between two transactions.
            tonAmount = (msgValue - gasRequired) / 2;
            mode = NORMAL;
        }

        if (amount0Out > 0) {
            var body0 = createSimpleTransferBody(queryId, 0, amount0Out, owner);
            // Append exit code.
            body0 = body0.storeUint(exitCode, 32);
            sendSimpleMessage(tonAmount, token0Address, body0.endCell(), mode | IGNORE_ERRORS);
        }

        if (amount1Out > 0) {
            var body1 = createSimpleTransferBody(queryId, 0, amount1Out, owner);
            // Append exit code.
            body1 = body1.storeUint(exitCode, 32);
            sendSimpleMessage(tonAmount, token1Address, body1.endCell(), mode | IGNORE_ERRORS);
        }

        return;
    }

    if (op == OP_TRANSFER_NOTIFICATION) {
        val jettonAmount = msgBody.loadCoins();
        val fromUser = msgBody.loadAddress();
        var refDs = msgBody.loadRef().beginParse();
        
        assert(jettonAmount > 0, INVALID_AMOUNT);
        
        val transferredOp = refDs.loadUint(32);
        val tokenWallet1 = refDs.loadAddress();
        forceChain(WORKCHAIN, tokenWallet1, WRONG_WORKCHAIN);

        // Check if the call is valid.
        if ((fwdFee * 6 > msgValue) || isSliceBitsEqual(senderAddress, tokenWallet1) || (STORAGE_IS_LOCKED == 1)) {
            // Refund jettons.
            var body = createSimpleTransferBody(queryId, 0, jettonAmount, fromUser);
            if (STORAGE_IS_LOCKED) {
                body = body.storeUint(OP_TRANSFER_BOUNCE_LOCKED, 32);
            } else {
                body = body.storeUint(OP_TRANSFER_BOUNCE_INVALID_REQUEST, 32);
            }
            sendSimpleMessage(0, senderAddress, body.endCell(), CARRY_REMAINING_GAS);
        } else {
            // Route call to the correct pool
            if (transferredOp == OP_SWAP) {
                val minOut = refDs.loadCoins();
                val toAddress = refDs.loadAddress();
                val hasRef = refDs.loadUint(1);
                val (_, poolAddress) = getPoolStateInitAndAddress(senderAddress, tokenWallet1);
                
                var body = beginCell()
                    .storeUint(OP_SWAP, 32)
                    .storeUint(queryId, 64)
                    .storeSlice(toAddress)
                    .storeSlice(senderAddress)
                    .storeCoins(jettonAmount)
                    .storeCoins(minOut)
                    .storeUint(hasRef, 1);

                var bodyRef = beginCell()
                    // Real caller.
                    .storeSlice(fromUser);
                
                if (hasRef == 1) {
                    val refAddress = refDs.loadAddress();
                    bodyRef = bodyRef.storeSlice(refAddress);
                }

                body = body.storeRef(bodyRef.endCell());

                sendSimpleMessage(0, poolAddress, body.endCell(), CARRY_REMAINING_GAS);
                return;
            }

            if (transferredOp == OP_PROVIDE_LP) {
                val minLpOut = refDs.loadCoins();
                val (stateInit, poolAddress) = getPoolStateInitAndAddress(senderAddress, tokenWallet1);

                var body = beginCell()
                    .storeUint(OP_PROVIDE_LP, 32)
                    .storeUint(queryId, 64)
                    .storeSlice(fromUser)
                    .storeCoins(minLpOut);

                if (sliceHash(senderAddress) > sliceHash(tokenWallet1)) {
                    body = body.storeCoins(jettonAmount);
                    body = body.storeCoins(0);
                } else {
                    body = body.storeCoins(0);
                    body = body.storeCoins(jettonAmount);
                }

                sendMessageWithStateInit(0, poolAddress, stateInit, body.endCell(), CARRY_REMAINING_GAS);
                return;
            }
        }
        return;
    }

    // Handle governance message from admin to change pool parameters.
    if (isSliceBitsEqual(senderAddress, STORAGE_ADMIN_ADDRESS)) {
        handleAdminMessages(op, queryId, myBalance, msgValue, msgBody);
        return;
    }

    // Make sure that the message has been processed.
    if (handleGetterMessages(op, queryId, senderAddress, msgBody)) {
        return; 
    }

    throw WRONG_OP;
}
