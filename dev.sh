echo "BUILDING"
cobc -x helloweb.cbl -o helloweb.cgi
echo "RUNNING"
./caddy run --config Caddyfile