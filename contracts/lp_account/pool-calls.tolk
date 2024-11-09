tolk 0.6

import "errors.tolk"
import "op.tolk"
import "storage.tolk"
import "../common/utils.tolk"

// Handle pool calls

@inline
fun handlePoolMessages(op: int, queryId: int, myBalance: int, msgValue: int, msgBody: slice) {
    if (op == OP_ADD_LIQUIDITY) { 
        val newAmount0 = msgBody.loadCoins();
        val newAmount1 = msgBody.loadCoins();
        val minLpOut = msgBody.loadCoins();

        STORAGE_AMOUNT_0 += new_amount0;
        STORAGE_AMOUNT_1 += new_amount1;

        if (minLpOut && ((STORAGE_AMOUNT_0 > 1000) && (STORAGE_AMOUNT_1 > 1000))){
            val msg = beginCell()
                .storeUint(OP_CB_ADD_LIQUIDITY, 32)
                .storeUint(queryId, 64)
                .storeCoins(STORAGE_AMOUNT_0)
                .storeCoins(STORAGE_AMOUNT_1)
                .storeSlice(STORAGE_USER_ADDRESS)
                .storeCoins(minLpOut);
            sendPayload(STORAGE_POOL_ADDRESS, msg.endCell());
            STORAGE_AMOUNT_0 = 0;
            STORAGE_AMOUNT_1 = 0;
        }

        saveStorage();
        return;
    }
    
    throw WRONG_OP;
}