use CGI;
use Time::HiRes qw(gettimeofday usleep);
use MIME::Base64;

# files uploaded into this directory
$UPLOAD_ROOT = "/var/www/games/files";

# do not use my !! causing problems!
$cgi = CGI->new();
if ( my $error = $cgi->cgi_error ) {
    print $cgi->header( -status => $error );
    print "Error: $error";
    exit 0;
}

my $local_file = $cgi->param('local_file');
my $data_url = $cgi->param('data_url');
my $sizes = $cgi->param('sizes');

# place it under sub directory for each proj
my $proj = $cgi->param('proj');
$UPLOAD_ROOT = $UPLOAD_ROOT."/$proj" if $proj;
system("mkdir -p $UPLOAD_ROOT >/dev/null 2>&1") unless -d $UPLOAD_ROOT;

my $FILE_ID = obj_id();
my $THUMB = obj_id();

my $flag = 0;

if (!open(LOCAL, ">$UPLOAD_ROOT/$FILE_ID")) {
    print $cgi->header( -status => "500 Internal Server Error" );
    print "Error: No write permission of dir, $UPLOAD_ROOT";
    exit 0;
}

if ($data_url) {
	if ($data_url =~ s/^data:image\/png;base64,//) {
		$flag = 1;
		print LOCAL decode_base64($data_url);
	}
} else {
	while(<$local_file>) {
		print LOCAL $_;
		$flag = 1;
	}
}
close LOCAL;

my $type = "nd";

$RESIZE_UPLOAD_IMAGE_WIDTH_TO = 1280;
$RESIZE_UPLOAD_IMAGE_THUMB_WIDTH_TO = 300;

if (-s "$UPLOAD_ROOT/$FILE_ID") {

	$type = `file $UPLOAD_ROOT/$FILE_ID`;
	
	$type = "pdf" if $type =~ /PDF/;
	$type = "jpg" if $type =~ /JPEG/;
	$type = "png" if $type =~ /PNG/;
	
	$type = "nd" unless $type =~ /(pdf|png|jpg)/;
	
	# madatory resizing
	if ($type eq "jpg" || $type eq "png") {
	
		my $size = `identify $UPLOAD_ROOT/$FILE_ID`;
		
		if ($size =~ / (\d+)x(\d+) /) {
		
			# larger than what is necessary?
			system("mogrify -resize $RESIZE_UPLOAD_IMAGE_WIDTH_TO $UPLOAD_ROOT/$FILE_ID")
				if $1 > $RESIZE_UPLOAD_IMAGE_WIDTH_TO;
			
			# thumb 300x
			system("convert -resize $RESIZE_UPLOAD_IMAGE_THUMB_WIDTH_TO $UPLOAD_ROOT/$FILE_ID $UPLOAD_ROOT/$THUMB")
				if $1 > $RESIZE_UPLOAD_IMAGE_THUMB_WIDTH_TO;
			
			# pic is smaller than thumb? do nothing, make a copy	
			system("cp $UPLOAD_ROOT/$FILE_ID $UPLOAD_ROOT/$THUMB")
				if $1 <= $RESIZE_UPLOAD_IMAGE_THUMB_WIDTH_TO;
		}
	}
}

# standard json output, filename is local file name where it is uploaded
my $output = '{"fid":"'.$FILE_ID.'","thumb":"'.$THUMB.'","type":"'.$type.'","filename":"'.$local_file.'"}';

if (!$flag || !(-s "$UPLOAD_ROOT/$FILE_ID")) {
	system("rm $UPLOAD_ROOT/$FILE_ID 2>/dev/null");
	$output = '{"fid":"","thumb":"","filename":"'.$local_file.'"}';
}

=h multiple resultions
if (-s "$UPLOAD_ROOT/$FILE_ID") {
	if ($sizes) {
		my @sizes = split /,/, $sizes;
		foreach my $s (@sizes) {
			my $fid = obj_id();
			$output .= " ".$fid;
			system("convert -resize $s $UPLOAD_ROOT/$FILE_ID jpg:$UPLOAD_ROOT/$fid &");
		}
	}
}
=cut

print "Access-Control-Allow-Origin: *\r\n";
print "Content-Type: application/json\r\n";
print "Content-Length: ".length($output)."\r\n\r\n";
print $output;

######################################################################################################################################################################
$LAST_OBJ_ID = 0;

sub obj_id {
	# scheme id determines how to intepret the file id, version and algo etc.
	my $SCHEME_ID = "001";

	# id itself is a timestamp and can be used for comparison, client use fids2urls
	# to globally replace 10103 formated fids to urls
	my $tod = scalar(gettimeofday());
	
	while(1) {
		my $file_id = "f".int($tod).sprintf("%010d",int(10000000000*($tod-int($tod)))).$SCHEME_ID;
		if ($file_id eq $LAST_OBJ_ID) {
			usleep(10);
			$tod = scalar(gettimeofday());
			next;
		}
		$LAST_OBJ_ID = $file_id;
		return $file_id;
	}
}
