tolk 0.6

global STORAGE_IS_LOCKED: int;
global STORAGE_ADMIN_ADDRESS: slice; 
global STORAGE_JETTON_LP_WALLET_CODE: cell; 
global STORAGE_POOL_CODE: cell;
global STORAGE_LP_ACCOUNT_CODE: cell; 
global STORAGE_TEMP_UPGRADE: cell;

@inline
fun loadStorage() {
    var ds = getContractData().beginParse();
    STORAGE_IS_LOCKED = ds.loadUint(1);
    STORAGE_ADMIN_ADDRESS = ds.loadAddress();
    STORAGE_JETTON_LP_WALLET_CODE = ds.loadRef();
    STORAGE_POOL_CODE = ds.loadRef();
    STORAGE_LP_ACCOUNT_CODE = ds.loadRef();
    STORAGE_TEMP_UPGRADE = ds.loadRef();
}

@inline
fun saveStorage() {
    setContractData(beginCell()
        .storeUint(STORAGE_IS_LOCKED, 1)
        .storeSlice(STORAGE_ADMIN_ADDRESS)
        .storeRef(STORAGE_JETTON_LP_WALLET_CODE)
        .storeRef(STORAGE_POOL_CODE)
        .storeRef(STORAGE_LP_ACCOUNT_CODE)
        .storeRef(STORAGE_TEMP_UPGRADE)
    .endCell());
}