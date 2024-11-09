tolk 0.6

import "errors.tolk"
import "op.tolk"
import "params.tolk"
import "storage.tolk"
import "../common/messages.tolk"

@inline
fun handleUserMessages(op: int, queryId: int, myBalance: int, msgValue: int, msgBody: slice) {
    if (op == OP_REFUND_ME) {
        assert((STORAGE_AMOUNT_0 > 0) || (STORAGE_AMOUNT_1 > 0), NO_LIQUIDITY);

        val msg = beginCell()
            .storeUint(OP_CB_REFUND_ME, 32)
            .storeUint(queryId, 64)
            .storeCoins(STORAGE_AMOUNT_0)
            .storeCoins(STORAGE_AMOUNT_1)
            .storeSlice(STORAGE_USER_ADDRESS);
        sendSimpleMessage(0, STORAGE_POOL_ADDRESS, msg.endCell(), CARRY_REMAINING_GAS);

        STORAGE_AMOUNT_0 = 0;
        STORAGE_AMOUNT_1 = 0;
        saveStorage();
        return;
    }

    if (op == OP_DIRECT_ADD_LIQUIDITY) {
        val am0 = msgBody.loadCoins();
        val am1 = msgBody.loadCoins();
        val minLpOut = msgBody.loadCoins();
        assert(minLpOut && ((am0 > 1000) && (am1 > 1000)), ZERO_OUTPUT);

        STORAGE_AMOUNT_0 -= am0;
        STORAGE_AMOUNT_1 -= am1;

        assert((STORAGE_AMOUNT_0 >= 0) && (STORAGE_AMOUNT_1 >= 0), NO_LIQUIDITY);

        val msg = beginCell()
            .storeUint(OP_CB_ADD_LIQUIDITY, 32)
            .storeUint(queryId, 64)
            .storeCoins(am0)
            .storeCoins(am1)
            .storeSlice(STORAGE_USER_ADDRESS)
            .storeCoins(minLpOut);
        sendSimpleMessage(0, STORAGE_POOL_ADDRESS, msg.endCell(), CARRY_REMAINING_GAS);

        saveStorage();
        return;
    }

    if (op == OP_RESET_GAS) { 
        assert(INSUFFICIENT_GAS, myBalance > REQUIRED_TON_RESERVE);
        sendEmptyMessage(myBalance - REQUIRED_TON_RESERVE, STORAGE_USER_ADDRESS, NORMAL);
        return;
    }

    throw WRONG_OP;
}