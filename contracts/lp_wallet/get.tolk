tolk 0.6

import "storage.tolk"

// Get methods

get getWalletData(): (int, slice, slice, cell) { 
  return loadStorage();
}