#!/usr/bin/python

""" 
Compress word lists.

Tim Heaney (oylensheegul@gmail.com)
"""

import string

schemes = {'Crack':{'header':'#!xdawg',
                    'numarr': "".join(chr(i) for i in range(ord('0'),
                                                            ord('z')+1)),
                   },
           'DAWG': {'header':'#!xdawg',
                    'numarr': string.digits + \
                              string.ascii_uppercase + \
                              string.ascii_lowercase,
                   },
           'Mike': {'header':'',
                    'numarr': "".join(chr(i) for i in range(ord('@'),
                                                            ord('z')+1)),
                   },
          }

def compress (inf, outf=None, scheme='Crack'):
    """ compress the word list given by inf """
    if outf == None: # read from list, return list
        if schemes[scheme]['header'] != "":
            outf = [(schemes[scheme]['header'])]
        else:
            outf = []
        prev = ""
        for word in inf:
            num = 0
            while num < len(prev) and \
                  num < len(word) and \
                  prev[num] == word[num] and \
                  num < len(schemes[scheme]['numarr']):
                num += 1
            outf.append(schemes[scheme]['numarr'][num] + word[num:])
            prev = word
        return outf
    else:            # read from file, write to file
        if schemes[scheme]['header'] != "":
            print >>outf, schemes[scheme]['header']
        prev = ""
        for word in inf:
            num = 0
            while num < len(prev) and \
                  num < len(word) and \
                  prev[num] == word[num] and \
                  num < len(schemes[scheme]['numarr']):
                num += 1
            outf.write(schemes[scheme]['numarr'][num] + word[num:])
            prev = word
        return None


def decompress (inf, outf=None, scheme='Crack'):
    """ decompress the word list given by inf """
    if outf == None: # read from list, return list
        outf = []
        if schemes[scheme]['header'] != "":
            inf.pop(0)
        prev = ""
        for word in inf:
            num = schemes[scheme]['numarr'].find(word[0])
            prev = prev[:num] + word[1:]
            outf.append(prev)
        return outf
    else:            # read from file, write to file
        if schemes[scheme]['header'] != "":
            inf.readline()
        prev = ""
        for word in inf:
            num = schemes[scheme]['numarr'].find(word[0])
            prev = prev[:num] + word[1:]
            outf.write(prev)
        return None



if __name__ == "__main__":

    import os

    test1 = """
foo
foot
footle
fubar
fub
grunt
"""

    test1_cpt = """
#!xdawg
0foo
3t
4le
1ubar
3
0grunt
"""

    print
    print "Testing the list version of compress..."
    print "\n".join(compress(test1.strip().split("\n")))
    print
    print "That should have printed this...",
    print test1_cpt

    print
    print "Testing the list version of decompress..."
    print "\n".join(decompress(test1_cpt.strip().split("\n")))
    print
    print "That should have printed this...",
    print test1

    print
    print "Testing the file version of compress..."
    if os.path.isfile('wordlist.txt'):
        compress(open('wordlist.txt'),
                 open('wordlist.cpt', 'w'),
                 scheme='Mike')
        print "You should now have a wordlist.cpt file."
    else:
        print "You need a wordlist.txt file for this test."
        
    print
    print "Testing the file version of decompress..."
    if os.path.isfile('wordlist.cpt'):
        decompress(open('wordlist.cpt'),
                   open('wordlist.out', 'w'),
                   scheme='Mike')
        print "You should now have a wordlist.out file."
        print "It should be identical to the wordlist.txt file."
    else:
        print "You need a wordlist.cpt file for this test."
