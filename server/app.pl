package XXX;
# leave the above package name as is, it will be replaced with project code when deployed

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
    This interface is called automatically on client SDK initialization.

EOF

sub p_server_info {
    return jr({server_info=>server_info()});
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
get the connection id to display in QR code login usually called by web app

OUTPUT:
    conn: // connection id

EOF

sub p_person_qr_get {
    return jr({ conn => $global_ngxconn });
}

$p_person_qr_login = <<EOF;
log in web app by scanning QR code displayed on the webapp with mobile device

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

    my $rt_send = sendto_conn($gr->{conn}, {
        sess        => $rt_sess,
        io          => "o",
        obj         => "person",
        act         => "login",
        user_info   => $pref, 
        server_info => server_info(),
    });
    
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
#              CONVERSATION AND MESSAGING RELATED SAMPLE CODE                  #
#                                                                              #
################################################################################
$p_push_message_chat = <<EOF;
push notification: personal chat message received

PUSH:
    obj              // push
    act              // message_chat
    chat_content     // message content text, link, etc.
    chat_time
    chat_type        // message type: text/image/voice/link/file
    from_id          // sender person id
    from_image       // sender avatar
EOF

sub p_push_chat_person {
    return jr() unless assert(0, "", "ERROR", "push data only, not a callable API");
}

$p_message_chat_send =<<EOF;
personal chat send. Client calls this api to send a message to the other party

INPUT:
    from_id:     "o14477630553830869197",  // sender person id
    to_id:       "o14477397324317851066",  // person id to send chat to
    chat_type:   "text",                   // message type: text/image/voice/link/file
    chat_content:"Hello"                   // message content text, link, etc.
    chat_id":    "o14489513231729540824"   // chat header record id, null when chat starts

OUTPUT:
    chat_id: "o14489513231729540824",    // chat header record id
    
EOF

sub p_message_chat_send {

    return jr() unless assert($gr->{from_id}, "from_id is missing", "ERR_FROM_ID", "Chat from person id is not specified.");
    
    return jr() unless assert($gr->{from_id} ne $gr->{to_id}, "from_id to_id identical", "ERR_SEND_TO_SELF", "Sending chat to self is not supported.");
    
    # if to_id is not in the format of our system object id, we assume it is a device unique id
    if ($gr->{to_id} !~ /^o\d{20}$/) {
    
        my $mcol = mdb()->get_collection("account");
        my $aref = $mcol->find_one({device_id => "device:$gr->{to_id}"});
        
        $gr->{to_id} = $aref->{pids}->{$gr->{server}};
    }
    
    return jr() unless assert($gr->{to_id}, "to_id is missing", "ERR_TO_ID", "Chat partner person id is not specified.");
    
    return jr() unless assert($gr->{chat_content}, "chat_content is missing", "ERR_CHAT_CONTENT", "Chat message content is empty.");
    
    return jr() unless assert($gr->{chat_type}, "chat_type is missing", "ERR_CHAT_TYPE", "Chat message content type is not specified.");
    
    my $chat_id = $gr->{chat_id};
    
    if(!$chat_id) {
    
        # Chat header record is empty. Chat is just started. Create a record for this conversation.
        my $col = mdb()->get_collection("chat");
        
        # pair field consist of ordered two person id, is the key to find the chat header record.
        my $chat_header = $col->find_one({pair => join("",sort($gr->{from_id}, $gr->{to_id}))});
        
        if(!$chat_header) {

            $chat_header->{_id} = obj_id();
            $chat_header->{type} = "chat";
            $chat_header->{pair} = join("",sort($gr->{from_id}, $gr->{to_id}));
            $chat_header->{block_id} = 0;

            obj_write($chat_header);
        }
        
        $chat_id = $chat_header->{_id};
    }
    
    my $from_person = obj_read("person", $gr->{from_id});
    
    my $message = {
        obj             => "push",
        act             => "chat_person",
        chat_content    => $gr->{chat_content},
        chat_time       => time,
        chat_type       => $gr->{chat_type},
        from_id         => $gr->{from_id},
        from_name       => $from_person->{name},
        from_image      => $from_person->{avatar_fid},
    };
    
    $message->{from_image} = $DEFAULT_IMAGE_FID unless $message->{from_image};
    
    # Push this message to chat partner. count - actuall message number sent
    # count may be more than one if there are more than one logins with the same account
    # $gr->{server} - same server where the request is coming from.
    my $count = sendto_pid($gr->{server}, $gr->{to_id}, $message);  

    # If none of them is online to receives message through our communication channel, push this
    # message through third-party push notification mechanism.
    if(!$count){
    
        my $person = obj_read("person", $gr->{to_id});
        
        # devicetoken stores the token needed for third-party push notification
        # Client sends this token after it logins the system.
        if($person->{devicetoken} && $person->{devicetype} eq "ios") {
            net_apns_batch($message, $person->{devicetoken});
        }
    }

    # create new chat block record for new message or simply added to current block
    # chat data are stored with multiple chained blocks where each block stores maximum of 50
    # chat entries.
    return jr() unless add_new_messages_block($chat_id, $gr->{from_id}, $gr->{chat_type}, $gr->{chat_content});

    my $chat_header = obj_read("chat", $chat_id);
    
    # Third param "2" will cause system to siliently create an obj of this type with specified id
    # Obj is created as needed instead of assertion failure when obj is accessed before creation.
    my $inbox = obj_read("inbox", $gr->{to_id}, 2);
    
    # Add an entry in chat sender's message center.
    $inbox->{ut} = time;
    $inbox->{messages}->{$gr->{from_id}}->{xtype}  = "person";
    $inbox->{messages}->{$gr->{from_id}}->{id}     = $gr->{from_id};
    $inbox->{messages}->{$gr->{from_id}}->{ut}     = time;
    $inbox->{messages}->{$gr->{from_id}}->{count} ++;
    $inbox->{messages}->{$gr->{from_id}}->{cid}    = $chat_header->{block_id};
    
    # Generate label to display on their message center.
    if ($gr->{chat_type} eq "text") {
        $inbox->{messages}->{$gr->{from_id}}->{last} = substr($gr->{chat_content}, 0, 30);
    } else {
        $inbox->{messages}->{$gr->{from_id}}->{last} = "[".$gr->{chat_type}."]";
    }
    
    $inbox->{messages}->{$gr->{from_id}}->{fid} = $from_person->{avatar_fid};
    $inbox->{messages}->{$gr->{from_id}}->{title} = $from_person->{name};
    
    obj_write($inbox);

    # Now do the same for the other chat party.
    
    # Obj is created as needed instead of causing assertion fails when obj is not created yet.
    my $inbox =obj_read("inbox", $gr->{from_id}, 2);

    my $to_person = obj_read("person", $gr->{to_id});
    
    # Add an entry in chat receiver's message center.
    $inbox->{ut} = time;
    $inbox->{messages}->{$gr->{to_id}}->{xtype}  = "person";
    $inbox->{messages}->{$gr->{to_id}}->{id}     = $gr->{to_id};
    $inbox->{messages}->{$gr->{to_id}}->{ut}     = time;
    $inbox->{messages}->{$gr->{to_id}}->{vt}     = time;
    $inbox->{messages}->{$gr->{to_id}}->{count}  = 0;
    $inbox->{messages}->{$gr->{to_id}}->{cid}    = $chat_header->{block_id};
    
    # Generate label to display on their message center.
    if ($gr->{chat_type} eq "text") {
        $inbox->{messages}->{$gr->{to_id}}->{last} = substr($gr->{chat_content}, 0, 30);
    } else {
        $inbox->{messages}->{$gr->{to_id}}->{last} = "[".$gr->{chat_type}."]";
    }
    
    $inbox->{messages}->{$gr->{to_id}}->{fid} = $to_person->{avatar_fid};
    $inbox->{messages}->{$gr->{to_id}}->{title} = $to_person->{name};
    
    obj_write($inbox);
    
    return jr({ chat_id => $chat_id });
}

$p_message_chat_get =<<EOF;
retrieve personal chat, get a list of chat contents entries

INPUT:
    users:["o14477397324317851066","o14477630553830869197"]    //sender and receiver pid
    chat_block_id: // to request next block of chat entries, use the block id from the last block record

OUTPUT:
    chat_block: {
        _id: "o14489513231757400035", 
        next_id: 0,
		
        records: [
		
        {
            content:    "Hello?",                    // message content
            from_name:  "Tom",                       // sender name
            from_image: "f100055555",                // sender avatar
            send_time:  1448955461,                  // send timestamp
            sender_pid: "o14477397324317851066",     // sender pid
            xtype:      "text"                       // message type: text/image/voice/link/file
        },
		
        {
            content:    "Hi, whats up", 
            from_name:  "Smith",
            from_image: "f10007777", 
            send_time:  1448955486, 
            sender_pid: "o14477630553830869197", 
            xtype:      "text"
        },
		
        {
            content:    "Jane", 
            from_image: "f100055555", 
            send_time:  1448956085, 
            sender_pid: "o14477397324317851066", 
            xtype:      "text"
        }
		
        ],
		
        type: "messages_block"
    }
    
EOF

sub p_message_chat_get {

    # $gs stores the data for this login session. It contains pid of the api caller.
    return jr() unless assert($gs->{pid}, "login first", "ERR_LOGIN", "Login first");
    
    if($gr->{users}){
    
        # If to_id is not in the format of our system object id, we assume it is for a device unique id.
        my $mcol = mdb()->get_collection("account");
        if ($gr->{users}->[0] !~ /^o\d{20}$/) {
            my $aref = $mcol->find_one({device_id => "device:$gr->{users}->[0]"});
            $gr->{users}->[0] = $aref->{pids}->{$gr->{server}};
        }
        
        if ($gr->{users}->[1] !~ /^o\d{20}$/) {
            my $aref = $mcol->find_one({device_id => "device:$gr->{users}->[1]"});
            $gr->{users}->[1] = $aref->{pids}->{$gr->{server}};
        }
        
        # The other chat party
        my $theother = $gr->{users}->[0];
        $theother = $gr->{users}->[1] if $theother eq $gs->{pid};
        
        my $inbox = obj_read("inbox", $gs->{pid}, 2);
        
        if ($inbox->{messages}->{$theother}) {
            # Update the message center visit status. reset new message count to 0.
            $inbox->{messages}->{$theother}->{vt} = time;
            $inbox->{messages}->{$theother}->{count} = 0;
            obj_write($inbox);
        }
        
        # Find chat header record to locate the chat block chain header.
        my $col = mdb()->get_collection("chat");
        
        my $chat = $col->find_one({pair => join("", @{$gr->{users}})});
        
        # No chat message entry found. Block is null.
        return jr({chat_block => {
            _id => 0,
            type => "messages_block",
            next_id => 0,
            records => [],
            et => time,
            ut => time,        
        }}) unless $chat->{block_id};

        my $block_record = obj_read("messages_block", $chat->{block_id});
        
        return jr({ chat_block => $block_record });

    } else {
    
        return jr() unless assert($gr->{chat_block_id}, "chat_block_id is missing", "ERR_BLOCK_ID", "Chat entries block is null.");
        
        my $block_record = obj_read("messages_block", $gr->{chat_block_id});
        
        return jr({ chat_block => $block_record });
    }
}

$p_message_inbox_get = <<EOF;
retrieve list of received messages on user message center

INPUT:
    ut: // client cache the returned list, timestamp of lass call

OUTPUT:
    changed: 0/1     // check against input valur ut, and set 1 if any new messages
    ut: inbox        // last update timestamp
	
    inbox: [
	
    {
        cid:   null, 
        count: 0, 
        id:    "o14613657119255800247", 
        last:  "following: [n/a]", 
        title: "Message One", 
        ut:    1462579955, 
        vt:    1462579955, 
        xtype: "task"
    }
	
    {
        cid:   "o14625831090064589977", 
        count: 0, 
        fid:   "f14605622061056489944001", 
        id:    "o14589256603505270481", 
        last:  "Message Two", 
        title: "Message Two", 
        ut:    1462583109, 
        vt:    1462583111, 
        xtype: "person"
    }
	
    ]
EOF

sub p_message_inbox_get {

    # $gs stores the data for this log in session. It contains pid of the api caller.
    return jr() unless assert($gs->{pid}, "login first", "ERR_LOGIN", "Login first");
    
    my @messages = (); 
    
    my $inbox = obj_read("inbox", $gs->{pid}, 2);
    
    # No new message.
    return jr({ changed => 0 }) if $gr->{ut} && $gr->{ut} < $inbox->{ut};
    
    my @ids = keys %{$inbox->{messages}};
    
    # Sort the messages, newer first.
    @ids = sort { $inbox->{messages}->{$b}->{ut} <=> $inbox->{messages}->{$a}->{ut} } @ids;
    
    foreach my $id (@ids) {
        push @messages, $inbox->{messages}->{$id}; 
    }
    
    return jr({ changed => 1, ut => $inbox->{ut}, inbox => \@messages });
}

sub add_new_messages_block{

    my ($chat_id, $from_id, $xtype, $content) = @_;

    my $chat_header = obj_read("chat", $chat_id);
    
    return unless assert($chat_header, "", "ERR_CHAT_HEADER", "Invalid chat header id.");
    
    my $from_person = obj_read("person", $from_id);  
    
    # Chat message entry in a chat block.
    my $message = {
        from_name    => $from_person->{name},
        from_id      => $from_id,
        from_image   => $from_person->{avatar_fid}, 
        xtype        => $xtype, 
        content      => $content, 
        send_time    => time(),
    };
        
    $message->{from_image} = $DEFAULT_IMAGE_FID unless $message->{from_image};
        
    # This is the first message. New block will be created
    if (!$chat_header->{block_id}) {

        my $chat_block;
        
        $chat_block->{_id}     = obj_id();
        $chat_block->{type}    = "messages_block";
        $chat_block->{next_id} = 0;
        $chat_block->{records} = [];
        
        push @{$chat_block->{records}}, $message;

        obj_write($chat_block);

        $chat_header->{block_id} = $chat_block->{_id}; 
        
        obj_write($chat_header);
        
    } else {

        my $block = obj_read("messages_block", $chat_header->{block_id});
        
        my $count = $block->{records};
        
        # Maximum number of chat entries is 50.
        # This is the first message of a new block. New block will be created
        if ((scalar(@{$block->{records}}) + 1) > 50) {

            my $chat_block;
            
            $chat_block->{_id}     = obj_id();
            $chat_block->{type}    = "messages_block";
            $chat_block->{next_id} = $block->{_id};
            $chat_block->{records} = [];
            
            push @{$chat_block->{records}}, $message;

            obj_write($chat_block); 

            $chat_header->{block_id} = $chat_block->{_id};
            
            obj_write($chat_header);
            
        } else {

            push @{$block->{records}}, $message;

            obj_write($block); 
        }  
    }
    
    return 1;
}

################################################################################
#                                                                              #
#                  TEST API，TEST VARIOUS SYSTEM CAPABILITIES                  #
#                                                                              #
################################################################################
$p_test_geo = <<EOF;
MongoDB geo location LBS api test

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
#  DATA STRUCTURE DEFINITIONS - DATASTRUCTURE DEFINITIONS REQUIRED BEFORE USE  #
#                                                                              #
################################################################################
$man_ds_person = <<EOF;
user record, store personal information other than account information

    display_name:123
    
    devicetoken: unique device id
    devicetype: unique device type, android/ios ...
    
    // user personal record update time and entry time
    ut: update time
    et: entry time
EOF

$man_ds_inbox = <<EOF;
user inbox, message center

    // id of this record reuses owner's person id
    // cache the last record for each type of chat
    // for most of the push, there shall be a record here

    ut: // inbox update time

    // record the last message, and new message count for each type of message
    messages: {
    
        id1: { 
            xtype: person/topic, two party chat (private) or group chat, group chat header not used in this demo 
            id: same as id1
            ut: unix time, last update time
            vt: unix time, last visit time
            count: new message count under id1
            crid: block_record ID for id1
            lastusername: last user name in the chat
            lastcomment: last comment, message content
            fid: user avatar
            title: title, or private chat party
        }
    }
EOF

$man_ds_chat = <<EOF;
personal chat header record
    
    // chat is for two party private personal chat
    // Other forms of conversation, group conversation, conversation under certain topics
    // all have similar header structure storing group/topic data, participants, assets, members etc.
    // And each member shall have list of conversation header ids that they are part of.
    
    // Ordered two person ids.
    pair: $id1.$id2
    
    // Instead of storing header object id, paired ids of counter party and self 
    // are good enough to find the chat record.

    block_id: last message entries block record id, for new chat, this fields is set to 0
EOF

$man_ds_messages_block = <<EOF;
message entries block record, conversation messages are divided into chained blocks

    // next message entries block id. 0 if this is the first block
    // conversation header structure contains the latest block
    next_id:

    et: entry time, when this block was first created
    ut: update time, last time when this block was updated
   
    // chat entries block contains 50 entries max
    // all the new entries will be placed on new block

    records: [
    {
        from_id:     chat entry sender
        from_name:   chat entry sender
        xtype:       text/image/voice/link
        content:     chat entry content, text, file id, link address
        send_time:   chat entry timestamp
    },
    {
        from_id:     chat entry sender
        from_name:   chat entry sender
        xtype:       text/image/voice/link
        content:     chat entry content, text, file id, link address
        send_time:   chat entry timestamp
    }
    ]
EOF

$man_geotest = <<EOF;
MongoDB geo location based algorithms api test

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


