MARC (manipulate MAchine Readable Cataloging)
VERSION=0.91, 19 October 1999

This is a cross-platform module. All of the files except README.txt
are LF-only terminations. You will need a better editor than Notepad
to read them on Win32. README.txt is README with CRLF.

DESCRIPTION:

MARC.pm is a Perl 5 module for reading in, manipulating, and outputting
bibliographic records in the USMARC format. You will need to have Perl
5.004 or greater for MARC.pm to work properly. Since it is a Perl module
you use MARC.pm from one of your own Perl scripts. It handles conversions
from MARC into ASCII (text),  Library of Congress MARCMaker, HTML, XML,
and ISBD. Input from MARCMaker format is also supported. Individual
records, fields, indicators, and subfields can be created, modified, and
deleted. It can extract URLs from the 856 field into HTML.

MARC.pm can handle both single and batches of MARC records. The limit on
the number of records in a batch is determined by the memory capacity of
the machine you are running. If memory is an issue for you MARC.pm will
allow you to read in records from a batch gradually. MARC.pm also includes
a variety of tools for searching, removing, and even creating records from
scratch.

FILES:

    Changes		- for history lovers
    Makefile.PL		- the "starting point" for traditional reasons
    MANIFEST		- file list
    README		- this file for CPAN
    README.txt		- this file for DOS
    MARC.pm		- the reason you're reading this

    t			- test directory
    t/marc.dat		- two record data file for testing
    t/test1.t		- RUN ME FIRST, basic tests

    eg			- test directory
    eg/microlif.001	- eighteen record data file for demo
    eg/addlocal.pl	- simple modify/write demo with comments

INSTALL and TEST:

On linux and Unix, this distribution uses Makefile.PL and the "standard"
install sequence for CPAN modules:
	perl Makefile.PL
	make
	make test
	make install

On Win32, Makefile.PL creates equivalent scripts for the "make-deprived"
and follows a similar sequence.
	perl Makefile.PL
	perl test.pl
	perl install.pl

Both sequences create install files and directories. The test uses a
small sample input file and creates outputs in various formats. You can
specify an optional PAUSE (0..5 seconds) between pages of output. The
'perl t/test1.pl PAUSE' form works on all OS types. The test will
indicate if any unexpected errors occur (not ok).

Once you have installed, you can check if Perl can find it. Change to
some other directory and execute from the command line:

            perl -e "use MARC"

No response that means everything is OK! If you get an error like
* Can't locate method "use" via package MARC *, then Perl is not
able to find MARC.pm--double check that the file copied it into the
right place during the install.

NOTES:

Please let us know if you run into any difficulties using MARC.pm--
e'd be happy to try to help. Also, please contact us if you notice any
bugs, or if you would like to suggest an improvement/enhancement. Email
addresses are listed at the bottom of this page.

The module is provided in standard CPAN distribution format. Additional
documentation is created during the installation (html and man formats).

Download the latest version from CPAN or:

    http://libstaff.lib.odu.edu/depts/systems/iii/scripts/MARCpm

AUTHORS:

    Chuck Bearden cbearden@rice.edu
    Bill Birthisel wcbirthisel@alum.mit.edu
    Charles McFadden chuck@vims.edu
    Ed Summers esummers@odu.edu

COPYRIGHT
    Copyright (C) 1999, Bearden, Birthisel, McFadden, Summers. All
    rights reserved.

    This module is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

