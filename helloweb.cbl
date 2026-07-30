IDENTIFICATION DIVISION.
       PROGRAM-ID. HELLOWEB.
       
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 NEWLINE PIC X VALUE X'0A'.
       
       PROCEDURE DIVISION.
           DISPLAY "Content-type: text/html" NEWLINE
           END-DISPLAY.
           
           DISPLAY "<html>"
           DISPLAY "<head><title>COBOL Webserver</title></head>"
           DISPLAY "<body>"    
           DISPLAY "<h1>COBOL webserver</h1>"                                   
           DISPLAY ""
           DISPLAY "Hello from COBOL!"
           DISPLAY "</body>"
           DISPLAY "</html>"
           END-DISPLAY.
           
           STOP RUN.