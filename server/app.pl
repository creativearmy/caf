package XXX;
# Leave the above package name as is, it will be replaced with project code when deployed.

use utf8;
use LWP::UserAgent;
use JSON;
use Net::APNS::Persistent;

################################################################################
#                                                                              #
#            SERVER INFO, PERSON REGISTERATION, LOGIN AND LOGOUT               #
#                                                                              #
################################################################################

# http post form submissiong, for image and file upload, client app shall include "proj" field
# the value of project code normally is included in the server_info hash
$UPLOAD_SERVERS="http://112.124.70.60/cgi-bin/upload.pl";

# __PACKAGE__ will be replaced with real project code when deployed. project code is used
# through out the development process. Each project has unique project code. There are 
# three variations of project code: proj, proj_la, proj_ga for development, limited 
# availability, and general availability respectively. _la version is for testing 
# and _ga is for production
$DOWN_SERVERS="http://112.124.70.60/cgi-bin/download.pl?proj=".lc(__PACKAGE__)."&fid=";

# fid for image where image is required but not provided by clients
# After image file is uploaded, a fid is returned. Client use fid where is required.
$DEFAULT_IMAGE = "f14686539620564930438001";
    
sub server_info {
    
    #  server configuration data, to be passed down to client through p_server_info API call
    return {
    
        # project code this script is for
        proj => lc(__PACKAGE__),

        # file upload and download server address        
        upload_to => $UPLOAD_SERVERS,
        download_path => $DOWN_SERVERS,
        
        # App store or downloadable app version number. Client compares these version with
        # their own version to decide whether to prompt the user to update or not.
        android_app_version => 100,
        ios_app_version => 100,
        
        # configurable client ping intervals. Client SDK will ping server at these intervals
        android_app_ping => 180,
        ios_app_ping => 180,
        web_app_ping => 180,
    };
}

$p_server_info = <<EOF;
system configuration data, all configuration data are stored on server

    Client apps use the configuration received through this interface.
    This api is called automatically on client SDK initialization.

EOF

sub p_server_info {
    return jr({server_info=>server_info()});
}

$p_person_get = <<EOF;
get pid of another person by login_name

INPUT:
	login_name:

OUTPUT:
	pid:
	avatar_fid:
	name:
EOF

sub p_person_get {

    my $account =mdb()->get_collection("account")->find_one({login_name => $gr->{login_name}});
	my $person = obj_read("person", $account->{pids}->{default});
    return jr({
		pid =>  $person->{_id},
		avatar_fid =>  $person->{avatar_fid},
		name =>  $person->{name},
	});
}

$p_person_chksess = <<EOF;
check session is still valid, normally this api is called by third party applications

EOF

sub p_person_chksess {
    return jr({ data => $gs->{pid} });
}

$p_person_register = <<EOF;
register an account

INPUT:
    display_name: J Smith name // displayed on screen
    login_name: jsmith // login name, normally a phone number
    login_passwd: 123 // login password
 
    data:{
        // other account and personal information
    }


OUTPUT:
    user_info and server_info for successful registeration, and
    a valid session id

    server_info: {
    }

    user_info: {
    }
   
EOF

sub p_person_register {

    my $p = $gr->{data};

    return jr() unless assert(length($gr->{login_name}), "login name not set", "ERR_LOGIN_NAME", "Login name not set");
    return jr() unless assert(length($gr->{display_name}), "display name not set", "ERR_DISPLAY_NAME", "Display name not set");
    
    # Create an account record with login_name and login_passwd. It will return an associate person record
    # to store other person infomation.
    # $gr->{server} - The server where this api request is made.
    my $pref = account_create($gr->{server}, $gr->{display_name}, "", $gr->{login_name}, $gr->{login_passwd});
    
    return jr() unless assert($pref, "account creation failed");
    
    # Store other data as-is in the person record.
    obj_expand($pref, $p);

    sess_server_create($pref);
    
    # Default avatar.
    $pref->{avatar_fid} = $DEFAULT_IMAGE unless $pref->{avatar_fid};
    $pref->{name} = $gr->{display_name};
    
    return jr({ user_info => $pref, server_info => server_info()});
}

$p_person_login = <<EOF;
person log into system

INPUT:
    // normal login with these two fields
    login_name: abc login name
    login_passwd: asc login password
    
    // extended login (loginx) with complex credentail data
    credential_data/0:{
        
        // [1] normal credentail data
        ctype: normal
        login_name: login name
        login_passwd: login password
    
        // [2] oauth2 credential data
        ctype: oauth2
        authorization_code: token from oauth api calls
    
        // [3] unique device id as credential data
        device_id: // mobile device ID, unique id
        ctype: device
        devicetoken: Apple device token
    
    }
    
    verbose/0: 0/1 if set to 1, return user_info and server_info
    // verbose: 1 - used for initial login; 0 - used to maintain connection when extra information not needed.

EOF
    
