#!/usr/bin/perl 
# Ship.pl -- uses a SHIP file to make a .tar.gz version of 
# the directory. Auto-creates README.txt; allows addition
# of use lib '..'; #DEV in t/test*.t for easy perldb-emacs
# testing.

# Usage: chdir to top directory of dist and do bin/ship.pl
# Win/DOS try perl bin/ship.pl (not tested).

use File::Copy;
use strict;
use Cwd;
$|++;
my $fromdir = getcwd;
print "from:$fromdir\n";
my %conf = ();
my @testfiles=(); # we munge test*.t

open S, "SHIP";
while (<S>) {
    chomp;
    next if /^#/;
    next if /^\s*$/;
    
    $conf{$1} = $2 if /(\w+)\s*=\s*(.*)/;
    print;
}
close S;

my %seendir = ();
open M,"MANIFEST";
while (<M>) {
    if (/^#/) {
	print;
	next;
    }
    chomp;

    my $dir;
    my $shdir;
    $dir = $1 if m{^(\S+)/};
    die "don't deal with two-level dirs" if $dir=~m{/};
    $shdir = "$conf{shipdir}/$dir" if $dir;

    mkdir $shdir,0770 unless ( !$shdir or -e $shdir or $seendir{$shdir});
    $seendir{$shdir}++;

    next if /^SAVE|README.txt|MANIFEST$/;
    next if /^\s*$/;
    if (/test\d\.t/) {
	push @testfiles,$_;
	next;
    }
    copy "$_", "$conf{shipdir}/$_"   or  die "ERROR copying file $_: ($!)\n";
}

close M;

my $shipdir = $conf{shipdir};

foreach my $testfile (@testfiles) {
    open T, $testfile or die  "Could not open $testfile:$!\n";
    open ST, ">$shipdir/$testfile" or die "Could not open $testfile in $shipdir:$!\n";
    while (<T>) {
	print ST unless /DEV/;
    }
    close T;
    close ST;
}


copy $conf{pmfile}, "$conf{shipdir}/$conf{shippm}"
    or  die "ERROR copying files $conf{pmfile}: ($!)\n";

open R,"README" or die;
open RDOS,">$shipdir/README.txt" or die;
while (<R>) {
    s/$/\r/;
    print RDOS;
}
close R;
close RDOS;

opendir D,$shipdir;
my @goners = grep /^$conf{'cleargz'}/,readdir D;
chdir $shipdir;
unlink @goners;
chdir $fromdir;
closedir D;

open M,"MANIFEST" or die;
open SHM,">$shipdir/MANIFEST" or die;
while (<M>) {
    next if /^#/;
    print SHM;
}
close SHM;
close M;

chdir $conf{shipdir} or die "could not change dir :$!";

system ("perl Makefile.PL");
system ("make; make test; make tardist");
