/*  Arithmetic operations with overflow check
 *  Copyright (C) 2016  ComdivByZero
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#if !defined(HEADER_GUARD_Arithmetic)
#define HEADER_GUARD_Arithmetic

#include "Limits.h"

extern o7c_bool Arithmetic_Add(int *sum, int a1, int a2);

extern o7c_bool Arithmetic_Sub(int *diff, int m, int s);

extern o7c_bool Arithmetic_Mul(int *prod, int m1, int m2);

extern o7c_bool Arithmetic_Div(int *frac, int n, int d);

extern o7c_bool Arithmetic_Mod(int *mod, int n, int d);

extern void Arithmetic_init(void);
#endif
