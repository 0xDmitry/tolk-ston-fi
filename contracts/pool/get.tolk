tolk 0.6

import "amm.tolk"
import "errors.tolk"
import "jetton-utils.tolk"
import "lp_account-utils.tolk"
import "params.tolk"
import "storage.tolk"
import "utils.tolk"

// Get methods

get getPoolData(): (int, int, slice, slice, int, int, int, slice, int, int) {
    loadStorage();
    return (
        STORAGE_RESERVE_0,
        STORAGE_RESERVE_1,
        STORAGE_TOKEN_0_ADDRESS,
        STORAGE_TOKEN_1_ADDRESS,
        STORAGE_LP_FEE,
        STORAGE_PROTOCOL_FEE, 
        STORAGE_REF_FEE,
        STORAGE_PROTOCOL_FEE_ADDRESS,
        STORAGE_COLLECTED_TOKEN_0_PROTOCOL_FEE, 
        STORAGE_COLLECTED_TOKEN_1_PROTOCOL_FEE
    );
}

get getExpectedOutputs(amount: int, tokenWallet: slice): (int, int, int) {
    loadStorage();
    assert(STORAGE_TOTAL_SUPPLY_LP > REQUIRED_MIN_LIQUIDITY, NO_LIQUIDITY);
    var out = 0;
    var protocolFeeOut = 0;
    var refFeeOut = 0;

    if (isSliceBitsEqual(tokenWallet, STORAGE_TOKEN_0_ADDRESS)) {
            (out, protocolFeeOut, refFeeOut) = getAmountOut(
            false, 
            amount, 
            STORAGE_RESERVE_0, 
            STORAGE_RESERVE_1
        );
    }
    if (isSliceBitsEqual(tokenWallet, STORAGE_TOKEN_1_ADDRESS)) {
            (out, protocolFeeOut, refFeeOut) = getAmountOut(
            false, 
            amount, 
            STORAGE_RESERVE_1, 
            STORAGE_RESERVE_0
        );
    }
    return ((out < 0 ? 0 : out), protocolFeeOut, refFeeOut);
}

// Estimate expected lp tokens minted when providing liquidity.
get getExpectedTokens(amount0: int, amount1: int): int {
    loadStorage();
    return min(amount0 * STORAGE_TOTAL_SUPPLY_LP / STORAGE_RESERVE_0, amount1 * STORAGE_TOTAL_SUPPLY_LP / STORAGE_RESERVE_1);
}

get getExpectedLiquidity(jettonAmount: int): (int, int) {
    loadStorage();
    assert(jettonAmount > 0, ZERO_OUTPUT); 

    val amount0Out = (jettonAmount * STORAGE_RESERVE_0) / STORAGE_TOTAL_SUPPLY_LP; 
    val amount1Out = (jettonAmount * STORAGE_RESERVE_1) / STORAGE_TOTAL_SUPPLY_LP; 
    
    assert((amount0Out > 0) && (amount1Out > 0), ZERO_OUTPUT);

    return (amount0Out, amount1Out);
}

get getLpAccountAddress(ownerAddress: slice): slice {
    loadStorage();
    return calculateUserLpAccountAddress(ownerAddress, getMyAddress(), STORAGE_LP_ACCOUNT_CODE); 
}

// Standard jetton 'get' methods

get getJettonData(): (int, int, slice, cell, cell) {
    loadStorage();
    val (_, hashpart) = parseStandardAddress(getMyAddress());

    val contentLp = beginCell()
        .storeUint(0x01, 8)
        .storeSlice(URI_BASE)
        .storeSlice(addressToHexString(hashpart))
        .storeSlice(URI_END)
    .endCell();

    return (STORAGE_TOTAL_SUPPLY_LP, -1, STORAGE_ROUTER_ADDRESS, contentLp, STORAGE_JETTON_LP_WALLET_CODE);
}

get getWalletAddress(ownerAddress: slice): slice {
    loadStorage();
    return calculateUserJettonLpWalletAddress(ownerAddress, getMyAddress(), STORAGE_JETTON_LP_WALLET_CODE); 
}