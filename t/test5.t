#!/usr/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test1.t'
use lib  '.','./t';	# for inheritance and Win32 test

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..138\n"; }
END {print "not ok 1\n" unless $loaded;}
use MARC 1.07;
use Data::Dumper;

$loaded = 1;
print "ok 1\n";

######################### End of black magic.
#
#Added tests should have an comment matching /# \d/
#If so, the following will renumber all the tests
#to match Perl's idea of test:
#perl -pi.bak -e 'BEGIN{$i=1};next if /^#/;if (/# \d/){ $i++};s/# \d+/# $i/' test5.t
#
######################### End of test renumber.

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

sub filestring {
    my $file = shift;
    local $/ = undef;
    unless (open(YY, $file)) {warn "Can't open file $file: $!\n"; return;}
    binmode YY;
    my $yy = <YY>;
    unless (close YY) {warn "Can't close file $file: $!\n"; return;}
    return $yy;
}

sub dumper_eq {
  my ($r1,$r2)=@_;
  return Dumper($r1) eq Dumper($r2);
}

sub testfile {
    my $rvar = shift;
    $$rvar = "t/$$rvar" if -e "t/$$rvar";
    die "No MARC sample file found ($$rvar)\n" unless -e $$rvar;
}

my $file = "marc4.dat";
my $badfile = "badmarc.dat";
my $badstrictout  = "badmarcstrict.mkr";
my $badout  = "badmarc.mkr";
my $badoutnl  = "badmarcnl.mkr";
my $badstrictcmp  = "badstrictcmp.mkr";
my $badcmp  = "badcmp.mkr";
my $badcmpnl  = "badcmpnl.mkr";
my $makrtestnl = "makrtestnl.src";
my $makrbrkr = "makrbrkr.out";
my $makrcmp = "makrbrkr.mrc";

testfile (\$file);
testfile (\$badfile);
testfile (\$badstrictout);
testfile (\$badout);
testfile (\$badoutnl);
testfile (\$badstrictcmp);
testfile (\$badcmp);
testfile (\$badcmpnl);
testfile (\$makrtestnl);
testfile (\$makrbrkr);
testfile (\$makrcmp);

my $naptime = 0;	# pause between output pages
if (@ARGV) {
    $naptime = shift @ARGV;
    unless ($naptime =~ /^[0-5]$/) {
	die "Usage: perl test?.t [ page_delay (0..5) ]";
    }
}

my $x;
unlink 'output4.txt','output4.mkr';

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


$MARC::TEST = 1;
my $y = MARC->new();

is_ok('0 but true' eq $y->openmarc({file=>$badfile,
				    'format'=>"usmarc"}));	
is_ok(-1 == $y->nextmarc(4));					
is_ok(1 == $y->marc_count);                                       
is_ok( !defined($y->nextmarc(1)));				
is_ok(1 == $y->marc_count);                                       
is_ok(1 == $y->nextmarc(1));					
is_ok(2 == $y->marc_count);					

is_ok($y->closemarc);						
is_ok(2 == $y->deletemarc());					

is_ok('0 but true' eq $y->openmarc({file=>$badfile,
				    'format'=>"usmarc"}));	

is_ok(-1 == $y->nextmarc(2));					
is_ok( !defined($y->nextmarc(1)));					
is_ok(1 == $y->nextmarc(1));					
is_ok(2 == $y->marc_count);					

is_ok ($y->output({file=>">$badstrictout",'format'=>"marcmaker"}));	
is_ok (filestring($badstrictout) eq filestring($badstrictcmp));       
is_ok($y->closemarc);						
is_ok(2 == $y->deletemarc());					

is_ok('0 but true' eq 
      $y->openmarc({file=>$badfile,
		    format=>"usmarc",
		    strict =>0}));	

is_ok(2 == $y->nextmarc(2));					
is_ok( 1== $y->nextmarc(1));					
is_ok( 1 == $y->nextmarc(1));					
is_ok(4 == $y->marc_count);					

