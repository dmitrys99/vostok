(* Copyright 2018 ComdivByZero
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
 *)

(* Разборщик строки с локалью на подстроки. Формат локали соответствует тому,
 * что можно получить в значении переменной окружения LANG в POSIX *)
MODULE LocaleParser;

  IMPORT Chars0X;

  PROCEDURE ParseByOfs*(locale: ARRAY OF CHAR; ofs: INTEGER;
                        VAR lang, state, enc: ARRAY OF CHAR): BOOLEAN;
  VAR tOfs: INTEGER;
      ok: BOOLEAN;
  BEGIN
    tOfs := 0;
    ok := Chars0X.Copy(locale, ofs, FALSE, 2, lang, tOfs)
        & (locale[ofs] = "_");
    IF ok THEN
      INC(ofs);
      tOfs := 0;
      ok := Chars0X.Copy(locale, ofs, FALSE, 2, state, tOfs)
          & (locale[ofs] = ".");
      IF ok THEN
        INC(ofs);
        tOfs := 0;
        ok := Chars0X.Copy(locale, ofs, TRUE, LEN(enc), enc, tOfs)
      END
    END
  RETURN
    ok
  END ParseByOfs;

  PROCEDURE Parse*(locale: ARRAY OF CHAR; VAR lang, state, enc: ARRAY OF CHAR)
                  : BOOLEAN;
  RETURN
    ParseByOfs(locale, 0, lang, state, enc)
  END Parse;
  
END LocaleParser.
