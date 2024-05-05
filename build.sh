vasmm68k_mot -Fbin -o TestModeEntry.bin -nosym TestModeEntry.s -sc -showopt
srec_cat -o TestModeEntry_HIGH.bin -binary TestModeEntry.bin -binary -split 2 0
srec_cat -o TestModeEntry_LOW.bin -binary TestModeEntry.bin -binary -split 2 1