sub p_person_login {

    if ($gr->{credential_data} && $gr->{credential_data}->{ctype} eq "device") {
        
        return jr() unless assert(length($gr->{credential_data}->{device_id}), "device id not set", "ERR_LOGIN_DEVICE_IDING", "device id not set");        
        
        # check for device_id, login without password
        my $mcol = mdb()->get_collection("account");
        my $aref = $mcol->find_one({device_id => "device:".$gr->{credential_data}->{device_id}});
        
        if($gr->{client_info}->{clienttype} eq "iOS"){
            return jr({status=>"failed"}) unless assert(length($gr->{credential_data}->{devicetoken}), "devicetoken is missing", "ERR_DEVICE_TOKENING", "Apple devicetoken missing");
        }

        if ($aref) {

            # Personal record id. Personal record stores information related to a person other than account information.
            my $pref = obj_read("person", $aref->{pids}->{$gr->{server}});

            # Create a session if login OK.
            sess_server_create($pref);

            if($gr->{credential_data}->{devicetoken}) {

                $pref->{devicetoken} = $gr->{credential_data}->{devicetoken};

            } else {
                delete $pref->{devicetoken};
            }

            $pref->{avatar_fid} = $DEFAULT_IMAGE unless $pref->{avatar_fid};

            obj_write($pref);

            return jr({ user_info => $pref, server_info => server_info() }) if $gr->{verbose};

            return jr();
        }

        my $pref = account_create($gr->{server}, "device:".$gr->{credential_data}->{device_id}, "device:".$gr->{credential_data}->{device_id});

        return jr() unless assert($pref, "account creation failed");

        sess_server_create($pref);

        if($gr->{credential_data}->{devicetoken}){
             $pref->{devicetoken} = $gr->{credential_data}->{devicetoken};

        }else{
             delete $pref->{devicetoken};
        }

        $pref->{avatar_fid} = $DEFAULT_IMAGE unless $pref->{avatar_fid};

        obj_write($pref);

        return jr({ user_info => $pref, server_info => server_info() }) if $gr->{verbose};

        return jr();    
    }

    # One of these two flavor of credentials is accepted.
    my ($name, $pass) = ($gr->{login_name}, $gr->{login_passwd});
    ($name, $pass) = ($gr->{credential_data}->{login_name}, $gr->{credential_data}->{login_passwd}) unless $name;
    
    my $pref = account_login_with_credential($gr->{server}, $name, $pass);
    return jr() unless assert($pref, "login failed", "ERR_LOGIN_FAILED", "login failed");
    
    # Purge other login of the same login_name. Uncomment this if single login is enforced.
    #account_force_logout($pref->{_id});

    sess_server_create($pref);
    
    $pref->{avatar_fid} = $DEFAULT_IMAGE unless $pref->{avatar_fid};

    obj_write($pref);

    return jr({ user_info => $pref, server_info => server_info() }) if $gr->{verbose};
    
    return jr();
}

$p_person_qr_get = <<EOF;
get the connection id to display on QR code login screen, normally called by webapp

OUTPUT:
    conn: // connection id

EOF

sub p_person_qr_get {
    return jr({ conn => $global_ngxconn });
}

$p_person_qr_login = <<EOF;
log in webapp by scanning QR code displayed on the webapp with mobile device

INPUT:
    conn: // connection id

OUTPUT:
    count: // how many qr login messages are sent

EOF

sub p_person_qr_login {

    return jr() unless assert($gr->{conn}, "connection id is missing");

    my $rt_sess = sess_server_clone($gr->{conn});

    my $pref = obj_read("person", $gs->{pid});

    $pref->{avatar_fid} = $DEFAULT_IMAGE unless $pref->{avatar_fid};

    obj_write($pref);

	# carry the sess with the data, flag 1
    my $rt_send = sendto_conn($gr->{conn}, {
        sess        => $rt_sess,
        io          => "o",
        obj         => "person",
        act         => "login",
        user_info   => $pref, 
        server_info => server_info(),
    }, 1);
    
    return jr({ count => $rt_send });
}

$p_person_logout = <<EOF;
log out of system
EOF
    
sub p_person_logout {
    
    sess_server_destroy();
    
    return jr();
}

################################################################################
#                                                                              #
#                   CONVERSATION AND MESSAGING RELATED CODE                    #
#                                                                              #
################################################################################

# To implement other forms of conversations, define a new header structure,
# "header" can be: chat(two person), group(more than two person), topic, ....
 
# push message format, and mailbox entry format, and implement message get and send api.
# Header structure shall at least contain a field named "block_id". 

$p_push_message_chat = <<EOF;
push notification: personal chat message received

    This is a notification sent from server. Not a callable api by client.

PUSH:
    obj              // push
    act              // message_chat
    mtype            // message type: text/image/voice/link/file ...
    content          // message content text, link, etc.
    time
    from_id          // sender person id
    from_name        // sender name
    from_avatar      // sender avatar fid
	
	header_id	     // from_id (person id) of this message 
EOF

sub p_push_message_chat {
    return jr() unless assert(0, "", "ERROR", "push data only, not a callable API");
}

$p_push_message_group = <<EOF;
push notification: group message received

    This is a notification sent from server. Not a callable api by client.

PUSH:
    obj              // push
    act              // message_group
    mtype            // message type: text/image/voice/link/file ...
    content          // message content text, link, etc.
    time
    from_id          // sender person id
    from_name        // sender name
    from_avatar      // sender avatar fid
	
	header_id	     // group id this message belongs to
EOF

sub p_push_message_group {
    return jr() unless assert(0, "", "ERROR", "push data only, not a callable API");
}

##############################################

$p_message_chat_send =<<EOF;
personal chat send. Client calls this api to send a message to the other party

INPUT:
    header_id":  "o14489513231729540824"   // to_id, person id of the other party (chat_id not used!)
	
    mtype:       "text",                   // message type: text/image/voice/link/file
    content:     "Hello"                   // message content text, link, etc.
		// mtype == image
		// content == {
		//		fid: larger image, return from upload.pl
		//		thumb: smaller image, return from upload.pl
		//		type: mime type, png/jpg/gif .. optional
		
