tolk 0.6

@pure
@inline
fun getGasConfigParam(wc: int): cell {
    if (wc == -1) {
        return getBlockchainConfigParam(20);
    } else {
        return getBlockchainConfigParam(21);
    }
}

@pure
@inline
fun loadGasFlatPfx(mutate self: slice): (int, int) {
    val flatGasLimit = self.loadUint(64);
    val flatGasPrice = self.loadUint(64);
    return (flatGasLimit, flatGasPrice);
}

@pure
@inline
fun loadGasPrices(mutate self: slice): int  {
    var gasPrice = self.loadUint(64);
    return gasPrice;
}

@pure
@inline_ref
fun loadGasLimitsPrices(mutate self: slice): (int, int, int)  {
    val contructorTag = self.loadUint(8);
    if (contructorTag == 0xd1) {
        val (flatGasLimit, flatGasPrice) = self.loadGasFlatPfx();
        val (_, _, gasPrice) = self.loadGasLimitsPrices();
        return (flatGasLimit, flatGasPrice, gasPrice);
    } else if ((contructorTag == 0xde) || (contructorTag == 0xdd)) {
        var gasPrice = self.loadGasPrices();
        return (0, 0, gasPrice);
    } else {
        return (0, 0, 0);
    }
}

@pure
@inline
fun getGasLimitsPrices(wc: int): (int, int, int) {
    var gasPriceConfig = getGasConfigParam(wc).beginParse();
    return gasPriceConfig.loadGasLimitsPrices();
}

@pure
@inline_ref
fun getGasFee(gasAmount: int, wc: int): int {
    val (flatGasLimit, flatGasPrice, gasPrice) = getGasLimitsPrices(wc);
    return gasAmount < flatGasLimit ? flatGasPrice : (gasAmount - flatGasLimit) * (gasPrice >> 16) + flatGasPrice;
}