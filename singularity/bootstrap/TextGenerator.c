#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>

#define O7C_BOOL_UNDEFINED
#include <o7c.h>

#include "TextGenerator.h"

o7c_tag_t TextGenerator_Out_tag;

extern void TextGenerator_Init(struct TextGenerator_Out *g, o7c_tag_t g_tag, struct VDataStream_Out *out) {
	assert(out != NULL);
	V_Init(&(*g)._, g_tag);
	(*g).out = out;
	(*g).len = 0;
	(*g).isNewLine = false;
}

extern void TextGenerator_SetTabs(struct TextGenerator_Out *g, o7c_tag_t g_tag, struct TextGenerator_Out *d, o7c_tag_t d_tag) {
	(*g).tabs = (*d).tabs;
}

static void Chars(struct TextGenerator_Out *gen, o7c_tag_t gen_tag, o7c_char ch, int count) {
	o7c_char c[1] ;
	memset(&c, 0, sizeof(c));

	assert(o7c_cmp(count, 0) >=  0);
	c[0] = ch;
	while (o7c_cmp(count, 0) >  0) {
		(*gen).len = o7c_add((*gen).len, VDataStream_Write(&(*(*gen).out), NULL, c, 1, 0, 1));
		count = o7c_sub(count, 1);
	}
}

static void Indent(struct TextGenerator_Out *gen, o7c_tag_t gen_tag, int adder) {
	(*gen).tabs = o7c_add((*gen).tabs, adder);
	Chars(&(*gen), gen_tag, 0x09u, (*gen).tabs);
}

static void NewLine(struct TextGenerator_Out *gen, o7c_tag_t gen_tag) {
	if ((*gen).isNewLine) {
		(*gen).isNewLine = false;
		Chars(&(*gen), gen_tag, 0x09u, (*gen).tabs);
	}
}

extern void TextGenerator_Str(struct TextGenerator_Out *gen, o7c_tag_t gen_tag, o7c_char str[/*len0*/], int str_len0) {
	assert(str[o7c_ind(str_len0, o7c_sub(str_len0, 1))] == 0x00u);
	NewLine(&(*gen), gen_tag);
	(*gen).len = o7c_add((*gen).len, VDataStream_Write(&(*(*gen).out), NULL, str, str_len0, 0, o7c_sub(str_len0, 1)));
}

extern void TextGenerator_StrLn(struct TextGenerator_Out *gen, o7c_tag_t gen_tag, o7c_char str[/*len0*/], int str_len0) {
	NewLine(&(*gen), gen_tag);
	(*gen).len = o7c_add((*gen).len, VDataStream_Write(&(*(*gen).out), NULL, str, str_len0, 0, o7c_sub(str_len0, 1)));
	(*gen).len = o7c_add((*gen).len, VDataStream_Write(&(*(*gen).out), NULL, "\x0A", 2, 0, 1));
	(*gen).isNewLine = true;
}

extern void TextGenerator_Ln(struct TextGenerator_Out *gen, o7c_tag_t gen_tag) {
	(*gen).len = o7c_add((*gen).len, VDataStream_Write(&(*(*gen).out), NULL, "\x0A", 2, 0, 1));
	(*gen).isNewLine = true;
}

extern void TextGenerator_StrOpen(struct TextGenerator_Out *gen, o7c_tag_t gen_tag, o7c_char str[/*len0*/], int str_len0) {
	TextGenerator_StrLn(&(*gen), gen_tag, str, str_len0);
	(*gen).tabs = o7c_add((*gen).tabs, 1);
}

extern void TextGenerator_IndentOpen(struct TextGenerator_Out *gen, o7c_tag_t gen_tag) {
	(*gen).tabs = o7c_add((*gen).tabs, 1);
}

extern void TextGenerator_IndentClose(struct TextGenerator_Out *gen, o7c_tag_t gen_tag) {
	assert(o7c_cmp((*gen).tabs, 0) >  0);
	(*gen).tabs = o7c_sub((*gen).tabs, 1);
}

extern void TextGenerator_StrClose(struct TextGenerator_Out *gen, o7c_tag_t gen_tag, o7c_char str[/*len0*/], int str_len0) {
	TextGenerator_IndentClose(&(*gen), gen_tag);
	TextGenerator_Str(&(*gen), gen_tag, str, str_len0);
}

extern void TextGenerator_StrLnClose(struct TextGenerator_Out *gen, o7c_tag_t gen_tag, o7c_char str[/*len0*/], int str_len0) {
	TextGenerator_IndentClose(&(*gen), gen_tag);
	TextGenerator_StrLn(&(*gen), gen_tag, str, str_len0);
}

