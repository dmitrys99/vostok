(*  Command line interface for Oberon-07 translator
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
 *)
MODULE Translator;

IMPORT
	Log,
	Out,
	CLI,
	Stream := VDataStream,
	File := VFileStream,
	Utf8,
	Strings := StringStore,
	Parser,
	Scanner,
	Ast,
	GeneratorC,
	TranLim := TranslatorLimits,
	Exec := PlatformExec;

CONST
	ResultC   = 0;
	ResultBin = 1;
	ResultRun = 2;

	ErrNo                   =   0;
	ErrWrongArgs            = - 1;
	ErrTooLongSourceName    = - 2;
	ErrTooLongOutName       = - 3;
	ErrOpenSource           = - 4;
	ErrOpenH                = - 5;
	ErrOpenC                = - 6;
	ErrParse                = - 7;
	ErrUnknownCommand       = - 8;
	ErrNotEnoughArgs        = - 9;
	ErrTooLongModuleDirs    = -10;
	ErrTooManyModuleDirs    = -11;
	ErrTooLongCDirs         = -12;
	ErrTooLongCc            = -13;
	ErrCCompiler            = -14;
	ErrTooLongRunArgs       = -15;
	ErrUnexpectArg          = -16;
TYPE
	ModuleProvider = POINTER TO RECORD(Ast.RProvider)
		opt: Parser.Options;
		fileExt: ARRAY 32 OF CHAR;
		extLen: INTEGER;
		path: ARRAY 4096 OF CHAR;
		sing: SET;
		modules: RECORD
			first, last: Ast.Module
		END
	END;

PROCEDURE AstErrorMessage(code: INTEGER);
	PROCEDURE O(s: ARRAY OF CHAR);
	BEGIN
		Out.String(s)
	END O;
