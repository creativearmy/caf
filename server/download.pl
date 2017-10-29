
use CGI;
use Time::HiRes qw(gettimeofday);
use MIME::Base64;
use File::MimeInfo::Magic;

# remote server path 
$DOWNLOAD_ROOT = "/var/www/games/files";

# scheme id determines how to intepret the file id, version and algo etc.
my $SCHEME_ID = "001";

# do not use my !! causing problems!
$cgi = CGI->new();

my $fid = $cgi->param('fid');

# download from sub directory for each proj
my $proj = $cgi->param('proj');
$DOWNLOAD_ROOT = $DOWNLOAD_ROOT."/$proj" if $proj;

my $content = read_from_file("$DOWNLOAD_ROOT/$fid");
my $mime = mimetype("$DOWNLOAD_ROOT/$fid");

my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat("$DOWNLOAD_ROOT/$fid");
my $last = scalar(gmtime($mtime));
print "Last-Modified: $last\r\n";

my $length = -s "$DOWNLOAD_ROOT/$fid";
print "Content-Length: $length\r\n";
print "Content-Type: $mime\r\n\r\n";
print $content;

sub read_from_file {
	open FILE, $_[0];
	local $/;
	my $c = <FILE>;
	close FILE;
	return $c;
}
