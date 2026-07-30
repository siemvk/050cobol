rm -f helloweb.cgi api.cgi server
echo "BUILDING"
cobc -x helloweb.cbl -o helloweb.cgi
cobc -x api.cbl -lsqlite3 -o api.cgi
cobc -x server.cbl -o server
echo "RUNNING"
./server