tolk 0.6

import "amm.tolk"
import "errors.tolk"
import "jetton-utils.tolk"
import "lp_account-utils.tolk"
import "op.tolk"
import "params.tolk"
import "storage.tolk"
import "utils.tolk"
import "../common/utils.tolk"

// Onchain get methods

@inline
fun handleGetterMessages(msgValue: int, fwdFee: int, op: int, queryId: int, senderAddress: slice, msgBody: slice): int {
    reserveToncoinsOnBalance(0, 4);

    if (op == OP_GETTER_POOL_DATA) { 
        var payload = beginCell()
            .storeUint(OP_GETTER_POOL_DATA, 32)
            .storeUint(queryId, 64)
            .storeCoins(STORAGE_RESERVE_0)
            .storeCoins(STORAGE_RESERVE_1)
            .storeSlice(STORAGE_TOKEN_0_ADDRESS)
            .storeSlice(STORAGE_TOKEN_1_ADDRESS)
            .storeRef(beginCell()
                .storeUint(STORAGE_LP_FEE, 8)
                .storeUint(STORAGE_PROTOCOL_FEE, 8)
                .storeUint(STORAGE_REF_FEE, 8)
                .storeSlice(STORAGE_PROTOCOL_FEE_ADDRESS)
                .storeCoins(STORAGE_COLLECTED_TOKEN_0_PROTOCOL_FEE)
                .storeCoins(STORAGE_COLLECTED_TOKEN_1_PROTOCOL_FEE)
            .endCell());
        sendPayload(senderAddress, payload.endCell());
        return true;
    }

    if (op == OP_GETTER_EXPECTED_OUTPUTS) { 
        assert(STORAGE_TOTAL_SUPPLY_LP > REQUIRED_MIN_LIQUIDITY, NO_LIQUIDITY);
        val amount = msgBody.loadCoins();
        val tokenWallet = msgBody.loadAddress();

        var out = 0;
        var ok = false;
        var protocolFeeOut = 0;
        var refFeeOut = 0;

        if (isSliceBitsEqual(tokenWallet, STORAGE_TOKEN_0_ADDRESS)) {
            ok = true;
            (out, protocolFeeOut, refFeeOut) = getAmountOut(false, amount, STORAGE_RESERVE_0, STORAGE_RESERVE_1);
        }
        if (isSliceBitsEqual(tokenWallet, STORAGE_TOKEN_1_ADDRESS)) {
            ok = true;
            (out, protocolFeeOut, refFeeOut) = getAmountOut(false, amount, STORAGE_RESERVE_1, STORAGE_RESERVE_0);
        }
    
        assert(ok, INVALID_TOKEN);
    
        val payload = beginCell()
            .storeUint(OP_GETTER_EXPECTED_OUTPUTS, 32)
            .storeUint(queryId, 64)
            .storeCoins((out <= 0 ? 0 : out))
            .storeCoins(protocolFeeOut)
            .storeCoins(refFeeOut);
        sendPayload(senderAddress, payload.endCell());
        return true;
    }

    if (op == OP_GETTER_LP_ACCOUNT_ADDRESS) { 
        val userAddress = msgBody.loadAddress();
    
        var payload = beginCell()
            // [ERR] Should be OP_GETTER_LP_ACCOUNT_ADDRESS
            .storeUint(OP_GETTER_EXPECTED_OUTPUTS, 32)
            .storeUint(queryId, 64)
            .storeSlice(calculateUserLpAccountAddress(userAddress, getMyAddress(), STORAGE_LP_ACCOUNT_CODE));
        sendPayload(senderAddress, payload.endCell());
        return true;
    }

    if (op == OP_GETTER_EXPECTED_TOKENS) { 
        val userAddress = msgBody.loadAddress();
        val amount0 = msgBody.loadCoins();
        val amount1 = msgBody.loadCoins();

        val toMint0 = (amount1 * STORAGE_TOTAL_SUPPLY_LP) / STORAGE_RESERVE_0;
        val toMint1 = (amount0 * STORAGE_TOTAL_SUPPLY_LP) / STORAGE_RESERVE_1;

        val liquidity = min(toMint0, toMint1);
    
        var payload = beginCell()
            .storeUint(OP_GETTER_EXPECTED_TOKENS, 32)
            .storeUint(queryId, 64)
            .storeCoins(liquidity);
        sendPayload(senderAddress, payload.endCell());
        return true;
    }

    if (op == OP_GETTER_EXPECTED_LIQUIDITY) { 
        val jettonAmount = msgBody.loadCoins();

        assert(jettonAmount > 0, ZERO_OUTPUT); 

        val amount0Out = (jettonAmount * STORAGE_RESERVE_0) / STORAGE_TOTAL_SUPPLY_LP; 
        val amount1Out = (jettonAmount * STORAGE_RESERVE_1) / STORAGE_TOTAL_SUPPLY_LP; 
      
        assert((amount0Out > 0) && (amount1Out > 0), ZERO_OUTPUT);

        var payload = beginCell()
            .storeUint(OP_GETTER_EXPECTED_LIQUIDITY, 32)
            .storeUint(queryId, 64)
            .storeCoins(amount0Out)
            .storeCoins(amount1Out);
        sendPayload(senderAddress, payload.endCell());
        return true;
    }

    if (op == OP_PROVIDE_WALLET_ADDRESS) {
        // Reference implementation:
        // https://github.com/ton-blockchain/token-contract/blob/920c5aa3a33ede6405b5653147895c9e27bfe535/ft/jetton-minter-discoverable.fc#L100
        assert(msgValue > fwdFee + PROVIDE_ADD_GAS_CONSUMPTION, 75);

        val ownerAddress = msgBody.loadAddress();
        val includeAddress = msgBody.loadUint(1);

        val includedAddress = includeAddress ? beginCell().storeSlice(ownerAddress).endCell() : null;

        var msg = beginCell()
            .storeUint(OP_TAKE_WALLET_ADDRESS, 32)
            .storeUint(queryId, 64);

        if (isResolvable(ownerAddress)) {
            msg = msg.storeSlice(calculateUserJettonLpWalletAddress(ownerAddress, getMyAddress(), STORAGE_JETTON_LP_WALLET_CODE));
        } else {
            // addr_none
            msg = msg.storeUint(0, 2);
        }

        sendPayload(senderAddress, msg.storeMaybeRef(includedAddress).endCell());
        return true;
    }
    
    // Wrong op.
    return false;
}