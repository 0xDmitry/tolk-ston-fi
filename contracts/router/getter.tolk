tolk 0.6

import "errors.tolk"
import "op.tolk"
import "params.tolk"
import "utils.tolk"
import "../common/utils.tolk"

// Onchain get methods

@inline
fun handleGetterMessages(op: int, queryId: int, senderAddress: slice, msgBody: slice): int {
    reserveToncoinsOnBalance(0, 4);

    if (op == OP_GETTER_POOL_ADDRESS){
        val token0 = msgBody.loadAddress();
        val token1 = msgBody.loadAddress();

        assert(!isSliceBitsEqual(token0, token1), WRONG_ADDRESS);
        forceChain(WORKCHAIN, token0, WRONG_WORKCHAIN);
        forceChain(WORKCHAIN, token1, WRONG_WORKCHAIN);

        val (_, poolAddress) = getPoolStateInitAndAddress(token0, token1);
        
        val payload = beginCell()
            .storeUint(OP_GETTER_POOL_ADDRESS, 32)
            .storeUint(queryId, 64)
            .storeSlice(poolAddress)
        .endCell();
        sendPayload(senderAddress, payload);
        return true;
    }

    // Wrong op.
    return false;
}