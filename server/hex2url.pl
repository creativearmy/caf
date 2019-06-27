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

my $extra_query = "";
# there shall be no more than two ? in the string
if (index($ENV{"QUERY_STRING"}, "?")>=0) {
	$extra_query = substr($ENV{"QUERY_STRING"}, index($ENV{"QUERY_STRING"}, "?")+1);
}

my $hex = $cgi->param("hex");
my @c = split //, $hex;
my $decoded_str = "";
shift @c if $c[0] eq "_";
shift @c if $c[0] eq "_";
while(1) {
	last unless scalar(@c);
	my $c1 = shift @c;
	my $c2 = shift @c;
	$decoded_str = $decoded_str . chr(hex("$c1$c2"));
}

# split off the client_side # part to be merged later
my ($main_str, $client_side) = split /#/, $decoded_str;

my $other_param = "";
foreach my $p ($cgi->param()) {
	next if $p eq "hex";
	if (!$other_param) {
		$other_param = $p."=".$cgi->param($p);
	} else {
		$other_param = $other_param."&".$p."=".$cgi->param($p);
	}
}

# before merging, print to the log
open FILE, ">/tmp/hex2url.log";
print FILE "QUERY_STRING: ".$ENV{"QUERY_STRING"}."\n";
print FILE "decoded_str: ".$decoded_str."\n";
print FILE "other_param: ".$other_param."\n";
close FILE;

# merge params
if ($extra_query) {
	if ($other_param) {
		$extra_query = $other_param."&".$extra_query;
	}
} else {
	$extra_query = $other_param;
}

# merge to the main str
if ($extra_query) {
	if (index($main_str, "?") >= 0) {
		$main_str = $main_str . "&".$extra_query;
	} else {
		$main_str = $main_str . "?".$extra_query;
	}
}

# finally, merge the client side to the main str, normally it goes to the end
# for some webframework, fragment marker # needs to go before query string
if ($client_side) {
	# RFC compliant
	if (1) {
		$main_str = $main_str . "#" .$client_side;
	} else {
		my ($m1,  $m2) = split /\?/, $main_str;
		$main_str = $m1 . "#" .$client_side;
		$main_str = $main_str . "?" .$m2 if $m2;
	}
}

print $cgi->redirect(-uri => "http://abc.com/$main_str", -status=>303);
