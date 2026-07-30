       >>SOURCE FORMAT IS FREE
       IDENTIFICATION DIVISION.
       PROGRAM-ID. HELLOWEB.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TEXT-FILE ASSIGN TO WS-FILENAME
           ORGANIZATION IS LINE SEQUENTIAL
           FILE STATUS IS WS-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  TEXT-FILE.
       01  TEXT-RECORD       PIC X(65536).

       WORKING-STORAGE SECTION.
       01  NEWLINE           PIC X VALUE X'0A'.
       01  USER-AGENT        PIC X(512) VALUE SPACES.
       01  REQ-PATH          PIC X(512) VALUE SPACES.
       01  WS-CLEAN-PATH     PIC X(512) VALUE SPACES.
       01  TARGET-NAME       PIC X(256) VALUE SPACES.
       01  WS-FILENAME       PIC X(256) VALUE SPACES.
       01  WS-LINE           PIC X(65536) VALUE SPACES.
       01  WS-STATUS         PIC XX VALUE "00".
       01  EOF-FLAG          PIC X VALUE 'N'.
           88 END-OF-FILE    VALUE 'Y'.

       01  PATH-LEN          PIC 9(4) COMP VALUE 0.
       01  EXT-3             PIC X(3) VALUE SPACES.
       01  EXT-4             PIC X(4) VALUE SPACES.
       01  IS-BINARY         PIC X VALUE 'N'.

       01  F-HANDLE          PIC X(4).
       01  F-OFFSET          PIC 9(18) COMP-5 VALUE 0.
       01  F-BUF-SIZE        PIC 9(4) COMP-5 VALUE 4096.
       01  F-FLAGS           PIC X VALUE X"00".
       01  F-BYTES-READ      PIC 9(4) COMP-5 VALUE 4096.
       01  F-STATUS          PIC S9(4) COMP-5 VALUE 0.
       01  STDOUT-FD         PIC S9(9) COMP-5 VALUE 1.

       PROCEDURE DIVISION.
           ACCEPT USER-AGENT FROM ENVIRONMENT "HTTP_USER_AGENT".
           ACCEPT REQ-PATH FROM ENVIRONMENT "REQUEST_URI".

           IF REQ-PATH = SPACES THEN
               ACCEPT REQ-PATH FROM ENVIRONMENT "PATH_INFO"
           END-IF.

           MOVE FUNCTION TRIM(REQ-PATH) TO WS-CLEAN-PATH.

           *> Determine relative target filename
           EVALUATE TRUE
               WHEN WS-CLEAN-PATH = "/" OR WS-CLEAN-PATH = SPACES OR WS-CLEAN-PATH = "/index.html"
                   MOVE "index.html" TO TARGET-NAME
               WHEN WS-CLEAN-PATH(1:1) = "/"
                   MOVE FUNCTION TRIM(WS-CLEAN-PATH(2:)) TO TARGET-NAME
               WHEN OTHER
                   MOVE WS-CLEAN-PATH TO TARGET-NAME
           END-EVALUATE.

           *> Build full path inside src/ directory
           MOVE SPACES TO WS-FILENAME.
           STRING "src/" DELIMITED BY SIZE
                  FUNCTION TRIM(TARGET-NAME) DELIMITED BY SIZE
                  INTO WS-FILENAME
           END-STRING.

           *> Inspect extension to set correct Content-Type header and mode
           COMPUTE PATH-LEN = FUNCTION LENGTH(FUNCTION TRIM(TARGET-NAME)).
           IF PATH-LEN >= 4 THEN
               MOVE TARGET-NAME(PATH-LEN - 3 : 4) TO EXT-4
           END-IF.
           IF PATH-LEN >= 3 THEN
               MOVE TARGET-NAME(PATH-LEN - 2 : 3) TO EXT-3
           END-IF.

           MOVE 'N' TO IS-BINARY.

           EVALUATE TRUE
               WHEN EXT-4 = ".css" OR EXT-4 = ".CSS"
                   DISPLAY "Content-type: text/css" NEWLINE END-DISPLAY
               WHEN EXT-3 = ".js" OR EXT-3 = ".JS"
                   DISPLAY "Content-type: text/javascript" NEWLINE END-DISPLAY
               WHEN EXT-4 = ".png" OR EXT-4 = ".PNG"
                   DISPLAY "Content-type: image/png" NEWLINE END-DISPLAY
                   MOVE 'Y' TO IS-BINARY
               WHEN EXT-4 = ".jpg" OR EXT-4 = ".JPG" OR EXT-4 = "jpeg" OR EXT-4 = "JPEG"
                   DISPLAY "Content-type: image/jpeg" NEWLINE END-DISPLAY
                   MOVE 'Y' TO IS-BINARY
               WHEN EXT-4 = ".gif" OR EXT-4 = ".GIF"
                   DISPLAY "Content-type: image/gif" NEWLINE END-DISPLAY
                   MOVE 'Y' TO IS-BINARY
               WHEN EXT-4 = ".ico" OR EXT-4 = ".ICO"
                   DISPLAY "Content-type: image/x-icon" NEWLINE END-DISPLAY
                   MOVE 'Y' TO IS-BINARY
               WHEN EXT-4 = ".svg" OR EXT-4 = ".SVG"
                   DISPLAY "Content-type: image/svg+xml" NEWLINE END-DISPLAY
               WHEN EXT-4 = ".json" OR EXT-4 = ".JSON"
                   DISPLAY "Content-type: application/json" NEWLINE END-DISPLAY
               WHEN OTHER
                   DISPLAY "Content-type: text/html" NEWLINE END-DISPLAY
           END-EVALUATE.

           IF IS-BINARY = 'Y' THEN
               *> TODO Impl diff handeling for
           ELSE
               OPEN INPUT TEXT-FILE
               IF WS-STATUS = "00" THEN
                   PERFORM UNTIL END-OF-FILE
                       READ TEXT-FILE INTO WS-LINE
                           AT END
                               SET END-OF-FILE TO TRUE
                           NOT AT END
                               DISPLAY FUNCTION TRIM(WS-LINE, TRAILING)
                       END-READ
                   END-PERFORM
                   CLOSE TEXT-FILE
               ELSE
                   DISPLAY "<h1>404 - File Not Found</h1>"
                   DISPLAY "<p>Status code: " WS-STATUS "</p>"
               END-IF
           END-IF.

           STOP RUN.