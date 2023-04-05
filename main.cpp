#include <stdio.h>

extern "C" int WrapPrintf(const char *format_string, ...);


int main() {
    const char *str1 = "Hello, World!";
    const char *str2 = "Love";
    WrapPrintf(
        "Dec: %d%p%e\nHex: %x\nOct: %o\nBin: %b\nChr: %c\nStr: %s\nPro: %%\n%d %s %x %d%%%c%b\n",
        2147483647, 2147483647, 2147483647, 2147483647, 0x21, str1, -1, str2, 3802, 100, 33, 127
    );

    return 0;
}
