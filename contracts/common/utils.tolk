tolk 0.6

import "messages.tolk"

// 0.04 TON
const FWD_GAS = 35000000; 

@inline_ref
fun sendPayload(caller: slice, payload: cell)  {
  val msg = beginCell()
    .storeUint(0x18, 6)
    .storeSlice(caller) 
    .storeCoins(0) 
    .storeUint(1, 1 + 4 + 4 + 64 + 32 + 1 + 1)
    .storeRef(payload)
  .endCell();
  sendRawMessage(msg, CARRY_ALL_BALANCE);
}

@pure
@inline
fun getWorkchain(address: slice): int  {
  val (wc, _) = parseStandardAddress(address);
  return wc;
}

@inline
fun forceChain(workchain: int, address: slice, errorCode: int) {
  val wc = getWorkchain(address);
  assert(wc == workchain, errorCode);
}