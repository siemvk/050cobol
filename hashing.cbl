       >>SOURCE FORMAT IS FREE
      *>================================================================*
      *> HASHING.CBL: SHA256 Password Hashing using OpenSSL             *
      *> PROGRAM-ID: HashService                                        *
      *>================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. HashService.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       *> OpenSSL configuration
       01  WS-ALGO             PIC X(10) VALUE "SHA256" & X"00".
       01  WS-MD-POINTER       POINTER.
       01  WS-NULL-PTR         POINTER VALUE NULL.
       01  WS-HASH-RAW         PIC X(32) VALUE LOW-VALUES.
       01  WS-HASH-LEN         BINARY-LONG VALUE 0.
       01  I                   BINARY-LONG VALUE 1.
       01  HEX-POS             BINARY-LONG VALUE 1.

       LINKAGE SECTION.
       01  LK-PASSWORD         PIC X(50).
       01  LK-PWD-LEN          BINARY-LONG.
       01  LK-HASH-HEX         PIC X(64).

       PROCEDURE DIVISION USING LK-PASSWORD LK-PWD-LEN LK-HASH-HEX.
       HASH-PROCEDURE.
           *> 1. Get OpenSSL SHA-256 digest algorithm
           CALL "EVP_get_digestbyname" USING BY REFERENCE WS-ALGO
                                       RETURNING WS-MD-POINTER
           END-CALL.

           IF WS-MD-POINTER = NULL THEN
               MOVE "ERROR: OPENSSL ALGO NOT FOUND" TO LK-HASH-HEX
               GOBACK
           END-IF.

           *> 2. Execute digest hashing
           CALL "EVP_Digest" USING BY REFERENCE LK-PASSWORD
                                    BY VALUE     LK-PWD-LEN
                                    BY REFERENCE WS-HASH-RAW
                                    BY REFERENCE WS-HASH-LEN
                                    BY VALUE     WS-MD-POINTER
                                    BY VALUE     WS-NULL-PTR
           END-CALL.

           *> 3. Convert raw bytes to 64-character hex string
           MOVE SPACES TO LK-HASH-HEX.
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > WS-HASH-LEN
               COMPUTE HEX-POS = ((I - 1) * 2) + 1
               MOVE FUNCTION HEX-OF(WS-HASH-RAW(I:1)) TO LK-HASH-HEX(HEX-POS:2)
           END-PERFORM.

           GOBACK.
