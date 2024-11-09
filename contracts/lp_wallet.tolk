tolk 0.6

import "lp_wallet/errors.tolk"
import "lp_wallet/get.tolk"
import "lp_wallet/jetton-utils.tolk"
import "lp_wallet/op.tolk"
import "lp_wallet/params.tolk"
import "lp_wallet/storage.tolk"
import "common/utils.tolk"

fun sendTokens(msgBody: slice, senderAddress: slice, msgValue: int, fwdFee: int) {
    val queryId = msgBody.loadUint(64);
    val jettonAmount = msgBody.loadCoins();
    val toOwnerAddress = msgBody.loadAddress();
    forceChain(WORKCHAIN, toOwnerAddress, WRONG_WORKCHAIN);

    var (balance, ownerAddress, jettonMasterAddress, jettonWalletCode) = loadStorage();
    balance -= jettonAmount;

    assert(isSliceBitsEqual(ownerAddress, senderAddress), 705);
    assert(balance >= 0, 706);

    val stateInit = calculateJettonLpWalletStateInit(toOwnerAddress, jettonMasterAddress, jettonWalletCode);
    val toWalletAddress = calculateJettonLpWalletAddress(stateInit);
    val responseAddress = msgBody.loadAddress();
    val customPayload = msgBody.loadDict();
    val forwardTonAmount = msgBody.loadCoins();
    assert(getRemainingBitsCount(msgBody) >= 1, 708);
    val eitherForwardPayload = msgBody;
    var outMsg = beginCell()
        .storeUint(0x18, 6)
        .storeSlice(toWalletAddress)
        .storeCoins(0)
        .storeUint(4 + 2 + 1, 1 + 4 + 4 + 64 + 32 + 1 + 1 + 1)
        .storeRef(stateInit);
    val outMsgBody = beginCell()
        .storeUint(OP_INTERNAL_TRANSFER, 32)
        .storeUint(queryId, 64)
        .storeCoins(jettonAmount)
        .storeSlice(ownerAddress)
        .storeSlice(responseAddress)
        .storeCoins(forwardTonAmount)
        .storeSlice(eitherForwardPayload)
    .endCell();
    outMsg = outMsg.storeRef(outMsgBody);
    val fwdCount = forwardTonAmount ? 2 : 1;
    assert(msgValue > forwardTonAmount + fwdCount * fwdFee + (2 * REQUIRED_GAS + REQUIRED_TON_STORAGE), 709);
    sendRawMessage(outMsg.endCell(), 64);
    saveStorage(balance, ownerAddress, jettonMasterAddress, jettonWalletCode);
}

fun receiveTokens(msgBody: slice, senderAddress: slice, myTonBalance: int, fwdFee: int, msgValue: int) {
    var (balance, ownerAddress, jettonMasterAddress, jettonWalletCode) = loadStorage();
    val queryId = msgBody.loadUint(64);
    val jettonAmount = msgBody.loadCoins();
    balance += jettonAmount;
    val fromAddress = msgBody.loadAddress();
    val responseAddress = msgBody.loadAddress();
    assert(
        isSliceBitsEqual(jettonMasterAddress, senderAddress) || isSliceBitsEqual(calculateUserJettonLpWalletAddress(fromAddress, jettonMasterAddress, jettonWalletCode), senderAddress),
        707
    );
    val forwardTonAmount = msgBody.loadCoins();
    val tonBalanceBeforeMsg = myTonBalance - msgValue;
    val storageFee = REQUIRED_TON_STORAGE - min(tonBalanceBeforeMsg, REQUIRED_TON_STORAGE);
    msgValue -= (storageFee + REQUIRED_GAS);
    if(forwardTonAmount) {
        msgValue -= (forwardTonAmount + fwdFee);
        val eitherForwardPayload = msgBody;
        var outMsgBody = beginCell()
            .storeUint(OP_TRANSFER_NOTIFICATION, 32)
            .storeUint(queryId, 64)
            .storeCoins(jettonAmount)
            .storeSlice(fromAddress)
            .storeSlice(eitherForwardPayload)
        .endCell();
        var outMsg = beginCell()
            .storeUint(0x18, 6)
            .storeSlice(ownerAddress)
            .storeCoins(forwardTonAmount)
            .storeUint(1, 1 + 4 + 4 + 64 + 32 + 1 + 1)
            .storeRef(outMsgBody);
        sendRawMessage(outMsg.endCell(), 1);
    }

    if ((responseAddress.preloadUint(2) != 0) && (msgValue > 0)) {
        var outMsg = beginCell()
            .storeUint(0x10, 6) 
            .storeSlice(responseAddress)
            .storeCoins(msgValue)
            .storeUint(0, 1 + 4 + 4 + 64 + 32 + 1 + 1)
            .storeUint(OP_EXCESSES, 32)
            .storeUint(queryId, 64);
        sendRawMessage(outMsg.endCell(), 2);
    }

    saveStorage(balance, ownerAddress, jettonMasterAddress, jettonWalletCode);
}

