#!/usr/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test1.t'
use lib '.','./t';	# for inheritance and Win32 test

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..187\n"; }
END {print "not ok 1\n" unless $loaded;}
use MARC 1.03;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.
#
#Added tests should have an comment matching /# \d/
#If so, the following will renumber all the tests
#to match Perl's idea of test:
#perl -pe 'BEGIN{$i=1};if (/# \d/){ $i++};s/# \d+/# $i/' test1.t > test1.t1
#
######################### End of test renumber.

use strict;

my $tc = 2;		# next test number

sub brk {1;} # so we can break on $tc.
sub is_ok {
    brk;
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

sub filestring {
    my $file = shift;
    local $/ = undef;
    unless (open(YY, $file)) {warn "Can't open file $file: $!\n"; return;}
    binmode YY;
    my $yy = <YY>;
    unless (close YY) {warn "Can't close file $file: $!\n"; return;}
    return $yy;
}

my $file = "marc.dat";
my $file2 = "badmarc.dat";
my $testdir = "t";
if (-d $testdir) {
    $file = "$testdir/$file";
    $file2 = "$testdir/$file2";
}
unless (-e $file) {
    die "No MARC sample file found\n";
}
unless (-e $file2) {
    die "Missing bad sample file for MARC tests: $file2\n";
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
       'output.urls', 'output2.html', 'output.mkr';

   # Create the new MARC object. You can use any variable name you like...
   # Read the MARC file into the MARC object.

unless (is_ok ($x = MARC->new ($file))) {			
    printf "could not create MARC from $file\n";
    exit 1;
    # next test would die at runtime without $x
}

is_ok (2 == $x->marc_count);					

# Check that m005 matches original file.
my ($m005) = $x->getvalue({field=>'005',record=>1}); 
is_ok($m005 eq "19990808143752.0");				

   #Output the MARC object to an ascii file
is_ok ($x->output({file=>">output.txt",'format'=>"ASCII"}));	


   #Output the MARC object to an html file
is_ok ($x->output({file=>">output.html",'format'=>"HTML"}));	

   #Try to output the MARC object to an xml file
my $quiet = $^W;
$^W = 0;
is_bad ($x->output({file=>">output.xml",'format'=>"XML"}));	
$^W = $quiet;

   #Output the MARC object to an url file
is_ok ($x->output({file=>">output.urls",'format'=>"URLS"}));	

   #Output the MARC object to an isbd file
is_ok ($x->output({file=>">output.isbd",'format'=>"ISBD"}));	

   #Output the MARC object to a marcmaker file
is_ok ($x->output({file=>">output.mkr",'format'=>"marcmaker"}));	

   #Output the MARC object to an html file with titles
is_ok ($x->output({file=>">output2.html", 
                   'format'=>"HTML","245"=>"TITLE:"}));		

is_ok (-s 'output.txt');					
is_ok (-s 'output.html');					
is_bad (-e 'output.xml');					
is_ok (-s 'output.urls');					

   #Append the MARC object to an html file with titles
is_ok ($x->output({file=>">>output2.html",
                   'format'=>"HTML","245"=>"TITLE:"}));		

   #Append to an html file with titles incrementally
is_ok ($x->output({file=>">output.html",'format'=>"HTML_START"}));	
is_ok ($x->output({file=>">>output.html",
                   'format'=>"HTML_BODY","245"=>"TITLE:"}));		
is_ok ($x->output({file=>">>output.html",'format'=>"HTML_FOOTER"}));	

my ($y1, $y2, $yy);
is_ok ($y1 = $x->output({'format'=>"HTML","245"=>"TITLE:"}));	
$y2 = "$y1$y1";
is_ok ($yy = filestring ("output2.html"));			
is_ok ($yy eq $y2);						

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

is_ok ($yy = filestring ("output.html"));			
is_ok ($y1 eq $yy);						

#Simple test of (un)?pack.*
my $mldr = $x->ldr(1);
my $rhldr = $x->unpack_ldr(1);
is_ok('c' eq ${$rhldr}{RecStat});				
is_ok('a' eq ${$rhldr}{Type});				        
is_ok('m' eq ${$rhldr}{BLvl});				        

my $rhff  = $x->unpack_008(1);
is_ok('741021' eq ${$rhff}{Entered});				
is_ok('s' eq ${$rhff}{DtSt});					
is_ok('1884' eq ${$rhff}{Date1});				

my ($m000) = $x->getvalue({field=>'000',record=>1});
my ($m001) = $x->getvalue({field=>'001',record=>1});
my ($m003) = $x->getvalue({field=>'003',record=>1});

my ($m008) = $x->getvalue({field=>'008',record=>1});

is_ok($m000 eq "00901cam  2200241Ia 45e0");			
is_ok($m001 eq "ocm01047729 ");					
is_ok($m003 eq "OCoLC");					

is_ok($m008 eq "741021s1884    enkaf         000 1 eng d");	

is_ok($x->_pack_ldr($rhldr) eq $m000);				
is_ok($x->_pack_ldr($rhldr) eq $x->ldr(1));			
is_ok($x->_pack_008($m000,$rhff) eq $m008);			

$x->pack_ldr(1);
is_ok($x->ldr(1) eq $mldr);                                     
$x->pack_008(1);
my ($cmp008) = $x->getvalue({field=>'008',record=>1});
is_ok($cmp008 eq $m008);                                        

my ($indi1) = $x->getvalue({field=>'245',record=>1,subfield=>'i1'});
my ($indi2) = $x->getvalue({field=>'245',record=>1,subfield=>'i2'});
my ($indi12) = $x->getvalue({field=>'245',record=>1,subfield=>'i12'});

is_ok($indi1 eq "1");						
is_ok($indi2 eq "4");						
is_ok($indi12 eq "14");						

my ($m100a) = $x->getvalue({field=>'100',record=>1,subfield=>'a'});
my ($m100d) = $x->getvalue({field=>'100',record=>1,subfield=>'d'});
my ($m100e) = $x->getvalue({field=>'100',record=>1,subfield=>'e'});

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

is_ok($m100a eq "Twain, Mark,");				
is_ok($m100d eq "1835-1910.");					
is_bad(defined $m100e);						

my @ind12 = $x->getvalue({field=>'246',record=>2,subfield=>'i12'});
is_ok(3 == scalar @ind12);					
is_ok($ind12[0] eq "30");					
is_ok($ind12[1] eq "3 ");					
is_ok($ind12[2] eq "30");					

my @m246a = $x->getvalue({field=>'246',record=>2,subfield=>'a'});
is_ok(3 == scalar @m246a);					
is_ok($m246a[0] eq "Photo archive");				
is_ok($m246a[1] eq "Associated Press photo archive");		
is_ok($m246a[2] eq "AP photo archive");				

my @records=$x->searchmarc({field=>"245"});
is_ok(2 == scalar @records);					
is_ok($records[0] == 1);					
is_ok($records[1] == 2);					

@records=$x->searchmarc({field=>"245",subfield=>"a"});
is_ok(2 == scalar @records);					
is_ok($records[0] == 1);					
is_ok($records[1] == 2);					

@records=$x->searchmarc({field=>"245",subfield=>"b"});
is_ok(1 == scalar @records);					
is_ok($records[0] == 1);					

@records=$x->searchmarc({field=>"245",subfield=>"h"});
is_ok(1 == scalar @records);					
is_ok($records[0] == 2);					

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

@records=$x->searchmarc({field=>"246",subfield=>"a"});
is_ok(1 == scalar @records);					
is_ok($records[0] == 2);					

@records=$x->searchmarc({field=>"245",regex=>"/huckleberry/i"});
is_ok(1 == scalar @records);					
is_ok($records[0] == 1);					

@records=$x->searchmarc({field=>"260",subfield=>"c",regex=>"/19../"});
is_ok(1 == scalar @records);					
is_ok($records[0] == 2);					

@records=$x->searchmarc({field=>"245",notregex=>"/huckleberry/i"});
is_ok(1 == scalar @records);					
is_ok($records[0] == 2);					

@records=$x->searchmarc({field=>"260",subfield=>"c",notregex=>"/19../"});
is_ok(1 == scalar @records);					
is_ok($records[0] == 1);					

@records=$x->searchmarc({field=>"900",subfield=>"c"});
is_ok(0 == scalar @records);					
is_bad(defined $records[0]);					

@records=$x->searchmarc({field=>"999"});
is_ok(0 == scalar @records);					
is_bad(defined $records[0]);					

is_ok (-s 'output.isbd');					
is_ok (-s 'output.mkr');					

my $update246 = {field=>'246',record=>2,ordered=>'y'};
my @u246 = $x->getupdate($update246);
is_ok(21 ==  @u246);						

is_ok(1 == $x->searchmarc($update246));				
is_ok(3 == $x->deletemarc($update246));				

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

is_ok($u246[0] eq "i1");					
is_ok($u246[1] eq "3");						
is_ok($u246[2] eq "i2");					
is_ok($u246[3] eq "0");						
is_ok($u246[4] eq "a");						
is_ok($u246[5] eq "Photo archive");				
is_ok($u246[6] eq "\036");					

is_ok($u246[7] eq "i1");					
is_ok($u246[8] eq "3");						
is_ok($u246[9] eq "i2");					
is_ok($u246[10] eq " ");					
is_ok($u246[11] eq "a");					
is_ok($u246[12] eq "Associated Press photo archive");		
is_ok($u246[13] eq "\036");					

is_ok($u246[14] eq "i1");					
is_ok($u246[15] eq "3");					
is_ok($u246[16] eq "i2");					
is_ok($u246[17] eq "0");					
is_ok($u246[18] eq "a");					
is_ok($u246[19] eq "AP photo archive");				
is_ok($u246[20] eq "\036");					

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

is_ok ($y1 = $x->output({'format'=>"HTML_HEADER"}));		
my $header = "Content-type: text/html\015\012\015\012";
is_ok ($y1 eq $header);						

is_ok ($y1 = $x->output({'format'=>"HTML_START"}));		
$header = "<html><body>";
is_ok ($y1 eq $header);						

is_ok ($y1 = $x->output({'format'=>"HTML_START",'title'=>"Testme"}));	
$header = "<html><head><title>Testme</title></head>\n<body>";
is_ok ($y1 eq $header);						

is_ok ($y1 = $x->output({'format'=>"HTML_FOOTER"}));		
$header = "\n</body></html>\n";
is_ok ($y1 eq $header);						

is_ok(0 == $x->searchmarc($update246));				
@records = $x->getupdate($update246);
is_ok(0 == @records);						

    # prototype setupdate()
@records = ();
foreach $y1 (@u246) {
    unless ($y1 eq "\036") {
	push @records, $y1;
	next;
    }
    $x->addfield($update246, @records) || warn "not added\n";
    @records = ();
}

@u246 = $x->getupdate($update246);
is_ok(21 == @u246);						

is_ok($u246[0] eq "i1");					
is_ok($u246[1] eq "3");						
is_ok($u246[2] eq "i2");					
is_ok($u246[3] eq "0");						
is_ok($u246[4] eq "a");						
is_ok($u246[5] eq "Photo archive");				
is_ok($u246[6] eq "\036");					

is_ok($u246[7] eq "i1");					
is_ok($u246[8] eq "3");						

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

is_ok($u246[9] eq "i2");					
is_ok($u246[10] eq " ");					
is_ok($u246[11] eq "a");					
is_ok($u246[12] eq "Associated Press photo archive");		
is_ok($u246[13] eq "\036");					

is_ok($u246[14] eq "i1");					
is_ok($u246[15] eq "3");					
is_ok($u246[16] eq "i2");					
is_ok($u246[17] eq "0");					
is_ok($u246[18] eq "a");					

is_ok($u246[19] eq "AP photo archive");				
is_ok($u246[20] eq "\036");					

@records = $x->searchmarc({field=>'900'});
is_ok(0 == @records);						
@records = $x->searchmarc({field=>'999'});
is_ok(0 == @records);						

is_ok($x->addfield({record=>1, field=>"999", ordered=>"n", 
                    i1=>"5", i2=>"3", value=>[c=>"wL70",
		    d=>"AR Clinton PL",f=>"53525"]}));		

is_ok($x->addfield({record=>1, field=>"900", ordered=>"y", 
                    i1=>"6", i2=>"7", value=>[z=>"part 1",
		    z=>"part 2",z=>"part 3"]}));		

is_ok($x->addfield({record=>2, field=>"900", ordered=>"y", 
                    i1=>"9", i2=>"8", value=>[z=>"part 4"]}));	

@records = $x->searchmarc({field=>'900'});
is_ok(2 == @records);						
@records = $x->searchmarc({field=>'999'});
is_ok(1 == @records);						

@records = $x->getupdate({field=>'900',record=>1});
is_ok(11 == @records);						

is_ok($records[0] eq "i1");					
is_ok($records[1] eq "6");					

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

is_ok($records[2] eq "i2");					
is_ok($records[3] eq "7");					
is_ok($records[4] eq "z");					
is_ok($records[5] eq "part 1");					
is_ok($records[6] eq "z");					
is_ok($records[7] eq "part 2");					
is_ok($records[8] eq "z");					
is_ok($records[9] eq "part 3");					
is_ok($records[10] eq "\036");					

@records = $x->getupdate({field=>'900',record=>2});
is_ok(7 == @records);						

is_ok($records[0] eq "i1");					
is_ok($records[1] eq "9");					
is_ok($records[2] eq "i2");					
is_ok($records[3] eq "8");					
is_ok($records[4] eq "z");					

is_ok($records[5] eq "part 4");					
is_ok($records[6] eq "\036");					

@records = $x->getupdate({field=>'999',record=>1});
is_ok(11 == @records);						

is_ok($records[0] eq "i1");					
is_ok($records[1] eq "5");					
is_ok($records[2] eq "i2");					
is_ok($records[3] eq "3");					

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

is_ok($records[4] eq "c");					
is_ok($records[5] eq "wL70");					
is_ok($records[6] eq "d");					
is_ok($records[7] eq "AR Clinton PL");				
is_ok($records[8] eq "f");					
is_ok($records[9] eq "53525");					
is_ok($records[10] eq "\036");					

@records = $x->getupdate({field=>'999',record=>2});
is_ok(0 == @records);						

@records = $x->getupdate({field=>'001',record=>2});
is_ok(2 == @records);						
is_ok($records[0] eq "ocm40139019 ");				
is_ok($records[1] eq "\036");					

is_ok(2 == $x->deletemarc());					
is_zero($x->marc_count);					

$MARC::TEST = 1;
is_ok('0 but true' eq $x->openmarc({file=>$file2,
				    'format'=>"usmarc"}));	
is_ok(-1 == $x->nextmarc(2));					
is_ok(1 == $x->marc_count);					
is_bad(defined $x->nextmarc(1));				
is_ok(1 == $x->nextmarc(2));					
is_ok(2 == $x->marc_count);					
is_ok($x->closemarc);						
