#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>

#include <o7c.h>

#include "VDataStream.h"

o7c_tag_t VDataStream_In_tag;
o7c_tag_t VDataStream_Out_tag;

extern void VDataStream_InitIn(struct VDataStream_In *in_, o7c_tag_t in__tag, VDataStream_ReadProc read) {
	V_Init(&(*in_)._, in__tag);
	(*in_).read = read;
}

extern int VDataStream_Read(struct VDataStream_In *in_, o7c_tag_t in__tag, char unsigned buf[/*len0*/], int buf_len0, int ofs, int count) {
	assert((ofs >= 0) && (count > 0) && (buf_len0 - count >= ofs));
	return (*in_).read(&(*in_), in__tag, buf, buf_len0, ofs, count);
}

extern void VDataStream_InitOut(struct VDataStream_Out *out, o7c_tag_t out_tag, VDataStream_WriteProc write) {
	V_Init(&(*out)._, out_tag);
	(*out).write = write;
}

extern int VDataStream_Write(struct VDataStream_Out *out, o7c_tag_t out_tag, char unsigned buf[/*len0*/], int buf_len0, int ofs, int count) {
	assert((ofs >= 0) && (count > 0) && (buf_len0 - count >= ofs));
	return (*out).write(&(*out), out_tag, buf, buf_len0, ofs, count);
}

extern void VDataStream_init_(void) {
	static int initialized__ = 0;
	if (0 == initialized__) {
		V_init_();

		o7c_tag_init(VDataStream_In_tag, V_Base_tag);
		o7c_tag_init(VDataStream_Out_tag, V_Base_tag);

	}
	++initialized__;
}

