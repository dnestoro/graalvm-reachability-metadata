#!/bin/bash

set -u
set -x

if [ $# -ne 2 ]; then
  echo "Usage: $0 <test-coordinates> <versions-json-array>"
  exit 1
fi

TEST_COORDINATES="$1"
VERSIONS_JSON="$2"

if ! command -v jq &> /dev/null; then
  echo "jq is required but not installed."
  exit 1
fi

# Remove surrounding single quotes if present (when called from workflow)
VERSIONS_JSON="${VERSIONS_JSON#"${VERSIONS_JSON%%[!\']*}"}"
VERSIONS_JSON="${VERSIONS_JSON%"${VERSIONS_JSON##*[!\']}"}"

# Parse versions with jq
readarray -t VERSIONS < <(echo "$VERSIONS_JSON" | jq -r '.[]')

for VERSION in "${VERSIONS[@]}"; do
  ATTEMPT=1
  MAX_ATTEMPTS=3
  while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    echo "Running test with GVM_TCK_LV=$VERSION and coordinates=$TEST_COORDINATES"
    GVM_TCK_LV="$VERSION" ./gradlew test -Pcoordinates="$TEST_COORDINATES"
    RESULT=$?
    if [ "$RESULT" -eq 0 ]; then
      echo "PASSED:$VERSION"
      break
    else
      echo "FAILED:$VERSION"
    fi
    ATTEMPT=$((ATTEMPT + 1))
  done
  if [ "$RESULT" -ne 0 ]; then
    break
  fi
done

exit 0