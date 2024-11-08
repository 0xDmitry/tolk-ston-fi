tolk 0.6

const NORMAL = 0;
const PAID_EXTERNALLY = 1;
const IGNORE_ERRORS = 2;

const DESTROY_IF_ZERO = 32;
const CARRY_REMAINING_GAS = 64;
const CARRY_ALL_BALANCE = 128;

@inline_ref
fun sendEmptyMessage(amount: int, to: slice, mode: int) {
    val msg = beginCell()
        .storeUint(0x18, 6)
        .storeSlice(to)
        .storeCoins(amount)
        .storeUint(0, 107)
    .endCell();
    sendRawMessage(msg, mode);
}

@inline_ref
fun sendSimpleMessage(amount: int, to: slice, body: cell, mode: int) {
    val msg = beginCell()
        .storeUint(0x18, 6)
        .storeSlice(to)
        .storeCoins(amount)
        .storeUint(1, 107)
        .storeRef(body)
    .endCell();
    sendRawMessage(msg, mode);
}

@inline_ref
fun sendMessageNobounce(amount: int, to: slice, body: cell, mode: int) {
    val msg = beginCell()
        .storeUint(0x10, 6)
        .storeSlice(to)
        .storeCoins(amount)
        .storeUint(1, 107)
        .storeRef(body)
    .endCell();
    sendRawMessage(msg, mode);
}

@inline_ref
fun sendMessageWithStateInit(amount: int, to: slice, stateInit: cell, body: cell, mode: int) {
    val msg = beginCell()
        .storeUint(0x18, 6)
        .storeSlice(to)
        .storeCoins(amount)
        .storeUint(7, 108)
        .storeRef(stateInit)
        .storeRef(body)
    .endCell();
    sendRawMessage(msg, mode);
}