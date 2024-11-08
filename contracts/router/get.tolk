tolk 0.6

import "errors.tolk"
import "params.tolk"
import "storage.tolk"
import "utils.tolk"

// Get methods

get getPoolAddress(token0: slice, token1: slice): slice {
    loadStorage();
    assert(!equal_slices(token0, token1), WRONG_ADDRESS);
    forceChain(WORKCHAIN, token0, WRONG_WORKCHAIN);
    forceChain(WORKCHAIN, token1, WRONG_WORKCHAIN);
    val (_, poolAddress) = getPoolStateInitAndAddress(token0, token1);
    return poolAddress;
}

get getRouterData(): (int, slice, cell, cell, cell, cell) {
    loadStorage();
    return (
        STORAGE_IS_LOCKED == 1,
        STORAGE_ADMIN_ADDRESS,
        STORAGE_TEMP_UPGRADE,
        STORAGE_POOL_CODE,
        STORAGE_JETTON_LP_WALLET_CODE,
        STORAGE_LP_ACCOUNT_CODE
    );
}