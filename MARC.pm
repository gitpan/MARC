package MARC;

use Carp;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $DEBUG);
$VERSION = '0.91';
$DEBUG = 0;

require Exporter;
require 5.004;

@ISA = qw(Exporter);
@EXPORT= qw();
@EXPORT_OK= qw();

#### Not using these yet

#### %EXPORT_TAGS = (USTEXT	=> [qw( marc2ustext )]);
#### Exporter::export_ok_tags('USTEXT');
#### $EXPORT_TAGS{ALL} = \@EXPORT_OK;

# Preloaded methods go here.

####################################################################
# This is the constructor method that creates the MARC object. It  #
# will call the appropriate read using the file and format         #
# parameters that are passed.                                      #
####################################################################
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $file = shift;
    my $marc = []; 
    my $totalrecord;
    #store the default increment 
    $marc->[0]{'increment'}=-1; #store the default increment variable in the object
    #if file isn't defined then just return the empty MARC object
    if (not($file)) {return bless $marc, $class;}
    #if the file doesn't exist return an error
    if (not(-e $file)) {carp "File $file doesn't exit"; return}
    my $format = shift || "usmarc"; # $format defaults to USMARC if undefined
    if ($format =~ /usmarc$/io) {
	open(*file, $file);
	$marc->[0]{'handle'}=\*file;
	$marc->[0]{'format'}='usmarc';
	$totalrecord = _readmarc($marc);
	close *file;
    }
    elsif ($format =~ /unimarc$/io) {
	open(*file, $file);
	$marc->[0]{'handle'}=\*file;
	$marc->[0]{'format'}='unimarc';
	$totalrecord = _readmarc($marc);
	close *file;
    }
    elsif ($format =~ /marcmaker$/io) {
	open (*file, $file);
	$marc->[0]{'handle'}=\*file;
	$totalrecord = _readmarcmaker($marc);
	close *file;				  
    }
    else {
	carp "I don't recognize that format $!";
	return;
    }
    print "read in $totalrecord records\n" if $DEBUG;
    return bless $marc, $class;
}

###################################################################
# _readmarc() reads in a MARC file into the $marc object           #
###################################################################
sub _readmarc {
    my $marc = shift;
    my $handle = $marc->[0]{'handle'};
    my $increment = $marc->[0]{'increment'}; #pick out increment from the object
    my $recordcount = 0;
    binmode $handle;
    local $/ = "\035";	# cf. TPJ #14
    local $^W = 0;	# no warnings
    while (($increment==-1 || $recordcount<$increment) and my $line=<$handle>) {
	$line=~s/[\n\r\cZ]//og;
	last unless $line;
	my @d = ();
	my $record={};
	$record->{"array"}=[];
	$line=~/^(.{24})([^\036]*)\036(.*)/o;
	my $leader=$1; my $dir=$2; my $data=$3;
	push(@{$record->{array}[0]},("000",$leader));
	$record->{"000"}=\$leader;
	@d=$dir=~/(.{12})/go;
	for my $d(@d) {
	    my @field=();
	    my $tag=substr($d,0,3);
	    chop(my $field=substr($data,substr($d,7,5),substr($d,3,4)));
	    if ($tag<10) {
		@field=("$tag","$field");
	    }
	    else {
		my $indi1=substr($field,0,1);
		my $indi2=substr($field,1,1);
		push (@field, "$tag", "$indi1", "$indi2");
		my $field_data = substr($field,2);
		my @subfields = split(/\037/,$field_data);
		foreach (@subfields) {
		    my $delim = substr($_,0,1);
		    next unless $delim;
		    my $subfield_data = substr($_,1);
		    push(@field, "$delim", "$subfield_data");
		    push(@{$record->{$tag}{$delim}}, \$subfield_data);
		} #end parsing subfields
		push(@{$record->{$tag}{i1}{$indi1}},\@field);
		push(@{$record->{$tag}{i2}{$indi2}},\@field);
		push(@{$record->{$tag}{i12}{indi1}{indi2}},\@field);
	    } #end testing tag number
	    push(@{$record->{'array'}},\@field);
	    push(@{$record->{$tag}{field}},\@field);
	} #end processing this field
	push(@$marc,$record);
	$recordcount++;
    } #end processing this record
    return $recordcount;
} 

###################################################################
# readmarcmaker() reads a marcmaker file into the MARC object     #
###################################################################
sub _readmarcmaker {
    my $marc = shift;
    my $handle = $marc->[0]{'handle'};
    my $increment = $marc->[0]{'increment'}; #pick out increment from the object
    my $recordcount = 0;
      #Set the file input separator to null, which is the same as 
      #a blank line. A blank line separates individual MARC records
      #in the MARCMakr format.
    local $/ = "";	# cf. TPJ #14
    local $^W = 0;	# no warnings
      #Read in each individual MARCMAKER record in the file
    while (($increment==-1 or $recordcount<$increment) and my $record=<$handle>) {
	my $record_array={};
	  #Split each record on the "\n=" into the @fields array
	my @lines=split/\n=/,$record;
	  #Remove = from LDR
	$lines[0]=~s/^=//o;
	  #rename LDR to 000
	$lines[0]=~s/^LDR/000/;
	  #Remove newlines from @fields ; and also substitute " " for \
	for (my $i=0; $i<@lines; $i++) {	
	    $lines[$i]=~s/[\n\r]//og;
	    $lines[$i]=~s/\\/ /go;
	}
	foreach my $line (@lines) {
	    my @field=(); 
	      #get the tag name
	    my $tag = substr($line,0,3);
	      #if the tag is less than 010 (has no indicators or subfields)
	      #then push the data into @$field
	    if ($tag < 10) {
		push (@field, $tag); #push the tag name (ie. 245)
		push (@field, substr($line,5)); #push the tag value
	    }
	      #elseif the tag is greater than 010 (has indicators and 
	      #subfields then add the data to the $marc object
	    else {
		push(@field, $tag); #push the tag name (ie. 245)
		  #push indicator data
		push @field, substr($line,5,1),substr($line,6,1);
		my $field_data=substr($line,7);
		my @subfields=split /\$/, $field_data; #get the subfields
		foreach my $subfield (@subfields) {
		    my $delim=substr($subfield,0,1); #extract subfield delimiter
		    next unless $delim;
		    my $subfield_data=substr($subfield,1); #extract subfield value
		    push (@field, $delim, $subfield_data);
		} #end parsing subfields
	    } #end tag>10
	    push @{$record_array->{array}}, \@field;
	} #end reading this line
	push @$marc,$record_array; 
	$recordcount++;
    } #end reading this record
    return $recordcount;
}

