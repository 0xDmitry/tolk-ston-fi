tolk 0.6

@pure
@inline
fun createSimpleTransferBody(queryId: int, fwdAmount: int, jettonAmount: int, to: slice): builder {
    return beginCell()
        .storeUint(0xf8a7ea5, 32)
        .storeUint(queryId, 64)
        .storeCoins(jettonAmount)
        // to_owner_address
        .storeSlice(to)
        .storeSlice(to)
        .storeUint(0, 1)
        // forward_ton_amount
        .storeCoins(fwdAmount)
        .storeUint(0, 1);
}