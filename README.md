# Whisper LLM Cleaner

Automated post-processing for Superwhisper. This tool bridges the gap between raw voice-to-text and polished technical prose.

## 🚀 The Productivity Gap
- **Voice Speed:** ~147 Words Per Minute
- **Typing Speed:** ~40 Words Per Minute
- **Efficiency Gain:** 360% increase in communication bandwidth.

## 🛠 How it Works
1. **Trigger:** Superwhisper (local) transcribes your voice to its internal SQLite database.
2. **Detection:** This script watches the database for new entries.
3. **Processing:** The raw text is sent to Gemini 2.0 Flash via OpenRouter.
4. **Action:** The cleaned text is copied to your clipboard and auto-pasted into your active application.

## 📁 System Information
- **Superwhisper Database:** `~/Library/Application Support/superwhisper/database/superwhisper.sqlite`
- **Project Location:** `~/projects/whisper-llm-cleaner`
- **Configuration & Prompt:** All AI instructions are defined in `config.json`.

## ⚙️ Running in the Background
To keep the cleaner running without keeping a terminal open:
```bash
nohup ./cleaner.sh > output.log 2>&1 &
```
To verify it is running:
```bash
ps aux | grep cleaner.sh
```

## 📝 Customizing the AI
You can change how the AI rewrites your text by editing the `"prompt"` field in `config.json`. This is where you can tell it to focus on specific programming languages, fix grammar, or change the tone.

## 🔒 Requirements
- **Accessibility Permissions:** Ensure your Terminal app (or `sh`/`bash`) has permission to "Control your computer" in **System Settings > Privacy & Security > Accessibility**.
