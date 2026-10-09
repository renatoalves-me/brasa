#!/bin/bash
# Builds the site and publishes it to Cloudflare. Works from any folder.
# Usage: ./site/publish.sh                      (default URL below)
#        ./site/publish.sh https://other-url
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
URL="${1:-https://brasa.igia.workers.dev}"
cd "$ROOT"
python3 site/build.py "$URL"
npx --yes wrangler deploy
echo "published: $URL"
