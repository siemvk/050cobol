       >>SOURCE FORMAT IS FREE
       *> SERVER.CBL: HTTP Web Server in COBOL replacing Caddy
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SERVER.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       *> Socket descriptors and return codes
       01 SERVER-FD        PIC S9(9) COMP-5 VALUE -1.
       01 CLIENT-FD        PIC S9(9) COMP-5 VALUE -1.
       01 RC               PIC S9(9) COMP-5 VALUE 0.
       01 OPTVAL           PIC S9(9) COMP-5 VALUE 1.

       *> sockaddr_in structure for port 8080 binding (16 bytes)
       01 SOCKADDR-IN.
          05 SIN-LEN       PIC X VALUE X"10".
          05 SIN-FAMILY    PIC X VALUE X"02".
          05 SIN-PORT      PIC X(2) VALUE X"1F90". *> Port 8080 network byte order
          05 SIN-ADDR      PIC X(4) VALUE X"00000000".
          05 SIN-ZERO      PIC X(8) VALUE X"0000000000000000".
       01 ADDR-LEN         PIC S9(9) COMP-5 VALUE 16.

       *> Request reading & routing buffers
       01 REQ-BUF          PIC X(4096) VALUE SPACES.
       01 BYTES-READ       PIC S9(9) COMP-5 VALUE 0.

       01 REQ-METHOD       PIC X(10) VALUE SPACES.
       01 REQ-PATH         PIC X(512) VALUE SPACES.
       01 CGI-CMD          PIC X(512) VALUE SPACES.
       01 NULL-CGI-CMD     PIC X(513) VALUE SPACES.
       01 NULL-MODE        PIC X(2) VALUE "r" & X"00".
       01 NULL-ENV-NAME    PIC X(256) VALUE SPACES.
       01 NULL-ENV-VAL     PIC X(512) VALUE SPACES.

       *> Pipe streaming buffers
       01 PIPE-PTR         USAGE POINTER VALUE NULL.
       01 BUF-SIZE         PIC S9(9) COMP-5 VALUE 4096.
       01 IO-BUF           PIC X(4096).
       01 HTTP-OK          PIC X(19) VALUE "HTTP/1.1 200 OK" & X"0D" & X"0A".
       01 HTTP-OK-LEN      PIC S9(9) COMP-5 VALUE 17.

       PROCEDURE DIVISION.
           *> 1. Create socket (AF_INET=2, SOCK_STREAM=1, protocol=0)
           CALL "socket" USING BY VALUE 2 BY VALUE 1 BY VALUE 0 RETURNING SERVER-FD.
           IF SERVER-FD < 0 THEN
               DISPLAY "Failed to create socket."
               STOP RUN
           END-IF.

           *> 2. Set SO_REUSEADDR option
           CALL "setsockopt" USING BY VALUE SERVER-FD BY VALUE 65535 BY VALUE 4 BY REFERENCE OPTVAL BY VALUE 4 RETURNING RC.

           *> 3. Bind socket to 0.0.0.0:8080
           CALL "bind" USING BY VALUE SERVER-FD BY REFERENCE SOCKADDR-IN BY VALUE ADDR-LEN RETURNING RC.
           IF RC < 0 THEN
               DISPLAY "Failed to bind socket on port 8080."
               CALL "close" USING BY VALUE SERVER-FD
               STOP RUN
           END-IF.

           *> 4. Listen for incoming connections
           CALL "listen" USING BY VALUE SERVER-FD BY VALUE 10 RETURNING RC.
           IF RC < 0 THEN
               DISPLAY "Failed to listen on socket."
               CALL "close" USING BY VALUE SERVER-FD
               STOP RUN
           END-IF.

           DISPLAY "COBOL HTTP Server running on http://localhost:8080 ...".

           *> 5. Accept and process client connections loop
           PERFORM UNTIL EXIT
               CALL "accept" USING BY VALUE SERVER-FD BY VALUE 0 BY VALUE 0 RETURNING CLIENT-FD
               IF CLIENT-FD >= 0 THEN
                   MOVE SPACES TO REQ-BUF
                   CALL "read" USING BY VALUE CLIENT-FD BY REFERENCE REQ-BUF BY VALUE 4096 RETURNING BYTES-READ
                   IF BYTES-READ > 0 THEN
                       PERFORM HANDLE-REQUEST
                   END-IF
                   CALL "close" USING BY VALUE CLIENT-FD
               END-IF
           END-PERFORM.

           CALL "close" USING BY VALUE SERVER-FD.
           STOP RUN.

       *> Handle HTTP request and delegate to CGI scripts
       HANDLE-REQUEST.
           MOVE SPACES TO REQ-METHOD REQ-PATH.
           UNSTRING REQ-BUF DELIMITED BY SPACES INTO REQ-METHOD REQ-PATH.

           *> Set CGI environment variables
           MOVE "REQUEST_METHOD" TO NULL-ENV-NAME
           PERFORM SET-ENV-VAR-1

           MOVE "REQUEST_URI" TO NULL-ENV-NAME
           MOVE REQ-PATH TO NULL-ENV-VAL
           PERFORM SET-ENV-VAR-2

           *> Route request to appropriate CGI handler
           IF REQ-PATH(1:5) = "/api/" OR REQ-PATH(1:5) = "/api" THEN
               MOVE "./api.cgi" TO CGI-CMD
           ELSE
               MOVE "./helloweb.cgi" TO CGI-CMD
           END-IF.

           MOVE SPACES TO NULL-CGI-CMD.
           STRING FUNCTION TRIM(CGI-CMD) DELIMITED BY SIZE
                  X"00" DELIMITED BY SIZE
                  INTO NULL-CGI-CMD
           END-STRING.

           *> Write HTTP 200 OK header line
           CALL "write" USING BY VALUE CLIENT-FD BY REFERENCE HTTP-OK BY VALUE HTTP-OK-LEN RETURNING RC.

           *> Execute CGI script and pipe standard output to client socket
           CALL "popen" USING BY REFERENCE NULL-CGI-CMD BY REFERENCE NULL-MODE RETURNING PIPE-PTR.
           IF PIPE-PTR NOT = NULL THEN
               PERFORM UNTIL EXIT
                   CALL "fread" USING BY REFERENCE IO-BUF BY VALUE 1 BY VALUE BUF-SIZE BY VALUE PIPE-PTR RETURNING BYTES-READ
                   IF BYTES-READ <= 0 THEN
                       EXIT PERFORM
                   END-IF
                   CALL "write" USING BY VALUE CLIENT-FD BY REFERENCE IO-BUF BY VALUE BYTES-READ RETURNING RC
               END-PERFORM
               CALL "pclose" USING BY VALUE PIPE-PTR RETURNING RC
           END-IF.

       *> Helper to set REQUEST_METHOD environment variable
       SET-ENV-VAR-1.
           MOVE SPACES TO NULL-ENV-VAL.
           STRING FUNCTION TRIM(REQ-METHOD) DELIMITED BY SIZE X"00" DELIMITED BY SIZE INTO NULL-ENV-VAL END-STRING.
           MOVE SPACES TO NULL-CGI-CMD.
           STRING FUNCTION TRIM(NULL-ENV-NAME) DELIMITED BY SIZE X"00" DELIMITED BY SIZE INTO NULL-CGI-CMD END-STRING.
           CALL "setenv" USING BY REFERENCE NULL-CGI-CMD BY REFERENCE NULL-ENV-VAL BY VALUE 1.

       *> Helper to set REQUEST_URI environment variable
       SET-ENV-VAR-2.
           MOVE SPACES TO NULL-CGI-CMD.
           STRING FUNCTION TRIM(NULL-ENV-NAME) DELIMITED BY SIZE X"00" DELIMITED BY SIZE INTO NULL-CGI-CMD END-STRING.
           MOVE SPACES TO REQ-BUF.
           STRING FUNCTION TRIM(NULL-ENV-VAL) DELIMITED BY SIZE X"00" DELIMITED BY SIZE INTO REQ-BUF END-STRING.
           CALL "setenv" USING BY REFERENCE NULL-CGI-CMD BY REFERENCE REQ-BUF BY VALUE 1.
