
################################################################################
#                                                                              #
#          -= Creativearmy App Framework - Client Application in Perl =-       #
#                      https://github.com/creativearmy/caf                     #
#                                                                              #
################################################################################

# Handler for server data. Most application business logics are defined here.
# If local input is needed, send IPC data to local port $LOCAL_LISTENING_PORT
sub response_handler {
    # jo, json object reference, for response, ipc message, or push notification
    # For ipc message, field $jo->{ipc} will be set.
    my ($jo) = @_;
        
}

# Minder recurring routine will be executed at $MINDER_TIME interval
sub minder_recurring {
    
}

################################################################################
# Cross platform application in Perl. For Windows PC, Perl application
# can be packaged into standalone executable with "Perl Packager" module.
# Perl is most likely already installed for your flavor of Linux or Mac

# global system parameters
$MINDER_TIME = 30; # Check to see if ping needs to fire
$PING_INTERVAL = 180; # 3 mins, recurring pings to server
$LOCAL_LISTENING_PORT = 3000; # If local line input is no required, set this to 0.

################################################################################
use Mojo::UserAgent;
use JSON;
use utf8;

# flush after every write
$| = 1;

$json = JSON->new;
$json_pretty = JSON->new->pretty;

# ws:// or wss:// string for WebSocket server
($ws_server_url) = @ARGV;

print STDERR "WebSocket server url ws_server_url missing\n"
    and exit unless $ws_server_url;

$ws_useragent = Mojo::UserAgent->new;
$ws_useragent->inactivity_timeout(0); # Allow connections to be inactive indefinitely.

$response_data_size_to_read = 0; # remaining data for response
$response_data_obj = undef; # received json response obj
$response_data_buf = undef; # received raw response data
$session = undef; # once logged in, server returns a session to identify the client
$ws_transactor = undef; # WebSocket transactor for api calls
$last_ping = 0; # last time an api call occured
$ws_useragent->websocket($ws_server_url => sub {

    my ($ua, $tx) = @_;
    
    # global reference of WebSocket transactor
    $ws_transactor = $tx;
    
    print STDERR "WebSocket handshake failed\nws_server_url: $ws_server_url\n"
        and exit unless $tx->is_websocket;

    $tx->on(finish => sub {
        my ($tx, $code, $reason) = @_;
        print STDERR "WebSocket closed with status: $code:$reason\nws_server_url: $ws_server_url\n";
    });

    $tx->on(message => sub {
        
        my ($tx, $msg) = @_;
        # print STDERR "msg: ", $msg, "\n\n";

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
        return if $response_data_size_to_read > 0;

        # Set the globals of the response. Only first element of the returned array
        # is used.
        
        chomp $response_data_buf;
        
        if ($response_data_buf =~ /^\{/s && $response_data_buf =~ /\}$/s) {
    
            my @lines = split /\n/, $response_data_buf;
            my $resp_tmp = $json->decode("[".join(",", @lines)."]");
            
            $response_data_obj = shift @{$resp_tmp};
            print STDERR "\n:: OUTPUT : [".localtime()."]\n".$json_pretty->encode($response_data_obj);
            # Exttract session if present
            $session = $response_data_obj->{sess} if $response_data_obj->{sess};
            $last_ping = time();
            response_handler($response_data_obj);
            
        } else {
            print STDERR "Fatal, illformed json string received.";
            exit;
        }
    });
    
	# Reset the expected length to 0
    $response_data_size_to_read = 0;

    # Send first websocket api call.
    send_obj_str('{"obj":"server","act":"info"}');
});

# Minder timer to send recurring pings to server
Mojo::IOLoop->recurring($MINDER_TIME => sub {
    if (time - $last_ping > $PING_INTERVAL) {
        send_obj_str('{"obj":"server","act":"ping"}');
    }
    
    minder_recurring();
});

# Local IPC socket data port
Mojo::IOLoop->server({port => $LOCAL_LISTENING_PORT} => sub {
    my ($loop, $stream, $id) = @_;
    
    # Line command shell input, or for inter process communication
    # Only stringified json string server api call is accepted.
    
    # TO TEST: echo '{"obj":"server","act":"info"}' |netcat 127.0.0.1 3000
    $stream->on(read => sub {
        my ($stream, $bytes) = @_;  chomp $bytes;
        my $jo = $json->decode($bytes);
        $jo->{ipc} = 1;
        print STDERR "\n:: OUTPUT : [".localtime()."]\n".$json_pretty->encode($jo);
        response_handler($jo);
    });
}) if $LOCAL_LISTENING_PORT;

# start the event loop
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

################################################################################

# Send API call as an obj reference, with $session auto injected
sub send_obj {
    my ($ref) = @_;
    $ref->{sess} = $session if $session;
    print STDERR "\n::  INPUT : [".localtime()."]\n".$json_pretty->encode($ref);
    $ws_transactor->send($json->encode($ref)."\n");
}

# Send API call as an json enencoded string, with $session auto injected
sub send_obj_str {
    my ($str) = @_;
    my $ref = $json->decode($str);
    send_obj($ref);
}

