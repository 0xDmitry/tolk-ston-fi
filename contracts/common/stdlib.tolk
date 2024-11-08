// stdlib++

@pure
fun mod (x: int, y: int): int
    asm "MOD";

@pure 
fun divc (x: int, y: int): int
    asm "DIVC";

@pure
fun preloadBitsOffset(s: slice, offset: int, len: int): slice
    asm "SDSUBSTR";