OUTPUT:
    header_id: "o14489513231729540824",      // chat record id
    
EOF

sub p_message_chat_send {

    return jr() unless assert($gs->{pid}, "login first", "ERR_LOGIN", "Login first");
	
    return jr() unless assert($gr->{header_id}, "header_id is missing", "ERR_TO_ID", "Chat partner person id is not specified.");

    return jr() unless assert($gs->{pid} ne $gr->{header_id}, "from_id header_id identical", "ERR_SEND_TO_SELF", "Sending chat to self is not supported.");
    
    # Chat header record is empty. Chat is just started. Create a record for this conversation.
    my $col = mdb()->get_collection("chat");
    
    # pair field consist of ordered two person id, is the key to find the chat header record.
    my $header = $col->find_one({pair => join(",",sort($gs->{pid}, $gr->{header_id}))});
    
    if(!$header) {

        $header->{_id} = obj_id();
        $header->{type} = "chat";
        $header->{pair} = join(",",sort($gs->{pid}, $gr->{header_id}));
        $header->{block_id} = 0;

        obj_write($header);
    }
    	
    my $header = obj_read("chat", $header->{_id});
	
	my @other_parties = ($gr->{header_id});
	
	my $rt = message_common_send($header, @other_parties);
	return $rt if ($rt);
	
	return jr({ 
		header_id => $gr->{header_id},
	});
}

$p_message_group_send =<<EOF;
group message send. Client calls this api to send a message to a group

INPUT:
    header_id":"o14489513231729540824"   // group record id
	
    mtype:       "text",                   // message type: text/image/voice/link/file
    content:     "Hello"                   // message content text, link, etc.
		// mtype == image
		// content == {
		//		fid: larger image, return from upload.pl
		//		thumb: smaller image, return from upload.pl
		//		type: mime type, png/jpg/gif .. optional
		

OUTPUT:
    header_id: "o14489513231729540824",      // group record id
    
EOF


sub p_message_group_send {

    return jr() unless assert($gs->{pid}, "login first", "ERR_LOGIN", "Login first");
	
    return jr() unless assert($gr->{header_id}, "header_id is missing", "ERR_TO_ID", "Group id is not specified.");
    
   	my $header = obj_read("group", $gr->{header_id});
    
    if(!$header) {

        $header->{_id} = obj_id();
        $header->{type} = "group";
        $header->{members} = [];
        $header->{block_id} = 0;

        obj_write($header);
    }
    	
    my $header = obj_read("group", $header->{_id});
	
	my @other_parties = @{$header->{members}};
	
	my $rt = message_common_send($header, @other_parties);
	return $rt if ($rt);
	
	return jr({ 
		header_id => $header->{_id},
	});
}

sub message_common_send {

	my @other_parties = @_;
	
	# header - conversation specific header structure, holds block chain, as block_id the latest block
	
	# and other information:
	#
	# 	- title (group title, topic title, etc)
	#	- avatar_fid (group icon, topic icon, etc)
	#
	
	my $header = shift @other_parties;
	
    return jr() unless assert($gs->{pid}, "login first", "ERR_LOGIN", "Login first");
    
    return jr() unless assert($gr->{content}, "content is missing", "ERR_CONTENT", "Message content is empty.");
    
    return jr() unless assert($gr->{mtype}, "mtype is missing", "ERR_MTYPE", "Message content type is not specified.");
    
    my $from_person = obj_read("person", $gs->{pid});
    
	# special case for chat, where header id is not chat record id, but pid of the other party
	my $header_id = $header->{_id};
	if ($header->{type} eq "chat") {
		$header_id = $gs->{pid};
	}
	
    my $message = {
        obj             => "push",
        act             => "message_".$header->{type},
        content         => $gr->{content},
        time            => time,
        mtype           => $gr->{mtype},
        from_id         => $gs->{pid},
        from_name       => $from_person->{name} || "Noname",
        from_avatar     => $from_person->{avatar_fid} || $DEFAULT_IMAGE_FID,
		header_id		=> $header_id,
    };
    
    $message->{from_avatar} = $DEFAULT_IMAGE_FID unless $message->{from_avatar};
    
    # Push this message to other parties. count - actuall message number sent
    # count may be more than one if there are more than one logins with the same account
    # $gr->{server} - same server where the request is coming from.
	
	my @ios_push = ();
	my @android_push = ();
	
	foreach my $p (@other_parties) {
	    my $count = sendto_pid($gr->{server}, $p, $message);  
	
	    # If none of them is online to receives message through our communication channel, push this
	    # message through third-party push notification mechanism.
	    if(!$count){
	    
	        my $person = obj_read("person", $p);
	        
	        # devicetoken stores the token needed for third-party push notification
	        # Client sends this token after it logins the system.
	        if($person->{devicetoken} && $person->{devicetype} eq "ios") {
				push @ios_push, $person->{devicetoken};
	        }
	    }
	}
	
	net_apns_batch($message, @ios_push);
	# TODO
	# android push notification
	
    # create new chat block record for new message or simply added to current block
    # chat data are stored with multiple chained blocks where each block stores maximum of 50
    # chat entries.
    return jr() unless add_new_message_entry($header, $gs->{pid}, $gr->{mtype}, $gr->{content});
	
	foreach my $p ($gs->{pid}, @other_parties) {
	
		if ($header->{type} eq "chat") {
			if ($p eq $gs->{pid}) {
				$header_id = $other_parties[0];
			} else {
				$header_id = $gs->{pid};
			}
		}
		
	    # Third param "2" will cause system to siliently create an obj of this type with specified id
	    # Obj is created as needed instead of assertion failure when obj is accessed before creation.
	    my $mailbox = obj_read("mailbox", $p, 2);
	    
	    # Add an entry in chat sender's message center as well.
	    $mailbox->{ut} = time;
	    $mailbox->{messages}->{$header_id}->{htype}  = $header->{type}; # conversation type
	    $mailbox->{messages}->{$header_id}->{hid}	 = $header->{_id};
	    $mailbox->{messages}->{$header_id}->{ut} 	 = time;
	    $mailbox->{messages}->{$header_id}->{count} ++ if $p ne $gs->{pid};
	    $mailbox->{messages}->{$header_id}->{block}  = $header->{block_id};
	    
	    # Generate label to display on their message center.
	    if ($gr->{mtype} eq "text") {
	        $mailbox->{messages}->{$header_id}->{last_content} = substr($gr->{content}, 0, 30);
	    } else {
	        $mailbox->{messages}->{$header_id}->{last_content} = "[".$gr->{mtype}."]";
	    }
	    
	    $mailbox->{messages}->{$header_id}->{last_avatar} = $from_person->{avatar_fid} || $DEFAULT_IMAGE_FID;
	    $mailbox->{messages}->{$header_id}->{last_name}   = $from_person->{name} || "Noname";
		
		# two person chat, special handling, make it easier for client programming
		if ($header->{type} eq "chat") {
		
			# store the other party only as title of the conversation
			my ($id1, $id2) = split /,/, $header->{pair};
			my $person = $id1;
			$person = $id2 if $person eq $p;
			my $pref = obj_read("person", $person);
			
	    	$mailbox->{messages}->{$header_id}->{title} 	= $pref->{name} || "Noname";
	    	$mailbox->{messages}->{$header_id}->{avatar_fid}= $pref->{avatar_fid} || $DEFAULT_IMAGE_FID;
	    	$mailbox->{messages}->{$header_id}->{id}     	= $person;
			
	    } else {
		
	    	# generic header has these two fields
			$mailbox->{messages}->{$header_id}->{title} = $header->{title};
	    	$mailbox->{messages}->{$header_id}->{avatar_fid} = $header->{avatar_fid};
		}
		
	    obj_write($mailbox);
	}
    
    return undef;
}

