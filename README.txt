MARC (manipulate MAchine Readable Cataloging)
VERSION=0.82, 6 October 1999

This is a cross-platform module. All of the files except README.txt
are LF-only terminations. You will need a better editor than Notepad
to read them on Win32. README.txt is README with CRLF.

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
'perl t/test1.pl PAUSE' form works on all OS types. The test will indicate
if any unexpected errors occur (not ok).

SYNOPSIS:
     use MARC 0.82;

     $x=MARC->new("mymarcfile.mrc");
     $x->output({file=>">my_text.txt",format=>"ascii"});
     $x->output({file=>">my_marcmaker.mkr",format=>"marcmaker"});
     $x->output({file=>">my_html.html",format=>"html"});
     $x->output({file=>">my_xml.xml",format=>"xml"});
     $x->output({file=>">my_urls.html",format=>"urls"});
     $x->output({file=>">isbd.txt",format=>"isbd"});
     print $x->length();

DESCRIPTION:

    MARC.pm is a Perl 5 module for reading in, manipulating, and
    outputting bibliographic records in the *USMARC* format. You
    will need to have Perl 5.004 or greater for MARC.pm to work
    properly. Since it is a Perl module you use MARC.pm from one of
    your own Perl scripts. To see what sorts of conversions are
    possible you can try out a web interface to MARC.pm which will
    allow you to upload MARC files and retrieve the results (for
    details see the section below entitled "Web Interface").

    However, to get the full functionality you will probably want to
    install MARC.pm on your server or PC. MARC.pm can handle both
    single and batches of MARC records. The limit on the amount of
    records in a batch is determined by the memory capacity of the
    machine you are running. If memory is an issue for you MARC.pm
    will allow you to read in records from a batch gradually.
    MARC.pm also includes a variety of tools for searching,
    removing, and even creating records from scratch.

  Types of Conversions:

    *   MARC -> ASCII : separates the MARC fields out into separate
        lines

    *   MARC <-> MARCMaker : The MARCMaker format is a format that was
        developed by the *Library of Congress* for use with their
        DOS based *MARCMaker* and *MARCBreaker* utilities. This
        format is particularly useful for making global changes (ie.
        with a text editor's search and replace) and then converting
        back to MARC (MARC.pm will read properly formatted MARCMaker
        records). For more information about the MARCMaker format
        see http://lcweb.loc.gov/marc/marcsoft.html

    *   MARC -> HTML : The MARC to HTML conversion creates an HTML file
        from the fields and field labels that you supply. You could
        possibly use this to create HTML bibliographies from a batch
        of MARC records.

    *   MARC -> XML : The MARC to XML conversion creates an XML document
        that does not have a *Document Type Definition*.
        Fortunately, since XML does not require a DTD this is OK.

    *   MARC -> URLS : This conversion will extract URLs from a batch of
        MARC records. The URLs are found in the 856 field, subfield
        u. The HTML page that is generated can then be used with
        link-checking software to determine which URLs need to be
        repaired. Hopefully library system vendors will soon support
        this activity soon and make this conversion unecessary!

    *   MARC -> ISBD : An experimental output format that attempts to
	mimic the ISBD.

  Downloading and Installing

    Download

    Unix
            perl Makefile.PL
            make
            make test
            make install

    Win9x/WinNT/Win2000
            perl Makefile.PL
            perl test.pl
            perl install.pl

    Test
        Once you have installed, you can check if Perl can find it.
        Change to some other directory and execute from the command
        line:

            perl -e "use MARC"

        If you do not get any response that means everything is OK!
        If you get an error like *Can't locate method "use" via
        package MARC*. then Perl is not able to find MARC.pm--double
        check that the file copied it into the right place during
        the install.

  Todo

    *   Support for other MARC formats.

    *   Create a map and instructions for using and extending the
        MARC.pm data structure.

    *   Develop better error catching mechanisms.

    *   Support for character conversions from MARC to Unicode ??

    *   Managing MARC records that exceed 99999 characters in length
        (not uncommon for MARC AMC records)

    *   MARC <-> DC/RDF conversion ??

  Web Interface

    A web interface to MARC.pm is available at
    http://libstaff.lib.odu.edu/cgi-bin/marc.cgi where you can
    upload records and observe the results. If you'd like to check
    out the cgi script take a look at
    http://libstaff.lib.odu.edu/depts/systems/iii/scripts/MARCpm/mar
    c-cgi.txt However, to get the full functionality you will want
    to install MARC.pm on your server or PC.

  Notes

    Please let us know if you run into any difficulties using
    MARC.pm--we'd be happy to try to help. Also, please contact us
    if you notice any bugs, or if you would like to suggest an
    improvement/enhancement. Email addresses are listed at the
    bottom of this page.

    The module is provided in standard CPAN distribution format.
    It will extract into a directory MARC-version with any
    necessary subdirectories. Change into the MARC top directory.
    Download the latest version from:

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
    modify it under the same terms as Perl itself. 6 October 1999.

