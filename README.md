# Whisper LLM Cleaner

A surgical, automated post-processor for Superwhisper on macOS. It watches the local Superwhisper database, sends new transcriptions to an LLM (via OpenRouter) for technical formatting, and auto-pastes the clean result.

## Prerequisites
- macOS
- [Superwhisper](https://superwhisper.com/) installed.
- `sqlite3` (pre-installed on macOS).
- An [OpenRouter](https://openrouter.ai/) API Key.

## Installation

1. Clone or download this project.
2. Ensure the script is executable:
   ```bash
   chmod +x cleaner.sh
   ```

## Configuration

Edit `config.json`:
- `api_key`: Your OpenRouter API key.
- `model`: The model you want to use (e.g., `google/gemini-2.0-flash-001`).
- `db_path`: The path to your Superwhisper SQLite database.
- `marker`: The prefix added to processed text (e.g., `✨ `).

## Usage

Run the script in a terminal window:
```bash
./cleaner.sh
```

### Important Superwhisper Settings
To avoid double-pasting:
1. Open Superwhisper Settings.
2. **Disable** "Auto-Paste" (the script handles pasting).
3. **Enable** "Copy to Clipboard" (optional, but recommended for fallback).

## Troubleshooting
If auto-pasting fails:
- Ensure your Terminal app has **Accessibility** permissions in `System Settings > Privacy & Security > Accessibility`.
- If the script stops, check the terminal output for errors.
