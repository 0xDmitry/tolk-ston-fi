tolk 0.6

const OP_TRANSFER = 0xf8a7ea5;
const OP_TRANSFER_NOTIFICATION = 0x7362d09c;
const OP_INTERNAL_TRANSFER = 0x178d4519;
const OP_EXCESSES = 0xd53276db;
const OP_BURN = 0x595f07bc;
const OP_BURN_NOTIFICATION = 0x7bdd97de;

const OP_PROVIDE_WALLET_ADDRESS = 0x2c76b973;
const OP_TAKE_WALLET_ADDRESS = 0xd1735400;

const OP_SWAP = "swap"c;
const OP_PROVIDE_LP = "provide_lp"c;
const OP_PAY_TO = "pay_to"c;

// Swap callbacks opcodes.
const OP_SWAP_REFUND_NO_LIQ = "swap_refund_no_liq"c;
const OP_SWAP_REFUND_RESERVE_ERR = "swap_refund_reserve_err"c;

const OP_SWAP_OK_REF = "swap_ok_ref"c;
const OP_SWAP_OK = "swap_ok"c;
const OP_BURN_OK = "burn_ok"c;
const OP_REFUND_OK = "refund_ok"c;

const OP_COLLECT_FEES = "collect_fees"c;
const OP_SET_FEES = "set_fees"c;
const OP_RESET_GAS = "reset_gas"c;
const OP_ADD_LIQUIDITY = "add_liquidity"c;
const OP_CB_ADD_LIQUIDITY = "cb_add_liquidity"c;
const OP_CB_REFUND_ME = "cb_refund_me"c;

// Async "get" calls.
const OP_GETTER_POOL_DATA = "getter_pool_data"c;
const OP_GETTER_EXPECTED_OUTPUTS = "getter_expected_outputs"c;
const OP_GETTER_LP_ACCOUNT_ADDRESS = "getter_lp_account_address"c;
const OP_GETTER_EXPECTED_TOKENS = "getter_expected_tokens"c;
const OP_GETTER_EXPECTED_LIQUIDITY = "getter_expected_liquidity"c;