#!/usr/bin/perl
# chk.pl -- allows batch test without Makefile.PL's 
# tendency to spend time updating blib, etc.
#
# Usage: chdir to top directory and do bin/chk.pl
# Win/DOS try perl bin/chk.pl (not tested).
#
foreach my $i (1..5) {
    print "test$i.t\n";
    open F, "perl t/test$i.t |" or die "Could not regress on test$i.t: $!\n";
    while (<F>) {
	print if /not/;
    }
    close F;
}

