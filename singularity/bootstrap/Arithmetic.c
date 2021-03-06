/* Generated by Vostok - Oberon-07 translator */

#include <stdbool.h>

#define O7_BOOL_UNDEFINED
#include <o7.h>

#include "Arithmetic.h"

#define Min_cnst TypeLimits_IntegerMin_cnst
#define Max_cnst TypeLimits_IntegerMax_cnst

extern o7_bool Arithmetic_Add(int *sum, int a1, int a2) {
	o7_bool norm;

	if (a2 > 0) {
		norm = a1 <= o7_sub(Max_cnst, a2);
	} else {
		norm = a1 >= o7_sub(Min_cnst, a2);
	}
	if (norm) {
		(*sum) = o7_add(a1, a2);
	}
	return norm;
}

extern o7_bool Arithmetic_Sub(int *diff, int m, int s) {
	o7_bool norm;

	if (s > 0) {
		norm = m >= o7_add(Min_cnst, s);
	} else {
		norm = m <= o7_add(Max_cnst, s);
	}
	if (norm) {
		(*diff) = o7_sub(m, s);
	}
	return norm;
}

extern o7_bool Arithmetic_Mul(int *prod, int m1, int m2) {
	o7_bool norm;

	norm = (m2 == 0) || (abs(m1) <= o7_div(Max_cnst, abs(m2)));
	if (norm) {
		(*prod) = o7_mul(m1, m2);
	}
	return norm;
}