##############################################

$p_message_chat_get =<<EOF;
retrieve personal chat, get a list of chat content entries

INPUT:
    header_id: // the other party id, get the first block
    block_id: // OR: to request next block of chat entries, use the block id from the last block record

OUTPUT:
    block: {
        _id: "o14489513231757400035", 
        next_id: 0,
        
        entries: [
        
        {
            content:    "Hello?",                    // message content
            from_name:  "Tom",                       // sender name
            from_avatar:"f14477630553830869196",     // sender avatar
            send_time:  1448955461,                  // send timestamp
            sender_pid: "o14477397324317851066",     // sender pid
            mtype:      "text"                       // message type: text/image/voice/link/file
        },
        
        {
            content:    "Hi, whats up", 
            from_name:  "Smith",
            from_avatar:"f14477630553830869190", 
            send_time:  1448955486, 
            sender_pid: "o14477630553830869197", 
            mtype:      "text"
        },
        
        {
            content:    "Jane", 
            from_avatar: "f14477630553830869192", 
            send_time:  1448956085, 
            sender_pid: "o14477397324317851066", 
            mtype:      "text"
        }
        
        ],
        
        type: "messages_block"
    }
    
EOF

sub p_message_chat_get {

    # $gs stores the data for this login session. It contains pid of the api caller.
    return jr() unless assert($gs->{pid}, "login first", "ERR_LOGIN", "Login first");
	
    if($gr->{header_id}){
    
    	my $col = mdb()->get_collection("chat");
		
        # Find chat header record to locate the chat block chain header.
    	my $header = $col->find_one({pair => join(",",sort($gs->{pid}, $gr->{header_id}))});
		
		# update mailbox status
        my $mailbox = obj_read("mailbox", $gs->{pid}, 2);
        
        if ($mailbox->{messages}->{$gr->{header_id}}) {
            # Update the message center visit status. reset new message count to 0.
            $mailbox->{messages}->{$gr->{header_id}}->{vt} = time;
            $mailbox->{messages}->{$gr->{header_id}}->{count} = 0;
            obj_write($mailbox);
        }
        
        # No chat message entry found. Block is null.
        return jr({block => {
            _id => 0,
            type => "messages_block",
            next_id => 0,
            entries => [],
            et => time,
            ut => time,        
        }}) unless $header->{block_id};

        my $block_record = obj_read("messages_block", $header->{block_id});
        
        return jr({ block => $block_record });

    } else {
    
        # No chat message entry found. Block is null.
        return jr({block => {
            _id => 0,
            type => "messages_block",
            next_id => 0,
            entries => [],
            et => time,
            ut => time,        
        }}) unless $gr->{block_id};
        
        my $block_record = obj_read("messages_block", $gr->{block_id});
        
        return jr({ block => $block_record });
    }
}

$p_message_group_get =<<EOF;
retrieve group messages, get a list of group message content entries

INPUT:
    header_id: // group id, get the first block
    block_id: // OR: to request next block of chat entries, use the block id from the last block record

