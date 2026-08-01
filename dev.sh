rm -f helloweb.cgi api.cgi server
echo "BUILDING"
cobc -x helloweb.cbl -o helloweb.cgi
cobc -x api.cbl -o api.cgi
cobc -x server.cbl hashing.cbl anticheat.c routes/api/status.cbl routes/api/login.cbl routes/api/users.cbl routes/api/leaderboard.cbl routes/api/maak_acount_V2.cbl routes/api/set_score.cbl routes/api/accName.cbl -L/opt/homebrew/opt/openssl@3/lib -lcrypto -o server
echo "RUNNING"
./server