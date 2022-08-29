decimal
t{  0.0 0.0 f+ >ieee32 fdrop -> $00000000. }t
t{ -0.0 0.0 f+ >ieee32 fdrop -> $80000000. }t \ -0.0
t{  0.0 1.0 f+ >ieee32 fdrop -> $3F800000. }t
t{  1.0 0.0 f+ >ieee32 fdrop -> $3F800000. }t
t{ -0.0 1.0 f+ >ieee32 fdrop -> $3F800000. }t
t{ 1.0 -0.0 f+ >ieee32 fdrop -> $3F800000. }t
t{ -1.0 1.0 f+ >ieee32 fdrop -> $80000000. }t \ -0.0
t{ 1.0 -1.0 f+ >ieee32 fdrop -> $00000000. }t
t{ 1.0 1.0 f+ >ieee32 fdrop -> $40000000. }t
t{ 2.0 1.0 f+ >ieee32 fdrop -> $40400000. }t
t{ 1.0 2.0 f+ >ieee32 fdrop -> $40400000. }t
t{ 2.0 3.0 f+ >ieee32 fdrop -> $40A00000. }t
t{ 3.0 2.0 f+ >ieee32 fdrop -> $40A00000. }t
t{ -2.0 1.0 f+ >ieee32 fdrop -> $BF800000. }t
t{ -1.0 2.0 f+ >ieee32 fdrop -> $3F800000. }t
t{ -2.0 3.0 f+ >ieee32 fdrop -> $3F800000. }t
t{ -3.0 2.0 f+ >ieee32 fdrop -> $BF800000. }t
t{ 2.0 -1.0 f+ >ieee32 fdrop -> $3F800000. }t
t{ 1.0 -2.0 f+ >ieee32 fdrop -> $BF800000. }t
t{ 2.0 -3.0 f+ >ieee32 fdrop -> $BF800000. }t
t{ 3.0 -2.0 f+ >ieee32 fdrop -> $3F800000. }t
t{ -2.0 -1.0 f+ >ieee32 fdrop -> $C0400000. }t
t{ -1.0 -2.0 f+ >ieee32 fdrop -> $C0400000. }t
t{ -2.0 -3.0 f+ >ieee32 fdrop -> $C0A00000. }t
t{ -3.0 -2.0 f+ >ieee32 fdrop -> $C0A00000. }t

t{  0.0 0.0 f- >ieee32 fdrop -> $00000000. }t
t{ -0.0 0.0 f- >ieee32 fdrop -> $80000000. }t \ -0.0
t{  0.0 1.0 f- >ieee32 fdrop -> $BF800000. }t
t{  1.0 0.0 f- >ieee32 fdrop -> $3F800000. }t
t{ -0.0 1.0 f- >ieee32 fdrop -> $BF800000. }t
t{ 1.0 -0.0 f- >ieee32 fdrop -> $3F800000. }t
t{ -1.0 1.0 f- >ieee32 fdrop -> $C0000000. }t
t{ 1.0 -1.0 f- >ieee32 fdrop -> $40000000. }t

t{ 2.0 1.0 f- >ieee32 fdrop -> $3F800000. }t
t{ 1.0 2.0 f- >ieee32 fdrop -> $BF800000. }t
t{ 2.0 3.0 f- >ieee32 fdrop -> $BF800000. }t
t{ 3.0 2.0 f- >ieee32 fdrop -> $3F800000. }t
t{ -2.0 1.0 f- >ieee32 fdrop -> $C0400000. }t
t{ -1.0 2.0 f- >ieee32 fdrop -> $C0400000. }t
t{ -2.0 3.0 f- >ieee32 fdrop -> $C0A00000. }t
t{ -3.0 2.0 f- >ieee32 fdrop -> $C0A00000. }t
t{ 2.0 -1.0 f- >ieee32 fdrop -> $40400000. }t
t{ 1.0 -2.0 f- >ieee32 fdrop -> $40400000. }t
t{ 2.0 -3.0 f- >ieee32 fdrop -> $40A00000. }t
t{ 3.0 -2.0 f- >ieee32 fdrop -> $40A00000. }t
t{ -2.0 -1.0 f- >ieee32 fdrop -> $BF800000. }t
t{ -1.0 -2.0 f- >ieee32 fdrop -> $3F800000. }t
t{ -2.0 -3.0 f- >ieee32 fdrop -> $3F800000. }t
t{ -3.0 -2.0 f- >ieee32 fdrop -> $BF800000. }t
t{ 1e-32 1e-2 f+ >ieee32 fdrop -> $3C23D70A. }t
t{ 1e-2 1e-32 f+ >ieee32 fdrop -> $3C23D70A. }t
t{ 1e-32 1e-2 f- >ieee32 fdrop -> $BC23D70A. }t
t{ 1e-2 1e-32 f- >ieee32 fdrop -> $3C23D70A. }t

