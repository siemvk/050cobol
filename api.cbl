       >>SOURCE FORMAT IS FREE
       *> APIHANDLER: GnuCOBOL CGI API with SQLite integration
       IDENTIFICATION DIVISION.
       PROGRAM-ID. APIHANDLER.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       *> HTTP & CGI path variables
       01  NEWLINE           PIC X VALUE X'0A'.
       01  REQ-PATH          PIC X(512) VALUE SPACES.
       01  WS-CLEAN-PATH     PIC X(512) VALUE SPACES.

       *> SQLite database path and C handles
       01  DB-PATH           PIC X(256) VALUE "app.db".
       01  DB-NULL-PATH      PIC X(257) VALUE SPACES.
       01  DB-HANDLE         USAGE POINTER VALUE NULL.
       01  STMT-HANDLE       USAGE POINTER VALUE NULL.

       *> SQL execution buffers
       01  SQL-STMT          PIC X(1024) VALUE SPACES.
       01  SQL-NULL          PIC X(1025) VALUE SPACES.
       01  ERR-MSG           USAGE POINTER VALUE NULL.
       01  RC                PIC S9(9) COMP-5 VALUE 0.

       *> JSON formatting helpers
       01  FIRST-ROW         PIC X VALUE 'Y'.
       01  COL-LEN           PIC S9(9) COMP-5 VALUE 0.
       01  PTR-VAL           USAGE POINTER VALUE NULL.
       01  DISP-NUM          PIC Z(9)9 VALUE SPACES.
       01  VAL-INT           PIC S9(9) COMP-5 VALUE 0.

       LINKAGE SECTION.
       *> Mapping buffer for C string pointers
       01  COL-STR           PIC X(512).

       PROCEDURE DIVISION.
           *> Read request path from CGI environment
           ACCEPT REQ-PATH FROM ENVIRONMENT "REQUEST_URI".
           IF REQ-PATH = SPACES THEN
               ACCEPT REQ-PATH FROM ENVIRONMENT "PATH_INFO"
           END-IF.
           MOVE FUNCTION TRIM(REQ-PATH) TO WS-CLEAN-PATH.

           *> Output standard CGI JSON response header
           DISPLAY "Content-type: application/json" NEWLINE END-DISPLAY.

           *> Open SQLite database connection
           MOVE SPACES TO DB-NULL-PATH.
           STRING FUNCTION TRIM(DB-PATH) DELIMITED BY SIZE
                  X"00" DELIMITED BY SIZE
                  INTO DB-NULL-PATH
           END-STRING.

           CALL "sqlite3_open" USING BY REFERENCE DB-NULL-PATH
                                     BY REFERENCE DB-HANDLE
                              RETURNING RC.

           *> Create users table schema if it doesn't exist
           IF RC = 0 THEN
               MOVE "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, username VARCHAR(255), password VARCHAR(255), email VARCHAR(255), user_score INT, user_rank INT, user_key VARCHAR(255), user_score_moeilijk INT, bage INT);" TO SQL-STMT
               PERFORM EXEC-SQL
           END-IF.

           *> Route request to matching endpoint handler
           EVALUATE TRUE
               *> Status check endpoint
               WHEN WS-CLEAN-PATH = "/api/status" OR WS-CLEAN-PATH = "/api/status/"
                   DISPLAY '{"status": "ok", "db": "connected"}'

               *> Example DB reading endpoint
               WHEN WS-CLEAN-PATH = "/api/users" OR WS-CLEAN-PATH = "/api/users/"
                   MOVE "SELECT id, username, email, user_score FROM users;" TO SQL-STMT
                   PERFORM QUERY-USERS-EXAMPLE

               *> Fallback 404 endpoint
               WHEN OTHER
                   DISPLAY '{"error": "Endpoint Not Found", "path": "' WS-CLEAN-PATH '"}'
           END-EVALUATE.

           *> Close SQLite connection
           IF DB-HANDLE NOT = NULL THEN
               CALL "sqlite3_close" USING BY VALUE DB-HANDLE RETURNING RC
           END-IF.

           STOP RUN.

       *> Helper subroutine to execute non-query SQL (CREATE, INSERT, UPDATE)
       EXEC-SQL.
           MOVE SPACES TO SQL-NULL
           STRING FUNCTION TRIM(SQL-STMT) DELIMITED BY SIZE
                  X"00" DELIMITED BY SIZE
                  INTO SQL-NULL
           END-STRING
           CALL "sqlite3_exec" USING BY VALUE DB-HANDLE
                                     BY REFERENCE SQL-NULL
                                     BY VALUE 0
                                     BY VALUE 0
                                     BY REFERENCE ERR-MSG
                               RETURNING RC.

       *> Helper subroutine demonstrating SQL query execution & JSON serialization
       QUERY-USERS-EXAMPLE.
           MOVE SPACES TO SQL-NULL
           STRING FUNCTION TRIM(SQL-STMT) DELIMITED BY SIZE
                  X"00" DELIMITED BY SIZE
                  INTO SQL-NULL
           END-STRING

           *> Prepare SQL query statement
           CALL "sqlite3_prepare_v2" USING BY VALUE DB-HANDLE
                                           BY REFERENCE SQL-NULL
                                           BY VALUE -1
                                           BY REFERENCE STMT-HANDLE
                                           BY VALUE 0
                                     RETURNING RC.

           IF RC = 0 THEN
               DISPLAY "[" WITH NO ADVANCING
               MOVE 'Y' TO FIRST-ROW

               *> Loop through fetched database rows (RC = 100 indicates SQLITE_ROW)
               PERFORM UNTIL EXIT
                   CALL "sqlite3_step" USING BY VALUE STMT-HANDLE RETURNING RC
                   IF RC NOT = 100 THEN
                       EXIT PERFORM
                   END-IF

                   IF FIRST-ROW = 'N' THEN
                       DISPLAY ", " WITH NO ADVANCING
                   ELSE
                       MOVE 'N' TO FIRST-ROW
                   END-IF

                   DISPLAY "{" WITH NO ADVANCING

                   *> Read Column 0: id (INTEGER)
                   CALL "sqlite3_column_int" USING BY VALUE STMT-HANDLE BY VALUE 0 RETURNING VAL-INT
                   MOVE VAL-INT TO DISP-NUM
                   DISPLAY '"id": ' FUNCTION TRIM(DISP-NUM) WITH NO ADVANCING

                   *> Read Column 1: username (TEXT)
                   CALL "sqlite3_column_text" USING BY VALUE STMT-HANDLE BY VALUE 1 RETURNING PTR-VAL
                   DISPLAY ', "username": "' WITH NO ADVANCING
                   PERFORM PRINT-TEXT-COL

                   *> Read Column 2: email (TEXT)
                   CALL "sqlite3_column_text" USING BY VALUE STMT-HANDLE BY VALUE 2 RETURNING PTR-VAL
                   DISPLAY '", "email": "' WITH NO ADVANCING
                   PERFORM PRINT-TEXT-COL

                   *> Read Column 3: user_score (INTEGER)
                   CALL "sqlite3_column_int" USING BY VALUE STMT-HANDLE BY VALUE 3 RETURNING VAL-INT
                   MOVE VAL-INT TO DISP-NUM
                   DISPLAY '", "user_score": ' FUNCTION TRIM(DISP-NUM) WITH NO ADVANCING

                   DISPLAY "}" WITH NO ADVANCING
               END-PERFORM

               DISPLAY "]"
               CALL "sqlite3_finalize" USING BY VALUE STMT-HANDLE RETURNING RC
           ELSE
               DISPLAY "[]"
           END-IF.

       *> Helper subroutine to print C text string pointers returned from SQLite
       PRINT-TEXT-COL.
           IF PTR-VAL NOT = NULL THEN
               SET ADDRESS OF COL-STR TO PTR-VAL
               CALL "strlen" USING BY VALUE PTR-VAL RETURNING COL-LEN
               IF COL-LEN > 0 THEN
                   DISPLAY COL-STR(1:COL-LEN) WITH NO ADVANCING
               END-IF
           END-IF.
