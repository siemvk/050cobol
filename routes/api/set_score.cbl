        >>SOURCE FORMAT IS FREE
       *>================================================================*
       *> FILE-BASED ROUTE: routes/api/set_score.cbl                     *
       *> PROGRAM-ID: api_set_score                                      *
       *>================================================================*
        IDENTIFICATION DIVISION.
        PROGRAM-ID. api_set_score.

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
        01  OUT-PTR              PIC 9(6) VALUE 1.

        01  ARG-EMPTY            PIC X(50) VALUE SPACES.
        01  ARG-API              PIC X(50) VALUE SPACES.
        01  ARG-ROUTE            PIC X(50) VALUE SPACES.
        01  SEARCH-KEY           PIC X(30) VALUE SPACES.
        01  ARG-SCORE            PIC X(10) VALUE SPACES.
        01  ARG-CHECK            PIC X(50) VALUE SPACES.
        01  USERDATAFOUND        PIC X(1) VALUE "N".
        01  VALID-FLAG           PIC X(1) VALUE "N".
        01  NUM-SCORE            PIC 9(8) VALUE 0.

        LINKAGE SECTION.
        01  LS-METHOD        PIC X(10).
        01  LS-URI           PIC X(512).
        01  LS-PAYLOAD       PIC X(4096).
        01  LS-RESP-BODY     PIC X(65536).

        PROCEDURE DIVISION USING LS-METHOD, LS-URI, LS-PAYLOAD, LS-RESP-BODY.
            PERFORM HANDLE-GET.
            GOBACK.

        HANDLE-GET.
            MOVE LOW-VALUES TO LS-RESP-BODY.
            MOVE 1 TO OUT-PTR.
            INITIALIZE USER-RECORD.

            STRING "Content-type: text/plain" DELIMITED BY SIZE
                   NEWLINE DELIMITED BY SIZE
                   NEWLINE DELIMITED BY SIZE
                   INTO LS-RESP-BODY
                   WITH POINTER OUT-PTR
            END-STRING.

            MOVE SPACES TO ARG-EMPTY ARG-API ARG-ROUTE SEARCH-KEY ARG-SCORE ARG-CHECK.
            UNSTRING LS-URI DELIMITED BY "/"
                INTO ARG-EMPTY
                     ARG-API
                     ARG-ROUTE
                     SEARCH-KEY
                     ARG-SCORE
                     ARG-CHECK
            END-UNSTRING.

            IF SEARCH-KEY = SPACES THEN
                STRING "invalid key" DELIMITED BY SIZE
                       INTO LS-RESP-BODY
                       WITH POINTER OUT-PTR
                END-STRING
                MOVE X"00" TO LS-RESP-BODY(OUT-PTR:1)
                GOBACK
            END-IF.

            *> Anti-cheat validation
            MOVE "N" TO VALID-FLAG.
            CALL "AntiCheatService" USING ARG-SCORE ARG-CHECK VALID-FLAG END-CALL.
            IF VALID-FLAG NOT = "Y" THEN
                STRING "ongeldige check" DELIMITED BY SIZE
                       INTO LS-RESP-BODY
                       WITH POINTER OUT-PTR
                END-STRING
                MOVE X"00" TO LS-RESP-BODY(OUT-PTR:1)
                GOBACK
            END-IF.

            MOVE SEARCH-KEY TO U-KEY.

            OPEN I-O USER-FILE.
            IF WS-STATUS = "00" THEN
                READ USER-FILE KEY IS U-KEY
                    INVALID KEY
                        MOVE "N" TO USERDATAFOUND
                    NOT INVALID KEY
                        MOVE "Y" TO USERDATAFOUND
                END-READ

                IF USERDATAFOUND = "Y" THEN
                    COMPUTE NUM-SCORE = FUNCTION NUMVAL(ARG-SCORE)
                    IF ARG-ROUTE = "set_score_moeilijk" THEN
                        IF NUM-SCORE > U-SCORE-M THEN
                            MOVE NUM-SCORE TO U-SCORE-M
                            REWRITE USER-RECORD
                                INVALID KEY
                                    STRING "error updating score" DELIMITED BY SIZE
                                           INTO LS-RESP-BODY
                                           WITH POINTER OUT-PTR
                                    END-STRING
                                NOT INVALID KEY
                                    STRING "score updated" DELIMITED BY SIZE
                                           INTO LS-RESP-BODY
                                           WITH POINTER OUT-PTR
                                    END-STRING
                            END-REWRITE
                        ELSE
                            STRING "score niet hoger" DELIMITED BY SIZE
                                   INTO LS-RESP-BODY
                                   WITH POINTER OUT-PTR
                            END-STRING
                        END-IF
                    ELSE
                        IF NUM-SCORE > U-SCORE THEN
                            MOVE NUM-SCORE TO U-SCORE
                            REWRITE USER-RECORD
                                INVALID KEY
                                    STRING "error updating score" DELIMITED BY SIZE
                                           INTO LS-RESP-BODY
                                           WITH POINTER OUT-PTR
                                    END-STRING
                                NOT INVALID KEY
                                    STRING "score updated" DELIMITED BY SIZE
                                           INTO LS-RESP-BODY
                                           WITH POINTER OUT-PTR
                                    END-STRING
                            END-REWRITE
                        ELSE
                            STRING "score niet hoger" DELIMITED BY SIZE
                                   INTO LS-RESP-BODY
                                   WITH POINTER OUT-PTR
                            END-STRING
                        END-IF
                    END-IF
                ELSE
                    STRING "gebruiker bestaat niet" DELIMITED BY SIZE
                           INTO LS-RESP-BODY
                           WITH POINTER OUT-PTR
                    END-STRING
                END-IF
                CLOSE USER-FILE
            ELSE
                STRING "DB READ ERROR" DELIMITED BY SIZE
                       INTO LS-RESP-BODY
                       WITH POINTER OUT-PTR
                END-STRING
            END-IF.

            MOVE X"00" TO LS-RESP-BODY(OUT-PTR:1).
