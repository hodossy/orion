#!/bin/bash

dry_run=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      dry_run=true
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [--dry-run]"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Usage: $0 [--dry-run]"
      exit 1
      ;;
  esac
done

echo "|-------------------------------------|"
echo "|-------------- ESPHOME --------------|"
echo "|-------------------------------------|"
echo ""

echo "Checking environment..."
# Check if esphome is available
if ! command -v esphome &> /dev/null; then
  echo "esphome not found. Exit"
  exit 1
fi
echo ""

# make sure globstar is on for ** to work
shopt -s globstar

echo "Checking devices for firmware update..."
if [ ! -f checksums.json ]; then
  echo '{}' > checksums.json
fi
# create checksums of the new configs
for f in *.yaml; do
  if [ "$f" = "secrets.yaml" ]; then
    continue
  fi
  output=$(esphome -l ERROR config --show-secrets $f)
  if echo "$output" | grep -qE "^ERROR|Failed config|Invalid"; then
    echo "Error in $f:"
    echo "$output"
    echo "Skipping $f"
    continue
  fi
  checksum=($(jq -r ".\"$f\"" checksums.json))
  new_checksum=($(echo "$output" | md5sum))
  if [ "$new_checksum" = "$checksum" ]; then
    echo "No changes for $f"
  else
    if [ "$dry_run" = true ]; then
      echo "Dry run: skipping deployment for $f"
      continue
    fi
    echo "Changes detected for $f, deploying..."
    esphome run --no-logs $f
    # update the checksum
    jq ". += {\"$f\":\"$new_checksum\"}" checksums.json > tmp.json && mv tmp.json checksums.json
  fi
done

echo "Finished esphome deployment"
