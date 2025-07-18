#!/bin/bash
# Tanawin Thongbai
# Last Edit: 14:48 18 Jul 2025

script_loc="$HOME/.masm" # This script location

# Check if prog_file is a valid file (exist, is a file)
# Input:
#    arg1 (string prog_file) File location
# No Output
# No Side Effect
# Exit Status:
#    1 Invalid file
function validate_progfile() {
  local prog_file=''
  prog_file="$1"

  if [[ $prog_file =~ ^[[:space:]]*$ ]]; then # Empty file name
    echo $'Error: No such file. [name] can\'t be blank.' >&2
    exit 1
  elif [[ ! -e $prog_file ]]; then # File doesn't exist
    echo $'Error: No such file. \"'"$prog_file"$'\" doesn\'t exist.' >&2
    exit 1
  elif [[ ! -f $prog_file ]]; then # File isn't a regular file
    echo $'Error: Invalid file type. \"'"$prog_file"$'\" isn\'t a regular file.' >&2
    exit 1
  fi
}

# Try to convert file to CP437 (\r\n) from UTF-8 (\n)
# Input:
#    arg1 (string from_file) Starting file location
#    arg2 (string dest_file) Destination file location
# No Output
# Side Effect:
#    Rewrite dest_file, Put iconv errors to iconverr.txt if error
# Exit Status:
#    1 Conversion Error
function try_conv2cp437() {
  local from_file=''
  from_file="$1"
  local dest_file=''
  dest_file="$2"

  if ! /usr/bin/iconv -f UTF-8 -t CP437 "$from_file" -o "$dest_file" \
    2> "$script_loc/iconverr.txt"; then
    echo 'Error: Invalid character for CP437 Encoding in program file.'
    cat "$script_loc/iconverr.txt"
    exit 1
  fi
  unix2dos -ascii "$dest_file" > /dev/null 2>&1 # Only change \n to \r\n (-ascii Flag)
}

# Assemble, link, run prog_file with given input from stdin and print output to stdout
# Note:
#    Input must be in UTF-8 but only consists of CP437 characters. (either \n or \r\n newline)
#    Output as UTF-8 to stdout (\n newline)
# Input:
#    arg1 (string prog_file) Assembly program file location
# No Output
# Side Effect:
#    Rewrite many files in ./runonly, iconverr.txt, tmp_in.txt, tmp_out.txt
# Exit Status:
#    1 Invalid file or Conversion Error
function runonly() {
  local prog_file=''
  prog_file="$1"

  # Get .asm file -> Change Encoding
  validate_progfile "$prog_file"
  try_conv2cp437 "$prog_file" "$script_loc/runonly/PROG.ASM"

  # Read input (maybe from redirection) to IN.TXT -> Change Encoding
  echo -n > "$script_loc/tmp_in.txt"
  local line=''
  while IFS='' read -r line; do # Read until EOF (Ctrl + D in Terminal)
      echo "$line" >> "$script_loc/tmp_in.txt"
  done
  try_conv2cp437 "$script_loc/tmp_in.txt" "$script_loc/runonly/IN.TXT"

  # Assemble and Run -> Redirect to OUT.TXT
  dosbox "$script_loc/exit" -userconf -conf "$script_loc/runonly.conf" -exit -c "ML.EXE PROG.ASM" \
    -c "PROG.EXE < IN.TXT > OUT.TXT" > /dev/null 2>&1
  
  # Change encoding from CP437 to UTF-8 -> Print
  /usr/bin/iconv -f CP437 -t UTF-8 "$script_loc/runonly/OUT.TXT" -o "$script_loc/tmp_out.txt"
  dos2unix -ascii "$script_loc/tmp_out.txt" > /dev/null 2>&1 # Only change \r\n to \n (-ascii Flag)
  cat "$script_loc/tmp_out.txt"
}

# Assemble, link, run prog_file and remain inside dosbox
# Note:
#    Input must be in UTF-8 but only consists of CP437 characters. (either \n or \r\n newline)
#    Output as UTF-8 to stdout (\n newline)
# Input:
#    arg1 (string prog_file) Assembly program file location
# No Output
# Side Effect:
#    Rewrite many files in ./runonly, iconverr.txt, tmp_in.txt, tmp_out.txt
# Exit Status:
#    1 Invalid file or Conversion Error
function interactive_input() {
  local prog_file=''
  prog_file="$1"

  # Get .asm file -> Change Encoding
  validate_progfile "$prog_file"
  try_conv2cp437 "$prog_file" "$script_loc/runonly/PROG.ASM"
}

function main() {
  runonly "$@"
}

(main "$@")