t{  0.0 0.0 f* >ieee32 fdrop -> $00000000. }t
t{ -0.0 0.0 f* >ieee32 fdrop -> $00000000. }t
t{  0.0 0.0 f* >ieee32 fdrop -> $00000000. }t
t{ -0.0 -0.0 f* >ieee32 fdrop -> $00000000. }t
t{  0.0 1.0 f* >ieee32 fdrop -> $00000000. }t
t{  1.0 0.0 f* >ieee32 fdrop -> $00000000. }t
t{ -0.0 1.0 f* >ieee32 fdrop -> $80000000. }t \ -0.0
t{ 1.0 -0.0 f* >ieee32 fdrop -> $80000000. }t \ -0.0

t{ 1.0 1.0 f* >ieee32 fdrop -> $3F800000. }t
t{ 2.0 1.0 f* >ieee32 fdrop -> $40000000. }t
t{ 1.0 2.0 f* >ieee32 fdrop -> $40000000. }t
t{ 2.0 3.0 f* >ieee32 fdrop -> $40C00000. }t
t{ 3.0 2.0 f* >ieee32 fdrop -> $40C00000. }t
t{ -1.0 1.0 f* >ieee32 fdrop -> $BF800000. }t
t{ -2.0 1.0 f* >ieee32 fdrop -> $C0000000. }t
t{ -1.0 2.0 f* >ieee32 fdrop -> $C0000000. }t
t{ -2.0 3.0 f* >ieee32 fdrop -> $C0C00000. }t
t{ -3.0 2.0 f* >ieee32 fdrop -> $C0C00000. }t
t{ 1.0 -1.0 f* >ieee32 fdrop -> $BF800000. }t
t{ 2.0 -1.0 f* >ieee32 fdrop -> $C0000000. }t
t{ 1.0 -2.0 f* >ieee32 fdrop -> $C0000000. }t
t{ 2.0 -3.0 f* >ieee32 fdrop -> $C0C00000. }t
t{ 3.0 -2.0 f* >ieee32 fdrop -> $C0C00000. }t
t{ -1.0 -1.0 f* >ieee32 fdrop -> $3F800000. }t
t{ -2.0 -1.0 f* >ieee32 fdrop -> $40000000. }t
t{ -1.0 -2.0 f* >ieee32 fdrop -> $40000000. }t
t{ -2.0 -3.0 f* >ieee32 fdrop -> $40C00000. }t
t{ -3.0 -2.0 f* >ieee32 fdrop -> $40C00000. }t

t{  0.0 1.0 f/ >ieee32 fdrop -> $00000000. }t
t{ 0.0 -1.0 f/ >ieee32 fdrop -> $80000000. }t \ -0.0
t{ -0.0 1.0 f/ >ieee32 fdrop -> $80000000. }t \ -0.0
t{ 0.0 -1.0 f/ >ieee32 fdrop -> $80000000. }t \ -0.0
t{ -0.0 -1.0 f/ >ieee32 fdrop -> $00000000. }t

t{ 1.0 1.0 f/ >ieee32 fdrop -> $3F800000. }t
t{ 2.0 1.0 f/ >ieee32 fdrop -> $40000000. }t
t{ 1.0 2.0 f/ >ieee32 fdrop -> $3F000000. }t
t{ 2.0 3.0 f/ >ieee32 fdrop -> $3F2AAAAB. }t
t{ 3.0 2.0 f/ >ieee32 fdrop -> $3FC00000. }t
t{ -1.0 -1.0 f/ >ieee32 fdrop -> $3F800000. }t
t{ -2.0 -1.0 f/ >ieee32 fdrop -> $40000000. }t
t{ -1.0 -2.0 f/ >ieee32 fdrop -> $3F000000. }t
t{ -2.0 -3.0 f/ >ieee32 fdrop -> $3F2AAAAB. }t
t{ -3.0 -2.0 f/ >ieee32 fdrop -> $3FC00000. }t
t{ 1.0 -1.0 f/ >ieee32 fdrop -> $BF800000. }t
t{ 2.0 -1.0 f/ >ieee32 fdrop -> $C0000000. }t
t{ 1.0 -2.0 f/ >ieee32 fdrop -> $BF000000. }t
t{ 2.0 -3.0 f/ >ieee32 fdrop -> $BF2AAAAB. }t
t{ 3.0 -2.0 f/ >ieee32 fdrop -> $BFC00000. }t
t{ -1.0 1.0 f/ >ieee32 fdrop -> $BF800000. }t
t{ -2.0 1.0 f/ >ieee32 fdrop -> $C0000000. }t
t{ -1.0 2.0 f/ >ieee32 fdrop -> $BF000000. }t
t{ -2.0 3.0 f/ >ieee32 fdrop -> $BF2AAAAB. }t
t{ -3.0 2.0 f/ >ieee32 fdrop -> $BFC00000. }t