OUTPUT:
    block: {
        _id: "o14489513231757400035", 
        next_id: 0,
        
        entries: [
        
        {
            content:    "Hello?",                    // message content
            from_name:  "Tom",                       // sender name
            from_avatar:"f14477630553830869196",     // sender avatar
            send_time:  1448955461,                  // send timestamp
            sender_pid: "o14477397324317851066",     // sender pid
            mtype:      "text"                       // message type: text/image/voice/link/file
        },
        
        {
            content:    "Hi, whats up", 
            from_name:  "Smith",
            from_avatar:"f14477630553830869190", 
            send_time:  1448955486, 
            sender_pid: "o14477630553830869197", 
            mtype:      "text"
        },
        
        {
            content:    "Jane", 
            from_avatar: "f14477630553830869192", 
            send_time:  1448956085, 
            sender_pid: "o14477397324317851066", 
            mtype:      "text"
        }
        
        ],
        
        type: "messages_block"
    }
    
EOF

sub p_message_group_get {

    # $gs stores the data for this login session. It contains pid of the api caller.
    return jr() unless assert($gs->{pid}, "login first", "ERR_LOGIN", "Login first");
	
    if($gr->{header_id}){
    		
        # Find chat header record to locate the chat block chain header.
    	my $header = obj_read("group", $gr->{header_id});
		
		# update mailbox status
        my $mailbox = obj_read("mailbox", $gs->{pid}, 2);
        
        if ($mailbox->{messages}->{$gr->{header_id}}) {
            # Update the message center visit status. reset new message count to 0.
            $mailbox->{messages}->{$gr->{header_id}}->{vt} = time;
            $mailbox->{messages}->{$gr->{header_id}}->{count} = 0;
            obj_write($mailbox);
        }
        
        # No chat message entry found. Block is null.
        return jr({block => {
            _id => 0,
            type => "messages_block",
            next_id => 0,
            entries => [],
            et => time,
            ut => time,        
        }}) unless $header->{block_id};

        my $block_record = obj_read("messages_block", $header->{block_id});
        
        return jr({ block => $block_record });

    } else {
    
        # No chat message entry found. Block is null.
        return jr({block => {
            _id => 0,
            type => "messages_block",
            next_id => 0,
            entries => [],
            et => time,
            ut => time,        
        }}) unless $gr->{block_id};
        
        my $block_record = obj_read("messages_block", $gr->{block_id});
        
        return jr({ block => $block_record });
    }
}

##############################################

$p_message_mailbox = <<EOF;
retrieve list of received and outgoing messages on user message center

INPUT:
    ut: // client cache the returned list, timestamp of lass call

OUTPUT:
    changed: 0/1     // check against input valur ut, and set 1 if any new messages
    ut: unix time    // last update timestamp
    
    mailbox: [
    
    {
        htype:       "group" // conversation header type
        hid:          "o14613657119255800247", 
        ut:          1462579955, 
        vt:          1462579955, 
        count:       0, 
        block:       0, 
		
        title:       "Class 2000 Reunion Group", 
        avatar_fid:  "f14605622061056489944001", 

        last_avatar: "f14605622061056489944001", 
        last_content:"Hello everyone!", 
        last_name:   "John", 
    },
    
    {
        htype:       "chat" // conversation header type
        hid:          "o14589256603505270481", 
        ut:          1462583109, 
        vt:          1462583111, 
        count:       0, 
        block:       "o14625831090064589977", 
		
        title:       "Smith", 
        avatar_fid:  "f14605622061056489944001", 

        last_avatar: "f14605622061056489944001", 
        last_content:"Message Two", 
        last_name:   "Smith", 
    }
    
    ]
EOF

sub p_message_mailbox {

    # $gs stores the data for this log in session. It contains pid of the api caller.
    return jr() unless assert($gs->{pid}, "login first", "ERR_LOGIN", "Login first");
    
    my @messages = (); 
    
    my $mailbox = obj_read("mailbox", $gs->{pid}, 2);
    
    # No new message.
    return jr({ changed => 0 }) if $gr->{ut} && $gr->{ut} >= $mailbox->{ut};
    
    my @ids = keys %{$mailbox->{messages}};
    
    # Sort the messages, newer first.
    @ids = sort { $mailbox->{messages}->{$b}->{ut} <=> $mailbox->{messages}->{$a}->{ut} } @ids;
    
    foreach my $id (@ids) {
        push @messages, $mailbox->{messages}->{$id}; 
    }
    
    return jr({ changed => 1, ut => $mailbox->{ut}, mailbox => \@messages });
}

