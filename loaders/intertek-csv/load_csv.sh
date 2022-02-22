#!/usr/bin/env bash

set -e          # Exit immediately if a command exits with a non-zero status.
set -u          # Treat unset variables as an error when substituting.
set -o pipefail # the return value of a pipeline is the status of the last command to exit with a non-zero status,
                #   or zero if no command exited with a non-zero status

usage() {
  cat > /dev/stderr <<-EOF
    Usage: $0 INTERTEK_CSV ...

    Trigger splitting of Intertek CSV file into separate TSVs and invoke EBSLoader.jar on each.

    Additional arguments after INTERTEK_CSV are passed through to EBSLoader.jar.

    Environment variables:
        LOAD_CSV_TMPDIR   Path under which temporary outputs will be created.
        LOAD_CSV_VERBOSE  Print commands before execution (default: 0)
        LOAD_CSV_DRYRUN   Toggle verbose mode but don't execute commands (default: 1)
                          Splitting script will still be run but EBSLoader.jar will not.

        For boolean variables, 0 indicates false and any other number indicates true
  
EOF
}

verbose_print() {
  (( ${LOAD_CSV_VERBOSE:-0} )) && echo -e "$*" > /dev/stderr
}

print_vars() {
  verbose_print "### USING ENVIRONMENT VARIABLES
  LOAD_CSV_DRYRUN=$LOAD_CSV_DRYRUN
  LOAD_CSV_VERBOSE=$LOAD_CSV_VERBOSE
  SCRIPT_DIR=$SCRIPT_DIR
  CSV=$CSV
  OUTPUT_DIR=$OUTPUT_DIR
"
}

split_csv() {
  local CMD="$SCRIPT_DIR/split_intertek_csv.py $CSV $OUTPUT_DIR"
  verbose_print "$CMD"
  eval "$CMD"
}

invoke_ebs_loader() {
  # depends on global environment variable ${db_pass}
  local CMD
  local TSV

  if (( $# < 2 )); then
    verbose_print "Insufficient arguments to 'invoke_ebs_loader()'. Expected 2, found $#."
    exit 1
  fi

  local MARKER_FILE="$1"
  local GRID_FILE="$2"
  shift 2

  if ! [[ -f $MARKER_FILE ]]; then
    echo "Marker file $MARKER_FILE not found. Exiting."
    exit 1
  elif ! [[ -f $GRID_FILE ]]; then
    echo "Grid file $GRID_FILE not found. Exiting."
    exit 1
  fi

  # TODO: pass project, experiment, and dataset as arguments to EBSLoader.jar
  for TSV in "$MARKER_FILE" "$GRID_FILE"; do
    CMD="java -jar /gobii_bundle/core/EbsLoader.jar --aspect $(basename "$TSV" .tsv) --inputFile $TSV --dbPassword $db_pass $*"
    verbose_print "$CMD"
    ((LOAD_CSV_DRYRUN)) || eval "$CMD"
  done

}

main() {

  if (( $# == 0 )); then
    usage
    exit 1
  fi

  LOAD_CSV_DRYRUN="${LOAD_CSV_DRYRUN:-0}"
  LOAD_CSV_VERBOSE="${LOAD_CSV_VERBOSE:-0}"
  (( LOAD_CSV_DRYRUN )) && LOAD_CSV_VERBOSE=1

  declare SCRIPT_DIR CSV OUTPUT_DIR

  SCRIPT_DIR="$(dirname "$0")"
  CSV="$1"; shift
  OUTPUT_DIR="$(mktemp --tmpdir="${LOAD_CSV_TMPDIR:-${TMPDIR:-/tmp}}" --directory "$(basename "$CSV" .csv)".XXXXXXXXXX)"

  print_vars

  verbose_print "### INVOKING COMMANDS"
  read -ra RESHAPED <<<"$(split_csv)"

  invoke_ebs_loader "${RESHAPED[@]}" "$@"

}

main "$@"
