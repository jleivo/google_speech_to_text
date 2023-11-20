#!/usr/bin/env python3

import whisper
import argparse

def transcribe_file(speech_file):
    model = whisper.load_model("medium")
    result = model.transcribe(speech_file)
    return(result["text"])

parser = argparse.ArgumentParser()
parser.add_argument('-f','--file',required = True)
args = parser.parse_args()

result = transcribe_file(args.file)
#trim leading white spaces
print(result.strip())