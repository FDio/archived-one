#!/usr/bin/env python

"""
generate_config.py - Generate specific configuration file for VPP from
                     generic config file

Usage:
  ./generate_config.py <directory> <output-file-type>

where <directory> is a system directory containing generic config file(s)
    (suffixed with *.config)
    <output-file-type> is one of 'vat' or 'cli'

This script looks for *.config files in provided directory and for each
generates a specific configuration file based on output file type in form
'<filename>.cli' or '<filename>.vat' respectively.
"""

import sys
import glob
import cmd_mappings


def generate_config(file_name, mode):
  """
  param file_name:
  param mode: one of 'vat' or 'cli'
  """
  s = ''
  f = open(file_name, 'r')
  line_num = 0

  for line in f:
    line_num += 1
    line = line.strip()
    if line == '' or line[0] == '#':
      continue

    kw = line[: line.index(' ')]
    args = line[ line.index(' ') + 1:]

    if kw not in cmd_mappings.mappings:
      raise Exception('Conversion error at {}:{}:\n > {}\nKeyword not found:'
              ' {}'.format(file_name, line_num, line, kw))

    mapping = cmd_mappings.mappings[kw]
    try:
      s = s + mapping.generate(mode, args) + '\n'
    except Exception as e:
      raise Exception('Conversion error at {}:{}:\n > {}'
              .format(file_name, line_num, line))

  return s


def main():
  if len(sys.argv) != 3:
    print('Error: expected 2 arguments!')
    sys.exit(1)

  dir_name = sys.argv[1]
  config_type = sys.argv[2]

  if config_type != 'vat' and config_type != 'cli':
    print('Error: expected second parameter one of "vat" or "cli"!')
    sys.exit(1)

  for f in glob.glob(dir_name + "/*.config"):
    config = generate_config(f, config_type)

    output_fname = f.replace('.config', '.' + config_type)
    print('\n* Generated config from {}:'.format(f))
    print(config)
    print ('* Saving to {}'.format(output_fname))

    fout = open(output_fname, 'w')
    fout.write(config);


main()
