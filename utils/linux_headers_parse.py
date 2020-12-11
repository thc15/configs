import getopt
import sys
from pyparsing import *


version = '1.0'
verbose = False
output_filename = 'accessors.h'

print 'Args      :', sys.argv[1:]

options, remainder = getopt.getopt(sys.argv[1:], 'o:i:v', ['output=', 'input='])
print 'options: ', options

for opt, arg in options:
    if opt in ('-o', '--output'):
        output_filename = arg
    elif opt in ('-i', '--input'):
        input_filename = arg

print 'output : ', output_filename
print 'input  : ', input_filename

inputfile = open(input_filename)

src = inputfile.read()
inputfile.close()

ident = Word(alphas + alphanums + "_")
macroDef = Suppress("#define") + ident + empty + restOfLine
macros = dict(list(macroDef.searchString(src)))

outputfile = open(output_filename, 'w')

for k, v in macros.items():
    outputfile.write(str(k) + ' = '+ str(v) + '\n')

outputfile.close()