t{  0.0 f^2 >ieee32 fdrop -> $00000000. }t
t{ -0.0 f^2 >ieee32 fdrop -> $00000000. }t
t{ 1.0 f^2 >ieee32 fdrop -> $3F800000. }t
t{ 2.0 f^2 >ieee32 fdrop -> $40800000. }t
t{ 3.0 f^2 >ieee32 fdrop -> $41100000. }t
t{ -1.0 f^2 >ieee32 fdrop -> $3F800000. }t
t{ -2.0 f^2 >ieee32 fdrop -> $40800000. }t
t{ -3.0 f^2 >ieee32 fdrop -> $41100000. }t

t{ 3 0 d>f >ieee32 fdrop -> $40400000. }t
t{ -3 -1 d>f >ieee32 fdrop -> $C0400000. }t
t{ 123.456 f>d -> 123. }t
t{ -123.456 f>d -> -123. }t

t{  0.0  ftrunc >ieee32 fdrop -> $00000000. }t
t{ -0.0  ftrunc >ieee32 fdrop -> $80000000. }t \ -0.0
t{  0.9  ftrunc >ieee32 fdrop -> $00000000. }t
t{  1e-9 ftrunc >ieee32 fdrop -> $00000000. }t
t{ -1e-9 ftrunc >ieee32 fdrop -> $80000000. }t \ -0.0
t{ -0.9  ftrunc >ieee32 fdrop -> $80000000. }t \ -0.0
t{ -1.0 1e-5 f+  ftrunc >ieee32 fdrop -> $80000000. }t \ -0.0
t{ -1.0 -1e-5 f+  ftrunc >ieee32 fdrop -> $BF800000. }t
t{  3.14  ftrunc >ieee32 fdrop -> $40400000. }t
t{  3.99  ftrunc >ieee32 fdrop -> $40400000. }t
t{  4.0  ftrunc >ieee32 fdrop -> $40800000. }t
t{  4.1  ftrunc >ieee32 fdrop -> $40800000. }t
t{ -4.0  ftrunc >ieee32 fdrop -> $C0800000. }t
t{ -4.1  ftrunc >ieee32 fdrop -> $C0800000. }t

t{  3.8 fround >ieee32 fdrop -> $40800000. }t
t{  3.4 fround >ieee32 fdrop -> $40400000. }t
t{  0.5 fround >ieee32 fdrop -> $3F800000. }t
t{  0.4 fround >ieee32 fdrop -> $00000000. }t
t{ -0.4 fround >ieee32 fdrop -> $80000000. }t \ -0.0
t{ -0.5 fround >ieee32 fdrop -> $BF800000. }t
t{ -3.4 fround >ieee32 fdrop -> $C0400000. }t
t{ -3.8 fround >ieee32 fdrop -> $C0800000. }t

t{  0.5 floor >ieee32 fdrop -> $00000000. }t
t{ -0.5 floor >ieee32 fdrop -> $BF800000. }t
t{  3.0 floor >ieee32 fdrop -> $40400000. }t
t{ -3.0 floor >ieee32 fdrop -> $C0400000. }t
t{  2.3 floor >ieee32 fdrop -> $40000000. }t
t{ -2.3 floor >ieee32 fdrop -> $C0400000. }t

