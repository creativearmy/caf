#!/opt/perl/bin/perl

# usage: callWS.pl '{"proj":"xxx","obj":"objA","act":"actA", ..., json-string }'

use Mojo::UserAgent;
use JSON;
use utf8;
use Encode;
use Data::Dumper;
use Digest::MD5 qw/md5_hex/;

binmode(STDIN, ':encoding(utf8)');
binmode(STDOUT, ':encoding(utf8)');
binmode(STDERR, ':encoding(utf8)');

# flush after every write
$| = 1;

$json = JSON->new;

# project WS server for development and production
$WS_URLS = {
	xxx => "ws://1.2.3.4:51717/xxx",
	xxx_ga => "ws://1.2.3.4:80/xxx_ga"
};

my ($RSP) = @ARGV;

open Log,">>/tmp/callWS.log";
print Log $RSP."\n";

$RSP = Encode::decode("utf8", $RSP);
#print Log "decode_utf8: ".$RSP."\n";

my $rsp_json = $json->decode($RSP);
$WS_SERVER = $WS_URLS->{$rsp_json->{proj}};

print Log Dumper($rsp_json)."\n";
close Log;

my $ua = Mojo::UserAgent->new;
$resp_len = 0;

# Non-blocking WebSocket connection sending and receiving JSON messages
$ua->websocket($WS_SERVER => sub {

    my ($ua, $tx) = @_;
  
    die "WebSocket handshake failed!\nWS_SERVER: $WS_SERVER\n" unless $tx->is_websocket;
  
    $tx->on(finish => sub {
        my ($tx, $code, $reason) = @_;
        die "WebSocket closed with status $code:$reason\nWS_SERVER: $WS_SERVER\n";
    });
  
    $tx->on(message => sub {
    
        my ($tx, $msg) = @_;
    
        # keep receiving until we have all the responded data
        if ($resp_len == 0) {
        
            # start with length of response string
		    ($resp_len) = ($msg =~ /^(\d+)$/m);
		    $msg =~ s/\d+\n//;
		    
		    $resp_buf = $msg;
		    
        } else {
        
            $resp_buf .= $msg;
        }
        
        $resp_len -= length(Encode::encode_utf8($msg));
        return if ($resp_len) > 0;
        
        # set the globals of the response
        chomp $resp_buf;
        if ($resp_buf =~ /^\{/s && $resp_buf =~ /\}$/s) {
        
            # response handling here
            print $resp_buf."\n";
            
		    exit;
		    
        } else {
            die "Fatal, illformed json string!!\n\n";
        }
    });
    
    $resp_len = 0;
    $tx->send($RSP."\n")
});

Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

