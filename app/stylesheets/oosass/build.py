#!/usr/local/bin/python
import os

def visit(arg, dirname, names):
    print dirname, names
for dirpath, dirnames, filenames in os.walk('.'):
    for i in range(len(dirnames)-1):
        if dirnames[i][0] == '.': del dirnames[i]
    for filename in filenames:
        name, ext = os.path.splitext(filename)
        if ext != '.css': continue
        source = os.path.join(dirpath, filename)
        dest = os.path.join(dirpath, name + '.sass')
        print 'sass-convert %s %s' % (source, dest)
        os.system('sass-convert %s %s' % (source, dest))
