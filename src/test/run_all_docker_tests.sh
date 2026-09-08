#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARGS=()

if [[ "${1:-}" == "--rebuild" ]]; then
    ARGS+=("--rebuild")
fi

echo "Running Docker integration test: /area_chart"
"$SCRIPT_DIR/test_area_chart_docker.sh" "${ARGS[@]-}"

echo "Running Docker integration test: /pdf"
"$SCRIPT_DIR/test_pdf_docker.sh" "${ARGS[@]-}"

echo "All Docker integration tests passed."