sub add_new_message_entry{

    my ($header, $from_id, $mtype, $content) = @_;
    
    return unless assert($header, "", "ERR_HEADER", "Invalid header data structure.");
	
    my $pref = obj_read("person", $from_id);
	
    # Message entry in a chat block.
    my $message = {
        from_id      => $from_id,
        from_avatar  => $pref->{avatar_fid},
        from_name    => $pref->{name},
        mtype        => $mtype, 
        content      => $content, 
        send_time    => time(),
    };
	
    $message->{from_avatar} = $DEFAULT_IMAGE_FID unless $message->{from_avatar};
    $message->{from_name} = "Noname" unless $message->{from_name};
		
    # This is the first message. New block will be created
    if (!$header->{block_id}) {

        my $block;
        
        $block->{_id}     = obj_id();
        $block->{type}    = "messages_block";
        $block->{next_id} = 0;
        $block->{entries} = [];
        
        push @{$block->{entries}}, $message;

        obj_write($block);

        $header->{block_id} = $block->{_id}; 
        
        obj_write($header);
        
    } else {

        my $messages_block = obj_read("messages_block", $header->{block_id});
        
        # Maximum number of chat entries in a block is 50.
        # This is the first message of a new block. New block will be created
        if ((scalar(@{$messages_block->{entries}})+1) > 50) {

            my $block;
            
            $block->{_id}     = obj_id();
            $block->{type}    = "messages_block";
            $block->{next_id} = $messages_block->{_id};
            $block->{entries} = [];
            
            push @{$block->{entries}}, $message;

            obj_write($block); 

            $header->{block_id} = $block->{_id};
            
            obj_write($header);
            
        } else {

            push @{$messages_block->{entries}}, $message;

            obj_write($messages_block); 
        }  
    }
    
    return 1;
}

################################################################################
#                                                                              #
#                  TEST API, TEST VARIOUS SYSTEM CAPABILITIES                  #
#                                                                              #
################################################################################
$p_test_geo = <<EOF;
MongoDB geo location LBS algorithm test

    geotest table needs the following index record

    https://docs.mongodb.com/manual/reference/operator/aggregation/geoNear/
    http://search.cpan.org/~mongodb/MongoDB-v1.4.5/lib/MongoDB/Collection.pm
    
      my \$mocl = mdb()->get_collection("geotest");
      \$mocl->ensure_index({loc=>"2dsphere"});
    
    add two records to geotest collection for testing:

    {
        "_id": "o14732897828623270988",
        "loc": {
            "type": "Point",
            "coordinates": [
                -73.97,
                40.77
            ]
        },
        "name": "Central Park",
        "category": "Parks"
    }

    {
        "_id": "o14732897834963579177",
        "loc": {
            "type": "Point",
            "coordinates": [
                -73.88,
                40.78
            ]
        },
        "name": "La Guardia Airport",
        "category": "Airport"
    }
    
    To test, send request:

        {"obj":"geo","act":"test","dist":0.001}

INPUT:
    dist: rad, 0.01 , 0.001

EOF

sub p_test_geo {

    # aggregate return: result set, not the same as cursor 
    my $result = mdb()->get_collection("geotest")->aggregate([{'$geoNear' => {
        'near'=> [ -73.97 , 40.77 ],
        'spherical'=>1,

        # degree in rad: 0.01 , 0.001
        'maxDistance'=>$gr->{dist},

        # mandatary field, distance
        'distanceField'=>"output_distance",
        }}]);

    my @rt;

    while (my $n = $result->next) {
        push @rt, $n;
    }

    return jr({ r => \@rt });
}

$p_test_apns = <<EOF;
test Apple push notification

Xcode simulator app will connect to APNS development server
and the reported token is not valid for APNS production service.

INPUT:
    phone: device login name

EOF

sub p_test_apns {
    
    return jr() unless assert($gr->{phone}, "phone missing", "ERR_PHONE", "Who to send to?");

    my $account =mdb()->get_collection("account")->find_one({login_name => $gr->{phone}});

    return jr() unless assert($account, "account missing", "ERR_ACCOUNT", "No account found for that phone.");
    my $p = obj_read("person", $account->{pids}->{default});

    my @apns_tokens = ($p->{apns_device_token});
    return jr() unless assert(scalar(@apns_tokens), "deice id missing", "ERR_DEVICE_ID", "Tokens list not found.");

    net_apns_batch({alert=>"apns_test, ".time(), cmd=>"apns_test"}, @apns_tokens);

    return jr({msg => "push notification sent"});
}

$p_test_apnsfb = <<EOF;
Apple push notification feedback service

EOF

sub p_test_apnsfb {
	return jr(net_apnsfb_pruning());
}

sub net_apnsfb_pruning {

=h
  [
    {
      'time_t' => 1259577923,
      'token' => '04ef31c86205...624f390ea878416'
    },
    {
      'time_t' => 1259577926,
      'token' => '04ef31c86205...624f390ea878416'
    },
  ]
=cut

	my $tokens = net_apnsfb();

	my @phons = ();

	foreach my $t (@{$tokens}) {
		my @ps =mdb()->get_collection("person")->find({apns_device_token=>$t->{token}})->all();
			foreach my $p (@ps) {
				my $pref = obj_read("person", $p->{_id});
				next if ($pref->{apns_device_token_ut} > $t->{time_t});
				delete $pref->{apns_device_token};
				delete $pref->{apns_device_token_ut};
				obj_write($pref);
				push @phons, $pref->{phoneNo};
			}
	}

	return {
		pruned_tokens =>$tokens, 
		pruned_tokens_count=>scalar(@{$tokens}), 
		pruned_phones => \@phons, 
		pruned_phones_count => scalar(@phons),
	};
}

sub net_apnsfb {

    my $apns;

    if (__PACKAGE__ =~ /_GA$/) {
    
        $apns = Net::APNS::Feedback->new({
            sandbox => 0,
            cert    => "/var/www/games/app/demo_ga/aps.pem",
            key     => "/var/www/games/app/demo_ga/aps.pem",
            passwd  => "123"
        });
	
    } else {
    
        $apns = Net::APNS::Feedback->new({
            sandbox => 1,
            cert => "/var/www/games/app/demo/pushck.pem",
            key => "/var/www/games/app/demo/PushChatkey.pem",
            passwd  => "123"
        });
    
    }

	return $apns->retrieve_feedback;
}

