#!/usr/bin/env python

import os
import argparse
import re
import json
import pandas as pd


def pathCheck(path, suffixes):

    # check path
    if not os.path.isfile(path):
        raise argparse.ArgumentTypeError(f"invalid file path: \'{path}\'")
    
    # check ext
    if not path.endswith(suffixes):
        *_, extPath = os.path.splitext(path)
        extOptions = ", ".join([f"\'{ext}\'" for ext in suffixes])
        raise argparse.ArgumentTypeError(f"invalid file extension: \'{extPath}\' (must be {extOptions})")
    
    return path


# parse arguments

parser = argparse.ArgumentParser(
    description ='Convert JSONL file to table',
           prog = os.path.basename(__file__),
          usage = '%(prog)s [options]',
         epilog = 'see readme for further details.'
    )

parser.add_argument( 
    '-i', '--input',
     metavar = '</path/to/input.jsonl>',
        type = lambda path: pathCheck(path=path, suffixes=(".jsonl",".json")), 
    required = True,
        help = 'specify path to json file'
    )

parser.add_argument( 
    '-s', '--seperater',
    metavar = '<symbol>',
       type = str, 
    default = '_',
       help = 'specify column seperator for nested records'
    )

sepTable = {
    'tsv' : '\t',
    'csv' : ',',
    }

parser.add_argument( 
    '-t', '--type',
    metavar = '<ext>',
       type = str, 
    choices = sepTable.keys(),
    default = 'tsv',
       help = 'specify table type'
    )


pathInput, sepRecord, extTable = vars(parser.parse_args()).values()


# determine input/output info

baseFile     = os.path.basename(pathInput)

nameFile, *_ = os.path.splitext(baseFile)

pathOutput = f"./{nameFile}.{extTable}"


# read jsonl

jsonlObject = open( file=pathInput, mode='r')


# convert each entry to json 

jsonNested = [
    json.loads( re.sub( pattern=r'\\r|\\n|\\t', repl='', string=entry) )
    for entry in jsonlObject
    ] # N.B. REMOVE LITERAL SPECIAL CHARACTERS FROM ENTRY COMMENTS

# unpack reports (json only)
if pathInput.endswith('.json'):

    json, = jsonNested

    jsonNested = json['reports']


# flatten json object

jsonFlat = pd.json_normalize(
    data = jsonNested, 
     sep = sepRecord )


# convert json to dataframe

dfTable = pd.DataFrame.from_dict(
       data = jsonFlat, 
     orient = 'columns', 
      dtype = None, 
    columns = None )


# output table

dfTable.to_csv(
    path_or_buf = pathOutput,
        columns = sorted(dfTable.columns),
          index = False,
            sep = sepTable[extTable] )