is_ok ($y->output({file=>">$badout",'format'=>"marcmaker"}));	
is_ok (filestring($badout) eq filestring($badcmp));       

is_ok ( $y->output({
    file=> ">$badoutnl",
    format=> "marcmaker",
    lineterm=>"\n",
    })
);	
is_ok (filestring($badoutnl) eq filestring($badcmpnl));       

is_ok($y->closemarc);						
is_ok(4 == $y->deletemarc());					

is_ok( 8 eq $y->openmarc({file=>$makrtestnl,
		    format=>"marcmaker", increment=> -1,
		    lineterm=>"\n"})
);	

is_ok ($y->output({file=>">$makrbrkr",'format'=>"usmarc"}));	
is_ok (filestring($makrbrkr) eq filestring($makrcmp));       

# I have found updatefirst/deletefirst functionality very tricky to
# implement.  And this is the second time I have implemented it. There
# are several semantics that can go either way.  These tests are
# intended to cover all semantic choices and data dependencies,
# providing reasonable evidence that any straightforward
# implementation is correct.

# Note to implementors. You should maintain a couple of obvious
# invariants by construction. Don't change any but the current record
# and don't change any but the current field (and subfield if it
# exists). Not hard to do, but someone has to say it....  If you need
# to violate the subfield constraint (possible if you put extra
# information in the field to reflect workflow) do it in updatehook().

#. Tests are for "all significant variations", which we 
# split by function: deletion or update
# Given deletion the variations are:
# da. tag < or > 10,                  (tags 1 090)
# db. 0,1, or more  matches                 (tags 2 11 3 49 500)
# dc. subfield spec or not                  (tags 5 245)  
# dd. indicator or not in the subfield spec (tag > 10)
# de. last subfield or not                  (tags 3 049)
# df. match in the first field or not.      (tags 500 subfield c and a)

# Given update the variations are:
# ua. to be tag < or > 10,                  (tags 1 3 5 8)
# ub. 0,1, or more  matches                 (tags 2 11 3 49 500)
# uc. subfield spec or not                  (tags 4   
# ud. indicator or not in the subfield spec
# uf. match in the first field or not.      (tags 500 subfield c and a)

# This gives an upper bound of 2*3*2*2*2*2 + 2*3*2*2*2 = 96+48 = 148
# tests. (There is some collapse possible, so we may get away with
# (much) less.) (Currently we have 16 deletes and 14 updates. Better...)


#. What needs to be tested.
# We must check that only the affected fields and subfields are 
# touched. Therefore we need to check, e.g. the 008 field when
# we are munging the 245's. From the structure of current code
# this is provably correct, but subclasses my override this...

my ($m008) = $x->getvalue({field=>'008',record=>1,delimeter=>"\c_"});

# Deletion.
#da1.db3 not currently tested. Check with a repeat 006 sometime.
#da1.db1.dc1
#da1.db1.dc2
#da1.db2.dc1
#da1.db2.dc2

#da2.db1.dc1.dd1
#da2.db1.dc1.dd2
#da2.db1.dc2

#da2.db2.dc1.dd1
#da2.db2.dc1.dd2.de1
#da2.db2.dc1.dd2.de2
#da2.db2.dc2
#da2.db3.dc1.dd1
#da2.db3.dc1.dd2
#da2.db3.dc1.dd2.de1
#da2.db3.dc1.dd2.de2.df1
#da2.db3.dc1.dd2.de2.df2

# Update.
#ua1.ub3 not currently tested. Check with a repeat 006 sometime.
#ua1.ub1.uc1
#ua1.ub1.uc2
#ua1.ub2.uc1
#ua1.ub2.uc2

#ua2.ub1.uc1.ud1
#ua2.ub1.uc1.ud2
#ua2.ub1.uc2

#ua2.ub2.uc1.ud1
#ua2.ub2.uc1.ud2
#ua2.ub2.uc2
#ua2.ub3.uc1.ud1
#ua2.ub3.uc1.ud2.uf1
#ua2.ub3.uc1.ud2.uf2

