tolk 0.6

import "params.tolk"
import "storage.tolk"

@pure
@inline
fun getSerializedAddress(workchain: int, address: int): slice {
    return beginCell()
        .storeUint(4, 3)
        .storeUint(workchain, 8)
        .storeUint(address, 256)
    .endCell().beginParse();
}

@pure
@inline_ref
fun packPoolData(token0Address: slice, token1Address: slice, jettonLpWalletCode: cell, lpAccountCode: cell): cell {
    return beginCell()
        // STORAGE_ROUTER_ADDRESS
        .storeSlice(getMyAddress())
        // STORAGE_LP_FEE (0.2% * FEE_DIVIDER)
        .storeUint(20, 8)
        // STORAGE_PROTOCOL_FEE (0.1% * FEE_DIVIDER)
        .storeUint(10, 8)
        // STORAGE_REF_FEE (0.1% * FEE_DIVIDER)
        .storeUint(10, 8)
        // STORAGE_TOKEN0_ADDRESS
        .storeSlice(token0Address)
        // STORAGE_TOKEN1_ADDRESS
        .storeSlice(token1Address)
        // STORAGE_TOTAL_SUPPLY_LP
        .storeCoins(0)
        .storeRef(beginCell()
            // STORAGE_COLLECTED_TOKEN0_PROTOCOL_FEE
            .storeCoins(0)
            // STORAGE_COLLECTED_TOKEN1_PROTOCOL_FEE
            .storeCoins(0)
            // STORAGE_PROTOCOL_FEE_ADDRESS
            .storeSlice(HOLE_ADDRESS)
            // STORAGE_RESERVE_0
            .storeCoins(0)
            // STORAGE_RESERVE_1
            .storeCoins(0)
        .endCell())
        // STORAGE_JETTON_LP_WALLET_CODE
        .storeRef(jettonLpWalletCode)
        // STORAGE_LP_ACCOUNT_CODE
        .storeRef(lpAccountCode)
    .endCell();
}

@pure
@inline
fun getPoolStateInitAndAddress(token0Address: slice, token1Address: slice): (cell, slice) {
    var stateInitBuilder = beginCell()
        .storeUint(0, 2)
        .storeDict(STORAGE_POOL_CODE);

    if (sliceHash(token0Address) > sliceHash(token1Address)) {
        stateInitBuilder = stateInitBuilder.storeDict(packPoolData(token0Address, token1Address, STORAGE_JETTON_LP_WALLET_CODE, STORAGE_LP_ACCOUNT_CODE));
    } else {
        stateInitBuilder = stateInitBuilder.storeDict(packPoolData(token1Address, token0Address, STORAGE_JETTON_LP_WALLET_CODE, STORAGE_LP_ACCOUNT_CODE));
    }

    val stateInit = stateInitBuilder
        .storeUint(0, 1)
        .endCell();
    
    return (stateInit, getSerializedAddress(WORKCHAIN, cellHash(stateInit)));
}

@pure
@inline
fun packTempUpgrade(endCode: int, code: cell, endAdmin: int, admin: slice): cell {
    val data = beginCell()
        .storeUint(endCode, 64)
        .storeUint(endAdmin, 64)
        .storeSlice(admin)
        .storeRef(code)
    .endCell();
    return data;
}

@pure
@inline
fun unpackTempUpgrade(cData: cell): (int, cell, int, slice) {
    var sData = cData.beginParse();
    val endCode = sData.loadUint(64);
    val endAdmin = sData.loadUint(64);
    val admin = sData.loadAddress();
    val code = sData.loadRef();
    return (endCode, code, endAdmin, admin);
}