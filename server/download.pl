
use CGI;
use Time::HiRes qw(gettimeofday);
use MIME::Base64;
use File::MimeInfo::Magic;

# remote server path 
$DOWNLOAD_ROOT = "/var/www/games/files";

# fallback image
$DEFAULT_IMAGE = "f14686539620564930448001";

# scheme id determines how to intepret the file id, version and algo etc.
my $SCHEME_ID = "001";

# do not use my !! causing problems!
$cgi = CGI->new();

my $fid = $cgi->param('fid');
$fid = $DEFAULT_IMAGE unless $fid;

# download from sub directory for each proj
my $proj = $cgi->param('proj');
$DOWNLOAD_ROOT = $DOWNLOAD_ROOT."/$proj" if $proj;

$fid = $DEFAULT_IMAGE unless -s "$DOWNLOAD_ROOT/$fid";
my $content = read_from_file("$DOWNLOAD_ROOT/$fid");
my $mime = mimetype("$DOWNLOAD_ROOT/$fid");

my $length = -s "$DOWNLOAD_ROOT/$fid";

# not Range!
my $range = $ENV{'HTTP_RANGE'};

if ($range =~ /^bytes=(\d+)-(\d+)$/) {
    $content = substr($content, $1, $2-$1+1);
    if ($1 != 0 || $2 != ($length-1)) {
        print "Status: 206 Partial Content\r\n";
    }
    print "Content-Range: bytes $1-$2/$length\r\n";
    print "Content-Length: ".length($content)."\r\n";
    
} elsif ($range =~ /^bytes=(\d+)-$/) {
    $content = substr($content, $1);
    my $to = $length-1;
    if ($1 != 0) {
        print "Status: 206 Partial Content\r\n";
    }
    print "Content-Range: bytes $1-$to/$length\r\n";
    print "Content-Length: ".length($content)."\r\n";
    
} else {
    print "Content-Length: $length\r\n";
}

my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat("$DOWNLOAD_ROOT/$fid");
my $last = scalar(gmtime($mtime));
print "Last-Modified: $last\r\n";

print "Accept-Ranges: bytes\r\n";
print "Content-Type: $mime\r\n\r\n";



print $content;

sub read_from_file {
	open FILE, $_[0];
	local $/;
	my $c = <FILE>;
	close FILE;
	return $c;
}

sub print_to_file {
    
    # TO DEBUG, print_to_file("/tmp/download.log", $x);

   	open FILE, ">>$_[0]";
    print FILE $_[1];
    close FILE;
}