extern void TextGenerator_StrIgnoreIndent(struct TextGenerator_Out *gen, o7c_tag_t gen_tag, o7c_char str[/*len0*/], int str_len0) {
	assert(str[o7c_ind(str_len0, o7c_sub(str_len0, 1))] == 0x00u);
	(*gen).len = o7c_add((*gen).len, VDataStream_Write(&(*(*gen).out), NULL, str, str_len0, 0, o7c_sub(str_len0, 1)));
}

extern void TextGenerator_String(struct TextGenerator_Out *gen, o7c_tag_t gen_tag, struct StringStore_String *word, o7c_tag_t word_tag) {
	NewLine(&(*gen), gen_tag);
	(*gen).len = o7c_add((*gen).len, StringStore_Write(&(*(*gen).out), NULL, &(*word), word_tag));
}

extern void TextGenerator_Data(struct TextGenerator_Out *g, o7c_tag_t g_tag, o7c_char data[/*len0*/], int data_len0, int ofs, int count) {
	NewLine(&(*g), g_tag);
	(*g).len = o7c_add((*g).len, VDataStream_Write(&(*(*g).out), NULL, data, data_len0, ofs, count));
}

extern void TextGenerator_ScreeningString(struct TextGenerator_Out *gen, o7c_tag_t gen_tag, struct StringStore_String *str, o7c_tag_t str_tag) {
	int i = O7C_INT_UNDEF, last = O7C_INT_UNDEF;
	StringStore_Block block = NULL;

	NewLine(&(*gen), gen_tag);
	block = (*str).block;
	i = (*str).ofs;
	last = i;
	assert(block->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] == (char unsigned)'"');
	i = o7c_add(i, 1);
	while (1) if (block->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] == 0x0Cu) {
		(*gen).len = o7c_add((*gen).len, VDataStream_Write(&(*(*gen).out), NULL, block->s, StringStore_BlockSize_cnst + 1, last, o7c_sub(i, last)));
		block = block->next;
		i = 0;
		last = 0;
	} else if (block->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] == (char unsigned)'\\') {
		(*gen).len = o7c_add((*gen).len, VDataStream_Write(&(*(*gen).out), NULL, block->s, StringStore_BlockSize_cnst + 1, last, o7c_add(o7c_sub(i, last), 1)));
		(*gen).len = o7c_add((*gen).len, VDataStream_Write(&(*(*gen).out), NULL, "\\", 2, 0, 1));
		i = o7c_add(i, 1);
		last = i;
	} else if (block->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] != 0x00u) {
		i = o7c_add(i, 1);
	} else break;
	assert(block->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] == 0x00u);
	(*gen).len = o7c_add((*gen).len, VDataStream_Write(&(*(*gen).out), NULL, block->s, StringStore_BlockSize_cnst + 1, last, o7c_sub(i, last)));
}

extern void TextGenerator_Int(struct TextGenerator_Out *gen, o7c_tag_t gen_tag, int int_) {
	o7c_char buf[14] ;
	int i = O7C_INT_UNDEF;
	o7c_bool sign = O7C_BOOL_UNDEF;
	memset(&buf, 0, sizeof(buf));

	NewLine(&(*gen), gen_tag);
	sign = o7c_cmp(int_, 0) <  0;
	if (sign) {
		int_ = o7c_sub(0, int_);
	}
	i = sizeof(buf) / sizeof (buf[0]);
	do {
		i = o7c_sub(i, 1);
		buf[o7c_ind(14, i)] = o7c_chr((o7c_add((int)(char unsigned)'0', o7c_mod(int_, 10))));
		int_ = o7c_div(int_, 10);
	} while (!(o7c_cmp(int_, 0) ==  0));
	if (sign) {
		i = o7c_sub(i, 1);
		buf[o7c_ind(14, i)] = (char unsigned)'-';
	}
	(*gen).len = o7c_add((*gen).len, VDataStream_Write(&(*(*gen).out), NULL, buf, 14, i, o7c_sub(sizeof(buf) / sizeof (buf[0]), i)));
}

extern void TextGenerator_Real(struct TextGenerator_Out *gen, o7c_tag_t gen_tag, double real) {
	NewLine(&(*gen), gen_tag);
	TextGenerator_Str(&(*gen), gen_tag, "Real not implemented", 21);
}

extern void TextGenerator_init(void) {
	static int initialized = 0;
	if (0 == initialized) {
		V_init();
		Utf8_init();
		StringStore_init();
		VDataStream_init();

		o7c_tag_init(TextGenerator_Out_tag, V_Base_tag);

	}
	++initialized;
}

