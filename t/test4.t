#!/usr/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test1.t'
use lib '.','./t';	# for inheritance and Win32 test

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..116\n"; }
END {print "not ok 1\n" unless $loaded;}
use MARC 1.03;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.
#
#Added tests should have an comment matching /# \d/
#If so, the following will renumber all the tests
#to match Perl's idea of test:
#perl -pi.bak -e 'BEGIN{$i=1};if (/# \d/){ $i++};s/# \d+/# $i/' test4.t
#
######################### End of test renumber.

use strict;

my $tc = 2;		# next test number
my $WCB = 0;

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

sub filestring {
    my $file = shift;
    local $/ = undef;
    unless (open(YY, $file)) {warn "Can't open file $file: $!\n"; return;}
    binmode YY;
    my $yy = <YY>;
    unless (close YY) {warn "Can't close file $file: $!\n"; return;}
    return $yy;
}

sub array_eq_str {
    my ($ra1,$ra2)=@_;
    my @a1= @$ra1;
    my @a2= @$ra2;
    return 0 unless (scalar(@a1) == scalar(@a2));
    for my $i (0..scalar(@a1)-1) {
	print "WCB: a1 = $a1[$i]...\n" if $WCB;
	print "WCB: a2 = $a2[$i]...\n" if $WCB;
	return 0 unless ($a1[$i] eq $a2[$i]);
    }
    return 1;
}
sub printarr {
    my @b=@_;
    print "(",(join ", ",grep {s/^/'/;s/$/'/} @b),")";
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
unlink 'output4.txt','output4.mkr','output4a.txt';

   # Create the new MARC object. You can use any variable name you like...
   # Read the MARC file into the MARC object.

unless (is_ok ($x = MARC->new ($file))) {			
    printf "could not create MARC from $file\n";
    exit 1;
    # next test would die at runtime without $x
}

   #Output the MARC object to an ascii file
is_ok ($x->output({file=>">output4.txt",'format'=>"ASCII"}));	

   #Output the MARC object to a marcmaker file
is_ok ($x->output({file=>">output4.mkr",'format'=>"marcmaker"}));	

is_ok (-s 'output4.txt');					
is_ok (-s 'output4.mkr');					
my @a1 = ('1',2,'b');
my @a2 = (1,2,'b');
my @b1 = ('1',2);
my @b2 = ('1',2,'c');
is_ok ( array_eq_str(\@a1,\@a2) );                            
is_bad( array_eq_str(\@a1,\@b1) );                            
is_bad( array_eq_str(\@a1,\@b2) );                            


delete $x->[1]{500};

for (@{$x->[1]{array}}) {
    $x->add_map(1,$_) if $_->[0] eq '500';
}

is_ok(${$x->[1]{500}{'a'}[0]} eq 'First English ed.'); 
${$x->[1]{500}{'a'}[0]} ="boo";
is_ok(${$x->[1]{500}{'a'}[0]} eq 'boo'); 
my @new500=(500,'x','y',a=>"foo",b=>"bar");
$x->add_map(1,[@new500]);       

is_ok(  array_eq_str($x->[1]{500}{field}[4],\@new500) );                            
$x->rebuild_map(1,500);       
my @add008 = ('008',"abcde");
$x->add_map(1,[@add008]);       

is_ok( array_eq_str($x->[1]{'008'}{field}[1],\@add008) );                            
#delete $x->[1]{'008'};
$x->rebuild_map(1,'008');      
my @m008 = ('008', '741021s1884    enkaf         000 1 eng d'); 
is_ok( array_eq_str($x->[1]{'008'}{field}[0],\@m008) );                            

is_ok( !defined($x->[1]{'008'}{field}[1]));                                         

my @m5000 = (500, ' ', ' ', a=> 'boo');
is_ok( array_eq_str($x->[1]{'500'}{field}[0],\@m5000) );                            

my @m5001 = (500, ' ', ' ', a=>'State B; gatherings saddle-stitched with wire staples.');
is_ok( array_eq_str($x->[1]{'500'}{field}[1],\@m5001) );                            

my @m5002 = (500, ' ', ' ', a=> 'Advertisements on p. [1]-32 at end.');
is_ok( array_eq_str($x->[1]{'500'}{field}[2],\@m5002) );                            

my @m5003 = (500, ' ', ' ', a=> 'Bound in red S cloth; stamped in black and gold.');
is_ok( array_eq_str($x->[1]{'500'}{field}[3],\@m5003) );                            

is_ok( $x->deletefirst({field=>'500',record=>1}) );    
$x->updatefirst({field=>'247',record=>1, rebuild_map =>0},
		 ('998',1," ", a =>"Photo marchive"));

$x->updatefirst({field=>'500',record=>1, rebuild_map =>0},
		 ('998',1," ", a =>"First English Fed."));

is_ok( $x->updatefirst({field=>'500',subfield=>"h",record=>1, rebuild_map =>0},
		 ('998',1," ", a =>"First English Fed.",h=>"foobar,the fed")) );    
is_ok( $x->updatefirst({field=>'500',subfield=>"k",record=>1, rebuild_map =>0},
		 ('998',1," ", a =>"First English Fed.",k=>"koobar,the fed")) );    

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

## is_ok($m008 eq "741021s1884    enkaf         000 1 eng d");

my ($m100a) = $x->getvalue({field=>'100',record=>1,subfield=>'a'});
my ($m100d) = $x->getvalue({field=>'100',record=>1,subfield=>'d'});
my ($m100e) = $x->getvalue({field=>'100',record=>1,subfield=>'e'});

is_ok($m100a eq "Twain, Mark,");				
is_ok($m100d eq "1835-1910.");					
is_bad(defined $m100e);						

my @m246a = $x->getvalue({field=>'246',record=>2,subfield=>'a'});
is_ok(3 == scalar @m246a);					
is_ok($m246a[0] eq "Photo archive");				
is_ok($m246a[1] eq "Associated Press photo archive");		
is_ok($m246a[2] eq "AP photo archive");				

is_ok ($x->output({file=>">output4a.txt",'format'=>"ASCII"}));	

my $update246 = {field=>'246',record=>2,ordered=>'y'};
my @u246 = $x->getupdate($update246);
is_ok(21 ==  @u246);						


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

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

is_ok($u246[13] eq "\036");					
is_ok($u246[14] eq "i1");					
is_ok($u246[15] eq "3");					
is_ok($u246[16] eq "i2");					
is_ok($u246[17] eq "0");					
is_ok($u246[18] eq "a");					
is_ok($u246[19] eq "AP photo archive");				
is_ok($u246[20] eq "\036");					

is_ok(3 == $x->deletemarc($update246));				
my @records = ();
foreach my $y1 (@u246) {
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
is_ok($u246[9] eq "i2");					
is_ok($u246[10] eq " ");					
is_ok($u246[11] eq "a");					

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

is_ok($u246[12] eq "Associated Press photo archive");		
is_ok($u246[13] eq "\036");					

is_ok($u246[14] eq "i1");					
is_ok($u246[15] eq "3");					
is_ok($u246[16] eq "i2");					
is_ok($u246[17] eq "0");					
is_ok($u246[18] eq "a");					

is_ok($u246[19] eq "AP photo archive");				
is_ok($u246[20] eq "\036");					


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
is_ok($records[2] eq "i2");					
is_ok($records[3] eq "7");					
is_ok($records[4] eq "z");					
is_ok($records[5] eq "part 1");					
is_ok($records[6] eq "z");					

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

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
is_ok($records[4] eq "c");					
is_ok($records[5] eq "wL70");					
is_ok($records[6] eq "d");					
is_ok($records[7] eq "AR Clinton PL");				
is_ok($records[8] eq "f");					

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

is_ok($records[9] eq "53525");					
is_ok($records[10] eq "\036");					

@records = $x->getupdate({field=>'999',record=>2});
is_ok(0 == @records);						

@records = $x->getupdate({field=>'001',record=>2});
is_ok(2 == @records);						
is_ok($records[0] eq "ocm40139019 ");				
is_ok($records[1] eq "\036");					

