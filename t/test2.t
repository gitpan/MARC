#!/usr/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test1.t'

use lib '.','./t';	# for inheritance and Win32 test

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..65\n"; }
END {print "not ok 1\n" unless $loaded;}
use MARC 1.04;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

use strict;

my $tc = 2;		# next test number

use strict;
use File::Compare;

sub out_cmp {
    my $outfile = shift;
    my $reffile = shift;
    if (-s $outfile && -s $reffile) {
        return is_zero (compare($outfile, $reffile));
    }
    printf ("not ok %d\n",$tc++);
}

sub is_zero {
    my $result = shift;
    if (defined $result) {
        return is_ok ($result == 0);
    }
    printf ("not ok %d\n",$tc++);
}

sub is_ok {
    my $result = shift;
    printf (($result ? "" : "not ")."ok %d\n",$tc++);
    return $result;
}

sub is_bad {
    my $result = shift;
    printf (($result ? "not " : "")."ok %d\n",$tc++);
    return (not $result);
}

my $file = "makrbrkr.mrc";
my $file2 = "brkrtest.ref";
my $file3 = "makrtest.src";
my $file4 = "makrtest.bad";

my $testdir = "t";
if (-d $testdir) {
    $file = "$testdir/$file";
    $file2 = "$testdir/$file2";
    $file3 = "$testdir/$file3";
    $file4 = "$testdir/$file4";
}
unless (-e $file) {
    die "Missing sample file for MARCMaker tests: $file\n";
}
unless (-e $file2) {
    die "Missing results file for MARCBreaker tests: $file2\n";
}
unless (-e $file3) {
    die "Missing source file for MARCMaker tests: $file3\n";
}
unless (-e $file4) {
    die "Missing bad source file for MARCMaker tests: $file4\n";
}

my $naptime = 0;	# pause between output pages
if (@ARGV) {
    $naptime = shift @ARGV;
    unless ($naptime =~ /^[0-5]$/) {
	die "Usage: perl test?.t [ page_delay (0..5) ]";
    }
}

my $x;
unlink 'output.txt', 'output.html', 'output.xml', 'output.isbd',
       'output.urls', 'output2.bkr', 'output.mkr', 'output.bkr';

   # Create the new MARC object. You can use any variable name you like...
   # Read the MARC file into the MARC object.

unless (is_ok ($x = MARC->new($file3,"marcmaker"))) {		
    die "could not create MARC from $file3\n";
    # next test would die at runtime without $x
}

$MARC::TEST = 1; # so outputs have known dates for 005
is_ok (8 == $x->marc_count);					

   #Output the MARC object to a marcmaker file with nolinebreak
is_ok ($x->output({file=>">output.bkr",'format'=>"marcmaker",
	nolinebreak=>'y'}));					
out_cmp ("output.bkr", $file2);					

my $y;
is_ok ($y = $x->output());					

   #Output the MARC object to an ascii file
is_ok ($x->output({file=>">output.txt",'format'=>"ASCII"}));	

   #Output the MARC object to a marcmaker file
is_ok ($x->output({file=>">output2.bkr",'format'=>"marcmaker"}));	

   #Output the MARC object to a marc file
is_ok ($x->output({file=>">output.mkr",'format'=>"marc"}));	

out_cmp ("output.mkr", $file);					

$MARC::TEST = 0; #minimal impact
$^W = 0;
my ($m000) = $x->getvalue({record=>'1',field=>'000'});
my ($m001) = $x->getvalue({record=>'1',field=>'001'});
is_ok ($m000 eq "01200nam  2200253 a 4500");			
is_ok ($m001 eq "tes96000001 ");				

my ($m002) = $x->getvalue({record=>'1',field=>'002'});
my ($m003) = $x->getvalue({record=>'1',field=>'003'});
is_bad (defined $m002);						
is_ok ($m003 eq "ViArRB");					

my ($m004) = $x->getvalue({record=>'1',field=>'004'});
my ($m005) = $x->getvalue({record=>'1',field=>'005'});
is_bad (defined $m004);						
is_ok ($m005 eq "19960221075055.7");				