t{  0.0  0.0 f< ->  0 }t
t{ -0.0  0.0 f< ->  0 }t
t{  0.0  1.0 f< -> -1 }t
t{  1.0  0.0 f< ->  0 }t
t{ -0.0  1.0 f< -> -1 }t
t{  1.0 -0.0 f< ->  0 }t
t{ -1.0  1.0 f< -> -1 }t
t{  1.0 -1.0 f< ->  0 }t
t{  1.0  1.0 f< ->  0 }t
t{  2.0  1.0 f< ->  0 }t
t{  1.0  2.0 f< -> -1 }t
t{  2.0  3.0 f< -> -1 }t
t{  3.0  2.0 f< ->  0 }t
t{ -2.0  1.0 f< -> -1 }t
t{ -1.0  2.0 f< -> -1 }t
t{ -2.0  3.0 f< -> -1 }t
t{ -3.0  2.0 f< -> -1 }t
t{  2.0 -1.0 f< ->  0 }t
t{  1.0 -2.0 f< ->  0 }t
t{  2.0 -3.0 f< ->  0 }t
t{  3.0 -2.0 f< ->  0 }t
t{ -2.0 -1.0 f< -> -1 }t
t{ -1.0 -2.0 f< ->  0 }t
t{ -2.0 -3.0 f< ->  0 }t
t{ -3.0 -2.0 f< -> -1 }t

t{  0.0 f0< ->  0 }t
t{ -0.0 f0< ->  0 }t
t{  1.0 f0< ->  0 }t
t{  2.0 f0< ->  0 }t
t{  3.0 f0< ->  0 }t
t{ -1.0 f0< -> -1 }t
t{ -2.0 f0< -> -1 }t
t{ -3.0 f0< -> -1 }t

t{  0.0 f0= -> -1 }t
t{ -0.0 f0= -> -1 }t
t{  1.0 f0= ->  0 }t
t{ -1.0 f0= ->  0 }t
t{  2.0 f0= ->  0 }t
t{  3.0 f0= ->  0 }t
t{ -2.0 f0= ->  0 }t
t{ -3.0 f0= ->  0 }t

t{  0.0 0.0  fmin >ieee32 fdrop -> $00000000. }t
t{ -0.0 0.0  fmin >ieee32 fdrop -> $80000000. }t \ -0.0
t{  0.0 1.0  fmin >ieee32 fdrop -> $00000000. }t
t{  1.0 0.0  fmin >ieee32 fdrop -> $00000000. }t
t{ -0.0 1.0  fmin >ieee32 fdrop -> $80000000. }t \ -0.0
t{ 1.0 -0.0  fmin >ieee32 fdrop -> $80000000. }t \ -0.0
t{ -1.0 1.0  fmin >ieee32 fdrop -> $BF800000. }t
t{ 1.0 -1.0  fmin >ieee32 fdrop -> $BF800000. }t
t{  1.0 1.0  fmin >ieee32 fdrop -> $3F800000. }t
t{  2.0 1.0  fmin >ieee32 fdrop -> $3F800000. }t
t{  1.0 2.0  fmin >ieee32 fdrop -> $3F800000. }t
t{  2.0 3.0  fmin >ieee32 fdrop -> $40000000. }t
t{  3.0 2.0  fmin >ieee32 fdrop -> $40000000. }t
t{ -2.0 1.0  fmin >ieee32 fdrop -> $C0000000. }t
t{ -1.0 2.0  fmin >ieee32 fdrop -> $BF800000. }t
t{ -2.0 3.0  fmin >ieee32 fdrop -> $C0000000. }t
t{ -3.0 2.0  fmin >ieee32 fdrop -> $C0400000. }t
t{ 2.0 -1.0  fmin >ieee32 fdrop -> $BF800000. }t
t{ 1.0 -2.0  fmin >ieee32 fdrop -> $C0000000. }t
t{ 2.0 -3.0  fmin >ieee32 fdrop -> $C0400000. }t
t{ 3.0 -2.0  fmin >ieee32 fdrop -> $C0000000. }t
t{ -2.0 -1.0 fmin >ieee32 fdrop -> $C0000000. }t
t{ -1.0 -2.0 fmin >ieee32 fdrop -> $C0000000. }t
t{ -2.0 -3.0 fmin >ieee32 fdrop -> $C0400000. }t
t{ -3.0 -2.0 fmin >ieee32 fdrop -> $C0400000. }t
t{  3.5  3.4 fmin >ieee32 fdrop -> $4059999A. }t
t{  3.4  3.5 fmin >ieee32 fdrop -> $4059999A. }t
t{ -3.5 -3.4 fmin >ieee32 fdrop -> $C0600000. }t
t{ -3.4 -3.5 fmin >ieee32 fdrop -> $C0600000. }t

