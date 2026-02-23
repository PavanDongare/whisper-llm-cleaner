#!/bin/bash

# Get the directory where the script is located
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CONFIG="$DIR/config.json"

# Load Config
API_KEY=$(python3 -c "import json; print(json.load(open('$CONFIG'))['api_key'])")
MODEL=$(python3 -c "import json; print(json.load(open('$CONFIG'))['model'])")
DB_PATH=$(python3 -c "import json; print(json.load(open('$CONFIG'))['db_path'])")
MARKER=$(python3 -c "import json; print(json.load(open('$CONFIG'))['marker'])")

# Get the ID of the last recording
LAST_ID=$(sqlite3 "$DB_PATH" "SELECT MAX(rowid) FROM recording_fts_content;")

echo "--- Whisper LLM Cleaner Started ---"
echo "Watching: $DB_PATH"

while true; do
    CURRENT_ID=$(sqlite3 "$DB_PATH" "SELECT MAX(rowid) FROM recording_fts_content;")

    if [ "$CURRENT_ID" -gt "$LAST_ID" ]; then
        RAW_TEXT=$(sqlite3 "$DB_PATH" "SELECT c2 FROM recording_fts_content WHERE rowid = $CURRENT_ID;")
        
        if [ -n "$RAW_TEXT" ]; then
            echo "Processing transcription: $RAW_TEXT"
            
            # Call LLM
            JSON_DATA=$(python3 -c "import json, sys; print(json.dumps({'model': '$MODEL', 'messages': [{'role': 'user', 'content': 'You are a technical transcription cleaner. Correct terms and grammar. Return ONLY clean text. TRANSCRIPTION: ' + sys.argv[1]}]}))" "$RAW_TEXT")
            
            RESPONSE=$(curl -s -X POST "https://openrouter.ai/api/v1/chat/completions" 
              -H "Content-Type: application/json" 
              -H "Authorization: Bearer $API_KEY" 
              -d "$JSON_DATA")

            RESULT=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['choices'][0]['message']['content'].strip())" 2>/dev/null)

            if [ -n "$RESULT" ]; then
                # Copy to clipboard with marker
                echo "$MARKER$RESULT" | pbcopy
                
                # Paste
                sleep 0.5
                osascript -e 'tell application "System Events" to keystroke "v" using command down'
                echo "Successfully pasted: $RESULT"
            fi
        fi
        LAST_ID=$CURRENT_ID
    fi
    sleep 0.5
done