####################################################################
# length() returns the amount of records in a particular           #
# MARC object                                                      #
####################################################################
sub length {
    my $marc=shift;
    return $#$marc;
}

####################################################################
# openmarc() is a method for reading in a MARC file. It takes      #
# several parameters: file (name of the marc file) ; format, ie.   #
# usmarc ; and increment which defines how many records to read in #
####################################################################
sub openmarc {
    my $marc=shift;
    my $params=shift;
    my $file=$params->{file};
    if (not(-e $file)) {carp "File \"$file\" doesn't exist"; return} 
    $marc->[0]{'format'}=$params->{'format'}; #store format in object
    my $totalrecord;
    $marc->[0]{'increment'}=$params->{'increment'} || 0;
        #store increment in the object, default is 0
    unless ($marc->[0]{'format'}) {$marc->[0]{'format'}="usmarc"}; #default to usmarc
    open (*file, $file);
    $marc->[0]{'handle'}=\*file; #store filehandle in object
    if ($marc->[0]{'format'} =~ /usmarc/oi) {
	$totalrecord = _readmarc($marc);
    }
    elsif ($marc->[0]{'format'} =~ /marcmaker/oi) {
	$totalrecord = _readmarcmaker($marc);
    }
    else {
	close *file;
	carp "Unrecognized format $marc->[0]{'format'}";
	return;
    }
    print "read in $totalrecord records\n" if $DEBUG;
    if ($totalrecord==0) {$totalrecord="0 but true"}
    return $totalrecord;    
}

####################################################################
# closemarc() will close a file-handle that was opened with        #
# openmarc()                                                       #
####################################################################
sub closemarc {
    my $marc = shift;
    $marc->[0]{'increment'}=0;
    if (not($marc->[0]{'handle'})) {carp "There isn't a MARC file to close"; return}
    my $ok = close $marc->[0]{'handle'};
    $marc->[0]{'handle'}=undef;
    return $ok;
}

####################################################################
# nextmarc() will read in more records from a file that has      #
# already been opened with openmarc(). the increment can be        #
# adjusted if necessary by passing a new value as a parameter. the # 
# new records will be APPENDED to the MARC object                  #
####################################################################
sub nextmarc {
    my $marc=shift;
    my $increment=shift;
    my $totalrecord;
    if (not($marc->[0]{'handle'})) {carp "There isn't a MARC file open"; return}
    if ($increment) {$marc->[0]{'increment'}=$increment}
    if ($marc->[0]{'format'} =~ /usmarc/oi) {
	$totalrecord = _readmarc($marc);
    }
    elsif ($marc->[0]{'format'} =~ /marcmaker/oi) {
	$totalrecord = _readmarcmaker($marc);
    }
    else {return}   
    return $totalrecord;
}

