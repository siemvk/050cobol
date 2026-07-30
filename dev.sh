rm -f helloweb.cgi api.cgi
echo "BUILDING"
cobc -x helloweb.cbl -o helloweb.cgi
cobc -x api.cbl -o api.cgi
echo "RUNNING"
./caddy run --config Caddyfile