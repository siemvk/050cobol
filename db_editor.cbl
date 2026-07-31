       >>SOURCE FORMAT IS FREE
      *>================================================================*
      *> DB_EDITOR.CBL: COBOL CLI Tool to Manage users.dat Database     *
      *>================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. DB_EDITOR.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           COPY "user_file_control.cpy".

       DATA DIVISION.
       FILE SECTION.
       FD  USER-FILE.
       COPY "user_record.cpy".

       WORKING-STORAGE SECTION.
       01 WS-STATUS            PIC XX VALUE "00".
       01 CHOICE               PIC X VALUE SPACES.
       01 EOF-FLAG             PIC X VALUE 'N'.
          88 END-OF-FILE       VALUE 'Y'.

       01 INPUT-ID             PIC 9(8) VALUE 0.
       01 INPUT-TEXT           PIC X(255) VALUE SPACES.
       01 INPUT-NUM            PIC 9(8) VALUE 0.
       01 DISP-NUM             PIC Z(7)9 VALUE SPACES.
       01 CONFIRM              PIC X VALUE SPACES.

       01 TBL-COUNT            PIC 9(4) VALUE 0.
       01 I                    PIC 9(4) VALUE 0.
       01 J                    PIC 9(4) VALUE 0.
       01 J-START              PIC 9(4) VALUE 0.

       01 TBL-ITEM OCCURS 200 TIMES.
          05 TBL-ID            PIC 9(8).
          05 TBL-USERNAME      PIC X(30).
          05 TBL-SCORE         PIC 9(8).
          05 TBL-EMAIL         PIC X(50).

       01 TEMP-ITEM.
          05 TMP-ID            PIC 9(8).
          05 TMP-USERNAME      PIC X(30).
          05 TMP-SCORE         PIC 9(8).
          05 TMP-EMAIL         PIC X(50).

       PROCEDURE DIVISION.
       MAIN-LOOP.
           PERFORM UNTIL CHOICE = '7' OR CHOICE = 'q' OR CHOICE = 'Q'
               DISPLAY " "
               DISPLAY "=================================================="
               DISPLAY "       COBOL ISAM DATABASE EDITOR (users.dat)     "
               DISPLAY "=================================================="
               DISPLAY "1. List all users (by ID)"
               DISPLAY "2. List users sorted by score (highest first)"
               DISPLAY "3. Find user by ID"
               DISPLAY "4. Add new user"
               DISPLAY "5. Update user record"
               DISPLAY "6. Delete user record"
               DISPLAY "7. Exit"
               DISPLAY "--------------------------------------------------"
               DISPLAY "Enter option [1-7]: " WITH NO ADVANCING
               ACCEPT CHOICE

               EVALUATE CHOICE
                   WHEN '1' PERFORM LIST-USERS
                   WHEN '2' PERFORM LIST-USERS-BY-SCORE
                   WHEN '3' PERFORM FIND-USER
                   WHEN '4' PERFORM ADD-USER
                   WHEN '5' PERFORM UPDATE-USER
                   WHEN '6' PERFORM DELETE-USER
                   WHEN '7' DISPLAY "Goodbye!"
                   WHEN 'q' DISPLAY "Goodbye!"
                   WHEN 'Q' DISPLAY "Goodbye!"
                   WHEN OTHER DISPLAY "Invalid choice. Please try again."
               END-EVALUATE
           END-PERFORM.
           STOP RUN.

       LIST-USERS.
           DISPLAY " "
           DISPLAY "--- ALL USERS IN DATABASE (BY ID) ---"
           OPEN INPUT USER-FILE
           IF WS-STATUS NOT = "00" THEN
               DISPLAY "Database file users.dat does not exist or cannot be opened."
               DISPLAY "File status: " WS-STATUS
           ELSE
               MOVE 'N' TO EOF-FLAG
               DISPLAY "ID         USERNAME                       EMAIL                                    SCORE"
               DISPLAY "-----------------------------------------------------------------------------------------"
               PERFORM UNTIL END-OF-FILE
                   READ USER-FILE NEXT RECORD
                       AT END
                           SET END-OF-FILE TO TRUE
                       NOT AT END
                           MOVE U-ID TO DISP-NUM
                           DISPLAY DISP-NUM "  " U-USERNAME " " U-EMAIL " " U-SCORE
                   END-READ
               END-PERFORM
               CLOSE USER-FILE
           END-IF.

       LIST-USERS-BY-SCORE.
           DISPLAY " "
           DISPLAY "--- ALL USERS SORTED BY SCORE (HIGHEST FIRST) ---"
           MOVE 0 TO TBL-COUNT
           OPEN INPUT USER-FILE
           IF WS-STATUS NOT = "00" THEN
               DISPLAY "Database file users.dat does not exist or cannot be opened."
           ELSE
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

           DISPLAY "ID         USERNAME                       EMAIL                                    SCORE"
           DISPLAY "-----------------------------------------------------------------------------------------"
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > TBL-COUNT
               MOVE TBL-ID(I) TO DISP-NUM
               DISPLAY DISP-NUM "  " TBL-USERNAME(I) " " TBL-EMAIL(I) " " TBL-SCORE(I)
           END-PERFORM.

       FIND-USER.
           DISPLAY " "
           DISPLAY "Enter User ID to find: " WITH NO ADVANCING
           ACCEPT INPUT-ID
           OPEN INPUT USER-FILE
           IF WS-STATUS = "00" THEN
               MOVE INPUT-ID TO U-ID
               READ USER-FILE KEY IS U-ID
                   INVALID KEY
                       DISPLAY "User ID " INPUT-ID " not found."
                   NOT INVALID KEY
                       DISPLAY "--------------------------------------------------"
                       MOVE U-ID TO DISP-NUM
                       DISPLAY "ID               : " DISP-NUM
                       DISPLAY "Username         : " FUNCTION TRIM(U-USERNAME)
                       DISPLAY "Password         : " FUNCTION TRIM(U-PASSWORD)
                       DISPLAY "Email            : " FUNCTION TRIM(U-EMAIL)
                       DISPLAY "Score            : " U-SCORE
                       DISPLAY "Rank             : " U-RANK
                       DISPLAY "User Key         : " FUNCTION TRIM(U-KEY)
                       DISPLAY "Score (Moeilijk) : " U-SCORE-M
                       DISPLAY "Badge            : " U-BAGE
                       DISPLAY "--------------------------------------------------"
               END-READ
               CLOSE USER-FILE
           ELSE
               DISPLAY "Error opening database. File status: " WS-STATUS
           END-IF.

       ADD-USER.
           DISPLAY " "
           DISPLAY "--- ADD NEW USER ---"
           INITIALIZE USER-RECORD
           DISPLAY "Enter User ID (numeric, e.g. 3): " WITH NO ADVANCING
           ACCEPT U-ID
           DISPLAY "Enter Username: " WITH NO ADVANCING
           ACCEPT INPUT-TEXT MOVE INPUT-TEXT TO U-USERNAME
           DISPLAY "Enter Password: " WITH NO ADVANCING
           ACCEPT INPUT-TEXT MOVE INPUT-TEXT TO U-PASSWORD
           DISPLAY "Enter Email: " WITH NO ADVANCING
           ACCEPT INPUT-TEXT MOVE INPUT-TEXT TO U-EMAIL
           DISPLAY "Enter Score (numeric): " WITH NO ADVANCING
           ACCEPT INPUT-NUM MOVE INPUT-NUM TO U-SCORE
           DISPLAY "Enter Rank (numeric): " WITH NO ADVANCING
           ACCEPT INPUT-NUM MOVE INPUT-NUM TO U-RANK
           MOVE "key_gen" TO U-KEY
           MOVE 00000000 TO U-SCORE-M
           MOVE 0001 TO U-BAGE

           OPEN I-O USER-FILE
           IF WS-STATUS = "35" THEN
               OPEN OUTPUT USER-FILE
               CLOSE USER-FILE
               OPEN I-O USER-FILE
           END-IF

           WRITE USER-RECORD
               INVALID KEY
                   DISPLAY "Error: User ID " U-ID " already exists!"
               NOT INVALID KEY
                   DISPLAY "User successfully created!"
           END-WRITE
           CLOSE USER-FILE.

       UPDATE-USER.
           DISPLAY " "
           DISPLAY "Enter User ID to update: " WITH NO ADVANCING
           ACCEPT INPUT-ID
           OPEN I-O USER-FILE
           IF WS-STATUS = "00" THEN
               MOVE INPUT-ID TO U-ID
               READ USER-FILE KEY IS U-ID
                   INVALID KEY
                       DISPLAY "User ID " INPUT-ID " not found."
                   NOT INVALID KEY
                       DISPLAY "Current Username: " FUNCTION TRIM(U-USERNAME)
                       DISPLAY "Enter new Username (leave empty to keep): " WITH NO ADVANCING
                       ACCEPT INPUT-TEXT
                       IF INPUT-TEXT NOT = SPACES THEN MOVE INPUT-TEXT TO U-USERNAME END-IF

                       DISPLAY "Current Email: " FUNCTION TRIM(U-EMAIL)
                       DISPLAY "Enter new Email (leave empty to keep): " WITH NO ADVANCING
                       ACCEPT INPUT-TEXT
                       IF INPUT-TEXT NOT = SPACES THEN MOVE INPUT-TEXT TO U-EMAIL END-IF

                       DISPLAY "Current Score: " U-SCORE
                       DISPLAY "Enter new Score (e.g. 1500, leave 0 to keep): " WITH NO ADVANCING
                       ACCEPT INPUT-NUM
                       IF INPUT-NUM > 0 THEN MOVE INPUT-NUM TO U-SCORE END-IF

                       REWRITE USER-RECORD
                           INVALID KEY
                               DISPLAY "Error updating user record."
                           NOT INVALID KEY
                               DISPLAY "User record updated successfully!"
                       END-REWRITE
               END-READ
               CLOSE USER-FILE
           ELSE
               DISPLAY "Error opening database. File status: " WS-STATUS
           END-IF.

       DELETE-USER.
           DISPLAY " "
           DISPLAY "Enter User ID to delete: " WITH NO ADVANCING
           ACCEPT INPUT-ID
           OPEN I-O USER-FILE
           IF WS-STATUS = "00" THEN
               MOVE INPUT-ID TO U-ID
               READ USER-FILE KEY IS U-ID
                   INVALID KEY
                       DISPLAY "User ID " INPUT-ID " not found."
                   NOT INVALID KEY
                       DISPLAY "Are you sure you want to delete user '" FUNCTION TRIM(U-USERNAME) "'? (y/n): " WITH NO ADVANCING
                       ACCEPT CONFIRM
                       IF CONFIRM = 'y' OR CONFIRM = 'Y' THEN
                           DELETE USER-FILE
                               INVALID KEY
                                   DISPLAY "Error deleting record."
                               NOT INVALID KEY
                                   DISPLAY "User deleted successfully."
                           END-DELETE
                       ELSE
                           DISPLAY "Deletion cancelled."
                       END-IF
               END-READ
               CLOSE USER-FILE
           ELSE
               DISPLAY "Error opening database. File status: " WS-STATUS
           END-IF.
