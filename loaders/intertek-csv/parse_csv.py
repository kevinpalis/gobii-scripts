#!/usr/bin/env python
# python 3.9.7
"""
    Evan R Rees
    Dec 2021
    err87@cornell.edu

    This is a preprocessing script for long-format CSV files from Intertek / LGC-Genomics.
    Examples of the input format can be found in `./resources`.
    The input file ($INPUT_FILE) is a series of catenated CSV tables with a short header providing metadata.
    The tables, including the header, are separated and written to separate files in $OUTPUT_FOLDER.
    This script performs little or no validation of the input file.

"""

import json
from typing import TextIO
from enum import Enum, auto
from argparse import ArgumentParser, Namespace


class Tables(Enum):
    """
    Valid table headers.
    """
    SNPs = auto()
    Scaling = auto()
    Data = auto()
    Statistics = auto()
    DNA = auto()


FIRST_LINES: list[str] = [                                      # expected values on first two lines of file
    'KBiosciences genotyping report',
    'LGC-Genomics'
]


class HeaderFormatException(Exception):
    """Encountered unexpected header format"""
    pass


class FileFormatException(Exception):
    """Encountered unexpected file format"""
    pass


def main(input_file: str, output_dir: str) -> None:
    """
    Extract and write TSV tables from Intertek / LGC-Genomics long-format concatenated CSV file.

    :param input_file: Long-format genotyping file to parse.
    :param output_dir: Directory in which to write output files.
    :raises FileFormatException: When either of the first two lines don't match expectation.
    :raises HeaderFormatException: When a table name is encountered and the preceding line is non-blank.
    """
    with open(input_file, 'r') as reader:
        prefix: str = input_file.rsplit('/', 1)[-1].removesuffix('.csv')
        output_file: TextIO = open(f'{output_dir}/{prefix}.header.tsv', 'w')
        line: str
        idx: int
        last_was_blank: bool = False
        for idx, line in enumerate(reader):
            if idx < 2:                                                         # validate first two lines
                if line.strip() != FIRST_LINES[idx]:
                    message: str = f'Unexpected value on line {idx}. Expected {FIRST_LINES[idx]}, found {line}'
                    raise FileFormatException(message)
            elif line.startswith('#'):                                          # skip comment lines
                continue
            elif line.isspace():                                                # end of table
                last_was_blank = True
                output_file.close()
            else:                                                               # table header or row
                fields: list[str] = line.strip().split(',')
                if len(fields) == 1 and 'Header' not in output_file.name:       # normal header processing
                    if fields[0] in Tables.__members__:                         # check header is valid
                        if not last_was_blank:                                  # check format is valid
                            message: str = f'Encountered header {fields[0]} on line {idx}, ' \
                                           f'but preceding line was not blank.'
                            raise HeaderFormatException(message)
                        else:                                                   # open new fd
                            output_file = open(f'{output_dir}/{prefix}.{fields[0].lower()}.tsv', 'w')
                    else:
                        raise Exception('')
                else:                                                           # normal processing
                    output_file.write(line.replace(',', '\t'))
        output_file.close()                                                     # close last fd

    header_tsv: str = f'{output_dir}/{prefix}.header.tsv'                       # transpose header file to JSON
    header_json: str = f'{output_dir}/{prefix}.header.json'
    json_dict: dict = {}
    with open(header_tsv, 'r') as reader:
        for idx, line in enumerate(reader):
            fields: list[str] = line.strip().split('\t')                        # some header values are enquoted
            json_dict[fields[0]] = fields[1].strip('"') if (len(fields) == 2) else ''
    with open(header_json, 'w') as writer:
        json.dump(json_dict, writer)


if __name__ == '__main__':
    parser: ArgumentParser = ArgumentParser(
        description='Extract and write TSV tables from Intertek / LGC-Genomics long-format concatenated CSV file.'
    )
    parser.add_argument('input_file', metavar='CSV', help='CSV file to parse')
    parser.add_argument('output_dir', metavar='OUTPUT_DIR', help='Directory in which to store output')
    args: Namespace = parser.parse_args()
    main(input_file=args.input_file,
         output_dir=args.output_dir)
