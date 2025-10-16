#!/bin/bash

echo "|-------------------------------------|"
echo "|--------------  ORION  --------------|"
echo "|-------------------------------------|"
echo ""

today=$(date -I)
backup_dir=/backup/orion-$today
echo "Creating backups at $backup_dir..."
for d in ./*/; do
  backup_script=$d/scripts/backup.sh
  dirname=$(basename "$d")
  if [ -f $backup_script ]; then
    (cd "$d" && ./scripts/backup.sh $backup_dir $today);
  else
    echo "No backup implementation found for $dirname. Please create it at $dirname/scripts/backup.sh"
  fi
done

echo ""

for d in ./*/; do
  deploy_script=$d/scripts/deploy.sh
  dirname=$(basename "$d")
  if [ -f $deploy_script ]; then
    (cd "$d" && ./scripts/deploy.sh);
  else
    echo "Skipping deployment of $dirname. No script found!"
  fi
done
