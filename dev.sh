rm -f helloweb.cgi api.cgi server
echo "BUILDING"
cobc -x helloweb.cbl -o helloweb.cgi
cobc -x api.cbl -o api.cgi
cobc -x server.cbl routes/api/status.cbl routes/api/users.cbl routes/api/leaderboard.cbl -o server
echo "RUNNING"
./server