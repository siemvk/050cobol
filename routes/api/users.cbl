       >>SOURCE FORMAT IS FREE
      *>================================================================*
      *> FILE-BASED ROUTE: routes/api/users.cbl                         *
      *> PROGRAM-ID: api_users                                          *
      *>================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. api_users.

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

       01  FIRST-ROW            PIC X VALUE 'Y'.
       01  DISP-NUM             PIC Z(9)9 VALUE SPACES.
       01  OUT-PTR              PIC 9(6) VALUE 1.

       01  MAX-ID               PIC 9(8) VALUE 0.
       01  NEW-ID               PIC 9(8) VALUE 1.
       01  DISP-ID              PIC Z(9)9 VALUE SPACES.

       01  POS-START            PIC 9(4) VALUE 0.
       01  VAL-LEN              PIC 9(4) VALUE 0.

       LINKAGE SECTION.
       01  LS-METHOD        PIC X(10).
       01  LS-URI           PIC X(512).
       01  LS-PAYLOAD       PIC X(4096).
       01  LS-RESP-BODY     PIC X(65536).

       PROCEDURE DIVISION USING LS-METHOD, LS-URI, LS-PAYLOAD, LS-RESP-BODY.
           IF LS-METHOD = "POST" THEN
                PERFORM HANDLE-POST
           ELSE
                PERFORM HANDLE-GET
           END-IF.
           GOBACK.

       HANDLE-GET.
           MOVE LOW-VALUES TO LS-RESP-BODY.
           MOVE 1 TO OUT-PTR.
           STRING "Content-type: application/json" DELIMITED BY SIZE
                  NEWLINE DELIMITED BY SIZE
                  NEWLINE DELIMITED BY SIZE
                  "[" DELIMITED BY SIZE
                  INTO LS-RESP-BODY
                  WITH POINTER OUT-PTR
           END-STRING.

           OPEN INPUT USER-FILE.
           IF WS-STATUS = "00" THEN
               MOVE 'Y' TO FIRST-ROW
               MOVE 'N' TO EOF-FLAG

               PERFORM UNTIL END-OF-FILE
                   READ USER-FILE NEXT RECORD
                       AT END
                           SET END-OF-FILE TO TRUE
                       NOT AT END
                           IF FIRST-ROW = 'N' THEN
                               STRING ", " DELIMITED BY SIZE INTO LS-RESP-BODY WITH POINTER OUT-PTR END-STRING
                           ELSE
                               MOVE 'N' TO FIRST-ROW
                           END-IF

                           MOVE U-ID TO DISP-NUM
                           STRING "{" DELIMITED BY SIZE
                                  '"id": ' DELIMITED BY SIZE
                                  FUNCTION TRIM(DISP-NUM) DELIMITED BY SIZE
                                  ', "username": "' DELIMITED BY SIZE
                                  FUNCTION TRIM(U-USERNAME) DELIMITED BY SIZE
                                  '", "password": "' DELIMITED BY SIZE
                                  FUNCTION TRIM(U-PASSWORD) DELIMITED BY SIZE
                                  '", "email": "' DELIMITED BY SIZE
                                  FUNCTION TRIM(U-EMAIL) DELIMITED BY SIZE
                                  '"}' DELIMITED BY SIZE
                                  INTO LS-RESP-BODY
                                  WITH POINTER OUT-PTR
                           END-STRING
                   END-READ
               END-PERFORM
               CLOSE USER-FILE
           END-IF.

           STRING "]" DELIMITED BY SIZE INTO LS-RESP-BODY WITH POINTER OUT-PTR END-STRING.
           MOVE X"00" TO LS-RESP-BODY(OUT-PTR:1).

       HANDLE-POST.
           INITIALIZE USER-RECORD.
           
           INSPECT LS-PAYLOAD TALLYING POS-START FOR CHARACTERS BEFORE INITIAL '"username": "'
           IF POS-START < 4000 THEN
               COMPUTE POS-START = POS-START + 14
               INSPECT LS-PAYLOAD(POS-START:) TALLYING VAL-LEN FOR CHARACTERS BEFORE INITIAL '"'
               IF VAL-LEN > 0 AND VAL-LEN <= 30 THEN
                   MOVE LS-PAYLOAD(POS-START:VAL-LEN) TO U-USERNAME
               END-IF
           END-IF.

           MOVE 0 TO POS-START MOVE 0 TO VAL-LEN.
           INSPECT LS-PAYLOAD TALLYING POS-START FOR CHARACTERS BEFORE INITIAL '"email": "'
           IF POS-START < 4000 THEN
               COMPUTE POS-START = POS-START + 11
               INSPECT LS-PAYLOAD(POS-START:) TALLYING VAL-LEN FOR CHARACTERS BEFORE INITIAL '"'
               IF VAL-LEN > 0 AND VAL-LEN <= 50 THEN
                   MOVE LS-PAYLOAD(POS-START:VAL-LEN) TO U-EMAIL
               END-IF
           END-IF.

           IF U-USERNAME = SPACES THEN MOVE "NewUser" TO U-USERNAME END-IF.
           IF U-PASSWORD = SPACES THEN MOVE "secret" TO U-PASSWORD END-IF.
           IF U-EMAIL = SPACES THEN MOVE "user@example.com" TO U-EMAIL END-IF.

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
           MOVE "key_gen" TO U-KEY.
           MOVE 00000100 TO U-SCORE.
           MOVE 00000001 TO U-RANK.
           MOVE 00000050 TO U-SCORE-M.
           MOVE 0001 TO U-BAGE.

           WRITE USER-RECORD INVALID KEY REWRITE USER-RECORD END-WRITE.
           CLOSE USER-FILE.

           MOVE NEW-ID TO DISP-ID.
           MOVE LOW-VALUES TO LS-RESP-BODY.
           MOVE 1 TO OUT-PTR.
           STRING "Content-type: application/json" DELIMITED BY SIZE
                  NEWLINE DELIMITED BY SIZE
                  NEWLINE DELIMITED BY SIZE
                  '{"status": "created", "id": ' DELIMITED BY SIZE
                  FUNCTION TRIM(DISP-ID) DELIMITED BY SIZE
                  ', "username": "' DELIMITED BY SIZE
                  FUNCTION TRIM(U-USERNAME) DELIMITED BY SIZE
                  '"}' DELIMITED BY SIZE
                  INTO LS-RESP-BODY
                  WITH POINTER OUT-PTR
           END-STRING.
           MOVE X"00" TO LS-RESP-BODY(OUT-PTR:1).
