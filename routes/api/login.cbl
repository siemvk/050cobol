        >>SOURCE FORMAT IS FREE
       *>================================================================*
       *> FILE-BASED ROUTE: routes/api/login.cbl                         *
       *> PROGRAM-ID: api_login                                          *
       *>================================================================*
        IDENTIFICATION DIVISION.
        PROGRAM-ID. api_login.

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
        01  RAW-PWD              PIC X(100) VALUE SPACES.
        01  PWD-LEN              BINARY-LONG VALUE 0.
        01  HASH-OUT             PIC X(64) VALUE SPACES.
        01  USERDATAFOUND        PIC X VALUE "N".

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

            MOVE SPACES TO ARG-EMPTY ARG-API ARG-ROUTE U-USERNAME RAW-PWD HASH-OUT.
            UNSTRING LS-URI DELIMITED BY "/"
                INTO ARG-EMPTY
                     ARG-API
                     ARG-ROUTE
                     U-USERNAME
                     RAW-PWD
            END-UNSTRING.

            COMPUTE PWD-LEN = FUNCTION LENGTH(FUNCTION TRIM(RAW-PWD)).
            IF PWD-LEN > 0 THEN
                CALL "HashService" USING RAW-PWD PWD-LEN HASH-OUT END-CALL
            END-IF.

            OPEN INPUT USER-FILE.
            IF WS-STATUS = "00" THEN
                READ USER-FILE KEY IS U-USERNAME
                    INVALID KEY
                        MOVE "N" TO USERDATAFOUND
                    NOT INVALID KEY
                        MOVE "Y" TO USERDATAFOUND
                END-READ
                CLOSE USER-FILE

                IF USERDATAFOUND = "Y" THEN
                    IF U-PASSWORD = HASH-OUT OR U-PASSWORD = RAW-PWD THEN
                        IF U-KEY = SPACES OR U-KEY = LOW-VALUES THEN
                            MOVE "key_default" TO U-KEY
                        END-IF
                        STRING FUNCTION TRIM(U-KEY) DELIMITED BY SIZE
                               INTO LS-RESP-BODY
                               WITH POINTER OUT-PTR
                        END-STRING
                    ELSE
                        STRING "verkeerd wachtwoord" DELIMITED BY SIZE
                               INTO LS-RESP-BODY
                               WITH POINTER OUT-PTR
                        END-STRING
                    END-IF
                ELSE
                    STRING "gebruiker bestaat niet" DELIMITED BY SIZE
                           INTO LS-RESP-BODY
                           WITH POINTER OUT-PTR
                    END-STRING
                END-IF
            ELSE
                STRING "gebruiker bestaat niet" DELIMITED BY SIZE
                       INTO LS-RESP-BODY
                       WITH POINTER OUT-PTR
                END-STRING
            END-IF.

            MOVE X"00" TO LS-RESP-BODY(OUT-PTR:1).
