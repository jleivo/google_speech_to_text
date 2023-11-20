#!/bin/bash
# Just to load python venv correctly

# shellcheck source=/dev/null
source /opt/LLM/OpenAI-whisper/bin/activate
/opt/LLM/OpenAI-whisper/LLM_text_to_speech.py -f "${1}"