       >>SOURCE FORMAT IS FREE
      *>================================================================*
      *> FILE-BASED ROUTE: routes/api/leaderboard.cbl                   *
      *> PROGRAM-ID: api_leaderboard                                    *
      *>================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. api_leaderboard.

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
       01  DISP-NUM             PIC Z(7)9 VALUE SPACES.
       01  DISP-SCORE           PIC Z(7)9 VALUE SPACES.
       01  OUT-PTR              PIC 9(6) VALUE 1.

       01  TBL-COUNT            PIC 9(4) VALUE 0.
       01  I                    PIC 9(4) VALUE 0.
       01  J                    PIC 9(4) VALUE 0.
       01  J-START              PIC 9(4) VALUE 0.

       01  TBL-ITEM OCCURS 200 TIMES.
           05 TBL-ID            PIC 9(8).
           05 TBL-USERNAME      PIC X(30).
           05 TBL-SCORE         PIC 9(8).
           05 TBL-EMAIL         PIC X(50).

       01  TEMP-ITEM.
           05 TMP-ID            PIC 9(8).
           05 TMP-USERNAME      PIC X(30).
           05 TMP-SCORE         PIC 9(8).
           05 TMP-EMAIL         PIC X(50).

       LINKAGE SECTION.
       01  LS-METHOD        PIC X(10).
       01  LS-URI           PIC X(512).
       01  LS-PAYLOAD       PIC X(4096).
       01  LS-RESP-BODY     PIC X(65536).

       PROCEDURE DIVISION USING LS-METHOD, LS-URI, LS-PAYLOAD, LS-RESP-BODY.
           IF LS-METHOD = "POST" THEN
                MOVE LOW-VALUES TO LS-RESP-BODY
                MOVE 1 TO OUT-PTR
                STRING "Content-type: application/json" DELIMITED BY SIZE
                       NEWLINE DELIMITED BY SIZE
                       NEWLINE DELIMITED BY SIZE
                       '{"status": "error", "error": "Post not supported"}' DELIMITED BY SIZE
                       INTO LS-RESP-BODY
                       WITH POINTER OUT-PTR
                END-STRING
                MOVE X"00" TO LS-RESP-BODY(OUT-PTR:1)
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

           MOVE 0 TO TBL-COUNT.
           OPEN INPUT USER-FILE.
           IF WS-STATUS = "00" THEN
               MOVE 'N' TO EOF-FLAG
               PERFORM UNTIL END-OF-FILE
                   READ USER-FILE NEXT RECORD
                       AT END
                           SET END-OF-FILE TO TRUE
                       NOT AT END
                           COMPUTE TBL-COUNT = TBL-COUNT + 1
                           IF TBL-COUNT <= 200 THEN
                               MOVE U-ID TO TBL-ID(TBL-COUNT)
                               MOVE U-USERNAME TO TBL-USERNAME(TBL-COUNT)
                               MOVE U-SCORE TO TBL-SCORE(TBL-COUNT)
                               MOVE U-EMAIL TO TBL-EMAIL(TBL-COUNT)
                           END-IF
                   END-READ
               END-PERFORM
               CLOSE USER-FILE
           END-IF.

           *> Sort in-memory table by score descending
           IF TBL-COUNT > 1 THEN
               PERFORM VARYING I FROM 1 BY 1 UNTIL I > TBL-COUNT - 1
                   COMPUTE J-START = I + 1
                   PERFORM VARYING J FROM J-START BY 1 UNTIL J > TBL-COUNT
                       IF TBL-SCORE(I) < TBL-SCORE(J) THEN
                           MOVE TBL-ITEM(I) TO TEMP-ITEM
                           MOVE TBL-ITEM(J) TO TBL-ITEM(I)
                           MOVE TEMP-ITEM TO TBL-ITEM(J)
                       END-IF
                   END-PERFORM
               END-PERFORM
           END-IF.

           *> Build JSON output from sorted table
           MOVE 'Y' TO FIRST-ROW.
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > TBL-COUNT
               IF FIRST-ROW = 'N' THEN
                   STRING ", " DELIMITED BY SIZE INTO LS-RESP-BODY WITH POINTER OUT-PTR END-STRING
               ELSE
                   MOVE 'N' TO FIRST-ROW
               END-IF

               MOVE TBL-ID(I) TO DISP-NUM
               MOVE TBL-SCORE(I) TO DISP-SCORE
               STRING "{" DELIMITED BY SIZE
                      '"id": ' DELIMITED BY SIZE
                      FUNCTION TRIM(DISP-NUM) DELIMITED BY SIZE
                      ', "username": "' DELIMITED BY SIZE
                      FUNCTION TRIM(TBL-USERNAME(I)) DELIMITED BY SIZE
                      '", "user_score": ' DELIMITED BY SIZE
                      FUNCTION TRIM(DISP-SCORE) DELIMITED BY SIZE
                      ', "bage": 0' DELIMITED BY SIZE
                      '}' DELIMITED BY SIZE
                      INTO LS-RESP-BODY
                      WITH POINTER OUT-PTR
               END-STRING
           END-PERFORM.

           STRING "]" DELIMITED BY SIZE INTO LS-RESP-BODY WITH POINTER OUT-PTR END-STRING.
           MOVE X"00" TO LS-RESP-BODY(OUT-PTR:1).
