/* Copyright 2016-2017 ComdivByZero
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#if !defined(HEADER_GUARD_CFiles)
#define HEADER_GUARD_CFiles 1

#define CFiles_KiB_cnst 1024
#define CFiles_MiB_cnst (CFiles_KiB_cnst * 1024)
#define CFiles_GiB_cnst (CFiles_MiB_cnst * 1024)

typedef struct CFiles_Implement* CFiles_File;


extern CFiles_File CFiles_in, CFiles_out, CFiles_err;

extern CFiles_File CFiles_Open(
	int name_len, o7_char name[O7_VLA(name_len)], int ofs,
	int mode_len, o7_char mode[O7_VLA(mode_len)]);

extern void CFiles_Close(CFiles_File *file);

extern int CFiles_Read(CFiles_File file,
	int len, o7_char buf[O7_VLA(len)], int ofs, int count);
extern int CFiles_Write(CFiles_File file,
	int len, o7_char buf[O7_VLA(len)], int ofs, int count);

O7_INLINE int CFiles_ReadChars(CFiles_File file,
	int len, o7_char buf[O7_VLA(len)], int ofs, int count)
{
	return CFiles_Read(file, len, buf, ofs, count);
}

O7_INLINE int CFiles_WriteChars(CFiles_File file,
	int len, o7_char buf[O7_VLA(len)], int ofs, int count)
{
	return CFiles_Write(file, len, buf, ofs, count);
}

extern o7_bool CFiles_Flush(CFiles_File file);

extern int CFiles_Seek(CFiles_File file, int gibs, int bytes);

extern int CFiles_Tell(CFiles_File file, int *gibs, int *bytes);

extern int CFiles_Remove(int len, o7_char const name[O7_VLA(len)], int ofs);

extern o7_bool CFiles_Exist(int len, o7_char const name[O7_VLA(len)], int ofs);

extern void CFiles_init(void);

#endif
