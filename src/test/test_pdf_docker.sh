#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-openitcockpit/puppeteer}"
HOST_PORT="${HOST_PORT:-18085}"
OUTPUT_FILE="${OUTPUT_FILE:-/tmp/pdf_test_output.pdf}"
REBUILD_IMAGE="${REBUILD_IMAGE:-0}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIXTURE_FILE="${FIXTURE_FILE:-$SCRIPT_DIR/pdf_render_input.json}"

if [[ "${1:-}" == "--rebuild" ]]; then
    REBUILD_IMAGE=1
fi

if [[ ! -f "$FIXTURE_FILE" ]]; then
    echo "Fixture file not found: $FIXTURE_FILE" >&2
    exit 1
fi

if [[ "$REBUILD_IMAGE" == "1" ]] || ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    echo "Building image $IMAGE_NAME ..."
    (
        cd "$PROJECT_ROOT"
        docker build . -t "$IMAGE_NAME" -f Dockerfile
    )
fi

CONTAINER_NAME="pdf-test-$$"
HEADERS_FILE="$(mktemp)"

cleanup() {
    rm -f "$HEADERS_FILE"
    docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "Starting container $CONTAINER_NAME on port $HOST_PORT ..."
docker run -d --rm --name "$CONTAINER_NAME" -p "$HOST_PORT:8084" "$IMAGE_NAME" >/dev/null

echo "Waiting for service to be reachable ..."
for _ in $(seq 1 40); do
    HTTP_CODE="$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:$HOST_PORT/" || true)"
    if [[ "$HTTP_CODE" != "000" ]]; then
        break
    fi
    sleep 0.5
done

HTTP_CODE="$(curl -sS -o "$OUTPUT_FILE" -D "$HEADERS_FILE" -w "%{http_code}" \
    -X POST "http://127.0.0.1:$HOST_PORT/pdf" \
    -H "Content-Type: application/json" \
    --data-binary "@$FIXTURE_FILE")"

if [[ "$HTTP_CODE" != "200" ]]; then
    echo "Expected HTTP 200, got: $HTTP_CODE" >&2
    echo "Response headers:" >&2
    cat "$HEADERS_FILE" >&2
    echo "Container logs:" >&2
    docker logs "$CONTAINER_NAME" >&2 || true
    exit 1
fi

CONTENT_TYPE="$(awk 'BEGIN{IGNORECASE=1} /^Content-Type:/ {print $2}' "$HEADERS_FILE" | tr -d '\r')"
if [[ "$CONTENT_TYPE" != application/pdf* ]]; then
    echo "Expected Content-Type application/pdf, got: $CONTENT_TYPE" >&2
    exit 1
fi

PDF_SIGNATURE="$(od -An -t x1 -N 5 "$OUTPUT_FILE" | tr -d ' \n')"
if [[ "$PDF_SIGNATURE" != "255044462d" ]]; then
    echo "Response is not a valid PDF (wrong file signature)." >&2
    exit 1
fi

FILE_SIZE="$(wc -c < "$OUTPUT_FILE" | tr -d ' ')"
if [[ "$FILE_SIZE" -le 16 ]]; then
    echo "PDF output looks too small: $FILE_SIZE bytes" >&2
    exit 1
fi

echo "Test passed: /pdf returned a PDF ($FILE_SIZE bytes)."
echo "Saved output: $OUTPUT_FILE"
