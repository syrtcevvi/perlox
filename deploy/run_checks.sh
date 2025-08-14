#!/usr/bin/env bash

# Traverse lib directory recursively and run perl -wc on each file
find . -path "./lib/*" -type f -print0 | xargs -0 -I {} perl -wc {}
perl -wc ./bin/perlox
