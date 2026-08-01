>>SOURCE FORMAT IS FREE
*>================================================================*
*> PROGRAM-ID: APIHANDLER                                         *
*> DESCRIPTION: Native COBOL CGI API using ISAM Indexed Files     *
*>              (ORGANIZATION IS INDEXED). No external C database *
*>              libraries required! 100% Native COBOL syntax.     *
*>================================================================*
IDENTIFICATION DIVISION.
PROGRAM-ID. APIHANDLER.

ENVIRONMENT DIVISION.
INPUT-OUTPUT SECTION.
FILE-CONTROL.
COPY "user_file_control.cpy".


DATA DIVISION.
FILE SECTION.
FD  USER-FILE.
COPY "user_record.cpy".


WORKING-STORAGE SECTION.
01  NEWLINE              PIC X VALUE X'0A'.
01  REQ-PATH             PIC X(512) VALUE SPACES.
01  WS-CLEAN-PATH        PIC X(512) VALUE SPACES.

01  WS-STATUS            PIC XX VALUE "00".
01  EOF-FLAG             PIC X VALUE 'N'.
88 END-OF-FILE       VALUE 'Y'.

01  FIRST-ROW            PIC X VALUE 'Y'.
01  DISP-NUM             PIC Z(9)9 VALUE SPACES.

PROCEDURE DIVISION.
*> Read request path from CGI environment
ACCEPT REQ-PATH FROM ENVIRONMENT "REQUEST_URI".
IF REQ-PATH = SPACES THEN
    ACCEPT REQ-PATH FROM ENVIRONMENT "PATH_INFO"
END-IF.
MOVE FUNCTION TRIM(REQ-PATH) TO WS-CLEAN-PATH.

*> Output standard CGI JSON response header
DISPLAY "Content-type: application/json" NEWLINE END-DISPLAY.

*> Initialize ISAM Indexed File if missing
PERFORM INIT-DATABASE.

*> Route request to matching endpoint handler
EVALUATE TRUE
    *> Status check endpoint
    WHEN WS-CLEAN-PATH = "/api/status" OR WS-CLEAN-PATH = "/api/status/"
        DISPLAY '{"status": "ok", "db": "native COBOL ISAM indexed file"}'

    *> Read all users from native indexed file
    WHEN WS-CLEAN-PATH = "/api/users" OR WS-CLEAN-PATH = "/api/users/"
        PERFORM QUERY-USERS-JSON

    *> Fallback 404 endpoint
    WHEN OTHER
        DISPLAY '{"error": "Endpoint Not Found", "path": "' WS-CLEAN-PATH '"}'
END-EVALUATE.

STOP RUN.

*> Helper subroutine to ensure users.dat exists and has initial data
INIT-DATABASE.
OPEN I-O USER-FILE.
IF WS-STATUS = "35" THEN *> File status 35 = File Not Found
    OPEN OUTPUT USER-FILE
    
    *> Seed sample user record into native COBOL indexed file
    MOVE 00000001 TO U-ID
    MOVE "Alice" TO U-USERNAME
    MOVE "secret123" TO U-PASSWORD
    MOVE "alice@example.com" TO U-EMAIL
    MOVE 00001500 TO U-SCORE
    MOVE 00000001 TO U-RANK
    MOVE FUNCTION RANDOM TO U-KEY
    MOVE 00000800 TO U-SCORE-M
    MOVE 002 TO U-BAGE
    WRITE USER-RECORD END-WRITE

    CLOSE USER-FILE
ELSE
    CLOSE USER-FILE
END-IF.

*> Helper subroutine to read indexed records sequentially and format as JSON
QUERY-USERS-JSON.
OPEN INPUT USER-FILE.
IF WS-STATUS = "00" THEN
    DISPLAY "[" WITH NO ADVANCING
    MOVE 'Y' TO FIRST-ROW
    MOVE 'N' TO EOF-FLAG

    PERFORM UNTIL END-OF-FILE
        READ USER-FILE NEXT RECORD
            AT END
                SET END-OF-FILE TO TRUE
            NOT AT END
                IF FIRST-ROW = 'N' THEN
                    DISPLAY ", " WITH NO ADVANCING
                ELSE
                    MOVE 'N' TO FIRST-ROW
                END-IF

                DISPLAY "{" WITH NO ADVANCING

                *> id
                MOVE U-ID TO DISP-NUM
                DISPLAY '"id": ' FUNCTION TRIM(DISP-NUM) WITH NO ADVANCING

                *> username
                DISPLAY ', "username": "' FUNCTION TRIM(U-USERNAME) '"' WITH NO ADVANCING

                *> password
                DISPLAY ', "password": "' FUNCTION TRIM(U-PASSWORD) '"' WITH NO ADVANCING

                *> email
                DISPLAY ', "email": "' FUNCTION TRIM(U-EMAIL) '"' WITH NO ADVANCING

                *> user_score
                MOVE U-SCORE TO DISP-NUM
                DISPLAY ', "user_score": ' FUNCTION TRIM(DISP-NUM) WITH NO ADVANCING

                *> user_rank
                MOVE U-RANK TO DISP-NUM
                DISPLAY ', "user_rank": ' FUNCTION TRIM(DISP-NUM) WITH NO ADVANCING

                *> user_key
                DISPLAY ', "user_key": "' FUNCTION TRIM(U-KEY) '"' WITH NO ADVANCING

                *> user_score_moeilijk
                MOVE U-SCORE-M TO DISP-NUM
                DISPLAY ', "user_score_moeilijk": ' FUNCTION TRIM(DISP-NUM) WITH NO ADVANCING

                *> bage
                MOVE U-BAGE TO DISP-NUM
                DISPLAY ', "bage": ' FUNCTION TRIM(DISP-NUM) WITH NO ADVANCING

                DISPLAY "}" WITH NO ADVANCING
        END-READ
    END-PERFORM

    DISPLAY "]"
    CLOSE USER-FILE
ELSE
    DISPLAY "[]"
END-IF.