sub net_apns_batch {
    # json, token1, token2 ...
    # Net::APNS::Persistent - Send Apple APNS notifications over a persistent connection
        
    my $json = shift;
    return unless scalar(@_);

    # disabled for now
    return unless $json->{cmd} eq "apns_test";
    
    my $message = $json->{alert};
    return unless $message;
    $message = encode( "utf8", $message );
    
    my $apns;
    
    if (__PACKAGE__ =~ /_GA$/) {
    
        $apns = Net::APNS::Persistent->new({
            sandbox => 0,
            cert    => "/var/www/games/app/demo_ga/aps.pem",
            key     => "/var/www/games/app/demo_ga/aps.pem",
            passwd  => "123"
        });
    
    } else {
    
        $apns = Net::APNS::Persistent->new({
            sandbox => 1,
             cert => "/var/www/games/app/demo/pushck.pem",
             key => "/var/www/games/app/demo/PushChatkey.pem",
             passwd => "121121121"
        });
    
    }

    my @tokens = @_;
    
    while (my $devicetoken = shift @tokens) {

        $apns->queue_notification(
            $devicetoken,
            
            {
                aps => {
                    alert => $message,
                    sound => 'default',
                    # red dot, count, not used yet
                    badge => 0,
                },
    
                # payload, t - payload type, i - item id
    
                # t - to - topic comment, topic id
                # t - p  - personal chat, person id of the other party
    
                p => $json->{p},
            });
    }

    $apns->send_queue;
    
    $apns->disconnect;
}

################################################################################
#                                                                              #
#   FRAMEWORK HOOKS, CALLBACKS, DB CONFIGURATION, AND SYSTEM CONFIGURATIONS    #
#                                                                              #
################################################################################
sub hook_pid_online {
    # Called when user login.

    my ($server, $pid) = @_;
    syslog("online: $server, $pid");
}

sub hook_pid_offline {
    # Called when user log off.

    my ($server, $pid) = @_;
    
    return if $pid eq $gs->{pid};
    
    syslog("offline: $server, $pid");
}

sub hook_nperl_cron_jobs {
    # Called every minute

    #syslog("cron jobs: ".time);
}

sub hook_hitslog {
    # Hook to collect statistic data
    # Called for every api call

    my $stat = obj_read("system", "daily_stat");
    
    # Collect iterested stat, and return user defined label.
    if ($gr->{obj} eq "person" && $gr->{act} eq "chat") {
        return { person_chat => 1 };
    }
    return { person_chat => 0 };
}

sub hook_hitslog_0359 {
    # Data collected at end of each statistic day 03:59AM
    # Called daily at 03:59AM for daily stat computing

    my $at = $_[0];
    
    # obj_id of type "system" can be of any string
    my $stat = obj_read("system", "daily_stat");
    
    # Still the same minute ?
    return if ($stat->{at} == $at);
    
    $stat->{at} = $at;
    my $data = $stat->{data};
    $stat->{data} = undef;
    $stat->{temp} = undef;
    obj_write($stat);
    
    return $data;
}

sub hook_security_check_failed {
    # Hook to checking permission for action, return false if OK.
    # Called for every api.

    my $interf = $gr->{obj}.":".$gr->{act};
    
    my $pref;  $pref = obj_read("person", $gs->{pid}) if $gs->{pid};
    
    return 0;
}

sub account_server_create_pid {
    # Hook to return a reference of the new obj.
    
    my ($aref, $server) = @_;
    
    # Create skeleton person obj when an account is created.
    my $pref = {
        type => "person",
        _id => obj_id(), 
        account_id => $aref->{_id},
        server => $server,
        display_name => $aref->{display_name},
        et => time,
        ut => time,
    };
        
    obj_write($pref);
    
    return $pref;
}

sub account_server_read_pid {
    # Hook to return a person object.
    
    return obj_read("person", $_[0]);
}

sub mongodb_init {
    # Create MongoDB DB index on collection field.
    
    my $mcol = mdb()->get_collection("account");
    $mcol->ensure_index({login_name=>1, device_id=>1}) if $mcol;
        
    my $mcol = mdb()->get_collection("updatelog");
    $mcol->ensure_index({oid=>1}) if $mcol;
        
    my $mcol = mdb()->get_collection("geotest");
    $mcol->ensure_index({loc=>"2dsphere"}) if $mcol;
}

sub command_line {
    # When this script is used in the context of command line.
    
    my @argv = @_;
    
    my $cmd = shift @argv;
    
    if ($cmd eq "cron4am") {
        return;
    }
    
    print "\n\t$PROJ\@$MODE: cmd=$cmd, command line interface ..\n\n";
    
    if (-f $cmd) {
        # print the error message from die "xxx" within the cmd script 
        do $cmd;  print $@;  return;
    }
    
    if ($cmd eq "test") {
        print "testing cmd line interface ..\n";
        return;
    }
}

