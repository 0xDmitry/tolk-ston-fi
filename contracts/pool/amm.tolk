tolk 0.6

import "jetton-utils.tolk"
import "op.tolk"
import "params.tolk"
import "storage.tolk"
import "../common/messages.tolk"
import "../common/stdlib.tolk"

@pure
@inline
fun getAmountOut(hasRef: int, amountIn: int, reserveIn: int, reserveOut: int): (int, int, int) {
    val amountInWithFee = amountIn * (FEE_DIVIDER - STORAGE_LP_FEE);
    var baseOut = (amountInWithFee * reserveOut) / (reserveIn * FEE_DIVIDER + amountInWithFee);
    
    var protocolFeeOut = 0;
    var refFeeOut = 0;

    if (STORAGE_PROTOCOL_FEE > 0) {
        protocolFeeOut = divc(baseOut * STORAGE_PROTOCOL_FEE, FEE_DIVIDER);
    }
    
    if ((hasRef == 1) && (STORAGE_REF_FEE > 0)) {
        refFeeOut = divc(baseOut * STORAGE_REF_FEE, FEE_DIVIDER);
    }
    
    baseOut -= protocolFeeOut + refFeeOut;
    return (baseOut, protocolFeeOut, refFeeOut);
}

@inline
fun mintLp(queryId: int, to: slice, amount: int) {
    val stateInit = calculateJettonLpWalletStateInit(to, getMyAddress(), STORAGE_JETTON_LP_WALLET_CODE);
    val toWalletAddress = calculateJettonLpWalletAddress(stateInit);
    var body = beginCell()
        .storeUint(OP_INTERNAL_TRANSFER, 32)
        .storeUint(queryId, 64)
        .storeCoins(amount)
        .storeSlice(getMyAddress())
        .storeSlice(to)
        .storeCoins(0) 
        .storeUint(0, 1);
    sendMessageWithStateInit(0, toWalletAddress, stateInit, body.endCell(), CARRY_REMAINING_GAS);
}