tolk 0.6

global STORAGE_USER_ADDRESS: slice;
global STORAGE_POOL_ADDRESS: slice; 
global STORAGE_AMOUNT_0: int;
global STORAGE_AMOUNT_1: int;

@inline
fun loadStorage() {
    var ds = getContractData().beginParse();
    STORAGE_USER_ADDRESS = ds.loadAddress();
    STORAGE_POOL_ADDRESS = ds.loadAddress(); 
    STORAGE_AMOUNT_0 = ds.loadCoins();
    STORAGE_AMOUNT_1 = ds.loadCoins();
}

@inline
fun saveStorage() {
    setContractData(beginCell()
        .storeSlice(STORAGE_USER_ADDRESS)
        .storeSlice(STORAGE_POOL_ADDRESS)
        .storeCoins(STORAGE_AMOUNT_0)
        .storeCoins(STORAGE_AMOUNT_1)
    .endCell());
}