my %o=();
for (qw(001 002 005 049 090 245 247 500)) {
    my @tmp = $x->getupdate({record=>1,field=>$_});
    $o{$_}=\@tmp;
}

my $templc1d1 = {record=>1,field=>245,subfield=>'i1'};
my $templc1d2 = {record=>1,field=>245,subfield=>'a'};
my $templc2    = {record=>1,field=>245};
my $subfieldf1  = 'a';
my $subfieldf2  = 'c';
my $fieldf  = 500;

#F u a1.b1.c2    002 a
my $ftempl = {record=>1,field=>'002'};
my $templ  = {record=>1,field=>'002'};
$templ->{subfield}= 'a';

{ # new block so that locals give us minimal impact.
    local $MARC::TEST=0;                      # We are gonna test warnings...
    local $SIG{__WARN__} = sub { die $_[0] }; # by making them exceptions...
    undef $@;
    eval{$x->updatefirst($templ,('002',"x","y", a =>"zz"));};
    is_ok( $@ =~/Cannot update subfields of control fields/);  
#... and testing for them in the time-honored way.
}    
my @new =$x->getupdate($ftempl);
my $ranew = \@new;

my ($indi1) = $x->getvalue({field=>'245',record=>1,subfield=>'i1'});
my ($indi2) = $x->getvalue({field=>'245',record=>1,subfield=>'i2'});

is_ok($indi1 eq "1");						
is_ok($indi2 eq "4");						

my @m245 = $x->getvalue({field=>'245',record=>1,subfield=>'a',delimiter=>"\c_"});
my @m247 = $x->getvalue({field=>'245',record=>1,subfield=>'a',delimiter=>"\c_"});
my @m500 = $x->getvalue({field=>'245',record=>1,subfield=>'a',delimiter=>"\c_"});

$x->updatefirst({field=>'245',record=>1,subfield => 'a'}, ('245','a','b', a=>'foo'));    

($indi1) = $x->getvalue({field=>'245',record=>1,subfield=>'i1'});
($indi2) = $x->getvalue({field=>'245',record=>1,subfield=>'i2'});

is_ok($indi1 eq "1");						
is_ok($indi2 eq "4");						
my ($m245_a) = $x->getvalue({field=>'245',record=>1,subfield=>'a'});

$x->deletefirst({field=>'500',record=>1});    
$x->updatefirst({field=>'247',record=>1},
		 (999,1," ", a =>"Photo marchive"));        

$x->updatefirst({field=>'500',record=>1},
		 (999,1," ", a =>"First English Fed."));    

is_ok($m008 eq "741021s1884    enkaf         000 1 eng d");	



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

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

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
is_ok($u246[12] eq "Associated Press photo archive");		
is_ok($u246[13] eq "\036");					

is_ok($u246[14] eq "i1");					
is_ok($u246[15] eq "3");					
is_ok($u246[16] eq "i2");					
is_ok($u246[17] eq "0");					
is_ok($u246[18] eq "a");					

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

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
is_ok($records[7] eq "part 2");					
is_ok($records[8] eq "z");					
is_ok($records[9] eq "part 3");					
is_ok($records[10] eq "\036");					

@records = $x->getupdate({field=>'900',record=>2});
is_ok(7 == @records);						

is_ok($records[0] eq "i1");					
is_ok($records[1] eq "9");					

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

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
is_ok($records[9] eq "53525");					
is_ok($records[10] eq "\036");					

is_ok($MARC::VERSION == $MARC::Rec::VERSION);			

@records = $x->getupdate({field=>'999',record=>2});
is_ok(0 == @records);						

@records = $x->getupdate({field=>'001',record=>2});
is_ok(2 == @records);						
is_ok($records[0] eq "ocm40139019 ");				
is_ok($records[1] eq "\036");					
my $string_rec = $x->[1]->as_string();
my $tmp_rec=$x->[0]{proto_rec}->copy_struct();
$tmp_rec->from_string($string_rec);
1;# for debug

