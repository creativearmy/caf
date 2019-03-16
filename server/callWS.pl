#!/opt/perl/bin/perl

# usage: callWS.pl '{"proj":"xxx","obj":"objA","act":"actA", ..., json-string }'
#
# usage: callWS.pl Your/script/file/name

# ---- script file spec begin ---------------------         
# proj or ws... string
# {"obj":"objA1","act":"actA1", ..., json-string }
# {"obj":"objA2","act":"actA2", ..., json-string }
# ...
# ---- script file spec end   ---------------------
#
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
	xxx_ga => "ws://1.2.3.4:80/xxx_ga",
};

my ($request_str) = @ARGV;

open Log,">>/tmp/callWS.log";
print Log "[".localtime()."] ".$request_str."\n";

my @request_strs; # support multiple request, with login session
my $sess = ""; # keep track of sess in response from server

$WS_SERVER = "";

if (-s $request_str) {
    local $/;
    open REQFILE, $request_str;
    my $c = <REQFILE>;
    close REQFILE;
    print Log $c."\n";
	$c = Encode::decode("utf8", $c);
    @request_strs = split /\n/, $c;
    
    # proj or ws... string
    $WS_SERVER = shift @request_strs;
    $WS_SERVER = $WS_URLS->{$WS_SERVER} unless ($WS_SERVER =~ /^ws/);
    
} else {
    @request_strs = ($request_str);
    $request_str = Encode::decode("utf8", $request_str);
    #print Log "decode_utf8: ".$RSP."\n";
    my $request_json = $json->decode($request_str);
    $WS_SERVER = $WS_URLS->{$request_json->{proj}};
}
close Log;

die "WS_SERVER or REQ invalid" unless $WS_SERVER && scalar(@request_strs);

#############################################################################################

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
        
            # response handling here, extract sess
            print $resp_buf."\n";
            my $resp_obj = $json->decode($resp_buf);
            
            $sess = $resp_obj->{sess};
            
            my $req = shift @request_strs;
		    exit unless $req;;
		    
            # inject sess into request
            my $req_obj = $json->decode($req);
            $req_obj->{sess} = $sess;
            $req = $json->encode($req_obj);
		    $tx->send($req."\n");
		    
        } else {
            die "Fatal, illformed json string!!\n\n";
        }
    });
    
    $resp_len = 0;
    my $req = shift @request_strs;
    
    # inject sess into request
    my $req_obj = $json->decode($req);
    $req_obj->{sess} = $sess;
    $req = $json->encode($req_obj);
    $tx->send($req."\n");
});

Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