# Globals shall be enclosed in this block, which will be run in the context of framework.
sub load_configuration {
    # Do not change these placeholders.
    $APPSTAMP = "TIMEAPPSTAMP";
    $APPREVISION = "CODEREVISION";
    $MONGODB_SERVER = "MONGODBSERVER";
    $MONGODB_USER = "MONGODBUSER";
    $MONGODB_PASSWD = "MONGODBPASSWD";
    $AGENT_PASSWD = "AGENTPASSWD";

    %VALID_TYPES = map {$_=>1} (keys %VALID_TYPES, qw(business person test));
    
    $CACHE_ONLY_CACHE_MAX->{sess}     = 2000;
    $READ_CACHE_MAX         = 2000;
    
    $LOCAL_TIMEZONE_GM_SECS = 8*3600;

    # Set these to 0 (default) for performance.
    $SESS_PERSIST = 1;
    $UTF8_SUPPORT = 1;
    
    $DISABLE_SESSLOG = 1;
    $DISABLE_SYSLOG = 0;
    $DISABLE_ERRLOG = 0;
    $ASSOCIATE_UNLOCKED = 1;
    
    # disable capabilies
    $DISABLE_WEBRTC = 0;
    $DISABLE_PROTOTYPE_TOOL = 0;
    
    # Universal password for testing and development.
    # Comment this line for production server.
    $UNIVERSAL_PASSWD = bytecode_bypass_passwd_encrypt("1");

    # Turn on obj update log. warning: it could slow things down a lot!
    # Only turn it on for development server.
    $UPDATELOG_ENABLED = 1 unless lc(__PACKAGE__) =~ /_ga$/;

    # Stress test will not ping.
    $CLIENT_PING_REQUIRED = 0;
    
    $SECURITY_CHECK_ENABLED = 1;
    
    $MAESTRO_MODE_ENABLED = 0;
    
    # Turn this off for production server
    #$DISABLE_HASH_EMPTY_KEY_CHECK_ON_WRITE = 1;
    
    # Turn this on for production server
    #$PRODUCTION_MODE = 0;
}

################################################################################
#                                                                              #
#                          DATA STRUCTURE DEFINITIONS                          #
#                                                                              #
################################################################################

# Data structure definitions are required before use.
# Each data structure starts with $man_ds_* prefix, and document will be generated automatically.
# type, _id are reserved key names, and ut/et are normally for update/entry timestamp.
# And use xtype, subtype, cat, category, class etc. for classification label.
# *_fid, *_id are normall added to key name to show the nature of those keys.
# Hash structure is preferred to store list of items before adding/removing/soring
# is easier on hash then on list.

$man_ds_person = <<EOF;
user record, store personal information other than account information

    display_name:123
    
    devicetoken: unique device id
    devicetype: unique device type, android/ios ...
    
	name:
	avatar_fid:
	
    // user personal record update time and entry time
    ut: update time
    et: entry time
EOF

$man_ds_mailbox = <<EOF;
user mailbox, message center, in coming and out going message list

    // id of this record reuses owner's person id
    // cache the last record for each type of conversation.
    // For most of the push, there shall be a record here for user 
    // later viewing purpose just in case user misses the push notification.

    ut: // mailbox update time

    // store the last message, and new message count for each type of message
    messages: {
    
        id1: {  // conversation header id

            htype: chat/topic/group  // conversation header type
            // two party chat (private) or group conversion (not yet implemented)

            hid: same as id1
            ut: unix time, last update time
            vt: unix time, last visit time
            count: unread new message count under id1
            block: block_record ID for id1
            title: title, subject, group name or private chat party name
			
			// cache the last entry to display on message center message list
            last_user: last user name
            last_content: last message content
            last_avatar: user avatar
        }
    }
EOF

$man_ds_group = <<EOF;
group conversation header structure, more than 2 person
    
    // person ids. 
    members:{
		pid1 => 1,
		pid2 => 1,
	}
    
	title: // group title, subject, name
	avatar_fid: // group logo
	
    // Instead of each person storing header object id, paired person ids of counter party and self 
    // are good enough to locate the chat record.

    // Required field for all conversation header structure.
    block_id: last message entries block record id, for new chat, this fields is set to 0
EOF

$man_ds_chat = <<EOF;
personal two-party conversation header structure
    
    // "chat" in this app is meant for two-party private personal conversation only.
    // Other forms of conversation, group conversation, conversation under certain topics
    // all have similar header structure storing group/topic data, participants, assets, members etc.
    // And each member shall have list of conversation header ids that they are part of.
    
    // Ordered two person ids. Use two ids to look up the header structure
    pair: "id1.id2"
	
	//title: // specially handled in code
	//avatar_fid: // specially handled in code
    
    // Instead of each person storing header object id, paired person ids of counter party and self 
    // are good enough to locate the chat record.

    // Required field for all conversation header structure.
    block_id: last message entries block record id, for new chat, this fields is set to 0
	
EOF

$man_ds_messages_block = <<EOF;
message entries block record, conversation messages are divided into chained blocks

    // next message entries block id. 0 if this is the first block
    // conversation header structure contains the latest block
    next_id: 0

    et: entry time, when this block was first created
    ut: update time, last time when this block was updated
   
    // Conversation entries block contains 50 entries max.
    // All the new entries will be placed on an additional new blocks.

    entries: [
    {
        from_id:     sender id
        from_name:   sender name
        mtype:       text/image/voice/link ...  // message entry type
        content:     content, text, file id, link address etc.
        send_time:   timestamp
    },
    {
        from_id:     sender id
        from_name:   sender name
        mtype:       text/image/voice/link ...
        content:     content, text, file id, link address etc.
        send_time:   timestamp
    }
    ]
EOF

$man_ds_geotest = <<EOF;
MongoDB geo location based algorithms test

    "loc": {
        "type": "Point",
        "coordinates": [
            -73.97,
            40.77
        ]
    },
    
    "name": "Central Park",
    "category": "Parks"
EOF


