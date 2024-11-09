tolk 0.6

import "op.tolk"
import "storage.tolk"
import "../common/utils.tolk"

// Handle onchain 'get' calls

@inline
fun handleGetterMessages(op: int, queryId: int, senderAddress: slice, msgBody: slice): int {
    reserveToncoinsOnBalance(0, 4);

    if (op == OP_GETTER_LP_ACCOUNT_DATA) { 
        val payload = beginCell()
            .storeUint(OP_GETTER_LP_ACCOUNT_DATA, 32)
            .storeUint(queryId, 64)
            .storeSlice(STORAGE_USER_ADDRESS)
            .storeSlice(STORAGE_POOL_ADDRESS)
            .storeCoins(STORAGE_AMOUNT_0)
            .storeCoins(STORAGE_AMOUNT_1);
        sendPayload(senderAddress, payload.endCell());
        return true;
    }

    // Wrong op.
    return false;
}