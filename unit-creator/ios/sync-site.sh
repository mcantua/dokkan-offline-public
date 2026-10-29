#!/bin/sh
# Copy the newest iPhone build of the app into the iPhone project (run web/build.py first).
set -e
cd "$(dirname "$0")"
rm -rf site && cp -r ../web/site-ios site && echo "site updated"
