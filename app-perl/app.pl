
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
	
    ####################################
	if ($jo->{obj} eq "server" && $jo->{act} eq "info" && !$session) {
		# Go on and start the login process automatically.
		if ($login_name && $login_passwd) {
		    # verbose: 1 to return user_info and server_info
		    send_obj_str('{"obj":"person","act":"login","login_name":"'.$login_name.'","login_passwd":"'.$login_passwd.'","verbose":"1"}');
		}
    }
	
    ####################################
    # Test ipc message: echo '{"obj":"server","act":"info"}' |netcat 127.0.0.1 3000
	if ($jo->{obj} eq "server" && $jo->{act} eq "info" && $jo->{ipc}) {
		# Simply forward this test ipc message to server
		send_obj_str('{"obj":"server","act":"info"}');
    }
    
	# test message comming from server, and forward to locally connected TCP client
	if ($jo->{obj} eq "objA" && $jo->{act} eq "actA" && $jo->{pushed}) {
	    if($last_local_connection_id) {
	        errlog("last_local_connection_id $last_local_connection_id\n");
	        my $stream = Mojo::IOLoop->stream($last_local_connection_id);
	        $stream->write("Hello, from our server!\n") if $stream;
	    }
    }
	
	####################################
	# login returns, attemp to execute json_input command
	if ($jo->{obj} eq "person" && $jo->{act} eq "login") {
		# Check if login succeeded.
		if ($json_input) {
		    send_obj_str($json_input);
		}
	}
	
	####################################
	# single execution
	if ($jo->{obj} eq "objA" && $jo->{act} eq "actA") {
	    # quit once commmand execution returns from server
	    # $json_input, '{"obj":"objA","act":"actA"}''
    }        
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
$AUTOCONNECT_TIME = 2; # In case of loss of connection, retry at this interval.
$PING_INTERVAL = 180; # 3 mins, recurring pings to server
$LOCAL_LISTENING_PORT = 3000; # If local line input is no required, set this to 0.

# for practical application, it should be a connection table to keep track of
# local connections to send data to
$last_local_connection_id = "";

################################################################################
use Mojo::UserAgent;
use JSON;
use utf8;

# flush after every write
$| = 1;

# allow_nonref is to fix a comlaint "JSON text has to be an object or array"
# on some Windows when decoding a valid JSON text
$json = JSON->new->allow_nonref;
$json_pretty = JSON->new->allow_nonref->pretty;

# ws:// or wss:// string for WebSocket server
# automatically login, and execute a $json_input command
($ws_server_url, $login_name, $login_passwd, $json_input) = @ARGV;

errlog("WebSocket server url ws_server_url missing\n")
    and exit unless $ws_server_url;

$ws_useragent = Mojo::UserAgent->new;
$ws_useragent->inactivity_timeout(0); # Allow connections to be inactive indefinitely.

$response_data_size_to_read = 0; # remaining data for response
$response_data_obj = undef; # received json response obj
$response_data_buf = undef; # received raw response data
$last_ping = 0; # last time an api call occured

$websocket_connecting = 0;
sub websocket_connect {

	return if $websocket_connecting;
	$websocket_connecting = 1;
	
	$ws_useragent->websocket($ws_server_url => sub {
		my ($ua, $tx) = @_;
        
		# No longer connecting.
		$websocket_connecting = 0;
		
	    # Fail to connect, keep going.
	    if (!$tx->is_websocket) {
	        return errlog("WebSocket handshake failed\nws_server_url: $ws_server_url\n");
	    }
	        
	    # global reference of WebSocket transactor
	    $ws_transactor = $tx;
	    Mojo::IOLoop->remove($auto_connect_id);
		$auto_connect_id = undef;
		
		$tx->on(finish => sub {
		    my ($tx, $code, $reason) = @_;
		    errlog("WebSocket closed with status: $code:$reason\nws_server_url: $ws_server_url\n");
			
	        # Restart the connecting process.
	        $ws_transactor = undef;
			$session = undef;
			$auto_connect_id = Mojo::IOLoop->recurring($AUTOCONNECT_TIME => sub { websocket_connect() });
		});
		
		$tx->on(message => sub {
		    
		    my ($tx, $msg) = @_;
		
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
		        iolog("\n:: OUTPUT : [".localtime()."]\n".$json_pretty->encode($response_data_obj));
		        # Exttract session if present
		        $session = $response_data_obj->{sess} if $response_data_obj->{sess};
		        $last_ping = time();
		        response_handler($response_data_obj);
		        
		    } else {
		        errlog("Fatal, illformed json string received.");
				
	            # Restart the connecting process.
	            $ws_transactor = undef;
				$session = undef;
				$auto_connect_id = Mojo::IOLoop->recurring($AUTOCONNECT_TIME => sub { websocket_connect() });
		    }
		});
		
		# Reset the expected length to 0
		$response_data_size_to_read = 0;
		
		# Send first websocket api call.
		send_obj_str('{"obj":"server","act":"info"}');
	});
}

# Start the initial connecting process.
$ws_transactor = undef; # WebSocket transactor for api calls
$session = undef; # once logged in, server returns a session to identify the client
$auto_connect_id = Mojo::IOLoop->recurring($AUTOCONNECT_TIME => sub { websocket_connect() });

# Minder timer to send recurring pings to server
Mojo::IOLoop->recurring($MINDER_TIME => sub {

    # Consider this connection loss, try reconnect again.
	# This also prevents unsent message piled up thanks to the design of Mojo.
    if (time - $last_ping > 2*$PING_INTERVAL && !$auto_connect_id) {
        $ws_transactor = undef;
		$session = undef;
		$auto_connect_id = Mojo::IOLoop->recurring($AUTOCONNECT_TIME => sub { websocket_connect() });
		return;
    }
	
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
    
    errlog("Local connection: $id\n");   
    $last_local_connection_id = $id;

    # increase the inactivity timeout to 300s or more
    $stream->timeout(300);

    # TO TEST: echo '{"obj":"server","act":"info"}' |netcat 127.0.0.1 3000
    $stream->on(read => sub {
        my ($stream, $bytes) = @_;  chomp $bytes;
        my $jo = $json->decode($bytes);
        $jo->{io} = "o";
        $jo->{ipc} = 1;
        iolog("\n:: OUTPUT : [".localtime()."]\n".$json_pretty->encode($jo));
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
    $ref->{io} = "i" unless $ref->{io};
    iolog("\n::  INPUT : [".localtime()."]\n".$json_pretty->encode($ref));
    $ws_transactor->send($json->encode($ref)."\n") if $ws_transactor;
}

# Send API call as an json enencoded string, with $session auto injected
sub send_obj_str {
    my ($str) = @_;
    my $ref = $json->decode($str);
    send_obj($ref);
}

# Input/output logging. Caller does the formatting. Add file io to save it to file
sub iolog {
	my $msg = $_[0];
	print STDERR $msg;
}

# Error logging. Caller does the formatting. Add file io to save it to file
sub errlog {
	my $msg = "[".localtime()."] ".$_[0];
	print STDERR $msg;
}