BEGIN
	CASE code OF
	  Ast.ErrImportNameDuplicate:
		O("Имя модуля уже встречается в списке импорта")
	| Ast.ErrDeclarationNameDuplicate:
		O("Повторное объявление имени в той же области видимости")
	| Ast.ErrDeclarationNameHide:
		O("Имя объявления затеняет объявление из модуля")
	| Ast.ErrMultExprDifferentTypes:
		O("Типы подвыражений в умножении несовместимы")
	| Ast.ErrDivExprDifferentTypes:
		O("Типы подвыражений в делении несовместимы")
	| Ast.ErrNotBoolInLogicExpr:
		O("В логическом выражении должны использоваться подвыражении логического типа")
	| Ast.ErrNotIntInDivOrMod:
		O("В целочисленном делении допустимы только целочисленные подвыражения")
	| Ast.ErrNotRealTypeForRealDiv:
		O("В дробном делении допустимы только подвыражения дробного типа")
	| Ast.ErrNotIntSetElem:
		O("В качестве элементов множества допустимы только целые числа")
	| Ast.ErrSetElemOutOfRange:
		O("Элемент множества выходит за границы возможных значений - 0 .. 31")
	| Ast.ErrSetLeftElemBiggerRightElem:
		O("Левый элемент диапазона больше правого")
	| Ast.ErrAddExprDifferenTypes:
		O("Типы подвыражений в сложении несовместимы")
	| Ast.ErrNotNumberAndNotSetInMult:
		O("В выражениях *, /, DIV, MOD допустимы только числа и множества")
	| Ast.ErrNotNumberAndNotSetInAdd:
		O("В выражениях +, - допустимы только числа и множества")
	| Ast.ErrSignForBool:
		O("Унарный знак не применим к логическому выражению")
	| Ast.ErrRelationExprDifferenTypes:
		O("Типы подвыражений в сравнении не совпадают")
	| Ast.ErrExprInWrongTypes:
		O("Ast.ErrExprInWrongTypes")
	| Ast.ErrExprInRightNotSet:
		O("Ast.ErrExprInRightNotSet")
	| Ast.ErrExprInLeftNotInteger:
		O("Левый член выражения IN должен быть целочисленным")
	| Ast.ErrRelIncompatibleType:
		O("В сравнении выражения несовместимых типов")
	| Ast.ErrIsExtTypeNotRecord:
		O("Проверка IS применима только к записям")
	| Ast.ErrIsExtVarNotRecord:
		O("Левый член проверки IS должен иметь тип записи или указателя на неё")
	| Ast.ErrConstDeclExprNotConst:
		O("Постоянная сопоставляется выражению, невычислимым на этапе перевода")
	| Ast.ErrAssignIncompatibleType:
		O("Несовместимые типы в присваивании")
	| Ast.ErrAssignExpectVarParam:
		O("Ожидалось изменяемое выражение в присваивании")
	| Ast.ErrCallNotProc:
		O("Вызов допустим только для процедур и переменных процедурного типа")
	| Ast.ErrCallIgnoredReturn:
		O("Возвращаемое значение не задействовано в выражении")
	| Ast.ErrCallExprWithoutReturn:
		O("Вызываемая процедура не возвращает значения")
	| Ast.ErrCallExcessParam:
		O("Лишние параметры при вызове процедуры")
	| Ast.ErrCallIncompatibleParamType:
		O("Несовместимый тип параметра")
	| Ast.ErrCallExpectVarParam:
		O("Параметр должен быть изменяемым значением")
	| Ast.ErrCallVarPointerTypeNotSame:
		O("Для переменного параметра - указателя должен использоваться аргумент того же типа")
	| Ast.ErrCallParamsNotEnough:
		O("Не хватает фактических параметров в вызове процедуры")
	| Ast.ErrCaseExprNotIntOrChar:
		O("Выражение в CASE должно быть целочисленным или литерой")
	| Ast.ErrCaseElemExprTypeMismatch:
		O("Метки CASE должно быть целочисленными или литерами")
	| Ast.ErrCaseElemDuplicate:
		O("Дублирование значения меток в CASE")
	| Ast.ErrCaseRangeLabelsTypeMismatch:
		O("Не совпадает тип меток CASE")
	| Ast.ErrCaseLabelLeftNotLessRight:
		O("Левая часть диапазона значений в метке CASE должна быть меньше правой")
	| Ast.ErrCaseLabelNotConst:
		O("Метки CASE должны быть константами")
	| Ast.ErrProcHasNoReturn:
		O("Процедура не имеет возвращаемого значения")
	| Ast.ErrReturnIncompatibleType:
		O("Тип возвращаемого значения не совместим типом, указанном в заголовке процедуры")
	| Ast.ErrExpectReturn:
		O("Ожидался возврат значения, так как в заголовке процедуры указан возвращаемый тип")
	| Ast.ErrDeclarationNotFound:
		O("Предварительное объявление имени не было найдено")
	| Ast.ErrConstRecursive:
		O("Недопустимое использование константы для задания собственного значения")
	| Ast.ErrImportModuleNotFound:
		O("Импортированный модуль не был найден")
	| Ast.ErrImportModuleWithError:
		O("Импортированный модуль содержит ошибки")
	| Ast.ErrDerefToNotPointer:
		O("Разыменовывание применено не к указателю")
	| Ast.ErrArrayItemToNotArray:
		O("Получение элемента не массива")
	| Ast.ErrArrayIndexNotInt:
		O("Индекс массива не целочисленный")
	| Ast.ErrArrayIndexNegative:
		O("Отрицательный индекс массива")
	| Ast.ErrArrayIndexOutOfRange:
		O("Индекс массива выходит за его границы")
	| Ast.ErrGuardExpectRecordExt:
		O("В защите типа ожидается расширенная запись")
	| Ast.ErrGuardExpectPointerExt:
		O("В защите типа ожидается указатель на расширенную запись")
	| Ast.ErrGuardedTypeNotExtensible:
		O("В защите типа переменная должна быть либо записью, либо указателем на запись")
	| Ast.ErrDotSelectorToNotRecord:
		O("Селектор элемента записи применён не к записи")
	| Ast.ErrDeclarationNotVar:
		O("Ожидалась переменная")
	| Ast.ErrForIteratorNotInteger:
		O("Итератор FOR не целочисленного типа")
	| Ast.ErrNotBoolInIfCondition:
		O("Выражение в охране условного оператора должно быть логическим")
	| Ast.ErrNotBoolInWhileCondition:
		O("Выражение в охране цикла WHILE должно быть логическим")
	| Ast.ErrWhileConditionAlwaysFalse:
		O("Охрана цикла WHILE всегда ложна")
	| Ast.ErrWhileConditionAlwaysTrue:
		O("Цикл бесконечен, так как охрана WHILE всегда истинна")
	| Ast.ErrNotBoolInUntil:
		O("Выражение в условии завершения цикла REPEAT должно быть логическим")
	| Ast.ErrUntilAlwaysFalse:
		O("Цикл бесконечен, так как условие завершения всегда ложно")
	| Ast.ErrUntilAlwaysTrue:
		O("Условие завершения всегда истинно")
	| Ast.ErrDeclarationIsPrivate:
		O("Объявление не экспортировано")
	| Ast.ErrNegateNotBool:
		O("Логическое отрицание применено не к логическому типу")
	| Ast.ErrConstAddOverflow:
		O("Переполнение при сложении постоянных")
	| Ast.ErrConstSubOverflow:
		O("Переполнение при вычитании постоянных")
	| Ast.ErrConstMultOverflow:
		O("Переполнение при умножении постоянных")
	| Ast.ErrConstDivByZero:
		O("Деление на 0")
	| Ast.ErrValueOutOfRangeOfByte:
		O("Значение выходит за границы BYTE")
	| Ast.ErrValueOutOfRangeOfChar:
		O("Значение выходит за границы CHAR")
	| Ast.ErrExpectIntExpr:
		O("Ожидается целочисленное выражение")
	| Ast.ErrExpectConstIntExpr:
		O("Ожидается константное целочисленное выражение")
	| Ast.ErrForByZero:
		O("Шаг итератора не может быть равен 0")
	| Ast.ErrByShouldBePositive:
		O("Для прохода от меньшего к большему шаг итератора должен быть > 0")
	| Ast.ErrByShouldBeNegative:
		O("Для прохода от большего к меньшему шаг итератора должен быть < 0")
	| Ast.ErrForPossibleOverflow:
		O("Во время итерации в FOR возможно переполнение")
	| Ast.ErrVarUninitialized:
		O("Использование неинициализированной переменной")
	| Ast.ErrDeclarationNotProc:
		O("Имя должно указывать на процедуру")
	| Ast.ErrProcNotCommandHaveReturn:
		O("В качестве команды может выступать только процедура без возращаемого значения")
	| Ast.ErrProcNotCommandHaveParams:
		O("В качестве команды может выступать только процедура без параметров")
	END
