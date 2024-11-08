tolk 0.6

global STORAGE_ROUTER_ADDRESS: slice;
global STORAGE_LP_FEE: int;
global STORAGE_PROTOCOL_FEE: int;
global STORAGE_REF_FEE: int;
global STORAGE_TOKEN_0_ADDRESS: slice;
global STORAGE_TOKEN_1_ADDRESS: slice;
global STORAGE_TOTAL_SUPPLY_LP: int; 
global STORAGE_COLLECTED_TOKEN_0_PROTOCOL_FEE: int;
global STORAGE_COLLECTED_TOKEN_1_PROTOCOL_FEE: int; 
global STORAGE_PROTOCOL_FEE_ADDRESS: slice;
global STORAGE_RESERVE_0: int;
global STORAGE_RESERVE_1: int; 
global STORAGE_JETTON_LP_WALLET_CODE: cell;
global STORAGE_LP_ACCOUNT_CODE: cell;

@inline
fun loadStorage() {
    var ds = getContractData().beginParse();
    STORAGE_ROUTER_ADDRESS = ds.loadAddress();
    STORAGE_LP_FEE = ds.loadUint(8);
    STORAGE_PROTOCOL_FEE = ds.loadUint(8);
    STORAGE_REF_FEE = ds.loadUint(8);
    STORAGE_TOKEN_0_ADDRESS = ds.loadAddress();
    STORAGE_TOKEN_1_ADDRESS = ds.loadAddress();
    STORAGE_TOTAL_SUPPLY_LP = ds.loadCoins(); 

    var ds0 = ds.loadRef().beginParse();
    STORAGE_COLLECTED_TOKEN_0_PROTOCOL_FEE = ds0.loadCoins();
    STORAGE_COLLECTED_TOKEN_1_PROTOCOL_FEE = ds0.loadCoins(); 
    STORAGE_PROTOCOL_FEE_ADDRESS = ds0.loadAddress();
    STORAGE_RESERVE_0 = ds0.loadCoins();
    STORAGE_RESERVE_1 = ds0.loadCoins(); 

    STORAGE_JETTON_LP_WALLET_CODE = ds.loadRef();
    STORAGE_LP_ACCOUNT_CODE = ds.loadRef();
}

@inline
fun saveStorage() {
    setContractData(beginCell()
        .storeSlice(STORAGE_ROUTER_ADDRESS)
        .storeUint(STORAGE_LP_FEE, 8) 
        .storeUint(STORAGE_PROTOCOL_FEE, 8) 
        .storeUint(STORAGE_REF_FEE, 8) 
        .storeSlice(STORAGE_TOKEN_0_ADDRESS)
        .storeSlice(STORAGE_TOKEN_1_ADDRESS) 
        .storeCoins(STORAGE_TOTAL_SUPPLY_LP)
        .storeRef(beginCell()
            .storeCoins(STORAGE_COLLECTED_TOKEN_0_PROTOCOL_FEE) 
            .storeCoins(STORAGE_COLLECTED_TOKEN_1_PROTOCOL_FEE) 
            .storeSlice(STORAGE_PROTOCOL_FEE_ADDRESS)
            .storeCoins(STORAGE_RESERVE_0) 
            .storeCoins(STORAGE_RESERVE_1)
        .endCell())
        .storeRef(STORAGE_JETTON_LP_WALLET_CODE)
        .storeRef(STORAGE_LP_ACCOUNT_CODE)
    .endCell());
}