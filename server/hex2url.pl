use CGI;
use Time::HiRes qw(gettimeofday);
use MIME::Base64;
use File::MimeInfo::Magic;
use JSON;
use URI::Escape;
# do not use my !! causing problems!
$cgi = CGI->new();


# work with APIConnection.min.js apiconn.url2hex to redirect hex encoded url back to normal
# url. apiconn.url2hex return address that looks like: http://abc.com/__hexstring
# 
# add nginx conf directive under server {
#
# rewrite ^/__(.*)$ /cgi-bin/hex2url.pl?hex=$1 last;

my $hex = $cgi->param("hex");
my @c = split //, $hex;
my $str = "";
shift @c if $c[0] eq "_";
shift @c if $c[0] eq "_";
while(1) {
	last unless scalar(@c);
	my $c1 = shift @c;
	my $c2 = shift @c;
	$str = $str . chr(hex("$c1$c2"));
}
print $cgi->redirect("http://abc.com/$str");
