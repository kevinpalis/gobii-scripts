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
  local CMD="$SCRIPT_DIR/parse_csv.py $CSV $OUTPUT_DIR"
  verbose_print "$CMD"
  eval "$CMD"
}

invoke_ebs_loader() {
  local CMD
  local TSV
  find "$OUTPUT_DIR" -type f -name "*.tsv" \
    | while read -r TSV; do
        CMD="java -jar /gobii_bundle/core/EbsLoader.jar -a $(basename "$TSV" .tsv) -i $TSV $*"
        verbose_print "$CMD"
        (( LOAD_CSV_DRYRUN )) || eval "$CMD"
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
  OUTPUT_DIR="$(gmktemp --tmpdir="${LOAD_CSV_TMPDIR:-$TMPDIR}" --directory "$(basename "$CSV" .csv)".XXXXXXXXXX)"

  print_vars

  verbose_print "### INVOKING COMMANDS"
  split_csv
  invoke_ebs_loader "$@"

}

main "$@"
