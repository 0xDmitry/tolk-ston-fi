tolk 0.6

import "params.tolk"

@pure
@inline
fun packJettonLpWalletData(balance: int, ownerAddress: slice, jettonMasterAddress: slice, jettonWalletCode: cell): cell {
    return beginCell()
        .storeCoins(balance)
        .storeSlice(ownerAddress)
        .storeSlice(jettonMasterAddress)
        .storeRef(jettonWalletCode)
    .endCell();
}

@pure
@inline
fun calculateJettonLpWalletStateInit(ownerAddress: slice, jettonMasterAddress: slice, jettonWalletCode: cell): cell {
    return beginCell()
        .storeUint(0, 2)
        .storeDict(jettonWalletCode)
        .storeDict(packJettonLpWalletData(0, ownerAddress, jettonMasterAddress, jettonWalletCode))
        .storeUint(0, 1)
    .endCell();
}

@pure
@inline
fun calculateJettonLpWalletAddress(stateInit: cell): slice {
    return beginCell()
        .storeUint(4, 3)
        .storeInt(WORKCHAIN, 8)
        .storeUint(cellHash(stateInit), 256)
    .endCell().beginParse();
}

@pure
@inline
fun calculateUserJettonLpWalletAddress(ownerAddress: slice, jettonMasterAddress: slice, jettonWalletCode: cell): slice {
    return calculateJettonLpWalletAddress(calculateJettonLpWalletStateInit(ownerAddress, jettonMasterAddress, jettonWalletCode));
}