MODULE PosixDir;

 TYPE
   Dir* = POINTER TO RECORD
   END;

   Ent* = POINTER TO RECORD
   END;

 PROCEDURE Open*(VAR d: Dir; name: ARRAY OF CHAR; ofs: INTEGER): BOOLEAN;
 BEGIN
   ASSERT(FALSE)
   RETURN FALSE
 END Open;

 PROCEDURE Close*(VAR d: Dir): BOOLEAN;
 BEGIN
   ASSERT(FALSE)
   RETURN FALSE
 END Close;

 PROCEDURE Read*(VAR e: Ent; d: Dir): BOOLEAN;
 BEGIN
   ASSERT(FALSE)
   RETURN FALSE
 END Read;

 PROCEDURE CopyName*(VAR buf: ARRAY OF CHAR; VAR ofs: INTEGER; e: Ent): BOOLEAN;
 BEGIN
   ASSERT(FALSE)
   RETURN FALSE
 END CopyName;

END PosixDir.
