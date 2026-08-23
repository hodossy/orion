#!/bin/bash

echo "|-------------------------------------|"
echo "|-------------- ESPHOME --------------|"
echo "|-------------------------------------|"
echo ""

target_folder=/homeassistant/esphome

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
echo '{}' > checksums_new.json
updateNeeded=()
# create checksums of the new configs
for f in *.yaml; do
  if [ "$f" = "secrets.yaml" ]; then
    continue
  fi
  checksum=($(esphome -l ERROR config $f | md5sum))
  cat <<< $(jq -M ". += {\"$f\":\"$checksum\"}" checksums_new.json) > checksums_new.json
  if ! grep -q "$f.*$checksum" checksums.json; then
    updateNeeded+=("$f")
  fi
done

if [ ${#updateNeeded[*]} -gt 0 ]; then
  echo "Update needed for: "
  for device in "${updateNeeded[@]}"; do
    echo "  $device"
  done
else
  echo "No update needed"
fi
echo ""

# for device in "${updateNeeded[@]}"; do
#   esphome run --no-logs $device
# done
echo "All devices are up to date"
echo ""

echo "Cleaning up..."
rm checksums.json
mv checksums_new.json checksums.json
echo ""

echo "Finished esphome deployment"
