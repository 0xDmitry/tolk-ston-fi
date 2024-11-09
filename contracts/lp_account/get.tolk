tolk 0.6

import "storage.tolk"

// Get methods

get getLpAccountData(): (slice, slice, int, int) {
    loadStorage();
    return (STORAGE_USER_ADDRESS, STORAGE_POOL_ADDRESS, STORAGE_AMOUNT_0, STORAGE_AMOUNT_1);
}