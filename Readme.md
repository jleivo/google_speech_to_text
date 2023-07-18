# Idea: audio rec to task or note

This is working set of scripts to convert a m4a audio file to text using Google
cloud text-to-speech service.

## Workflow

User records audio via watch application. Watch application transfer recording
as m4a file to phone. Syncthing monitors the folder and copies the file to a
server. Server has inotifywait waiting for files, it launches bash script which converts the m4a files to flac, sends the flacs to be translated by Google, then
if on first word is "muistiinpano" stores it to Obsidian folder, otherwise it's
sent to Nozbe.

## Installation

This is more of a technical list than step by step instructions, for example how
to configure Syncthing is out of scope.

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

### Secrets

scripts expects to receive following secrets:

- GOOGLE_APPLICATION_CREDENTIALS
- NOZBE_EMAIL

### Google cloud project

TBD

## Usage

1. configure Syncthing folders (audio recordings & Obsidian)
2. create .env file
3. set the script to run in tmux

```bash
cd /opt/scripts/text-to-speech/;./record_watcher.sh -d /home/syncthing/audio/
```

## Limits

We are using synchronious records to the max translate limit is ~1 min
(ref [Text-to-speech quotas](https://cloud.google.com/speech-to-text/quotas))

Google python script requires X64 platform, doesn't work on ARM (Raspberrypi)

## Improvement ideas

- [ ] Analyze file lenght and send it to storage if needed
- [ ] Move to Nozbe for teams, due to (better) API.
- [ ] Containerize the tool
- [ ] Make this work on Raspberrypi
- [ ] write systemctl definition for the script
