#!/bin/sh
# Automated quality gate for the bookstore page.
# Runs during `docker build` AND again in the Jenkins "Test Application" stage.
F=/usr/share/nginx/html/index.html

[ -s "$F" ] || { echo "FAIL: index.html missing or empty"; exit 1; }

BOOKS=$(grep -o 'class="book"' "$F" | wc -l)
[ "$BOOKS" -ge 6 ] || { echo "FAIL: only $BOOKS books found, need at least 6"; exit 1; }

for id in search category cart track; do
  grep -q "id=\"$id\"" "$F" || { echo "FAIL: missing element #$id"; exit 1; }
done

grep -q 'In stock' "$F" || { echo "FAIL: no availability labels"; exit 1; }
grep -q '&#8377;' "$F" || { echo "FAIL: no prices"; exit 1; }

# Basic security gate: no inline credentials or external script sources
if grep -qiE 'password\s*=|api[_-]?key|<script[^>]+src=' "$F"; then
  echo "FAIL: suspicious content (credentials or external script)"; exit 1
fi

echo "PASS: $BOOKS books, search, cart, tracking and availability labels present"
