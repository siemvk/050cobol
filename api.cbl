       >>SOURCE FORMAT IS FREE
       IDENTIFICATION DIVISION.
       PROGRAM-ID. APIHANDLER.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  NEWLINE           PIC X VALUE X'0A'.
       01  REQ-PATH          PIC X(512) VALUE SPACES.
       01  WS-CLEAN-PATH     PIC X(512) VALUE SPACES.
       01  REQ-METHOD        PIC X(10) VALUE SPACES.

       PROCEDURE DIVISION.
           ACCEPT REQ-PATH FROM ENVIRONMENT "REQUEST_URI".
           ACCEPT REQ-METHOD FROM ENVIRONMENT "REQUEST_METHOD".

           IF REQ-PATH = SPACES THEN
               ACCEPT REQ-PATH FROM ENVIRONMENT "PATH_INFO"
           END-IF.

           MOVE FUNCTION TRIM(REQ-PATH) TO WS-CLEAN-PATH.

           *> HTTP Header for JSON API response
           DISPLAY "Content-type: application/json" NEWLINE END-DISPLAY.

           EVALUATE TRUE
               WHEN WS-CLEAN-PATH = "/api/status" OR WS-CLEAN-PATH = "/api/status/"
                   DISPLAY '{"status": "ok", "server": "GnuCOBOL API"}'
               WHEN WS-CLEAN-PATH = "/api/users" OR WS-CLEAN-PATH = "/api/users/"
                   DISPLAY '[{"id": 1, "name": "Alice"}, {"id": 2, "name": "Bob"}]'
               WHEN OTHER
                   DISPLAY '{"error": "API Endpoint Not Found", "path": "' WS-CLEAN-PATH '"}'
           END-EVALUATE.

           STOP RUN.
