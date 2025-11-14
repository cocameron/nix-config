#!/bin/bash
# Wrapper to run the Romm collection script
# Usage: ROMM_PASSWORD=yourpassword ./run_romm_script.sh

if [ -z "$ROMM_PASSWORD" ]; then
    echo "Error: ROMM_PASSWORD environment variable not set"
    echo "Usage: ROMM_PASSWORD=yourpassword ./run_romm_script.sh"
    exit 1
fi

cd "$(dirname "$0")"
python3 add_to_romm_collection.py chumpy "$ROMM_PASSWORD"
