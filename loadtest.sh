#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 3 ]; then
    echo "usage: ./loadtest.sh TARGETS_FILENAME RESULTS_FILENAME PLOT_FILENAME"
    exit 1
fi

grep -v "^#" "$1" | \
    vegeta attack -duration=1m -rate 100/1s | \
    tee "$2" | \
    vegeta plot > "$3"
