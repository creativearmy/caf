
# Cross platform application in Perl. For Windows PC, Perl application
# can be packaged into standalone executable with "Perl Packager" module.
# Perl is most likely already installed for your flavor of Linux or Mac

use Mojo::UserAgent;
use JSON;
use utf8;

# flush after every write
$| = 1;

my $json = JSON->new;

# ws:// or wss:// string for WebSocket server
my ($ws_server_url) = @ARGV;

my $ws_useragent = Mojo::UserAgent->new;

$response_data_size_to_read = 0; # remaining data for response
$response_data_obj = undef; # received json response obj
$response_data_buf = undef; # received raw response data

$ws_useragent->websocket($ws_server_url => sub {

    my ($ua, $tx) = @_;

    print STDERR "WebSocket handshake failed\nws_server_url: $ws_server_url\n"
        and exit unless $tx->is_websocket;

    $tx->on(finish => sub {
        my ($tx, $code, $reason) = @_;
        print STDERR "WebSocket closed with status: $code:$reason\nws_server_url: $ws_server_url\n";
    });

    $tx->on(message => sub {
        
        my ($tx, $msg) = @_;

        print STDERR "msg: ", $msg, "\n\n";

        # keep receiving data until we have all the responded data
        # the size of the response data is specified on the first line of the message
        if ($response_data_size_to_read == 0) {
        
            ($response_data_size_to_read) = ($msg =~ /^(\d+)$/m);
            $msg =~ s/\d+\n//;
            $response_data_buf = $msg;
        } else {
            $response_data_buf .= $msg;
        }
        
        # For multibytes encoding, get the correct size
        $response_data_size_to_read -= length(Encode::encode_utf8($msg));
        
        # Keep reading messages.
        return if ($response_data_size_to_read) > 0;

        # Set the globals of the response. Only first element of the returned array
        # is used.
        
        chomp $response_data_buf;
        
        if ($response_data_buf =~ /^\{/s && $response_data_buf =~ /\}$/s) {
    
            my @lines = split /\n/, $response_data_buf;
            my $resp_tmp = $json->decode("[".join(",", @lines)."]");
            
            $response_data_obj = shift @{$resp_tmp};
            
            ########################################################################
            # Application business logic handling here:
            
            
            
        } else {
            print STDERR "Fatal, illformed json string received.";
            exit;
        }
    });

    $response_data_size_to_read = 0;

    # Send first websocket api call.
    $tx->send('{"obj":"server","act":"info"}'."\n");
});

# start the event loop
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
