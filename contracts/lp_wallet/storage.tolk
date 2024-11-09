tolk 0.6

import "jetton-utils.tolk"

@pure
fun loadStorage(): (int, slice, slice, cell) {
    var ds = getContractData().beginParse();
    return (ds.loadCoins(), ds.loadAddress(), ds.loadAddress(), ds.loadRef());
}

@inline
fun saveStorage(balance: int, ownerAddress: slice, jettonMasterAddress: slice, jettonWalletCode: cell) {
    setContractData(packJettonLpWalletData(balance, ownerAddress, jettonMasterAddress, jettonWalletCode));
}