/*  Some constants of Utf-8/ASC II
 *  Copyright (C) 2016  ComdivByZero
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundationher version 3 of the License, or
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
#if !defined(HEADER_GUARD_Utf8)
#define HEADER_GUARD_Utf8


#define Utf8_Null_cnst "\x00"
#define Utf8_TransmissionEnd_cnst "\x04"
#define Utf8_Bell_cnst "\x07"
#define Utf8_BackSpace_cnst "\x08"
#define Utf8_Tab_cnst "\x09"
#define Utf8_NewLine_cnst "\x0A"
#define Utf8_NewPage_cnst "\x0C"
#define Utf8_CarRet_cnst "\x0D"
#define Utf8_Idle_cnst "\x16"
#define Utf8_DQuote_cnst "\x22"
#define Utf8_Delete_cnst "\x7F"

static inline void Utf8_init(void) { ; }
#endif
