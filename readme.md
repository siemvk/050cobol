# 050Guessr: Bank edition

In 2024 I made my first big website, [050Guessr](https://050guessr.com/), a game where you guess the location of a random image in 050 (Groningen, Netherlands). I having 0 experience with COBOL though it would be funny to remake it in COBOL. So I did. The result is [050Guessr: Bank edition](https://050guessr.nl/), a website that looks and works exactly like the original, but is written in COBOL.

The backend is 100% PURE COBOL!!!

also its bank edition bc banks are like the only one still on cobol.

## Running the project

run this:

```bash
./run.sh
```

this runs

```bash

rm -f helloweb.cgi api.cgi server
echo "BUILDING"
cobc -x helloweb.cbl -o helloweb.cgi
cobc -x api.cbl -lsqlite3 -o api.cgi
cobc -x server.cbl -o server
echo "RUNNING"
./server
```

after this first time you can just run `./server` to start the server.

we dont hot reload so you can just keep using the dev server....

## Ai 

I dont really know COBOL sooo Gemini wrote the code for the main web server code for me. I made the API and the frontend myself (frontend as of writing 2 years ago).