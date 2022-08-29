fp32.s       - 32-bit fp package for 65816 for the ca65 assembler

fpu.txt      - Marco Granati's original 128-bit fp code

fp.s         - ca65 port of fpu.txt

inc/macro.s  - macros used by fp.s

# 128-bit FP Package Use
Marco’s package uses a good deal of the direct page.  Depending on how full your direct page is, you may need to create a separate one for his package.  I had to do this for my system.  I named the new segment DPFPU.  There is a trick to get the linker to recognize this new segment that obviously isn’t located at $0000 as a direct page.  You need to define the segment as:
 
    DPFPU:    load=DPFP, run=DP, type=rw;
 
Then DP is defined as a memory range as:
 
    DP:       start=$0000, size=$0100;
 
I think Marco intended the code to be assembled into Bank 0 but I didn’t have any problems putting my port into Bank 1.  Marco’s package requires all fp calls to be made with 8-bit registers, DBR set to Bank 0 and the direct page set to the fp package DP if it’s separate from you own.
 
Using the package very much depends on your system.  Marco uses two fp registers, the accumulator, or fac, and the argument, or arg.  You load the registers as appropriate before calling a fp function.  The result is normally placed in the fp accumulator where you can retrieve it.
 
All of the bank and direct page switching and loading/retrieving values to/from the registers adds a bit of overhead.  Add in the time to process 128-bit precision caused me to develop a 32-bit version (with a limited set of Marco's functions so far).  It’s about 5 ½ times faster than Marco’s 128-bit package at a Mandelbrot plot.