END AstErrorMessage;

PROCEDURE ParseErrorMessage(code: INTEGER);
	PROCEDURE O(s: ARRAY OF CHAR);
	BEGIN
		Out.String(s)
	END O;
BEGIN
	CASE code OF
	  Scanner.ErrUnexpectChar:
		O("Неожиданный символ в тексте")
	| Scanner.ErrNumberTooBig:
		O("Значение константы слишком велико")
	| Scanner.ErrRealScaleTooBig:
		O("ErrRealScaleTooBig")
	| Scanner.ErrWordLenTooBig:
		O("ErrWordLenTooBig")
	| Scanner.ErrExpectHOrX:
		O("В конце 16-ричного числа ожидается 'H' или 'X'")
	| Scanner.ErrExpectDQuote:
		O("Ожидалась "); O(Utf8.DQuote)
	| Scanner.ErrExpectDigitInScale:
		O("ErrExpectDigitInScale")
	| Scanner.ErrUnclosedComment:
		O("Незакрытый комментарий")

	| Parser.ErrExpectModule:
		O("Ожидается 'MODULE'")
	| Parser.ErrExpectIdent:
		O("Ожидается имя")
	| Parser.ErrExpectColon:
		O("Ожидается ':'")
	| Parser.ErrExpectSemicolon:
		O("Ожидается ';'")
	| Parser.ErrExpectEnd:
		O("Ожидается 'END'")
	| Parser.ErrExpectDot:
		O("Ожидается '.'")
	| Parser.ErrExpectModuleName:
		O("Ожидается имя модуля")
	| Parser.ErrExpectEqual:
		O("Ожидается '='")
	| Parser.ErrExpectBrace1Close:
		O("Ожидается ')'")
	| Parser.ErrExpectBrace2Close:
		O("Ожидается ']'")
	| Parser.ErrExpectBrace3Close:
		O("Ожидается '}'")
	| Parser.ErrExpectOf:
		O("Ожидается OF")
	| Parser.ErrExpectTo:
		O("Ожидается TO")
	| Parser.ErrExpectStructuredType:
		O("Ожидается структурный тип: массив, запись, указатель, процедурный")
	| Parser.ErrExpectRecord:
		O("Ожидается запись")
	| Parser.ErrExpectStatement:
		O("Ожидается оператор")
	| Parser.ErrExpectThen:
		O("Ожидается THEN")
	| Parser.ErrExpectAssign:
		O("Ожидается :=")
	| Parser.ErrExpectVarRecordOrPointer:
		O("Ожидается переменная типа запись либо указателя на неё")
	| Parser.ErrExpectType:
		O("Ожидается тип")
	| Parser.ErrExpectUntil:
		O("Ожидается UNTIL")
	| Parser.ErrExpectDo:
		O("Ожидается DO")
	| Parser.ErrExpectDesignator:
		O("Ожидается обозначение")
	| Parser.ErrExpectProcedure:
		O("Ожидается процедура")
	| Parser.ErrExpectConstName:
		O("Ожидается имя константы")
	| Parser.ErrExpectProcedureName:
		O("Ожидается завершающее имя процедуры")
	| Parser.ErrExpectExpression:
		O("Ожидается выражение")
	| Parser.ErrExcessSemicolon:
		O("Лишняя ';'")
	| Parser.ErrEndModuleNameNotMatch:
		O("Завершающее имя в конце модуля не совпадает с его именем")
	| Parser.ErrArrayDimensionsTooMany:
		O("Слишком большая n-мерность массива")
	| Parser.ErrEndProcedureNameNotMatch:
		O("Завершающее имя в теле процедуры не совпадает с её именем")
	| Parser.ErrFunctionWithoutBraces:
		O("Объявление процедуры с возвращаемым значением не содержит скобки")
	| Parser.ErrArrayLenLess1:
		O("Длина массива должна быть > 0")
	| Parser.ErrExpectIntOrStrOrQualident:
		O("Ожидалось число или строка")
	END
