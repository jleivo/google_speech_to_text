import sounddevice as sd
from scipy.io.wavfile import write
import wavio as wv
import keyboard  # for keylogs
import paramiko
import argparse

hostname, port, username, keyfile, source_file, 
source_file='recording0.wav'
destination_file='/tmp/'
command='source /opt/LLM/OpenAI-whisper/bin/activate && /opt/LLM/OpenAI-whisper/LLM_text_to_speech.py -f '

# Sampling frequency
freq = 44100

# Recording duration
duration = 5

# Initialize recording
recording = None

# Flag to control recording state
is_recording = False

def copy_and_execute_file_over_ssh(hostname, port, username, keyfile, source_file, destination_file, command):
    try:
        # Create a new SSH client
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

        # Connect to the server
        ssh.connect(hostname, port, username, '', key_filename=keyfile)

        # Create a new SFTP client
        sftp = ssh.open_sftp()

        # Copy the file to the remote server
        sftp.put(source_file, destination_file)

        # Close the SFTP client
        sftp.close()

        # Run the command on the remote server
        stdin, stdout, stderr = ssh.exec_command(command.format(destination_file))

        # Print the output of the command
        print(stdout.read().decode())

        # Close the SSH client
        ssh.close()

    except Exception as e:
        print(f"An error occurred: {str(e)}")

def start_recording():
    global recording
    global is_recording
    # Start recorder with the given values of duration and sample frequency
    print("Recording started")
    recording = sd.rec(int(duration * freq), samplerate=freq, channels=2)
    is_recording = True

def stop_recording():
    global is_recording
    # Wait for the recording to end and then save it
    sd.wait()
    print("Recording stopped")
    write(source_file, freq, recording)
    is_recording = False
    destination_file=destination_file+'recording0.wav'
    copy_and_execute_file_over_ssh(hostname, port, username, keyfile, source_file, destination_file, command + destination_file)

# Use 's' key to start and stop recording
keyboard.add_hotkey("ctrl+shift+r", lambda: start_recording() if not is_recording else stop_recording())

# Block the script
print("Press 'ctrl+shift+r' to start and stop recording")
while True:
    pass