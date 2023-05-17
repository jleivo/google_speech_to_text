# Workflow: audio rec to task or note

This was to test if its feasible to get from a watch audio recording to a text or task, when language is finnish.

## Flow

Watch recorder stores files to phone. Syncthing monitors the folder and copies files to server. Server has inotifywait waiting for files, it launches bash script which converts the m4a files to flac, sends the flacs to be translated by Google, then if on first word is "muistiinpano" stores it to Obsidian folder, otherwise its sent to Nozbe.

## Installation

this is more of a technical list than step by step instructions, for example how to configure Syncthing is out of scope

### os dependencies

```bash
sudo apt-get install inotifywait ffmpeg syncthing
```

### python dependencies

```bash
mkdir /opt/pythonvenv/google
python3 -m venv /opt/pythonenv/google
source /opt/pythonvenv/google/bin/activate
pip install -r requirements.txt
```

### script dependencies

copy shared_functions.sh to /opt/scripts

### Google cloud project

TBD

## Usage

1. configure Syncthing folders (audio recordings & Obsidian)
2. set the script to run in tmux
```bash
/opt/scripts/record_watcher.sh -d /home/syncthing/audio/
```

## Limits

We are using synchronious records to the max translate limit is ~1 min (ref https://cloud.google.com/speech-to-text/quotas)
Google python script requires X64 platform, doesn't work on ARM (Raspberrypi)

## Improvement ideas
- Analyze file lenght and send it to storage if needed
- Move to Nozbe for teams, due to (better) API.
- Containerize the tool
- Make this work on Raspberrypi
- write systemctl definition for the script