####################################################################
# deletemarc() will delete entire records, specific fields, as     #
# well as specific subfields depending on what parameters are      #
# passed to it                                                     #
####################################################################
sub deletemarc {
    my $marc=shift;
    my $params=shift;
    my @delrecords=$params->{record} || (1..$#$marc);
       #if records parameter not passed set to all records in MARC object
    my $field=$params->{field};
    my $subfield=$params->{subfield};
    my $occurence=$params->{occurence};
    my $deletecount=0;

    #delete entire records
    if (not($field) and not($subfield)) {
	#my @marc1=@$marc;
	my @newmarc;
	my $count=0;
	foreach my $record (@$marc) {
	    my $match=0;
	    foreach my $delelement (@delrecords) {
		if ($delelement==$count) {$match=1;last;}
	    }
	    if (not($match)) {push(@newmarc,$record)}
	    else {$deletecount++}
	    $count++;
	}
	@$marc=@newmarc;
	return $deletecount;
    }

    #delete fields
    elsif ($field and not($subfield)) {
	for (my $record=1; $record<=$#$marc; $record++) {
	    foreach my $delelement (@delrecords) {
		if ($delelement != $record) {next}
		if ($marc->[$record]{$field}) {
		    foreach my $fieldref1 (@{$marc->[$record]{$field}{field}}) {
			my $count=0;
			foreach my $fieldref2 (@{$marc->[$record]{array}}) {
			    if ($fieldref1 == $fieldref2) {
				$deletecount++;
				splice @{$marc->[$record]{array}},$count,1;
				delete %$marc->[$record]{$field};
			    }
			    $count++;
			}
		    }
		}
	    }
	}
	return $deletecount;
    }

    #delete subfields
    elsif ($subfield) {
	for (my $record=1; $record<=$#$marc; $record++) {
	    foreach my $delelement (@delrecords) {
		if ($delelement != $record) {next}
		if ($marc->[$record]{$field}{$subfield}) {
		    foreach my $subfieldref (@{$marc->[$record]{$field}{$subfield}}) {
			foreach my $fieldref2 (@{$marc->[$record]{array}}) {
			    my $count=0;
			    foreach my $subfield2 (@$fieldref2) {
				if ($$subfieldref eq $subfield2) {
				    $deletecount++;
				    splice @$fieldref2,$count-1,2;
				    delete %$marc->[$record]{$field}{$subfield};
				}
				$count++
			    }
			}
		    }
		}
	    }
	}
	return $deletecount;
    }
}

####################################################################
# selectmarc() performs the opposite function of deletemarc(). It  #
# will select specified elements of a MARC object and return them  #
# as a MARC object. So if you wanted to select records 1-10 and 15 #
# of a MARC object you could say $x=$x->selectmarc(["1-10","15"]); #
####################################################################
sub selectmarc {
    my $marc1=shift;
    my @marc1=@$marc1;
    my @marc2;
    my $selarray=shift;
    my $count=0;
    my $selcount=0;
    if (not($selarray)) {$selarray->[0]="1-$#marc1"} 
    foreach my $record (@marc1) {
	my $match=0;
	foreach my $selelement (@$selarray) {
	    if ($selelement=~/(\d+)-(\d+)/) {
		if ($count>=$1 and $count<=$2) {$match=1;last;}
	    }
	    elsif ($selelement==$count) {$match=1;last;}
	}
	if ($match or $count==0) {push(@marc2,$record); $selcount++}
	$count++;
    }
    @$marc1=@marc2;
    return $selcount-1; #minus off the $marc->[0] 
}

####################################################################
# searchmarc() is method for searching a MARC object for specific  #
# values. It will return an array which contains the record        #
# numbers that matched.                                            #
####################################################################
sub searchmarc {
    my $marc=shift;
    my $params=shift;
    my $field=$params->{field};
    my $subfield=$params->{subfield};
    my $regex=$params->{regex};
    my $notregex=$params->{notregex};
    my @results;
    my $searchtype;

       #determine the type of search 
    if ($field and not($subfield) and not($regex) and not($notregex)) {
	$searchtype="fieldpresence"}
    elsif ($field and $subfield and not($regex) and not($notregex)) {
	$searchtype="subfieldpresence"}
    elsif ($field and not($subfield) and $regex) {
	$searchtype="fieldvalue"}
    elsif ($field and $subfield and $regex) {
	$searchtype="subfieldvalue"}
    elsif ($field and not($subfield) and $notregex) {
	$searchtype="fieldnotvalue"}
    elsif ($field and $subfield and $notregex) {
	$searchtype="subfieldnotvalue"}

       #do the search by cycling through each record
    for (my $i=1; $i<=$#$marc; $i++) {

	my $flag=0;
	if ($searchtype eq "fieldpresence" and
	    $marc->[$i]{$field}) {push(@results,$i)}
	elsif ($searchtype eq "subfieldpresence" and 
	    $marc->[$i]{$field}{$subfield}) {push(@results,$i)}
	elsif ($searchtype eq "fieldvalue") {
	    my $x=$marc->[$i]{$field}{field};
	    foreach my $y (@$x) {
		my $z=_joinfield($y,$field);
		if (eval qq("$z" =~ $regex)) {$flag=1}
	    }
	    if ($flag) {push (@results,$i)}
	}
	elsif ($searchtype eq "subfieldvalue") {
	    my $x=$marc->[$i]{$field}{$subfield};
	    foreach my $y (@$x) {
		if (eval qq("$$y" =~ $regex)) {$flag=1}
	    }
	    if ($flag) {push (@results,$i)}
	}
	elsif ($searchtype eq "fieldnotvalue" ) {
	    my $x=$marc->[$i]{$field}{field};
	    if (not($x)) {push(@results,$i); next}
	    foreach my $y (@$x) {
		my $z=_joinfield($y,$field);
		if (eval qq("$z" =~ $notregex)) {my $flag=1}
	    }
	    if (not($flag)) {push (@results,$i)}
	}
	elsif ($searchtype eq "subfieldnotvalue") {
	    my $x=$marc->[$i]{$field}{$subfield};
	    if (not($x)) {push (@results,$i); next}
	    foreach my $y (@$x) {
		if (eval qq("$$y" =~ $notregex)) {$flag=1}
	    }
	    if (not($flag)) {push (@results,$i)}
	}
    }
    return @results;
}

####################################################################
# getvalue() will return the value of a field or subfield in a     #
# particular record found in the MARC object                       #
####################################################################
sub getvalue {
    my $marc = shift;
    my $params = shift;
    my $record = $params->{record};
    if (not($record)) {carp "You must specify a record $!"; return}
    my $field = $params->{field};
    if (not($field)) {carp "You must specify a field $!"; return}
    my $subfield = $params->{subfield};
    my $delim = $params->{delimiter};
    my @values;
    if ($field and not($subfield)) {
	foreach (my $i; $i<=$#{$marc->[$record]{$field}{field}}; $i++) {
	    push @values, _joinfield($marc->[$record]{$field}{field}[$i],$field,$delim);
	}
	return @values;
    }
    elsif ($field and $subfield) {
	foreach (my $i; $i<=$#{$marc->[$record]{$field}{$subfield}}; $i++) {
	    push @values, ${$marc->[$record]{$field}{$subfield}[$i]};
	}
	return @values;
    }
}

####################################################################
# _joinfield() is an internal subroutine for creating a string out #
# of an array of subfields. It takes an optional delimiter         #
# parameter which will print out subfields if defined              #
####################################################################
sub _joinfield {
    my $array=shift;
    my @array=@$array;
    my $tag=shift;
    my $delim=shift;
    my $result;
    if ($tag<10) {
	$result=$array[1];
    }
    elsif ($delim) {
	for (my $i=3; $i<=$#array; $i=$i+2) {
	    $result.=$delim.$array[$i].$array[$i+1];
	}
    }
    else {
	for (my $i=4; $i<=$#array; $i=$i+2) {
	    $result.=$array[$i];
	    if ($result!~/ $/) {$result.=" "}
	}
    }
    return $result;
}
    
####################################################################
# output() will call the appropriate output method using the marc  #
# object and desired format parameters.                            # 
####################################################################
sub output {
    my $marc=shift;
    my $args=shift;
    my $output = "";

    if ($args->{'format'} =~ /marc$/oi) {
	$output = _writemarc($marc,$args);
    }
    elsif ($args->{'format'} =~ /marcmaker$/oi) {
	$output = _marcmaker($marc,$args);
    }
    elsif ($args->{'format'} =~ /ascii$/oi) {
	$output = _marc2ascii($marc,$args);
    }
    elsif ($args->{'format'} =~ /html$/oi) {
        $output .= "<html><body>";
	$output .= _marc2html($marc,$args);
        $output .="</body></html>";
    }
    elsif ($args->{'format'} =~ /html_header$/oi) {
	$output = "<html><body>\n";
    }
    elsif ($args->{'format'} =~ /html_body$/oi) {
        $output =_marc2html($marc,$args);
    }
    elsif ($args->{'format'} =~ /html_footer$/oi) {
	$output = "\n</body></html>";
    }
    elsif ($args->{'format'} =~ /xml$/oi) {
        $output .="<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n\n<marc>\n\n";
	$output .= _marc2xml($marc,$args);
        $output .= "\n</marc>";
    }
    elsif ($args->{'format'} =~ /xml_header$/oi) {
        $output .="<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n\n<marc>\n\n";
    }
    elsif ($args->{'format'} =~ /xml_body$/oi) {
	$output=_marc2xml($marc,$args);
    }
    elsif ($args->{'format'} =~ /xml_footer$/oi) {
	$output="\n</marc>";
    }
    elsif ($args->{'format'} =~ /urls$/oi) {
        $output .= "<html>\n<head><title>URLS in ".$args->{file}."</title></head>\n<body>\n";
	$output .= _urls($marc,$args);
        $output .="</body></html>";
    }
    elsif ($args->{'format'} =~ /isbd$/oi) {
	$output = _isbd($marc,$args);
    }
    if ($args->{file}) {
	if ($args->{file} !~ /^>/) {carp "Don't forget to use > or >>: $!"}
	open (OUT, "$args->{file}") || carp "Couldn't open file: $!";
        binmode OUT if ($args->{'format'} =~ /marc$/oi);
	print OUT $output;
	close OUT || carp "Couldn't close file: $!";
	return 1;
    }
      #if no filename was specified return the output so it can be grabbed
    else {
	return $output;
    }
}

####################################################################
# _writemarc() takes a MARC object as its input and returns the    #
# the USMARC equivalent of the object as a string                  #
####################################################################
sub _writemarc {
    my $marc=shift;
    my $args=shift;
    my (@record, $directory, $fieldbase, 
	$fielddata, $fieldlength, $fieldposition, 
	$fieldstream, $leader, $marcrecord, 
	$position, $recordlength);

    #Read in each individual MARC record in the file
    my @records;
    if ($args->{records}) {@records=@{$args->{records}}}
    else {for (my $i=1;$i<=$#$marc;$i++) {push(@records,$i)}}
    foreach my $i (@records) {
	my $record = $marc->[$i];
	#Reset variables
        my $position=undef; my $directory=undef; my $fieldstream=undef; 
####        my $position=0; my $directory=undef; my $fieldstream=undef; 
	my $leader=$record->{array}[0][1];
	foreach my $field (@{$record->{array}}) {
	    my $tag = $field->[0];
	    if ($tag eq "000") {next}; #don't output the directory!
	    my $fielddata="";
	    if ($tag < 10) {
		$fielddata=$field->[1]; 
	    }
	    else {
		$fielddata.=$field->[1].$field->[2]; #add on indicators
		my @subfields=@{$field}[3..$#{$field}];
		while (@subfields) {
		    $fielddata.="\037".shift(@subfields); #shift off subfield delimiter
		    $fielddata.=shift(@subfields); #shift off subfield value
		}
	    }
	    $fielddata.="\036";
	    $fieldlength=_offset(CORE::length($fielddata),4);
	    $fieldposition=_offset($position,5);
	    $directory.=$tag.$fieldlength.$fieldposition;
	    $position+=$fieldlength;
	    $fieldstream.=$fielddata;
	}
	$directory.="\036";
	$fieldstream.="\035";
	$fieldbase=24+CORE::length($directory);
	$fieldbase=_offset($fieldbase,5);
	$recordlength=24+CORE::length($directory)+CORE::length($fieldstream);
	$recordlength=_offset($recordlength,5);
	$leader=~s/^.{5}(.{7}).{5}(.{7})/$recordlength$1$fieldbase$2/;
	$marcrecord.="$leader$directory$fieldstream";
    }
    return $marcrecord;
}
    
####################################################################
# _marc2ascii() takes a MARC object as its input and returns the   #
# ASCII equivalent of the object (field names, indicators, field   #
# values and line-breaks)                                          #
####################################################################
sub _marc2ascii {
    my $output;
    my $marc=shift;
    my $args=shift;
    my @records;
    if ($args->{records}) {@records=@{$args->{records}}}
    else {for (my $i=1;$i<=$#$marc;$i++) {push(@records,$i)}}
    for my $i (@records) { #cycle through each record
	my $record=$marc->[$i];
	foreach my $fields (@{$record->{array}}) { #cycle each field 
	    my $tag=$fields->[0];
	    if ($tag<10) {
		$output.="$fields->[0]  $fields->[1]";
	    }
	    else {
		$output.="$tag  $fields->[1]$fields->[2]  ";
		my @subfields = @{$fields}[3..$#{$fields}];		
		while (@subfields) { #cycle through subfields
		    $output .= "\$".shift(@subfields).shift(@subfields);
		} #finish cycling through subfields
	    } #finish tag test < 10
	    $output .= "\n"; #put a newline at the end of the field
	}
	$output.="\n"; #put an extra newline to separate records
    }
    return $output;
}

####################################################################
# _marcmaker() takes a MARC object as its input and converts it    #
# into MARCMaker format, which is returned as a string             #
####################################################################
sub _marcmaker {
    my $output;
    my $marc=shift;
    my $args=shift;
    my @records;
    if ($args->{records}) {@records=@{$args->{records}}}
    else {for (my $i=1;$i<=$#$marc;$i++) {push(@records,$i)}}
    local $^W = 0;	# no warnings
    for my $i (@records) { #cycle through each record
	my $record=$marc->[$i];
	foreach my $fields (@{$record->{array}}) { #cycle each field 
	    my $tag=$fields->[0];
	    if ($tag eq "000") {
		my $value=$fields->[1];
		$value=s/ /\\/go;
		$output.="=LDR  $fields->[1]";
	    }
	    elsif ($tag<10) {
		my $value=$fields->[1];
		$value=s/ /\\/go;
		$output.="=$fields->[0]  $fields->[1]";
	    }
	    else {
		my $indicator1=$fields->[1];
		$indicator1=~s/ /\\/;
		my $indicator2=$fields->[2];
		$indicator2=~s/ /\\/;
		$output.="=$tag  $indicator1$indicator2";
		my @subfields = @{$fields}[3..$#{$fields}];		
		while (@subfields) { #cycle through subfields
		    $output .= "\$".shift(@subfields).shift(@subfields);
		} #finish cycling through subfields
	    } #finish tag test < 10
	    $output .= "\n"; #put a newline at the end of the field
	}
	$output.="\n"; #put an extra newline to separate records
    }
    return $output;
}

####################################################################
# _marc2html takes a MARC object as its input and converts it into #
# HTML. It is possible to specify which field you want to output   #
# as well as field labels to be used instead of the MARC codes.    #
# The HTML is returned as a string                                 #
####################################################################
sub _marc2html {
    my $marc = shift;
    my $args = shift;
    my $output = "";
    my $outputall = 1;
    my @alltags = sort(keys(%$args));
    my @tags = ();
    foreach my $tag (@alltags) {
        push (@tags, $tag) if ($tag =~ /^[0-9]/);
    }
    $outputall = 0 if (scalar(@tags));
    if (defined $args->{fields}) {
        if ($args->{fields} =~ /all$/oi) {$outputall=1} ## still needed ?????
    }
    my @records;
    if ($args->{records}) {@records=@{$args->{records}}}
    else {for (my $i=1;$i<=$#$marc;$i++) {push(@records,$i)}}
      #if 'all' fields are specified then set $outputall flag to yes
    local $^W = 0;	# no warnings
    foreach my $i (@records) {
	my $j=$marc->[$i];
	$output.="\n<p>";
	if ($outputall) {
	    foreach my $k ($j->{array}) {
		foreach my $l (@$k) {
		    $output.=$l->[0]." "._joinfield($l,$l->[0])."<br>\n";
		}
	    }		
	}
	else {
	    foreach my $tag (@tags) {
		foreach my $field (@{$j->{$tag}{field}}) {
		    $output.=%$args->{$tag}." "._joinfield($field,$tag)."<br>\n";
		}
	    }
	}		
	$output.="</p>";
    }
    return $output;
}

####################################################################
# _marc2xml takes a MARC object as its input and converts it into  #
# XML. The XML is returned as a string                             #
####################################################################
sub _marc2xml {
    my $output;
    my $marc=shift;
    my $args=shift;
    my @records;
    if ($args->{records}) {@records=@{$args->{records}}}
    else {for (my $i=1;$i<=$#$marc;$i++) {push(@records,$i)}}
    foreach my $i (@records) {
	my $record=$marc->[$i]; #cycle through each record
	$output.="<record>\n";
	foreach my $fields (@{$record->{array}}) { #cycle through each field 
	    my $tag=$fields->[0];
	    if ($tag<10) { #no indicators or subfields
	          #replace & < > with their corresponding entities 
		my $value=$fields->[1];
		$value=~s/&/&amp;/og; $value=~s/</&lt;/og; $value=~s/>/&gt;/og;
		$output.=qq(<field type="$tag">$value</field>\n);
	    }
	    else { #indicators and subfields
		$output.=qq(<field type="$tag" i1="$fields->[1]" i2="$fields->[2]">\n);
		my @subfields = @{$fields}[3..$#{$fields}];		
		while (@subfields) { #cycle through subfields
		    my $subfield_type = shift(@subfields);
		    my $subfield_value = shift(@subfields);
		    $subfield_value=~s/&/&amp;/og;
		    $subfield_value=~s/</&lt;/og;
		    $subfield_value=~s/>/&gt;/og;
		    $output .= qq(   <subfield type="$subfield_type">);
		    $output .= qq($subfield_value</subfield>\n);
		} #finish cycling through subfields
		$output .= qq(</field>\n);
	    } #finish tag test < 10
	}
	$output.="</record>\n\n"; #put an extra newline to separate records
    }
    return $output;
}

####################################################################
# _urls() takes a MARC object as its input, and then extracts the  #
# control# (MARC 001) and URLs (MARC 856) and outputs them as      #
# hypertext links in an HTML page. This could then be used with a  #
# link checker to determine what URLs are broken.                  #
####################################################################
sub _urls {
    my $marc = shift;
    my $args = shift;
    my $output = "";
    my @records;
    if ($args->{records}) {@records=@{$args->{records}}}
    else {for (my $i=1;$i<=$#$marc;$i++) {push(@records,$i)}}
    local $^W = 0;	# no warnings
    foreach my $h (@records) {
	my $i=$marc->[$h];
	my $x=0;
	my $controlnum=undef;
	foreach my $j (@{$i->{array}}) {
	    if ($j->[0] eq "001") {
		$controlnum=$j->[1];
	    }
	    elsif ($j->[0] eq "856") {
		for (my $k=1; $k< $#$j; $k++) {
		    if ($j->[$k] eq "u") {
			$output.=qq(<a href="$j->[$k+1]">$controlnum : $j->[$k+1]</a><br>\n);
		    }
		}
	    }
	}
    }
    return $output;
}

####################################################################
# isbd() attempts to create a quasi ISBD output format             #
####################################################################
sub _isbd {
    my $flag;
    my $output;
    my $marc=shift;
    my $args=shift;
    my @records;
    if ($args->{records}) {@records=@{$args->{records}}}
    else {for (my $i=1;$i<=$#$marc;$i++) {push(@records,$i)}}
    for my $i (@records) { #cycle through each record
	my $record=$marc->[$i];
	$output .= _joinfield($record->{245}{field}[0],"245");
	if ($record->{250}{field}[0]) {
	    $output .= " -- "._joinfield($record->{250}{field}[0],"250");
	}
	if ($record->{260}{field}[0]) {
	    $output .= " -- "._joinfield($record->{260}{field}[0],"260");
	}
	if ($record->{300}{field}[0]) {
	    $output .= " -- "._joinfield($record->{300}{field}[0],"300");
	}
	if ($record->{440}{field}) {
	    $flag=1;
	    $output .= " -- ";
	    foreach my $field (@$record->{440}{field}) {
		$output .= "("._joinfield($field,"440").") ";
	    }
	}
	if ($record->{490}{field}) {
	    unless ($flag) {$output .= " -- "}
	    foreach my $field (@$record->{490}{field}) {
		$output .= "("._joinfield($field,"490").") ";
	    }
	}
	for (my $x=500; $x<600; $x++) {
	    if ($record->{$x}) {
		foreach my $field (@{$record->{$x}{field}}) {
		    $output .= "\n"._joinfield($field,$x);
		}
	    }
	}
	if ($record->{020}) {
	    $output .= "\n"._joinfield($record->{020}{field}[0]);
	}
	$flag = undef;
	$output .= "\n\n";		
    }
    return $output;
}

sub createrecord {
    my $marc=shift;
    my $params=shift;
    my $leader=$params->{leader};
    my $record={};
    my @field;
    my $length=$#$marc;
       #default leader see MARC documentation http://lcweb.loc.gov/marc
    if (not($leader)) {$leader="00000nam  2200000 a 4500"}
    push (@field,"000",$leader);
    push(@{$marc->[$length+1]{array}},\@field); #add tag and value
    $marc->[$length+1]{"000"}=$leader; #create map
    return $length+1;
}

sub addfield {
    my $marc=shift;
    my $params=shift;
    my $record=$params->{record};
    my $field=$params->{field};
    my $i1=$params->{i1} || " ";
    my $i2=$params->{i2} || " ";
    my $value=$params->{value};
    my $ordered=$params->{ordered} || "y";
    my $insertorder;
       #if necessary figure out the insert order to preserve tag order
    if ($ordered=~/y/i) {
	for (my $i=0; $i<=$#{$marc->[$record]{array}}; $i++) {
	    if ($marc->[$record]{array}[$i][0] > $field) {
		$insertorder=$i;
		last;
	    }
	    if ($insertorder==0) {$insertorder=1}
	}
    }
    my @field;
    if ($field<10) {
	push (@field, $field, $value->[0]);
	if ($ordered=~/y/i) {
	    splice @{$marc->[$record]{array}},$insertorder,0,\@field; 
	}
	else {
	    push (@{$marc->[$record]{array}},\@field);
	}
	push (@{$marc->[$record]{$field}{field}},\@field); 
    }
    else {
	push (@field, $field, $i1, $i2);
	my ($sub_id, $subfield);
	while ($sub_id = shift @$value) {
	    $subfield = shift @$value;
	    push (@field, $sub_id, $subfield);
	    push (@{$marc->[$record]{$field}{$sub_id}}, \$subfield);
	}
	if ($ordered=~/y/i) {
	    splice @{$marc->[$record]{array}},$insertorder,0,\@field;
	}
	else {
	    push (@{$marc->[$record]{array}},\@field);
	}
	push (@{$marc->[$record]{$field}{field}},\@field);
	push (@{$marc->[$record]{$field}{i1}{$i1}},\@field);
	push (@{$marc->[$record]{$field}{i2}{$i2}},\@field);
	push (@{$marc->[$record]{$field}{i12}{$i1.$i2}},\@field);
    }
}

####################################################################
# _offset is an internal subroutine used by writemarc to offset    #
# number ie. making "34" into "00034".                             #
#################################################################### 
sub _offset{
    my $value=shift;
    my $digits=shift;
    print "DEBUG: _offset value = $value, digits = $digits\n" if ($DEBUG);
    my $x=CORE::length($value);
    $x=$digits-$x;
    $x="0"x$x."$value";
}

1;  # so the require or use succeeds

__END__


####################################################################
#                  D O C U M E N T A T I O N                       #
####################################################################

=pod

=head1 NAME

MARC.pm - Perl extension to manipulate B<MA>chine B<R>eadable B<C>ataloging records.

=head1 SYNOPSIS

 use MARC 0.91;

 $x=MARC->new("mymarcfile.mrc");
 $x->output({file=>">my_text.txt",'format'=>"ascii"});
 $x->output({file=>">my_marcmaker.mkr",'format'=>"marcmaker"});
 $x->output({file=>">my_html.html",'format'=>"html"});
 $x->output({file=>">my_xml.xml",'format'=>"xml"});
 $x->output({file=>">my_urls.html",'format'=>"urls"});
 print $x->length();

=head1 DESCRIPTION

MARC.pm is a Perl 5 module for reading in, manipulating, and outputting bibliographic records in the I<USMARC> format. You will need to have Perl 5.004 or greater for MARC.pm to work properly. Since it is a Perl module you use MARC.pm from one of your own Perl scripts. To see what sorts of conversions are possible you can try out a web interface to MARC.pm which will allow you to upload MARC files and retrieve the results (for details see the section below entitled "Web Interface"). 

However, to get the full functionality you will probably want to install MARC.pm on your server or PC. MARC.pm can handle both single and batches of MARC  records. The limit on the amount of records in a batch is determined by the memory capacity of the machine you are running. If memory is an issue for you MARC.pm will allow you to read in records from a batch gradually. MARC.pm also includes a variety of tools for searching, removing, and even creating records from scratch.

=head2 Types of Conversions:

=over 4

=item *

MARC -> ASCII : separates the MARC fields out into separate lines

=item *

MARC <-> MARCMaker : The MARCMaker format is a format that was developed by the
I<Library of Congress> for use with their DOS based I<MARCMaker> and
I<MARCBreaker> utilities. This format is particularly useful for making 
global changes (ie. with a text editor's search and replace) and then converting back to MARC (MARC.pm will read properly formatted MARCMaker records). For more information about the MARCMaker format see http://lcweb.loc.gov/marc/marcsoft.html

=item *

MARC -> HTML : The MARC to HTML conversion creates an HTML file
from the fields and field labels that you supply. You could possibly use
this to create HTML bibliographies from a batch of MARC records. 

=item *

MARC -> XML : The MARC to XML conversion creates an XML document that does not have a 
I<Document Type Definition>. Fortunately, since XML does not require a DTD this is OK.

=item *

MARC -> URLS : This conversion will extract URLs from a batch of MARC records. The URLs are found in the 856 field, subfield u. The HTML page that is generated can then be used with link-checking software to determine which URLs need to be repaired. Hopefully library system vendors will soon support this activity soon and make this conversion unecessary!

=back

=head2 Downloading and Installing

=over 4

=item Download

The module is provided in standard CPAN distribution format. It will
extract into a directory MARC-version with any necessary subdirectories.
Change into the MARC top directory. Download the latest version from 
http://www.cpan.org/modules/by-module/MARC/

=item Unix

    perl Makefile.PL
    make
    make test
    make install

=item Win9x/WinNT/Win2000

    perl Makefile.PL
    perl test.pl
    perl install.pl

=item Test

Once you have installed, you can check if Perl can find it. Change to some
other directory and execute from the command line:

    perl -e "use MARC"

If you do not get any response that means everything is OK! If you get an
error like I<Can't locate method "use" via package MARC>.
then Perl is not able to find MARC.pm--double check that the file copied
it into the right place during the install.

=back

=head2 Todo

=over 4

=item *

Support for other MARC formats.

=item *

Create a map and instructions for using and extending the MARC.pm data
structure.

=item *

Develop better error catching mechanisms.

=item *

Support for character conversions from MARC to Unicode ??

=item *

Managing MARC records that exceed 99999 characters in length (not
uncommon for MARC AMC records)

=item *

MARC <-> DC/RDF conversion ??

=back

=head2 Web Interface

A web interface to MARC.pm is available at
http://libstaff.lib.odu.edu/cgi-bin/marc.cgi where you can upload records and
observe the results. If you'd like to check out the cgi script take a look at
http://libstaff.lib.odu.edu/depts/systems/iii/scripts/MARCpm/marc-cgi.txt However, to get the full functionality you will want to install MARC.pm on your server or PC.

=head2 Notes

Please let us know if you run into any difficulties using MARC.pm--we'd be
happy to try to help. Also, please contact us if you notice any bugs, or
if you would like to suggest an improvement/enhancement. Email addresses 
are listed at the bottom of this page.

=head1 METHODS

Here is a list of the methods in MARC.pm that are available to you for reading in, manipulating and outputting MARC data.

=head2 new()

Creates a new MARC object. 

    $x = new MARC;

You can also use the optional I<file> and I<format> parameters to create and populate the object with data from a file. If a file is specified it will read in the entire file. If you wish to read in only portions of the file see openmarc(), nextmarc(), and closemarc() below.

    $x = MARC->new("mymarc.dat","usmarc");
    $x = MARC->new("mymarcmaker.mkr","marcmaker");

=head2 openmarc()

Opens a specified file for reading data into a MARC object. If no format is specified openmarc() will default to USMARC. The I<increment> parameter defines how many records you would like to read from the file. If no I<increment> is defined then the file will just be opened, and no records will be read in. If I<increment> is set to -1 then the entire file will be read in.

    $x = new MARC;
    $x->openmarc({file=>"mymarc.dat",'format'=>"usmarc",increment=>"1"});
    $x->openmarc({file=>"mymarcmaker.mkr",'format'=>"marcmaker",increment=>"5"});

note: openmarc() will return the number of records read in. If the file opens
successfully, but no records are read, it returns C<"0 but true">. For example:

    $y=$x->openmarc({file=>"mymarc.dat",'format'=>"usmarc",increment=>"5"});
    print "Read in $y records!";

=head2 nextmarc()

Once a file is open nextmarc() can be used to read in the next group of records. The increment can be passed to change the amount of records read in if necessary. An icrement of -1 will read in the rest of the file.

    $x->nextmarc();
    $x->nextmarc(10);
    $x->nextmarc(-1);

note: Similar to openmarc(), nextmarc() will return the amount of records read in. 

    $y=$x->nextmarc();
    print "$y more records read in!";

=head2 closemarc()

If you are finished reading in records from a file you should close it immediately.

    $x->closemarc();

=head2 length()

Returns the total amount of records in a MARC object.

    $length=$x->length();

=head2 getvalue()

This method will retrieve MARC field data from a specific record in the MARC object. getvalue() takes four paramters: I<record>, I<field>, I<subfield>, and I<delimiter>. Since a single MARC record could contain several of the fields or subfields the results are returned to you as an array. If you only pass I<record> and I<field> you will be returned the entire field without subfield delimters. Optionally you can use I<delimiter> to specify what character to use for the delimeter, and you will also get the subfield delimiters. If you also specify I<subfield> your results will be limited to just the contents of that subfield.

        #get the 650 field(s)
    @results = $x->getvalue({record=>'1',field=>'650'}); 
	#get the 650 field(s) with subfield delimiters (ie. |x |v etc)
    @results = $x->getvalue({record=>'1',field=>'650',delimiter=>'|'});
        #get all of the subfield u's from the 856 field
    @results = $x->getvalue({record=>'12',field=>'856',subfield=>'u'});
		

=head2 deletemarc()

This method will allow you to remove a specific record, fields or subfields from a MARC object. Accepted parameters include: I<record>, I<field> and I<subfield>. Note: you can use the .. operator to delete a range of records. deletemarc() will return the amount of items deleted (be they records, fields or subfields). The I<record> parameter is optional. 

        #delete all the records in the object
    $x->deletemarc();
        #delete records 1-5 and 7 
    $x->deletemarc({record=>[1..5,7]});
        #delete all of the 650 fields from all of the records
    $x->deletemarc({field=>'650'});
        #delete the 110 field in record 2
    $x->deletemarc({record=>'2',field=>'110'});
        #delete all of the subfield h's in the 245 fields
    $x->deletemarc({field=>'245',subfield=>'h'});

=head2 selectmarc()

This method will select specific records from a MARC object and delete the rest. You can specify both individual records and ranges of records in the same way as deletemarc(). selectmarc() will also return the amount of records deleted. 

    $x->selectmarc(['3']);
    $y=$x->selectmarc(['4','21-50','60']);
    print "$y records selected!";

=head2 searchmarc()

This method will allow you to search through a MARC object, and retrieve record numbers for records that matched your criteria. You can search for: 1) records that contain a particular field, or field and subfield ; 2) records that have fields or subfields that match a regular expression ; 3) and records that have fields or subfields that B<do not> match a regular expression. The record numbers are returned to you in an array which you can then use with deletemarc(), selectmarc() and output() if you want.

=over 4

=item *

1) Field/Subfield Presence:

    @records=$x->searchmarc({field=>"245"});
    @records=$x->searchmarc({field=>"245",subfield=>"a"});

=item *

2) Field/Subfield Match:

    @records=$x->searchmarc({field=>"245",regex=>"/huckleberry/i"});
    @records=$x->searchmarc({field=>"260",subfield=>"c",regex=>"/19../"});

=item *

3) Field/Subfield NotMatch:

    @records=$x->searchmarc({field=>"245",notregex=>"/huckleberry/i"});
    @records=$x->searchmarc({field=>"260",subfield=>"c",notregex=>"/19../"});

=back

=head2 createrecord()

You can use this method to initialize a new record. It only takes one optional parameter, I<leader> which sets the 24 characters in the record leader: see http://lcweb.loc.gov/marc/bibliographic/ecbdhome.html for more details on the leader. Note: you do not need to pass character positions 00-04 or 12-16 since these are calculated by MARC.pm if outputting to MARC you can assign 0 to each position. If no leader is passed a default USMARC leader will be created of "00000nam  2200000 a 4500". createrecord() will return the record number for the record that was created, which you will need to use later when adding fields with addfield().

    use MARC;
    my $x = new MARC;
    $record_number = $x->createrecord();
    $record_number = $x->createrecord({leader=>"00000nmm  2200000 a 4500"});

=head2 addfield()

This method will allow you to addfields to a specified record. The syntax may look confusing at first, but once you understand it you will be able to add fields to records that you have read in, or to records that you have created with createrecord(). addfield() takes six parameters: I<record> which indicates the record number to add the field to, I<field> which indicates the field you wish to create (ie. 245), I<i1> which holds one character for the first indicator, I<i2> which holds one character for the second indicator, and I<value> which holds the subfield data that you wish to add to the field. addfield() will automatically try to insert your new field in tag order (ie. a 500 field before a 520 field), however you can turn this off if you set I<ordered> to "no" which will add the field to the end. Here are some examples:

    $y = $x->createrecord(); # $y will store the record number created

    $x->addfield({record=>"$y", field=>"100", i1=>"1", i2=>"0",value=>
                 [a=>"Twain, Mark, ",
                  d=>"1835-1910."]});

    $x->addfield({record=>"$y", field=>"245", i1=>"1", i2=>"4", value=>
                 [a=>"The adventures of Huckleberry Finn /",
                  c=>"Mark Twain ; illustrated by E.W. Kemble."]});

This example intitalized a new record, and added a 100 field and a 245 field. For some more creative uses of the addfield() function take a look at the I<EXAMPLES> section.

=head2 output()

Output is a multifunctional method for creating formatted output from a MARC object. There are three parameters I<file>, I<format>, I<records>. If I<file> is specified the output will be directed to that file. B<It is important to specify with > and >> whether you want to create or append the file!> If no I<file> is specified then the results of the output will be returned to a variable (both variations are listed below). 

Valid I<format> values currently include usmarc, marcmaker, ascii, html, xml, urls, and isbd. The optional I<records> parameter allows you to pass an array of record numbers which you wish to output. You must pass the array as a reference, hence the forward-slash in \@records below. If you do not include I<records> the output will default to all the records in the object. 

=over 4

=item *

MARC

    $x->output({file=>">mymarc.dat",'format'=>"usmarc"});
    $x->output({file=>">mymarc.dat",'format'=>"usmarc",records=>\@records});
    $y=$x->output({'format'=>"usmarc"}); #put the output into $y

=item *

MARCMaker

    $x->output({file=>">mymarcmaker.mkr",'format'=>"marcmaker"});
    $x->output({file=>">mymarcmaker.mkr",'format'=>"marcmaker",records=>\@records});
    $y=$x->output({'format'=>"marcmaker"}); #put the output into $y

=item *

ASCII

    $x->output({file=>">myascii.txt",'format'=>"ascii"});
    $x->output({file=>">myascii.txt",'format'=>"ascii",records=>\@records});
    $y=$x->output({'format'=>"ascii"}); #put the output into $y

=item *

HTML

The HTML output method has some additional parameters. I<fields> which if set to "all" will output all of the fields. Or you can pass the tag number and a label that you want to use for that tag. This will result in HTML output that only contains the specified tags, and will use the label in place of the MARC code.

    $x->output({file=>">myhtml.html",'format'=>"html",fields=>"all"});
        #this will only output the 100 and 245 fields, with the 
	#labels "Title: " and "Author: "
    $x->output({file=>">myhtml.html",'format'=>"html",
                245=>"Title: ",100=>"Author: "});    
    $y=$x->output({'format'=>"html"});

If you want to build the HTML file in stages, there are three other I<format> values available to you: 1) "html_header", 2) "html_body", and 3) "html_footer". Be careful to use the >> append when adding to a file though!

    $x->output({file=>">myhtml.html",'format'=>"html_header"}); 
    $x->output({file=>">>myhtml.html",'format'=>"html_body",fields=>"all"});
    $x->output({file=>">>myhtml.html",'format'=>"html_footer"});

=item *

XML

    $x->output({file=>">myxml.xml",'format'=>"xml"});
    $y=$x->output({'format'=>"xml"});

Similar to the HTML output, the XML output has three different formats for creating the XML file in stages. Again, be careful to use the >> append where necessary.

    $x->output({file=>">myxml.xml",'format'=>"xml_header"});
    $x->output({file=>">>myxml.xml",'format'=>"xml_body"});
    $x->output({file=>">>myxml.xml",'format'=>"xml_footer"});

=item *

URLS

    $x->output({file=>"urls.html",'format'=>"urls"});
    $y=$x->output({'format'=>"urls"});

=item *

ISBD

An experimental output format that attempts to mimic the ISBD.

    $x->output({file=>"isbd.txt",'format'=>"isbd"});
    $y=$x->output({'format'=>"isbd"});

=back

=head1 EXAMPLES

Here are a few examples to fire your imagination.

=over 4

=item * 

This example will read in the complete contents of a MARC file called "mymarc.dat" and then output it as XML to a file called "myxml.xml".

    #!/usr/bin/perl
    use MARC;
    $x = MARC->new("mymarc.dat","usmarc");
    $x->output({file=>"myxml.xml",'format'=>"xml");

=item *

The MARC object occupies a fair amount of working memory, and you may want to do conversions on very large files. In this case you will want to use the openmarc(), nextmarc(), deletemarc(), and closemarc() methods to read in portions of the MARC file, do something with the record(s), remove them from the object, and then read in the next record(s). This example will read in one record at a time from a MARC file called "mymarc.dat" and convert it to XML. Note the use of formats "xml_header", "xml_body", and "xml_footer".

    #!/usr/bin/perl
    use MARC;
    $x = new MARC;
    $x->openmarc({file=>"mymarc.dat",'format'=>"usmarc"});
    $x->output({file=>">myxml.xml",'format'=>"xml_header"});
    while ($x->nextmarc(1)) {
	$x->output({file=>">>myxml.xml",'format'=>"xml_body"});
	$x->deletemarc(); #empty the object for reading in another
    }        
    $x->output({file=>"myxml.xml",'format'=>"xml_footer"});

=item *

Perhaps you have a tab delimited text file of data for online journals you have access to from Dow Jones Interactive, and you would like to create a batch of MARC records to load into your catalog. In this case you can use createrecord(), addfield() and output() to create records as you read in your delimited file. When you are done, you then output to a file in USMARC.

    #!/usr/bin/perl
    use MARC;
    $x = new MARC;
    open (INPUT_FILE, "delimited_file");
    while ($line=<INPUT_FILE>) {
        ($journaltitle,$issn) = split /\t/,$line;
        $num=$x->createrecord();
        $x->addfield({record=>$num, 
                      field=>"022", 
                      i1=>" ", i2=>" ", 
                      value=>$issn});
        $x->addfield({record=>$num, 
                      field=>"245", 
                      i1=>"0", i2=>" ", 
                      value=>[a=>$journaltitle]});
        $x->addfield({record=>$num, 
                      field=>"260", 
                      i1=>" ", i2=>" ", 
                      value=>[a=>"New York (N.Y.) :",b=>"Dow Jones & Company"]});
	$x->addfield({record=>$num,
		      field=>"710",
		      i1=>"2", i2=>" ",
		      value=>[a=>"Dow Jones Interactive."]});
	$x->addfield({record=>$num,
		      field=>"856",
		      i1=>"4", i2=>" ",
		      value=>[u=>"http://www.djnr.com",z=>"Connect"]});
    }
    close INPUT_FILE;
    $x->output({file=>">dowjones.mrc",'format'=>"usmarc"})

=back

=head1 AUTHORS

Chuck Bearden cbearden@rice.edu

Bill Birthisel wcbirthisel@alum.mit.edu

Charles McFadden chuck@vims.edu

Ed Summers esummers@odu.edu

=head1 SEE ALSO

perl(1), MARC http://lcweb.loc.gov/marc , XML http://www.w3.org/xml .

=head1 COPYRIGHT

Copyright (C) 1999, Bearden, Birthisel, McFadden, Summers. All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 19 October 1999.

=cut