fun burnTokens(msgBody: slice, senderAddress: slice, msgValue: int, fwdFee: int) {
    var (balance, ownerAddress, jettonMasterAddress, jettonWalletCode) = loadStorage();
    val queryId = msgBody.loadUint(64);
    val jettonAmount = msgBody.loadCoins();
    val responseAddress = msgBody.loadAddress();
    // slice customPayload = msgBody.loadDict();
    balance -= jettonAmount;
    assert(isSliceBitsEqual(ownerAddress, senderAddress), 705);
    assert(balance >= 0, 706);
    assert(msgValue > fwdFee + 2 * REQUIRED_GAS, 707);

    val outMsgBody = beginCell()
        .storeUint(OP_BURN_NOTIFICATION, 32)
        .storeUint(queryId, 64)
        .storeCoins(jettonAmount)
        .storeSlice(ownerAddress)
        .storeSlice(responseAddress)
    .endCell();

    val outMsg = beginCell()
        .storeUint(0x18, 6)
        .storeSlice(jettonMasterAddress)
        .storeCoins(0)
        .storeUint(1, 1 + 4 + 4 + 64 + 32 + 1 + 1)
        .storeRef(outMsgBody);

    sendRawMessage(outMsg.endCell(), 64);

    saveStorage(balance, ownerAddress, jettonMasterAddress, jettonWalletCode);
}

fun onBounce(msgBody: slice) {
    msgBody.skipBits(32);
    var (balance, ownerAddress, jettonMasterAddress, jettonWalletCode) = loadStorage();
    val op = msgBody.loadUint(32);
    assert((op == OP_INTERNAL_TRANSFER) || (op == OP_BURN_NOTIFICATION), 709);
    val queryId = msgBody.loadUint(64);
    val jettonAmount = msgBody.loadCoins();
    balance += jettonAmount;
    saveStorage(balance, ownerAddress, jettonMasterAddress, jettonWalletCode);
}

fun onInternalMessage(myBalance: int, msgValue: int, msgFull: cell, msgBody: slice) {
    if (msgBody.isEndOfSlice()) { 
        return;
    }

    var cs = msgFull.beginParse();
    val flags = cs.loadUint(4);
    if (flags & 1) {
        onBounce(msgBody);
        return;
    }
    val senderAddress = cs.loadAddress();
    cs.loadAddress();
    cs.loadCoins(); 
    cs.skipBits(1); 
    cs.loadCoins(); 
    val fwdFee = cs.loadCoins(); 

    val op = msgBody.loadUint(32);

    if (op == OP_TRANSFER) { 
        sendTokens(msgBody, senderAddress, msgValue, fwdFee);
        return;
    }

    if (op == OP_INTERNAL_TRANSFER) { 
        receiveTokens(msgBody, senderAddress, myBalance, fwdFee, msgValue);
        return;
    }

    if (op == OP_BURN) { 
        burnTokens(msgBody, senderAddress, msgValue, fwdFee);
        return;
    }

    throw WRONG_OP;
}