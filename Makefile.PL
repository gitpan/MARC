use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

require 5.004;
use vars qw($version);
$version = '0.81';

my $INST_LIBDIR = "./lib";
my $INST_FILES = "MARC.pm";
my $INST_NAME = "MARC";
    # probably should auto-generate @testfiles
my @testfiles = qw( output.txt output.html output.xml output.urls output2.html
		    t/output.txt t/output.html t/output.xml t/output.urls
		    t/output2.html output.isbd t/output.isbd
		  );

unless ($^O eq "MSWin32") {
    WriteMakefile(
        'NAME'	=> 'MARC',
        'VERSION_FROM' => 'MARC.pm', # finds $VERSION
        'SKIP'	=> [qw(tool_autosplit)],
        'clean'	=> {FILES => "t/output*.* output*.*"},
    );
    exit;
}

# On Windows, create substitute scripts for the "make deprived"

use File::Copy;
use File::Path;

print <<INTRO3;
                           MARC version $version

                      No 'Makefile' will be created
                      Test with:    perl test.pl
                      Install with: perl install.pl

INTRO3

my $dfile = "test.pl";
unlink $dfile, @testfiles;
print "Creating new $dfile\n";
open (DEFAULT, "> $dfile") or die "Can't create $dfile: $!\n";

print DEFAULT <<TEST4;
# Created by Makefile.PL
# $INST_NAME Version $version

use Test::Harness;
runtests ("t/test1.t");

print "\\nTo run individual tests, type:\\n";
print "    C:\\> perl t/test1.t Page_Pause_Time (0..5)\\n";
print "See README and other documentation for additional information.\\n\\n";
TEST4

close DEFAULT;

unless (-d $INST_LIBDIR) {
    File::Path::mkpath([ "$INST_LIBDIR" ],1,0777) or
        die "ERROR creating directories: ($!)\n";
}
File::Copy::copy($INST_FILES,$INST_LIBDIR) or
    die "ERROR copying files: ($!)\n";

$dfile = "install.pl";
unlink $dfile;
print "Creating new $dfile\n";
open (DEFAULT, "> $dfile") or die "Can't create $dfile: $!\n";

print DEFAULT <<INST5;
# Created by Makefile.PL
# $INST_NAME Version $version

use Config qw(\%Config);
use strict;
use ExtUtils::Install qw( install );

my \$FULLEXT = "$INST_NAME";
my \$INST_LIB = "$INST_LIBDIR";

install({
	   read => "\$Config{sitearchexp}/auto/\$FULLEXT/.packlist",
	   write => "\$Config{installsitearch}/auto/\$FULLEXT/.packlist",
	   \$INST_LIB => "\$Config{installsitelib}",
	  },1,0);

__END__
INST5

close DEFAULT;