END ParseErrorMessage;

PROCEDURE ErrorMessage(code: INTEGER);
BEGIN
	Out.Int(code - Parser.ErrAstBegin, 0); Out.String(" ");
	IF code <= Parser.ErrAstBegin THEN
		AstErrorMessage(code - Parser.ErrAstBegin)
	ELSE
		ParseErrorMessage(code)
	END
END ErrorMessage;

PROCEDURE PrintErrors(m: Ast.Module);
CONST SkipError = Ast.ErrImportModuleWithError + Parser.ErrAstBegin;
VAR i: INTEGER;
	err: Ast.Error;
BEGIN
	i := 0;
	WHILE m # NIL DO
		err := m.errors;
		WHILE (err # NIL) & (err.code = SkipError) DO
			err := err.next
		END;
		IF err # NIL THEN
			Out.String("Найдены ошибки в модуле ");
			Out.String(m.name.block.s); Out.String(": "); Out.Ln;
			err := m.errors;
			WHILE err # NIL DO
				IF err.code # SkipError THEN
					INC(i);

					Out.String("  ");
					Out.Int(i, 2); Out.String(") ");
					ErrorMessage(err.code);
					Out.String(" "); Out.Int(err.line + 1, 0);
					Out.String(" : "); Out.Int(err.column + err.tabs * 3, 0);
					Out.Ln
				END;

				err := err.next
			END
		END;
		m := m.module
	END
END PrintErrors;

PROCEDURE IsEqualStr(str: ARRAY OF CHAR; ofs: INTEGER; sample: ARRAY OF CHAR)
                    : BOOLEAN;
VAR i: INTEGER;
BEGIN
	i := 0;
	WHILE (str[ofs] = sample[i]) & (sample[i] # Utf8.Null) DO
		INC(ofs);
		INC(i)
	END
	RETURN str[ofs] = sample[i]
END IsEqualStr;

PROCEDURE CopyPath(VAR str: ARRAY OF CHAR; VAR sing: SET;
                   VAR cDirs: ARRAY OF CHAR; VAR cc: ARRAY OF CHAR;
                   VAR arg: INTEGER): INTEGER;
VAR i, dirsOfs, ccLen, count, optLen: INTEGER;
	ret: INTEGER;
	opt: ARRAY 256 OF CHAR;

	PROCEDURE CopyInfrPart(VAR str: ARRAY OF CHAR; VAR i, arg: INTEGER;
	                       add: ARRAY OF CHAR): BOOLEAN;
	VAR ret: BOOLEAN;
	BEGIN
		ret := CLI.Get(str, i, arg);
		IF ret THEN
			DEC(i);
			ret := Strings.CopyCharsNull(str, i, add);
			IF ret THEN
				INC(i);
				str[i] := 0X;
				INC(i)
			END;
		END
		RETURN ret
	END CopyInfrPart;
BEGIN
	i := 0;
	dirsOfs := 0;
	cDirs[0] := Utf8.Null;
	ccLen := 0;
	count := 0;
	sing := {};
	ret := ErrNo;
	optLen := 0;
	WHILE (ret = ErrNo) & (count < 32)
	    & (arg < CLI.count) & CLI.Get(opt, optLen, arg) & ~IsEqualStr(opt, 0, "--")
	DO
		optLen := 0;
		IF (opt = "-i") OR (opt = "-m") THEN
			INC(arg);
			IF arg >= CLI.count THEN
				ret := ErrNotEnoughArgs
			ELSIF CLI.Get(str, i, arg) THEN
				IF opt = "-i" THEN
					INCL(sing, count)
				END;
				INC(i);
				INC(count)
			ELSE
				ret := ErrTooLongModuleDirs
			END
		ELSIF opt = "-c" THEN
			INC(arg);
			IF arg >= CLI.count THEN
				ret := ErrNotEnoughArgs
			ELSIF CLI.Get(cDirs, dirsOfs, arg) & (dirsOfs < LEN(cDirs)) THEN
				cDirs[dirsOfs] := Utf8.Null;
				Log.Str("cDirs = ");
				Log.StrLn(cDirs)
			ELSE
				ret := ErrTooLongCDirs
			END
		ELSIF opt = "-cc" THEN
			INC(arg);
			IF arg >= CLI.count THEN
				ret := ErrNotEnoughArgs
			ELSIF CLI.Get(cc, ccLen, arg) THEN
				DEC(ccLen)
			ELSE
				ret := ErrTooLongCc
			END
		ELSIF opt = "-infr" THEN
			INC(arg);
			IF arg >= CLI.count THEN
				ret := ErrNotEnoughArgs
			ELSIF CopyInfrPart(str, i, arg, "/singularity/definition")
			    & CopyInfrPart(str, i, arg, "/library")
			    & CopyInfrPart(cDirs, dirsOfs, arg, "/singularity/implementation")
			THEN
				INCL(sing, count);
				INC(count, 2)
			ELSE
				ret := ErrTooLongModuleDirs
			END
		ELSE
			ret := ErrUnexpectArg
		END;
		INC(arg)
	END;
	IF i + 1 < LEN(str) THEN
		str[i + 1] := Utf8.Null;
		IF count >= 32 THEN
			ret := ErrTooManyModuleDirs
		END;
	ELSE
		ret := ErrTooLongModuleDirs;
		str[LEN(str) - 1] := Utf8.Null;
		str[LEN(str) - 2] := Utf8.Null;
		str[LEN(str) - 3] := "#"
	END
	RETURN ret
END CopyPath;

PROCEDURE SearchModule(mp: ModuleProvider;
                       name: ARRAY OF CHAR; ofs, end: INTEGER): Ast.Module;
VAR m: Ast.Module;
BEGIN
	m := mp.modules.first;
	WHILE (m # NIL) & ~Strings.IsEqualToChars(m.name, name, ofs, end) DO
		ASSERT(m # m.module);
		m := m.module
	END
	RETURN m
END SearchModule;

PROCEDURE AddModule(mp: ModuleProvider; m: Ast.Module; sing: BOOLEAN);
BEGIN
	ASSERT(m.module = m);
	m.module := NIL;
	IF mp.modules.first = NIL THEN
		mp.modules.first := m
	ELSE
		mp.modules.last.module := m
	END;
	mp.modules.last := m;
	IF sing THEN
		m.mark := TRUE
	END
END AddModule;

PROCEDURE GetModule(p: Ast.Provider; host: Ast.Module;
                    name: ARRAY OF CHAR; ofs, end: INTEGER): Ast.Module;
VAR m: Ast.Module;
	source: File.In;
	mp: ModuleProvider;
	pathOfs, pathInd: INTEGER;

	PROCEDURE Open(p: ModuleProvider; VAR pathOfs: INTEGER;
	               name: ARRAY OF CHAR; ofs, end: INTEGER): File.In;
	VAR n: ARRAY 1024 OF CHAR;
		len, l: INTEGER;
		in: File.In;
	BEGIN
		len := Strings.CalcLen(p.path, pathOfs);
		l := 0;
		IF (len > 0)
		 & Strings.CopyChars(n, l, p.path, pathOfs, pathOfs + len)
		 & Strings.CopyChars(n, l, "/", 0, 1)
		 & Strings.CopyChars(n, l, name, ofs, end)
		 & Strings.CopyChars(n, l, p.fileExt, 0, p.extLen)
		THEN
			Log.Str("Открыть "); Log.Str(n); Log.Ln;
			in := File.OpenIn(n)
		ELSE
			in := NIL
		END;
		pathOfs := pathOfs + len + 2
		RETURN in
	END Open;
BEGIN
	mp := p(ModuleProvider);
	m := SearchModule(mp, name, ofs, end);
	IF m # NIL THEN
		Log.StrLn("Найден уже разобранный модуль")
	ELSE
		pathInd := -1;
		pathOfs := 0;
		REPEAT
			source := Open(mp, pathOfs, name, ofs, end);
			INC(pathInd)
		UNTIL (source # NIL) OR (mp.path[pathOfs] = Utf8.Null);
		IF source # NIL THEN
			m := Parser.Parse(source, p, mp.opt);
			File.CloseIn(source);
			IF m # NIL THEN
				AddModule(mp, m, pathInd IN mp.sing)
			END
		ELSE
			Out.String("Не получается найти или открыть файл модуля");
			Out.Ln
		END
	END
	RETURN m
END GetModule;

PROCEDURE OpenCOutput(VAR interface, implementation: File.Out;
                      module: Ast.Module; isMain: BOOLEAN;
                      VAR dir: ARRAY OF CHAR; dirLen: INTEGER): INTEGER;
VAR destLen: INTEGER;
	ret: INTEGER;
BEGIN
	interface := NIL;
	implementation := NIL;
	destLen := dirLen;
	IF ~Strings.CopyChars(dir, destLen, "/", 0, 1)
	OR ~Strings.CopyToChars(dir, destLen, module.name)
	OR (destLen > LEN(dir) - 3)
	THEN
		ret := ErrTooLongOutName
	ELSE
		dir[destLen] := ".";
		dir[destLen + 2] := Utf8.Null;
		IF ~isMain THEN
			dir[destLen + 1] := "h";
			interface := File.OpenOut(dir)
		END;
		IF  ~isMain & (interface = NIL) THEN
			ret := ErrOpenH
		ELSE
			dir[destLen + 1] := "c";
			Log.StrLn(dir);
			implementation := File.OpenOut(dir);
			IF implementation = NIL THEN
				File.CloseOut(interface);
				ret := ErrOpenC
			ELSE
				ret := ErrNo
			END
		END
	END
	RETURN ret
END OpenCOutput;

PROCEDURE NewProvider(): ModuleProvider;
VAR mp: ModuleProvider;
BEGIN
	NEW(mp); Ast.ProviderInit(mp, GetModule);
	Parser.DefaultOptions(mp.opt);
	mp.opt.printError := ErrorMessage;
	mp.modules.first := NIL;
	mp.modules.last := NIL;
	mp.extLen := 0;
	RETURN mp
END NewProvider;

PROCEDURE PrintUsage;
	PROCEDURE S(s: ARRAY OF CHAR);
	BEGIN
		Out.String(s);
		Out.Ln
	END S;
BEGIN
S("Использование: ");
S("  1) o7c help");
S("  2) o7c to-c команда вых.каталог {-m путьКмодулям | -i кат.с_интерф-ми_мод-ми}");
S("Команда - это модуль[.процедура_без_параметров] .");
S("В случае успешной трансляции создаст в выходном каталоге набор .h и .c-файлов,");
S("соответствующих как самому исходному модулю, так и используемых им модулей,");
S("кроме лежащих в каталогах, указанным после опции -i, служащих интерфейсами");
S("для других .h и .с-файлов.");
S("  3) o7c to-bin ком-да результат {-m пКм | -i кИм | -c .h,c-файлы} [-cc компил.]");
S("После трансляции указанного модуля вызывает компилятор cc по умолчанию, либо");
S("указанный после опции -cc, для сбора результата - исполнимого файла, в состав");
S("которого также войдут .h,c файлы, находящиеся в каталогах, указанных после -c.");
S("  4) o7c run команда {-m путь_к_м. | -i к.с_инт_м. | -c .h,c-файлы} -- параметры");
S("Запускает собранный модуль с параметрами, указанными после --");
S("Также, доступен параметр -infr путь , который эквивалентен совокупности:");
S("-i путь/singularity/definition -c путь/singularity/implementation -m путь/library")
END PrintUsage;

PROCEDURE ErrMessage(err: INTEGER; cmd: ARRAY OF CHAR);
BEGIN
	IF err # ErrParse THEN
		CASE err OF
		  ErrWrongArgs:
			PrintUsage
		| ErrTooLongSourceName:
			Out.String("Слишком длинное имя исходного файла"); Out.Ln
		| ErrTooLongOutName:
			Out.String("Слишком длинное выходное имя"); Out.Ln
		| ErrOpenSource:
			Out.String("Не получается открыть исходный файл")
		| ErrOpenH:
			Out.String("Не получается открыть выходной .h файл")
		| ErrOpenC:
			Out.String("Не получается открыть выходной .c файл")
		| ErrParse:
			Out.String("Ошибка разбора исходного файла")
		| ErrUnknownCommand:
			Out.String("Неизвестная команда: ");
			Out.String(cmd); Out.Ln;
			PrintUsage
		| ErrNotEnoughArgs:
			Out.String("Недостаточно аргументов для команды: ");
			Out.String(cmd)
		| ErrTooLongModuleDirs:
			Out.String("Суммарная длина путей с модулями слишком велика")
		| ErrTooManyModuleDirs:
			Out.String("Cлишком много путей с модулями")
		| ErrTooLongCDirs:
			Out.String("Суммарная длина путей с .c-файлами слишком велика")
		| ErrTooLongCc:
			Out.String("Длина опций компилятора C слишком велика")
		| ErrCCompiler:
			Out.String("Ошибка при вызове компилятора C")
		| ErrTooLongRunArgs:
			Out.String("Слишком длинные параметры командной строки")
		| ErrUnexpectArg:
			Out.String("Неожиданный аргумент")
		END;
		Out.Ln
	END
END ErrMessage;

PROCEDURE GenerateC(module: Ast.Module; isMain: BOOLEAN; cmd: Ast.Call;
                    opt: GeneratorC.Options;
                    VAR dir: ARRAY OF CHAR; dirLen: INTEGER): INTEGER;
VAR imp: Ast.Declaration;
	ret: INTEGER;
	iface, impl: File.Out;
BEGIN
	module.mark := TRUE;

	ret := ErrNo;
	imp := module.import;
	WHILE (ret = ErrNo) & (imp # NIL) & (imp IS Ast.Import) DO
		IF ~imp.module.mark THEN
			ret := GenerateC(imp.module, FALSE, NIL, opt, dir, dirLen)
		END;
		imp := imp.next
	END;
	IF ret = ErrNo THEN
		ret := OpenCOutput(iface, impl, module, isMain, dir, dirLen - 1);
		IF ret = ErrNo THEN
			GeneratorC.Generate(iface, impl, module, cmd, opt);
			File.CloseOut(iface);
			File.CloseOut(impl)
		END
	END
	RETURN ret
END GenerateC;

PROCEDURE GetTempOutC(VAR dirCOut, bin: ARRAY OF CHAR; name: Strings.String)
                     : INTEGER;
VAR len, binLen: INTEGER;
	ok: BOOLEAN;
	cmd: Exec.Code;
BEGIN
	dirCOut := "/tmp/o7c-";
	len := Strings.CalcLen(dirCOut, 0);
	ok := Strings.CopyToChars(dirCOut, len, name);
	ASSERT(ok);
	IF bin[0] = Utf8.Null THEN
		binLen := 0;
		ok := Strings.CopyChars(bin, binLen, dirCOut, 0, len)
		    & Strings.CopyCharsNull(bin, binLen, "/")
		    & Strings.CopyToChars(bin, binLen, name);
		ASSERT(ok)
	END;
	ok := Exec.Init(cmd, "rm")
	    & Exec.Add(cmd, "-rf", 0)
	    & Exec.Add(cmd, dirCOut, 0);
	ASSERT(ok);
	ok := Exec.Do(cmd) = Exec.Ok;

	ok := Exec.Init(cmd, "mkdir")
	    & Exec.Add(cmd, "-p", 0)
	    & Exec.Add(cmd, dirCOut, 0);
	ASSERT(ok);
	ok := Exec.Do(cmd) = Exec.Ok

	RETURN len + 1
END GetTempOutC;

PROCEDURE ToC(res: INTEGER): INTEGER;
VAR ret: INTEGER;
	src: ARRAY 65536 OF CHAR;
	srcLen, srcNameEnd: INTEGER;
	resPath: ARRAY 1024 OF CHAR;
	resPathLen: INTEGER;
	cDirs, cc: ARRAY 4096 OF CHAR;
	mp: ModuleProvider;
	module: Ast.Module;
	opt: GeneratorC.Options;
	arg: INTEGER;
	call: Ast.Call;
	script: BOOLEAN;

	PROCEDURE Bin(module: Ast.Module; call: Ast.Call; opt: GeneratorC.Options;
	              cDirs, cc: ARRAY OF CHAR; VAR bin: ARRAY OF CHAR): INTEGER;
	VAR outC: ARRAY 1024 OF CHAR;
		cmd: Exec.Code;
		outCLen: INTEGER;
		ret, i: INTEGER;
		ok: BOOLEAN;
	BEGIN
		outCLen := GetTempOutC(outC, bin, module.name);
		ret := GenerateC(module, TRUE, call, opt, outC, outCLen);
		outC[outCLen] := Utf8.Null;
		IF ret = ErrNo THEN
			ok := Exec.Init(cmd, "");
			IF cc[0] = Utf8.Null THEN
				ok := ok & Exec.AddClean(cmd, "cc -g -O1");
			ELSE
				ok := ok & Exec.AddClean(cmd, cc)
			END;
			ok := ok
			    & Exec.Add(cmd, "-o", 0)
			    & Exec.Add(cmd, bin, 0)
			    & Exec.Add(cmd, outC, 0)
			    & Exec.AddClean(cmd, "*.c -I")
			    & Exec.Add(cmd, outC, 0);
			i := 0;
			WHILE ok & (cDirs[i] # Utf8.Null) DO
				ok := Exec.Add(cmd, cDirs, i)
				    & Exec.AddClean(cmd, "/*.c -I")
				    & Exec.Add(cmd, cDirs, i);
				i := i + Strings.CalcLen(cDirs, i) + 1
			END;
			Exec.Log(cmd);
			ASSERT(ok);
			IF Exec.Do(cmd) # Exec.Ok THEN
				ret := ErrCCompiler
			END
		END
		RETURN ret
	END Bin;

	PROCEDURE Run(bin: ARRAY OF CHAR; arg: INTEGER): INTEGER;
	VAR cmd: Exec.Code;
		buf: ARRAY 65536 OF CHAR;
		len: INTEGER;
		ret: INTEGER;
	BEGIN
		ret := ErrTooLongRunArgs;
		IF Exec.Init(cmd, bin) THEN
			INC(arg);
			len := 0;
			WHILE (arg < CLI.count)
			    & CLI.Get(buf, len, arg)
			    & Exec.Add(cmd, buf, 0)
			DO
				len := 0;
				INC(arg)
			END;
			IF arg >= CLI.count THEN
				CLI.SetExitCode(Exec.Do(cmd));
				ret := ErrNo
			END
		END
		RETURN ret
	END Run;

	PROCEDURE ParseCommand(src: ARRAY OF CHAR; VAR script: BOOLEAN): INTEGER;
	VAR i, j: INTEGER;

		PROCEDURE Empty(src: ARRAY OF CHAR; VAR j: INTEGER);
		BEGIN
			WHILE (src[j] = " ") OR (src[j] = Utf8.Tab) DO
				INC(j)
			END
		END Empty;
	BEGIN
		i := 0;
		WHILE (src[i] # Utf8.Null) & (src[i] # ".") DO
			INC(i)
		END;
		IF src[i] = "." THEN
			j := i + 1;
			Empty(src, j);
			WHILE (src[j] >= "a") & (src[j] <= "z")
			   OR (src[j] >= "A") & (src[j] <= "Z")
			   OR (src[j] >= "0") & (src[j] <= "9")
			DO
				INC(j)
			END;
			Empty(src, j);
			script := src[j] # Utf8.Null
		ELSE
			script := FALSE
		END
		RETURN i
	END ParseCommand;
BEGIN
	ASSERT(res IN {ResultC .. ResultRun});

	srcLen := 0;
	arg := 3 + ORD(res # ResultRun);
	IF CLI.count < arg THEN
		ret := ErrNotEnoughArgs
	ELSIF ~CLI.Get(src, srcLen, 2) THEN
		ret := ErrTooLongSourceName
	ELSE
		mp := NewProvider();
		mp.fileExt := ".mod"; (* TODO *)
		mp.extLen := Strings.CalcLen(mp.fileExt, 0);
		ret := CopyPath(mp.path, mp.sing, cDirs, cc, arg);
		IF ret = ErrNo THEN
			srcNameEnd := ParseCommand(src, script);
			IF script THEN
				module := Parser.Script(src, mp, mp.opt);
				AddModule(mp, module, FALSE)
			ELSE
				module := GetModule(mp, NIL, src, 0, srcNameEnd)
			END;
			resPathLen := 0;
			resPath[0] := Utf8.Null;
			IF module = NIL THEN
				ret := ErrParse
			ELSIF module.errors # NIL THEN
				PrintErrors(mp.modules.first);
				ret := ErrParse
			ELSIF (res # ResultRun) & ~CLI.Get(resPath, resPathLen, 3) THEN
				ret := ErrTooLongOutName
			ELSE
				IF ~script & (srcNameEnd < srcLen - 1) THEN
					ret := Ast.CommandGet(call, module,
					                      src, srcNameEnd + 1, srcLen - 1)
				ELSE
					call := NIL
				END;
				IF ret # Ast.ErrNo THEN
					AstErrorMessage(ret); Out.Ln;
					ret := ErrParse
				ELSE
					opt := GeneratorC.DefaultOptions();
					CASE res OF
					  ResultC:
						ret := GenerateC(module, call # NIL, call, opt, resPath, resPathLen)
					| ResultBin, ResultRun:
						ret := Bin(module, call, opt, cDirs, cc, resPath);
						IF (res = ResultRun) & (ret = ErrNo) THEN
							ret := Run(resPath, arg)
						END
					END
				END
			END
		END
	END
	RETURN ret
END ToC;

PROCEDURE Start*;
VAR cmd: ARRAY 1024 OF CHAR;
	cmdLen: INTEGER;
	ret: INTEGER;
BEGIN
	Out.Open;
	Log.Turn(FALSE);

	cmdLen := 0;
	IF (CLI.count <= 1) OR ~CLI.Get(cmd, cmdLen, 1) THEN
		ret := ErrWrongArgs
	ELSE
		ret := ErrNo;
		IF cmd = "help" THEN
			PrintUsage;
			Out.Ln
		ELSIF cmd = "to-c" THEN
			ret := ToC(ResultC)
		ELSIF cmd = "to-bin" THEN
			ret := ToC(ResultBin)
		ELSIF cmd = "run" THEN
			ret := ToC(ResultRun)
		ELSE
			ret := ErrUnknownCommand
		END
	END;
	IF ret # ErrNo THEN
		CLI.SetExitCode(1);
		ErrMessage(ret, cmd)
	END
END Start;

PROCEDURE Benchmark*;
VAR i: INTEGER;
BEGIN
	FOR i := 0 TO 10 DO
		Start
	END
END Benchmark;

END Translator.
