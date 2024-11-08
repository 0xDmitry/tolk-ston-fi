tolk 0.6

import "op.tolk"
import "params.tolk"
import "storage.tolk"
import "../common/messages.tolk"
import "../common/stdlib.tolk"

@pure
@inline
fun sqrt(x: int): int {
    if (x == 0) {
        return x; 
    }

    var r = 181;
    var xx = x;
    if (xx >= 0x100000000000000000000000000000000) {
        xx >>= 128;
        r <<= 64;
    }
    if (xx >= 0x10000000000000000) {
        xx >>= 64;
        r <<= 32;
    }
    if (xx >= 0x100000000) {
        xx >>= 32;
        r <<= 16;
    }
    if (xx >= 0x10000) {
        xx >>= 16;
        r <<= 8;
    }

    r = (r * (xx + 65536)) >> 18;

    repeat(7) {
        r = (r + x / r) >> 1;
    }

    val r1 = x / r;

    return (r < r1 ? r : r1);
}

@inline_ref
fun callPayTo(amount: int, mode: int, queryId: int, toAddress: slice, exitCode: int, amount0Out: int, amount1Out: int) {
    var body = beginCell()
        .storeUint(OP_PAY_TO, 32)
        .storeUint(queryId, 64)
        .storeSlice(toAddress)
        .storeUint(exitCode, 32)
        .storeUint(1, 1)
        .storeRef(beginCell()
            .storeCoins(amount0Out) 
            .storeSlice(STORAGE_TOKEN_0_ADDRESS)
            .storeCoins(amount1Out)
            .storeSlice(STORAGE_TOKEN_1_ADDRESS)
        .endCell());
    sendMessageNobounce(amount, STORAGE_ROUTER_ADDRESS, body.endCell(), mode);
}

@pure
@inline
fun isResolvable(addr: slice): int {
    val (wc, _) = parseStandardAddress(addr);
    return wc == WORKCHAIN;
}

@pure
@inline
fun addressToHexString(value: int): slice {
    if (value == 0) {
        var buffer = beginCell();
        var i = 0;
        while (i < 64){
            buffer = buffer.storeUint("0"u, 8);
            i += 1;
        }
        return buffer.endCell().beginParse().preloadBits(i * 8);
    } else {
        var j = value;
        var length = 0;
        while (j != 0) {
            length += 1;
            j = j >> 4;
        }
    
        val mask = 15;
        var buffer = beginCell();

        while (value != 0) {
            val curr = (value & mask);
            if (curr > 9) {
                buffer = buffer.storeUint(55 + curr, 8);
            } else {
                buffer = buffer.storeUint(48 + curr, 8);
            }
            value = value >> 4;
        }

        var finalCell = beginCell();

        val reversedBuffer = buffer.endCell().beginParse();
        var i = 64;
        while (i > 0) {
            i -= 1;
            val chr = reversedBuffer.preloadBitsOffset(i * 8, 8);
            finalCell = finalCell.storeSlice(chr);
        }
        return finalCell.endCell().beginParse().preloadBits(512);
    }
}