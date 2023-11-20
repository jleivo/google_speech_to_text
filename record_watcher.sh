#!/bin/bash
#
# Author: Juha Leivo
# Version: 2
# Date: 2023-05-05
#
# History
#   1 - 2023-04-29, initial write, monitors folder, converts items to flac
#   2 - 2023-05-05, Minor typo fixed, improved task/note detection, corrected
#       bug in detecting files with spaces in their names 

readonly print_to_screen=1
readonly obsidian_dir='/home/syncthing/Sync/Obsidian'

# shellcheck source=/dev/null
source /opt/scripts/shared_functions.sh

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
    echo 'Companion script to text-to-speech-LLM, which monitors directory'
    echo 'for new files which is then send to be translated. Results of'
    echo 'the translation is defines how the data is handled' 
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
    echo "${0##*/}": "${1}"
  fi
  logger "${0##*/}": "${1}"
}

function init() {

  program_fail=0

  # check if we have the programs
  for PROGRAM in inotifywait ffmpeg; do
    if ! hash "${PROGRAM}" 2>/dev/null; then
      log "ERROR: command not found in PATH: %s\n ${PROGRAM}" "${print_to_screen}"
      program_fail=1
    fi
  done

  if [[ "${program_fail}" == '1' ]]; then
    return 1
  fi

}

function monitor_directory() {

    echo "Monitoring directory: ${1}"
    # shellcheck disable=SC2034  # Unused variables left for readability
    inotifywait -m "$1" -e create -e moved_to |
    while read -r dir action file; do
        # check if the contents of the variable file ends in m4a
        if [[ "${file##*.}" == "m4a" ]]; then
            echo "Converting file: $file to text via OpenAI-whisper LLM"
            result=$(/opt/scripts/LLM_text_to_speech.py -f "$file" || { log "ERROR: Text-to-speech failed" "${print_to_screen}"; })
            # if first word in the variable is "muistiinpano", then it's a note
            # otherwise it's a task
            # get the first word from the variable result
            task=$(echo "$result"|cut -d' ' -f2)
            if [[ $task == *muistiinpano* ]]; then
                # echo everything after the first space in the variable result
                echo "It's a note, adding to Obsidian"
                echo "$result" | cut -d' ' -f2- > "$obsidian_dir/Inbox/$flac_name.md"
                mv "/tmp/$flac_name.flac" "$obsidian_dir/05 - media/"
                echo "![[$flac_name.flac]]" >> "$obsidian_dir/Inbox/$flac_name.md"
                rm "$1/$file"
            else 
                echo "It's a task or unknown thing, sending to Nozbe"
                # the mail function uses also file parameter and messes it up somehow
                # this is a dirty workaround to that problem. Mail application also
                # seems to have a problem with spaces in filenames, so we replace them
                # with underscores.
                nospacefile=${file// /_}
                mv "$1/$file" "/tmp/$nospacefile"
                send_mail "/tmp/$nospacefile" "empty" 'leivo.0303@nozbe.me' "$result"
                rm "/tmp/$flac_name.flac"
                rm "/tmp/$nospacefile"
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