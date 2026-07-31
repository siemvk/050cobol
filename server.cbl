       >>SOURCE FORMAT IS FREE
      *>================================================================*
      *> SERVER.CBL: COBOL HTTP Web Server with File-Based Routing     *
      *>================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SERVER.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 SERVER-FD        PIC S9(9) COMP-5 VALUE -1.
       01 CLIENT-FD        PIC S9(9) COMP-5 VALUE -1.
       01 RC               PIC S9(9) COMP-5 VALUE 0.
       01 OPTVAL           PIC S9(9) COMP-5 VALUE 1.

       01 SOCKADDR-IN.
          05 SIN-LEN       PIC X VALUE X"10".
          05 SIN-FAMILY    PIC X VALUE X"02".
          05 SIN-PORT      PIC X(2) VALUE X"1F90". *> Port 8080
          05 SIN-ADDR      PIC X(4) VALUE X"00000000".
          05 SIN-ZERO      PIC X(8) VALUE X"0000000000000000".
       01 ADDR-LEN         PIC S9(9) COMP-5 VALUE 16.

       01 REQ-BUF          PIC X(65536) VALUE SPACES.
       01 BYTES-READ       PIC S9(9) COMP-5 VALUE 0.

       01 REQ-METHOD       PIC X(10) VALUE SPACES.
       01 REQ-PATH         PIC X(512) VALUE SPACES.
       01 REQ-BODY         PIC X(4096) VALUE SPACES.
       01 RESP-BODY        PIC X(65536) VALUE SPACES.

       01 ROUTE-PROG       PIC X(64) VALUE SPACES.
       01 CLEAN-PATH       PIC X(512) VALUE SPACES.
       01 BODY-POS         PIC 9(6) VALUE 0.
       01 RESP-LEN         PIC S9(9) COMP-5 VALUE 0.

       01 SYS-CMD          PIC X(512) VALUE SPACES.
       01 FILE-DESC        PIC S9(9) COMP-5 VALUE -1.
       01 STREAM-BYTES     PIC S9(9) COMP-5 VALUE 0.
       01 TMP-FILE         PIC X(64) VALUE "/tmp/static_out.txt" & X"00".

       01 HTTP-OK          PIC X(19) VALUE "HTTP/1.1 200 OK" & X"0D" & X"0A".
       01 HTTP-OK-LEN      PIC S9(9) COMP-5 VALUE 17.

       PROCEDURE DIVISION.
           CALL "socket" USING BY VALUE 2 BY VALUE 1 BY VALUE 0 RETURNING SERVER-FD.
           IF SERVER-FD < 0 THEN
               DISPLAY "Failed to create socket."
               STOP RUN
           END-IF.

           CALL "setsockopt" USING BY VALUE SERVER-FD BY VALUE 65535 BY VALUE 4 BY REFERENCE OPTVAL BY VALUE 4 RETURNING RC.

           CALL "bind" USING BY VALUE SERVER-FD BY REFERENCE SOCKADDR-IN BY VALUE ADDR-LEN RETURNING RC.
           IF RC < 0 THEN
               DISPLAY "Failed to bind socket on port 8080."
               CALL "close" USING BY VALUE SERVER-FD
               STOP RUN
           END-IF.

           CALL "listen" USING BY VALUE SERVER-FD BY VALUE 10 RETURNING RC.
           IF RC < 0 THEN
               DISPLAY "Failed to listen on socket."
               CALL "close" USING BY VALUE SERVER-FD
               STOP RUN
           END-IF.

           DISPLAY "COBOL File-Based Web Server running on http://localhost:8080 ...".

           PERFORM UNTIL EXIT
               CALL "accept" USING BY VALUE SERVER-FD BY VALUE 0 BY VALUE 0 RETURNING CLIENT-FD
               IF CLIENT-FD >= 0 THEN
                   MOVE SPACES TO REQ-BUF
                   CALL "read" USING BY VALUE CLIENT-FD BY REFERENCE REQ-BUF BY VALUE 65536 RETURNING BYTES-READ
                   IF BYTES-READ > 0 THEN
                       PERFORM HANDLE-REQUEST
                   END-IF
                   CALL "close" USING BY VALUE CLIENT-FD
               END-IF
           END-PERFORM.

           CALL "close" USING BY VALUE SERVER-FD.
           STOP RUN.

       HANDLE-REQUEST.
           MOVE SPACES TO REQ-METHOD REQ-PATH REQ-BODY RESP-BODY ROUTE-PROG.
           UNSTRING REQ-BUF DELIMITED BY SPACES INTO REQ-METHOD REQ-PATH.

           MOVE 0 TO BODY-POS.
           INSPECT REQ-BUF TALLYING BODY-POS FOR CHARACTERS BEFORE INITIAL X"0D0A0D0A".
           IF BODY-POS < 60000 THEN
               COMPUTE BODY-POS = BODY-POS + 5
               IF REQ-BUF(BODY-POS:) NOT = SPACES THEN
                   MOVE REQ-BUF(BODY-POS:) TO REQ-BODY
               END-IF
           END-IF.

           MOVE FUNCTION TRIM(REQ-PATH) TO CLEAN-PATH.
           IF CLEAN-PATH = "/api/status" OR CLEAN-PATH = "/api/status/" THEN
               MOVE "api_status" TO ROUTE-PROG
           ELSE IF CLEAN-PATH = "/api/users" OR CLEAN-PATH = "/api/users/" THEN
               MOVE "api_users" TO ROUTE-PROG
           ELSE IF CLEAN-PATH = "/api/leaderboard" OR CLEAN-PATH = "/api/leaderboard/" THEN
               MOVE "api_leaderboard" TO ROUTE-PROG
           ELSE IF CLEAN-PATH(1:19) = "/api/maak_acount_V2" THEN
               MOVE "api_maak_acount_V2" TO ROUTE-PROG
           ELSE IF CLEAN-PATH(1:10) = "/api/login" THEN
               MOVE "api_login" TO ROUTE-PROG
           ELSE
               MOVE SPACES TO ROUTE-PROG
           END-IF.

           CALL "write" USING BY VALUE CLIENT-FD BY REFERENCE HTTP-OK BY VALUE HTTP-OK-LEN RETURNING RC.

           IF ROUTE-PROG NOT = SPACES THEN
               CALL ROUTE-PROG USING REQ-METHOD, REQ-PATH, REQ-BODY, RESP-BODY
               CALL "strlen" USING BY REFERENCE RESP-BODY RETURNING RESP-LEN
               IF RESP-LEN > 0 THEN
                   CALL "write" USING BY VALUE CLIENT-FD BY REFERENCE RESP-BODY BY VALUE RESP-LEN RETURNING RC
               END-IF
           ELSE
               MOVE SPACES TO SYS-CMD
               STRING "REQUEST_URI='" DELIMITED BY SIZE
                      FUNCTION TRIM(REQ-PATH) DELIMITED BY SIZE
                      "' ./helloweb.cgi > /tmp/static_out.txt" DELIMITED BY SIZE
                      X"00" DELIMITED BY SIZE
                      INTO SYS-CMD
               END-STRING
               CALL "system" USING BY REFERENCE SYS-CMD

               CALL "open" USING TMP-FILE BY VALUE 0 RETURNING FILE-DESC
               IF FILE-DESC >= 0 THEN
                   MOVE 1 TO STREAM-BYTES
                   PERFORM UNTIL STREAM-BYTES <= 0
                       CALL "read" USING BY VALUE FILE-DESC BY REFERENCE RESP-BODY BY VALUE 65536 RETURNING STREAM-BYTES
                       IF STREAM-BYTES > 0 THEN
                           CALL "write" USING BY VALUE CLIENT-FD BY REFERENCE RESP-BODY BY VALUE STREAM-BYTES RETURNING RC
                       END-IF
                   END-PERFORM
                   CALL "close" USING BY VALUE FILE-DESC
               END-IF
           END-IF.
