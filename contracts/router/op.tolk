tolk 0.6

const OP_TRANSFER = 0xf8a7ea5;
const OP_TRANSFER_NOTIFICATION = 0x7362d09c;

const OP_SWAP = "swap"c;
const OP_PROVIDE_LP = "provide_lp"c;
const OP_PAY_TO = "pay_to"c;
const OP_COLLECT_FEES = "collect_fees"c;
const OP_SET_FEES = "set_fees"c;
const OP_RESET_GAS = "reset_gas"c;
const OP_RESET_POOL_GAS = "reset_pool_gas"c;
const OP_LOCK = "lock"c;
const OP_UNLOCK = "unlock"c;

const OP_INIT_CODE_UPGRADE = "init_code_upgrade"c;
const OP_INIT_ADMIN_UPGRADE = "init_admin_upgrade"c;
const OP_CANCEL_CODE_UPGRADE = "cancel_code_upgrade"c;
const OP_CANCEL_ADMIN_UPGRADE = "cancel_admin_upgrade"c;
const OP_FINALIZE_UPGRADES = "finalize_upgrades"c;

// Async "get" calls.
const OP_GETTER_POOL_ADDRESS = "getter_pool_address"c;

// Transfer refund statuses.
const OP_TRANSFER_BOUNCE_LOCKED = "transfer_bounce_locked"c;
const OP_TRANSFER_BOUNCE_INVALID_REQUEST = "transfer_bounce_invalid_request"c;