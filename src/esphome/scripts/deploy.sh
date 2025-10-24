#!/bin/bash

echo "|-------------------------------------|"
echo "|-------------- ESPHOME --------------|"
echo "|-------------------------------------|"
echo ""

target_folder=/homeassistant/esphome

echo "Checking environment..."
# Check if esphome is available
if [ ! -d /share/esphome-env ]; then
  echo "ESPHome environment not found. Creating..."
  python -m venv /share/esphome-env
fi

source /share/esphome-env/bin/activate

if ! command -v esphome &> /dev/null; then
  echo "esphome not found. Installing..."
  pip3 install esphome
fi
echo ""

# make sure globstar is on for ** to work
shopt -s globstar

echo "Updated definition files:"
for f in **/*.yaml; do
  if [ -f "$f" ] && cmp $f $target_folder/$f >& /dev/null; then
    # empty command
    :
  else
    echo "$f"
    mkdir -p $(dirname $target_folder/$f)
    cp $f $target_folder/$f
  fi
done
echo ""

echo "Checking devices for firmware update..."
if [ ! -f checksums.json ]; then
  echo '{}' > checksums.json
fi
echo '{}' > checksums_new.json
updateNeeded=()
# create checksums of the new configs
for f in *.yaml; do
  # secrets.yaml file is not processed by esphome, therefore the checksum is always the same
  checksum=($(esphome -l ERROR config $f | md5sum))
  cat <<< $(jq -M ". += {\"$f\":\"$checksum\"}" checksums_new.json) > checksums_new.json
  if ! grep -q "$f.*$checksum" checksums.json; then
    updateNeeded+=("$f")
  fi
done

if [ ${#updateNeeded[*]} -gt 0 ]; then
  updates=$(printf "${updateNeeded[*]}")
  echo "Update needed for: \n$updates"
else
  echo "No update needed"
fi
echo ""

updateNeeded=(shelly-plus-2pm-1.yaml shelly-plus-2pm-10.yaml)
for device in "${updateNeeded[@]}"; do
  esphome run --no-logs $device
done
echo "All devices are up to date"
echo ""

echo "Cleaning up..."
rm checksums.json
mv checksums_new.json checksums.json
echo ""

echo "Finished esphome deployment"
