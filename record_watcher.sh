#!/bin/bash
#
# Author: Juha Leivo
# Version: 1
# Date: 2023-04-29
#
# History
#   1 - 2023-04-29, initial write, monitors folder, converts items to flac

readonly print_to_screen=1
readonly obsidian_dir='/mnt/c/Users/juha.LHE/Sync/Obsidian'

source /opt/pythonvenv/google/bin/activate
source /opt/scripts/shared_functions.sh
export GOOGLE_APPLICATION_CREDENTIALS='/mnt/c/temp/text-to-speech.json'

################################# FUNCTIONS ####################################
debug=0

function get_arguments() {

  if [[ "$#" -lt "2" ]] ; then
    print_usage
    return 1
  fi

  while getopts 'd:hv' flag; do
    case "${flag}" in
      d)
        DIRECTORY="${OPTARG}"
        ;;
      h)
        print_usage
        ;;
      v)
        debug=1
        ;;
      *)
        print_usage
        ;;
    esac
  done
}

function print_usage() {

    echo ''
    echo 'Companion script to Googl text-to-speech, which monitors directory'
    echo 'for new files and converts them to flac, then sends them to translated' 
    echo ''
    echo 'Usage'
    echo ''
    echo '  -d          Directory to monitor. MANDATORY'
    echo '  -v          Print debug output messages'
    echo '  -h          This help message'
    echo ''
    return 0

}

# Takes two parameters, first one is log message, second is debug info
# if debug = 1 then prints log message to screen, otherwise logs it to syslog
function log() {

  if [[ "${2}" -eq 1 ]]; then 
    echo ${0##*/}: "${1}"
  fi
  logger ${0##*/}: "${1}"
}

function init() {

  program_fail=0

  # check if we have the programs
  for PROGRAM in inotifywait ffmpeg; do
    if ! hash "${PROGRAM}" 2>/dev/null; then
      log "ERROR: command not found in PATH: %s\n "${PROGRAM}"" "${print_to_screen}"
      program_fail=1
    fi
  done

  if [[ "${program_fail}" == '1' ]]; then
    return 1
  fi

}

function monitor_directory() {

    echo "Monitoring directory: ${1}"
    inotifywait -m "$1" -e create -e moved_to |
    while read dir action file; do
        # check if the contents of the variable file ends in m4a
        if [[ "${file##*.}" == "m4a" ]]; then
            flac_name=${file%.*}
            echo "Converting file: $file"
            ffmpeg -i "$1/$file" -vn -acodec flac "/tmp/$flac_name.flac" -loglevel fatal || { log "ERROR: ffmpeg failed message" "${print_to_screen}"; exit 1; }
            echo "Converting file: $file to text via Google text-to-speech"
            result=$(/opt/scripts/text_to_speech.py -f "/tmp/$flac_name.flac" || { log "ERROR: test.py failed message" "${print_to_screen}"; exit 1; })
            if [[ $result == *muistiinpano* ]]; then
                # echo everything after the first space in the variable result
                echo $result | cut -d' ' -f2- > "$obsidian_dir/inbox/$flac_name.md"
                mv "/tmp/$flac_name.flac" "$obsidian_dir/05 - media/"
                echo "[[$flac_name.flac]]" >> "$obsidian_dir/inbox/$flac_name.md"
                rm "$1/$file"
            else 
                send_mail "$1/$file" "$result" 'leivo.0303@nozbe.me' $flac_name
                rm "$1/$file"
            fi
        fi
    done
}


##################################### LOGIC ####################################
echo ''
log "Started" "${debug}" 
get_arguments "${@}" || exit 1
init || { log "ERROR: Init failed message" "${print_to_screen}"; exit 1; }
monitor_directory "${DIRECTORY}"