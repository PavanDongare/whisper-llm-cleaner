#!/bin/bash

# --- SINGLETON LOGIC ---
LOCKFILE="/tmp/whisper_cleaner.lock"
if [ -e ${LOCKFILE} ] && kill -0 `cat ${LOCKFILE}` 2>/dev/null; then
    exit 1
fi
echo $$ > ${LOCKFILE}

# --- SECURE CONFIGURATION ---
API_KEY=$(cat ~/.openrouter_key)
DIR="/Users/pavandongare/projects/whisper-llm-cleaner"
CONFIG="$DIR/config.json"

MODEL=$(python3 -c "import json; print(json.load(open('$CONFIG'))['model'])")
DB_PATH=$(python3 -c "import json; print(json.load(open('$CONFIG'))['db_path'])")
MARKER=$(python3 -c "import json; print(json.load(open('$CONFIG'))['marker'])")
SYSTEM_PROMPT=$(python3 -c "import json; print(json.load(open('$CONFIG'))['prompt'])")

LAST_ID=$(sqlite3 "$DB_PATH" "SELECT MAX(rowid) FROM recording_fts_content;")

while true; do
    CURRENT_ID=$(sqlite3 "$DB_PATH" "SELECT MAX(rowid) FROM recording_fts_content;")

    if [ "$CURRENT_ID" -gt "$LAST_ID" ]; then
        RAW_TEXT=$(sqlite3 "$DB_PATH" "SELECT c2 FROM recording_fts_content WHERE rowid = $CURRENT_ID;")
        
        if [ -n "$RAW_TEXT" ]; then
            echo "$(date): [START] Calling Gemini for transcription $CURRENT_ID" >> /tmp/watcher.log
            
            JSON_DATA=$(python3 -c "import json, sys; print(json.dumps({'model': '$MODEL', 'messages': [{'role': 'user', 'content': sys.argv[1] + sys.argv[2]}]}))" "$SYSTEM_PROMPT" "$RAW_TEXT")
            
            RESPONSE=$(curl -s -X POST "https://openrouter.ai/api/v1/chat/completions" \
              -H "Content-Type: application/json" \
              -H "Authorization: Bearer $API_KEY" \
              -d "$JSON_DATA")

            RESULT=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['choices'][0]['message']['content'].strip())" 2>/dev/null)

            if [ -n "$RESULT" ]; then
                echo "$(date): [API SUCCESS] Received response. Updating clipboard..." >> /tmp/watcher.log
                echo "$MARKER$RESULT" | pbcopy
                
                # Small wait to ensure focus is on the editor
                sleep 0.8
                
                echo "$(date): [PASTE] Triggering Cmd+V..." >> /tmp/watcher.log
                osascript -e 'tell application "System Events" to keystroke "v" using command down'
            fi
        fi
        LAST_ID=$CURRENT_ID
    fi
    sleep 0.5
done