t{  0.0 0.0  fmax >ieee32 fdrop -> $00000000. }t
t{ -0.0 0.0  fmax >ieee32 fdrop -> $00000000. }t
t{  0.0 1.0  fmax >ieee32 fdrop -> $3F800000. }t
t{  1.0 0.0  fmax >ieee32 fdrop -> $3F800000. }t
t{ -0.0 1.0  fmax >ieee32 fdrop -> $3F800000. }t
t{ 1.0 -0.0  fmax >ieee32 fdrop -> $3F800000. }t
t{ -1.0 1.0  fmax >ieee32 fdrop -> $3F800000. }t
t{ 1.0 -1.0  fmax >ieee32 fdrop -> $3F800000. }t
t{  1.0 1.0  fmax >ieee32 fdrop -> $3F800000. }t
t{  2.0 1.0  fmax >ieee32 fdrop -> $40000000. }t
t{  1.0 2.0  fmax >ieee32 fdrop -> $40000000. }t
t{  2.0 3.0  fmax >ieee32 fdrop -> $40400000. }t
t{  3.0 2.0  fmax >ieee32 fdrop -> $40400000. }t
t{ -2.0 1.0  fmax >ieee32 fdrop -> $3F800000. }t
t{ -1.0 2.0  fmax >ieee32 fdrop -> $40000000. }t
t{ -2.0 3.0  fmax >ieee32 fdrop -> $40400000. }t
t{ -3.0 2.0  fmax >ieee32 fdrop -> $40000000. }t
t{ 2.0 -1.0  fmax >ieee32 fdrop -> $40000000. }t
t{ 1.0 -2.0  fmax >ieee32 fdrop -> $3F800000. }t
t{ 2.0 -3.0  fmax >ieee32 fdrop -> $40000000. }t
t{ 3.0 -2.0  fmax >ieee32 fdrop -> $40400000. }t
t{ -2.0 -1.0 fmax >ieee32 fdrop -> $BF800000. }t
t{ -1.0 -2.0 fmax >ieee32 fdrop -> $BF800000. }t
t{ -2.0 -3.0 fmax >ieee32 fdrop -> $C0000000. }t
t{ -3.0 -2.0 fmax >ieee32 fdrop -> $C0000000. }t
t{  3.5  3.4 fmax >ieee32 fdrop -> $40600000. }t
t{  3.4  3.5 fmax >ieee32 fdrop -> $40600000. }t
t{ -3.5 -3.4 fmax >ieee32 fdrop -> $C059999A. }t
t{ -3.4 -3.5 fmax >ieee32 fdrop -> $C059999A. }t

t{  0.0 fnegate >ieee32 fdrop -> $80000000. }t
t{ -0.0 fnegate >ieee32 fdrop -> $00000000. }t
t{  1.0 fnegate >ieee32 fdrop -> $BF800000. }t
t{  2.0 fnegate >ieee32 fdrop -> $C0000000. }t
t{  3.0 fnegate >ieee32 fdrop -> $C0400000. }t
t{ -1.0 fnegate >ieee32 fdrop -> $3F800000. }t
t{ -2.0 fnegate >ieee32 fdrop -> $40000000. }t
t{ -3.0 fnegate >ieee32 fdrop -> $40400000. }t
t{  3.4 fnegate >ieee32 fdrop -> $C059999A. }t
t{  3.5 fnegate >ieee32 fdrop -> $C0600000. }t
t{ -3.4 fnegate >ieee32 fdrop -> $4059999A. }t
t{ -3.5 fnegate >ieee32 fdrop -> $40600000. }t

\ ensure proper display of the fp value
decimal
1.1e-10 f.
1.1e-9 f.
9.9e-8 f.
1.1e-8 f.
0.000123456789 f.
0.00123456789 f.
0.0123456789 f.
0.123456789 f.
1.23456789 f.
12.3456789 f.
123.456789 f.
1234.56789 f.
12345.6789 f.
123456.789 f.
1234567.89 f.
12345678.9 f.
123456789.1 f.
1.1e8 f.
9.9e8 f.
1.1e9 f.
1.1e10 f.

decimal
1.1e-10 fs.
1.1e-9 fs.
9.9e-8 fs.
1.1e-8 fs.
0.000123456789 fs.
0.00123456789 fs.
0.0123456789 fs.
0.123456789 fs.
1.23456789 fs.
12.3456789 fs.
123.456789 fs.
1234.56789 fs.
12345.6789 fs.
123456.789 fs.
1234567.89 fs.
12345678.9 fs.
123456789.1 fs.
1.1e8 fs.
9.9e8 fs.
1.1e9 fs.
1.1e10 fs.
