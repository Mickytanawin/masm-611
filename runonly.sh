#!/bin/bash
# Tanawin Thongbai
# Last Edit: 17:20 23 Jul 2025

script_loc="$HOME/.masm" # This script location (Change to match yours)

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

# Clear tr_file if it exists; otherwise, create it
# Input:
#    arg1 (string tr_file) Target file location
# No Output
# Side Effect:
#    Clear tr_file
# Don't Exit
function clear_or_create() {
  local tr_file=''
  tr_file="$1"

  if [[ -e $tr_file ]]; then # tr_file exists
    echo -n > "$tr_file" # Empty the file
  else
    touch "$tr_file" # Create the file
  fi
}

# Try to convert from_file to CP437 (\r\n) from UTF-8 (\n) to dest_file
# Input:
#    arg1 (string from_file) Starting file location
#    arg2 (string dest_file) Destination file location
# No Output
# Side Effect:
#    Rewrite dest_file
# Exit Status:
#    1 Conversion Error
function try_conv2cp437() {
  local from_file=''
  from_file="$1"
  local dest_file=''
  dest_file="$2"

  clear_or_create "$dest_file"
  if ! /usr/bin/iconv -f UTF-8 -t CP437 "$from_file" -o "$dest_file" \
    2> "$script_loc/iconverr.txt"; then
    echo 'Error: Invalid character for CP437 Encoding in program file.' >&2
    cat "$script_loc/iconverr.txt" >&2
    rm "$script_loc/iconverr.txt" # Remove error file
    exit 1
  fi
  unix2dos -ascii "$dest_file" > /dev/null 2>&1 # Only change \n to \r\n (-ascii Flag)
}

# Setup Dosbox config file by replacing LOCATION with script_loc from template_file, output to dest_file
# Input:
#    arg1 (string template_file) Template file location
#    arg2 (string dest_file) Destination file location
# No Output
# Side Effect:
#    Rewrite dest_file
# Don't Exit
function setup_conf() {
  local template_file=''
  template_file="$1"
  local dest_file=''
  dest_file="$2"

  sed "s@LOCATION@$script_loc@g" "$template_file" > "$dest_file"
}

# (runonly() Helper) Remove files to prevent usage from the next call
# No Input
# No Output
# Side Effect:
#    Remove runonly()'s temporary files
# Don't Exit
function runonly_cleanup() {
  declare -a rm_runonly=('IN.TXT' 'OUT.TXT' 'MLOUT.TXT' 'PROG.ASM' 'PROG.OBJ' 'PROG.EXE')
  for f_name in "${rm_runonly[@]}"; do
    if [[ -e "$script_loc/runonly/$f_name" ]]; then
      rm "$script_loc/runonly/$f_name"
    fi
  done
  declare -a rm_files=('tmp_in.txt' 'tmp_out.txt')
  for f_name in "${rm_files[@]}"; do
    if [[ -e "$script_loc/$f_name" ]]; then
      rm "$script_loc/$f_name"
    fi
  done
}

# Assemble, link, run prog_file with given input from stdin and print output to stdout
# Note:
#    Input must be in UTF-8 but only consists of CP437 characters. (either \n or \r\n newline)
#    Output as UTF-8 to stdout (\n newline)
# Input:
#    arg1 (string prog_file) Assembly program file location
# No Output
# Side Effect:
#    Create files (and later remove those files) in ./runonly, iconverr.txt, tmp_in.txt, tmp_out.txt
# Exit Status:
#    1 Invalid file or Conversion Error
function runonly() {
  trap runonly_cleanup EXIT

  local prog_file=''
  prog_file="$1"

  # Get .asm file -> Change Encoding
  validate_progfile "$prog_file"
  try_conv2cp437 "$prog_file" "$script_loc/runonly/PROG.ASM"

  # Read input (maybe from redirection) to IN.TXT -> Change Encoding
  clear_or_create "$script_loc/tmp_in.txt"
  local line=''
  while IFS='' read -r line; do # Read until EOF (Ctrl + D in Terminal)
      echo "$line" >> "$script_loc/tmp_in.txt"
  done
  try_conv2cp437 "$script_loc/tmp_in.txt" "$script_loc/runonly/IN.TXT"

  # Setup Dosbox config file
  setup_conf "$script_loc/template_runonly.conf" "$script_loc/runonly.conf"

  # Assemble and Run
  # Note:
  #    MS Dos output error to stdout.
  # ML.EXE Assembler, Linker Redirect to MLOUT.TXT
  # PROG.EXE Redirect to OUT.TXT
  clear_or_create "$script_loc/runonly/OUT.TXT"
  clear_or_create "$script_loc/runonly/MLOUT.TXT"
  dosbox "$script_loc/exit" -userconf -conf "$script_loc/runonly.conf" -exit \
    -c 'ML.EXE PROG.ASM > MLOUT.TXT' \
    -c 'PROG.EXE < IN.TXT > OUT.TXT' > /dev/null 2>&1

  # Check if any errors occur during assemble + run step inside Dosbox
  clear_or_create "$script_loc/tmp_out.txt"
  /usr/bin/iconv -f CP437 -t UTF-8 "$script_loc/runonly/MLOUT.TXT" -o "$script_loc/tmp_out.txt"
  dos2unix -ascii "$script_loc/tmp_out.txt" > /dev/null 2>&1 # Only change \r\n to \n (-ascii Flag)
  if [[ "$(grep -c 'error' "$script_loc/tmp_out.txt")" -gt 0 ]]; then
    echo "Error: Assemble or link error. Output from ML.EXE as follows:" >&2
    sed "s@PROG.ASM@$prog_file@g" "$script_loc/tmp_out.txt" >&2
    exit 1
  fi

  # Change encoding from CP437 to UTF-8 -> Print
  clear_or_create "$script_loc/tmp_out.txt"
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
