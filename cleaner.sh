#!/bin/bash

# --- SINGLETON LOGIC ---
LOCKFILE="/tmp/whisper_cleaner.lock"
if [ -e ${LOCKFILE} ] && kill -0 `cat ${LOCKFILE}` 2>/dev/null; then
    echo "$(date): Already running. Exiting." >> /tmp/watcher.log
    exit 1
fi
echo $$ > ${LOCKFILE}

# --- SECURE CONFIGURATION ---
# Load API KEY from hidden file outside the project folder
API_KEY=$(cat ~/.openrouter_key)
DIR="/Users/pavandongare/projects/whisper-llm-cleaner"
CONFIG="$DIR/config.json"

# Load other settings from config.json
MODEL=$(python3 -c "import json; print(json.load(open('$CONFIG'))['model'])")
DB_PATH=$(python3 -c "import json; print(json.load(open('$CONFIG'))['db_path'])")
MARKER=$(python3 -c "import json; print(json.load(open('$CONFIG'))['marker'])")
SYSTEM_PROMPT=$(python3 -c "import json; print(json.load(open('$CONFIG'))['prompt'])")

# Get the ID of the last recording
LAST_ID=$(sqlite3 "$DB_PATH" "SELECT MAX(rowid) FROM recording_fts_content;")

echo "--- $(date): SECURE WATCHDOG STARTED ---" >> /tmp/watcher.log

while true; do
    CURRENT_ID=$(sqlite3 "$DB_PATH" "SELECT MAX(rowid) FROM recording_fts_content;")

    if [ "$CURRENT_ID" -gt "$LAST_ID" ]; then
        RAW_TEXT=$(sqlite3 "$DB_PATH" "SELECT c2 FROM recording_fts_content WHERE rowid = $CURRENT_ID;")
        
        if [ -n "$RAW_TEXT" ]; then
            # Call LLM
            JSON_DATA=$(python3 -c "import json, sys; print(json.dumps({'model': '$MODEL', 'messages': [{'role': 'user', 'content': sys.argv[1] + sys.argv[2]}]}))" "$SYSTEM_PROMPT" "$RAW_TEXT")
            
            RESPONSE=$(curl -s -X POST "https://openrouter.ai/api/v1/chat/completions" \
              -H "Content-Type: application/json" \
              -H "Authorization: Bearer $API_KEY" \
              -d "$JSON_DATA")

            RESULT=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['choices'][0]['message']['content'].strip())" 2>/dev/null)

            if [ -n "$RESULT" ]; then
                echo "$MARKER$RESULT" | pbcopy
                sleep 0.5
                osascript -e 'tell application "System Events" to keystroke "v" using command down'
                echo "$(date): SUCCESS" >> /tmp/watcher.log
            fi
        fi
        LAST_ID=$CURRENT_ID
    fi
    sleep 0.5
done
