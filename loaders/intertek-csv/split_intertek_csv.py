#!/usr/bin/env python3.6
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
from typing import TextIO, List, Dict
from enum import Enum, auto
from argparse import ArgumentParser, Namespace
import pandas as pd
import sys


class Tables(Enum):
    """Valid table headers."""
    Header = auto()
    SNPs = auto()
    Scaling = auto()
    Data = auto()
    Statistics = auto()
    DNA = auto()

    def file_name(self):
        return f"{self.name.lower()}.tsv"


class Reshaped(Enum):
    """Output files for loading."""
    Grid = auto()
    Markers = auto()

    def file_name(self):
        return f"{self.name.lower()}.tsv"


FIRST_LINES: List[str] = [                                      # expected values on first two lines of file
    'KBiosciences genotyping report',
    'LGC-Genomics'
]


class HeaderFormatException(Exception):
    """Encountered unexpected header format"""
    pass


class FileFormatException(Exception):
    """Encountered unexpected file format"""
    pass


def extract_csvs(input_file: str, output_dir: str) -> Dict[Tables, str]:
    """
    Extract and write TSV tables from Intertek / LGC-Genomics long-format concatenated CSV file.

    :param input_file: Long-format genotyping file to parse.
    :param output_dir: Directory in which to write output files.
    :raises FileFormatException: When either of the first two lines don't match expectation.
    :raises HeaderFormatException: When a table name is encountered and the preceding line is non-blank.
    :return: None
    """
    output_file_names: Dict[Tables, str] = {}
    with open(input_file, 'r') as reader:
        table = Tables.Header
        output_file_names[table] = f'{output_dir}/{table.file_name()}'
        output_file: TextIO = open(output_file_names[table], 'w')
        idx: int
        line: str
        last_was_blank: bool = False
        for idx, line in enumerate(reader):
            if idx < 2:                                                         # validate first two lines
                if line.strip() != FIRST_LINES[idx]:
                    message: str = f'Unexpected value on line {idx}. Expected {FIRST_LINES[idx]}, found {line}'
                    raise FileFormatException(message)
            elif line.isspace():                                                # end of table
                last_was_blank = True
                output_file.close()
            elif not line.startswith('#'):                                      # table header or row
                fields: list[str] = line.strip().split(',')
                if len(fields) == 1 and 'Header' not in output_file.name:       # normal header processing
                    if fields[0] in Tables.__members__:                         # check header is valid
                        if not last_was_blank:                                  # check format is valid
                            message: str = f'Encountered header {fields[0]} on line {idx}, ' \
                                           f'but preceding line was not blank.'
                            raise HeaderFormatException(message)
                        else:                                                   # open new fd
                            table: Tables = Tables[fields[0]]
                            output_file_names[table] = f'{output_dir}/{table.file_name()}'
                            output_file = open(output_file_names[table], 'w')
                    else:
                        raise Exception('')
                else:                                                           # normal processing
                    output_file.write(line.replace(',', '\t'))
        output_file.close()                                                     # close last fd
        return output_file_names


def reformat_tables(split_tables: Dict[Tables, str], output_dir: str) -> Dict[Reshaped, str]:
    """Reformat input tables into genotyping grid and marker metadata"""

    data = pd.read_csv(split_tables[Tables.Data], delimiter='\t', dtype=str)
    scaling = pd.read_csv(split_tables[Tables.Scaling], delimiter='\t', dtype=str)
    snps = pd.read_csv(split_tables[Tables.SNPs], delimiter='\t', dtype=str)

    # add marker_name column as concatenation of SNPID and SNPNum
    snps['marker_name'] = snps[['SNPID', 'SNPNum']].agg('_'.join, axis=1)

    # split masterwell into well row and column
    data[['well_row', 'well_col']] = data['MasterWell'].str.extract(r'([A-H])(\d+)')

    # pivot data table to sample-fast grid
    grid = data.dropna(subset=['SubjectID']) \
        .merge(scaling.merge(snps, on='SNPNum'), on=['SNPID', 'DaughterPlate']) \
        .pivot(index=['SubjectID', 'MasterPlate', 'MasterWell', 'well_row', 'well_col'],
               columns=['marker_name'],
               values=['Call']) \
        .reset_index()

    # flatten the multi-index leftover from pivot
    grid.columns = [a if not b else b for a, b in grid.columns]

    # write output files
    output_files = {e: f'{output_dir}/{e.file_name()}' for e in Reshaped}
    snps.to_csv(output_files[Reshaped.Markers], sep='\t', index=False)
    grid.to_csv(output_files[Reshaped.Grid], sep='\t', index=False)
    return output_files


def get_project_number(header_file: str) -> str:
    header = pd.read_csv(header_file, header=None, names=['key', 'value'], delimiter='\t', index_col=0)
    try:
        return header.loc['Project number', 'value']
    except KeyError:
        print("Could not find 'Project number' in header table.")
        exit(1)


def main() -> None:
    """Extract and write TSV tables from Intertek / LGC-Genomics long-format concatenated CSV file."""
    parser: ArgumentParser = ArgumentParser(
        description='Extract and write TSV tables from Intertek / LGC-Genomics long-format concatenated CSV file.'
    )
    parser.add_argument('input_file', metavar='CSV', help='CSV file to parse')
    parser.add_argument('output_dir', metavar='OUTPUT_DIR', help='Directory in which to store output')

    args: Namespace = parser.parse_args()
    print("Arguments:", file=sys.stderr)
    print('\n'.join(f'  {k:12} {v}' for k, v in args.__dict__.items()), file=sys.stderr)

    split_tables = extract_csvs(input_file=args.input_file, output_dir=args.output_dir)
    print("Split tables:", file=sys.stderr)
    print('\n'.join(f'  {k.name:12} {v}' for k, v in split_tables.items()), file=sys.stderr)

    reshaped_tables = reformat_tables(split_tables=split_tables, output_dir=args.output_dir)
    print("Reshaped tables for loading:", file=sys.stderr)
    print('\n'.join(f'  {k.name:12} {v}' for k, v in reshaped_tables.items()), file=sys.stderr)

    project_number = get_project_number(split_tables[Tables.Header])

    print(project_number, *reshaped_tables.values(), sep=' ')


if __name__ == '__main__':
    main()
