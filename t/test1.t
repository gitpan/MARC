#!/usr/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test1.t'

#### use lib '.','./t','./blib/lib','../blib/lib','./lib','../lib';
use lib '.','./t','./blib/lib','../blib/lib','./lib','../lib';
#### development
# can run from here or distribution base

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..21\n"; }
END {print "not ok 1\n" unless $loaded;}
use MARC 0.71;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

use strict;

my $tc = 2;		# next test number

sub is_ok {
    my $result = shift;
    printf (($result ? "" : "not ")."ok %d\n",$tc++);
    return $result;
}

sub is_zero {
    my $result = shift;
    if (defined $result) {
        return is_ok ($result == 0);
    }
    else {
        printf ("not ok %d\n",$tc++);
    }
}

sub is_bad {
    my $result = shift;
    printf (($result ? "not " : "")."ok %d\n",$tc++);
    return (not $result);
}

my $file = "marc.dat";
my $testfile = "t/marc.dat";
if (-e $testfile) {
    $file = $testfile;
}
unless (-e $file) {
    die "No MARC sample file found\n";
}

my $naptime = 0;	# pause between output pages
if (@ARGV) {
    $naptime = shift @ARGV;
    unless ($naptime =~ /^[0-5]$/) {
	die "Usage: perl test?.t [ page_delay (0..5) ]";
    }
}

my $x;
unlink 'output.txt', 'output.html', 'output.xml',
       'output.urls', 'output2.html';

   # Create the new MARC object. You can use any variable name you like...
   # Read the MARC file into the MARC object.

unless (is_ok ($x = MARC->new ($file))) {			# 2
    printf "could not create MARC from $file\n";
    exit 1;
    # next test would die at runtime without $x
}

is_ok (2 == $x->length);					# 3

   #Output the MARC object to an ascii file
is_ok ($x->output({file=>">output.txt",'format'=>"ASCII"}));	# 4

   #Output the MARC object to an html file
is_ok ($x->output({file=>">output.html",'format'=>"HTML"}));	# 5

   #Output the MARC object to an xml file
is_ok ($x->output({file=>">output.xml",'format'=>"XML"}));	# 6

   #Output the MARC object to an url file
is_ok ($x->output({file=>">output.urls",'format'=>"URLS"}));	# 7

   #Output the MARC object to an isbd file
is_ok ($x->output({file=>">output.isbd",'format'=>"ISBD"}));	# 8

   #Output the MARC object to an html file with titles
is_ok ($x->output({file=>">output2.html",
                   'format'=>"HTML","245"=>"TITLE:"}));		# 9

is_ok (-s 'output.txt');					# 10
is_ok (-s 'output.html');					# 11
is_ok (-s 'output.xml');					# 12
is_ok (-s 'output.urls');					# 13
is_ok (-s 'output.isbd');					# 14
my ($size1, $size2, $y);
is_ok ($size1 = -s 'output2.html');				# 15

   #Append the MARC object to an html file with titles
is_ok ($x->output({file=>">>output2.html",
                   'format'=>"HTML","245"=>"TITLE:"}));		# 16

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

is_ok ($size2 = -s 'output2.html');				# 17
$size2 -= ($size1 + $size1);
is_bad (($size2 > 5) || ($size2 < -5));				# 18
print "size1=$size1, size2=$size2\n";

is_ok ($y = $x->output({'format'=>"HTML","245"=>"TITLE:"}));	# 19
is_ok ($size2 = length ($y));					# 20
$size2 -= $size1;
is_bad (($size2 > 8) || ($size2 < -8));				# 21
print "size1=$size1, size2=$size2\n";
