use CGI;
use Time::HiRes qw(gettimeofday usleep);
use MIME::Base64;

# do not use my !! causing problems!
$cgi = CGI->new();

my $value1 = $cgi->param('key1');
my $value2 = $cgi->param('key2');

# gateway from HTTP->Websocket

# act as a gateway and call into p_* routine in app.pl of websocket server.

my $output = `/opt/perl/bin/perl /var/www/games/app/demo/callWS.pl '{"proj":"demo","obj":"$value1","act":"$value2"}'`;
chomp $output;

print "Access-Control-Allow-Origin: *\r\n";
print "Content-Type: application/json\r\n";
print "Content-Length: ".length($output)."\r\n\r\n";
print $output;
