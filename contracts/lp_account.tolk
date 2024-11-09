tolk 0.6

import "lp_account/errors.tolk"
import "lp_account/get.tolk"
import "lp_account/getter.tolk"
import "lp_account/params.tolk"
import "lp_account/pool-calls.tolk"
import "lp_account/storage.tolk"
import "lp_account/user-calls.tolk"
import "common/utils.tolk"

fun onInternalMessage(myBalance: int, msgValue: int, msgFull: cell, msgBody: slice) {
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
    forceChain(WORKCHAIN, senderAddress, WRONG_WORKCHAIN);

    val op = msgBody.loadUint(32);
    val queryId = msgBody.loadUint(64);

    // Handle message from pool.
    if (isSliceBitsEqual(senderAddress, STORAGE_POOL_ADDRESS)) {
        handlePoolMessages(op, queryId, myBalance, msgValue, msgBody);
        return;
    }

    // Handle message from user.
    if (isSliceBitsEqual(senderAddress, STORAGE_USER_ADDRESS)) {
        handleUserMessages(op, queryId, myBalance, msgValue, msgBody);
        return;
    }

    // Make sure that the message has a valid opcode.
    if (handleGetterMessages(op, queryId, senderAddress, msgBody)) {
        return; 
    }

    throw WRONG_OP;
}