my ($m006) = $x->getvalue({record=>'1',field=>'006'});
my ($m007) = $x->getvalue({record=>'1',field=>'007'});
is_bad (defined $m006);						
is_bad (defined $m007);						

my ($m008) = $x->getvalue({record=>'1',field=>'008'});
my ($m009) = $x->getvalue({record=>'1',field=>'009'});
is_ok ($m008 eq "960221s1955    dcuabcdjdbkoqu001 0deng d");	
is_bad (defined $m009);						

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

my ($m260a) = $x->getvalue({record=>'8',field=>'260',subfield=>'a'});
my ($m260b) = $x->getvalue({record=>'8',field=>'260',subfield=>'b'});
my ($m260c) = $x->getvalue({record=>'8',field=>'260',subfield=>'c'});
is_ok ($m260a eq "Washington, DC :");				
is_ok ($m260b eq "Library of Congress,");			
is_ok ($m260c eq "1955.");					

my @m260 = $x->getvalue({record=>'8',field=>'260'});
is_ok ($m260[0] eq "Washington, DC : Library of Congress, 1955. ");	

my ($m245i1) = $x->getvalue({record=>'8',field=>'245',subfield=>'i1'});
my ($m245i2) = $x->getvalue({record=>'8',field=>'245',subfield=>'i2'});
my ($m245i12) = $x->getvalue({record=>'8',field=>'245',subfield=>'i12'});
is_ok ($m245i1 eq "1");						
is_ok ($m245i2 eq "2");						
is_ok ($m245i12 eq "12");					

is_ok (3 == $x->selectmarc(["1","7-8"]));			
is_ok (3 == $x->marc_count);					

my @records=$x->searchmarc({field=>"020"});
is_ok(2 == scalar @records);					
is_ok($records[0] == 2);					
is_ok($records[1] == 3);					

@records=$x->searchmarc({field=>"020",subfield=>"c"});
is_ok(1 == scalar @records);					
is_ok($records[0] == 3);					

@records = $x->getupdate({field=>'020',record=>2});
is_ok(7 == @records);						

is_ok($records[0] eq "i1");					
is_ok($records[1] eq " ");					
is_ok($records[2] eq "i2");					
is_ok($records[3] eq " ");					
is_ok($records[4] eq "a");					
is_ok($records[5] eq "8472236579");				
is_ok($records[6] eq "\036");					

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

is_ok(1 == $x->deletemarc({field=>'020',record=>2}));		
$records[6] = "c";
$records[7] = "new data";
is_ok($x->addfield({field=>'020',record=>2}, @records));	

@records=$x->searchmarc({field=>"020",subfield=>"c"});
is_ok(2 == scalar @records);					
is_ok($records[0] == 2);					
is_ok($records[1] == 3);					

@records = $x->getvalue({record=>'2',field=>'020',delimiter=>'|'});
is_ok(1 == scalar @records);					
is_ok($records[0] eq "|a8472236579|cnew data");			

is_ok(1 == $x->deletemarc({field=>'020',record=>2,subfield=>'c'}));	
@records=$x->searchmarc({field=>"020",subfield=>"c"});
is_ok(1 == scalar @records);					
is_ok($records[0] == 3);					

@records = $x->getvalue({record=>'2',field=>'020',delimiter=>'|'});
is_ok(1 == scalar @records);					
is_ok($records[0] eq "|a8472236579");				

is_ok(3 == $x->deletemarc());					
is_zero($x->marc_count);					

$MARC::TEST = 1;
is_ok('0 but true' eq $x->openmarc({file=>$file4,
				    'format'=>"marcmaker"}));	
is_ok(-2 == $x->nextmarc(4));					
is_ok(2 == $x->marc_count);					
is_ok($x->closemarc);						
is_ok(2 == $x->deletemarc());					

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

is_ok(2 == $x->openmarc({file=>$file4, increment=>2,
			 'format'=>"marcmaker"}));		
is_bad(defined $x->nextmarc(1));				
is_ok(2 == $x->marc_count);					
is_ok($x->closemarc);						
