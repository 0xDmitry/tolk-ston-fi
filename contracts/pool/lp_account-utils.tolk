tolk 0.6

import "params.tolk"

@pure
@inline
fun packLpAccountData(userAddress: slice, poolAddress: slice, amount0: int, amount1: int): cell {
    return beginCell()
        .storeSlice(userAddress)
        .storeSlice(poolAddress)
        .storeCoins(amount0)
        .storeCoins(amount1)
    .endCell();
}

@pure
@inline
fun calculateLpAccountStateInit(userAddress: slice, poolAddress: slice, lpAccountCode: cell): cell {
    return beginCell()
        .storeUint(0, 2)
        .storeDict(lpAccountCode)
        .storeDict(packLpAccountData(userAddress, poolAddress, 0, 0))
        .storeUint(0, 1)
    .endCell();
}

@pure
@inline
fun calculateLpAccountAddress(stateInit: cell): slice {
    return beginCell()
        .storeUint(4, 3)
        .storeInt(WORKCHAIN, 8)
        .storeUint(cellHash(stateInit), 256)
    .endCell().beginParse();
}

@pure
@inline
fun calculateUserLpAccountAddress(userAddress: slice, poolAddress: slice, lpAccountCode: cell): slice {
    return calculateLpAccountAddress(calculateLpAccountStateInit(userAddress, poolAddress, lpAccountCode));
}