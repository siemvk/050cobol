       >>SOURCE FORMAT IS FREE
      *>================================================================*
      *> FILE-BASED ROUTE: routes/api/maak_acount_V2.cbl                *
      *> PROGRAM-ID: api_maak_acount_V2                                 *
      *>================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. api_maak_acount_V2.

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
       01  WS-STATUS            PIC XX VALUE "00".
       01  EOF-FLAG             PIC X VALUE 'N'.
           88 END-OF-FILE       VALUE 'Y'.

       01  OUT-PTR              PIC 9(6) VALUE 1.

       01  ARG-EMPTY            PIC X(50) VALUE SPACES.
       01  ARG-API              PIC X(50) VALUE SPACES.
       01  ARG-ROUTE            PIC X(50) VALUE SPACES.
       01  RAW-PWD              PIC X(50) VALUE SPACES.
       01  PWD-LEN              BINARY-LONG VALUE 0.
       01  HASH-OUT             PIC X(64) VALUE SPACES.

       01  MAX-ID               PIC 9(8) VALUE 0.
       01  NEW-ID               PIC 9(8) VALUE 1.

       LINKAGE SECTION.
       01  LS-METHOD        PIC X(10).
       01  LS-URI           PIC X(512).
       01  LS-PAYLOAD       PIC X(4096).
       01  LS-RESP-BODY     PIC X(4096).

       PROCEDURE DIVISION USING LS-METHOD, LS-URI, LS-PAYLOAD, LS-RESP-BODY.
           PERFORM MAKE-ACC.
           GOBACK.

       MAKE-ACC.
           MOVE LOW-VALUES TO LS-RESP-BODY.
           MOVE 1 TO OUT-PTR.

           INITIALIZE USER-RECORD.

           *> Parse URL /api/maak_acount_V2/username/password/email
           UNSTRING LS-URI DELIMITED BY "/"
               INTO ARG-EMPTY
                    ARG-API
                    ARG-ROUTE
                    U-USERNAME
                    RAW-PWD
                    U-EMAIL
           END-UNSTRING.

           IF U-USERNAME = SPACES THEN PERFORM RETURN-ERROR GOBACK END-IF.
           IF RAW-PWD = SPACES THEN PERFORM RETURN-ERROR GOBACK END-IF.
           IF U-EMAIL = SPACES THEN PERFORM RETURN-ERROR GOBACK END-IF.

           *> Hash password using HashService (OpenSSL SHA256)
           COMPUTE PWD-LEN = FUNCTION LENGTH(FUNCTION TRIM(RAW-PWD)).
           CALL "HashService" USING RAW-PWD PWD-LEN HASH-OUT END-CALL.
           

           MOVE HASH-OUT TO U-PASSWORD.

           *> Find next available U-ID
           MOVE 0 TO MAX-ID.
           OPEN I-O USER-FILE.
           IF WS-STATUS = "35" THEN
               OPEN OUTPUT USER-FILE
               CLOSE USER-FILE
               OPEN I-O USER-FILE
           END-IF.

           MOVE 'N' TO EOF-FLAG.
           PERFORM UNTIL END-OF-FILE
               READ USER-FILE NEXT RECORD
                   AT END
                       SET END-OF-FILE TO TRUE
                   NOT AT END
                       IF U-ID > MAX-ID THEN MOVE U-ID TO MAX-ID END-IF
               END-READ
           END-PERFORM.

           COMPUTE NEW-ID = MAX-ID + 1.
           MOVE NEW-ID TO U-ID.
           MOVE FUNCTION RANDOM TO U-KEY.
           MOVE 00000000 TO U-SCORE.
           MOVE 00000001 TO U-RANK.
           MOVE 00000000 TO U-SCORE-M.
           MOVE 0000 TO U-BAGE.

           WRITE USER-RECORD INVALID KEY REWRITE USER-RECORD END-WRITE.
           CLOSE USER-FILE.

           *> Return response expected by frontend (account aangemaakt)
           STRING "Content-type: text/plain" DELIMITED BY SIZE
                  NEWLINE DELIMITED BY SIZE
                  NEWLINE DELIMITED BY SIZE
                  "account aangemaakt" DELIMITED BY SIZE
                  INTO LS-RESP-BODY
                  WITH POINTER OUT-PTR
           END-STRING.

           MOVE X"00" TO LS-RESP-BODY(OUT-PTR:1).

       RETURN-ERROR.
           STRING "Content-type: application/json" DELIMITED BY SIZE
                  NEWLINE DELIMITED BY SIZE
                  NEWLINE DELIMITED BY SIZE
                  '{"status": "ERROR"}' DELIMITED BY SIZE
                  INTO LS-RESP-BODY
                  WITH POINTER OUT-PTR
           END-STRING.
           MOVE X"00" TO LS-RESP-BODY(OUT-PTR:1).
