       >>SOURCE FORMAT IS FREE
      *>================================================================*
      *> FILE-BASED ROUTE: routes/api/status.cbl                        *
      *> PROGRAM-ID: api_status                                         *
      *>================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. api_status.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  NEWLINE          PIC X VALUE X'0A'.
       01  OUT-PTR          PIC 9(6) VALUE 1.

       LINKAGE SECTION.
       01  LS-METHOD        PIC X(10).
       01  LS-URI           PIC X(512).
       01  LS-PAYLOAD       PIC X(4096).
       01  LS-RESP-BODY     PIC X(4096).

       PROCEDURE DIVISION USING LS-METHOD, LS-URI, LS-PAYLOAD, LS-RESP-BODY.
           MOVE LOW-VALUES TO LS-RESP-BODY.
           MOVE 1 TO OUT-PTR.
           STRING "Content-type: application/json" DELIMITED BY SIZE
                  NEWLINE DELIMITED BY SIZE
                  NEWLINE DELIMITED BY SIZE
                  '{"status": "ok", "db": "native COBOL ISAM indexed file", "routing": "file-based (routes/api/status.cbl)"}' DELIMITED BY SIZE
                  INTO LS-RESP-BODY
                  WITH POINTER OUT-PTR
           END-STRING.

           MOVE X"00" TO LS-RESP-BODY(OUT-PTR:1).
           GOBACK.
