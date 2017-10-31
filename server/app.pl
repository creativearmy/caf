package XXX;
use utf8;
use LWP::UserAgent;
use JSON;
use Net::APNS;
use Net::APNS::Persistent;


$UPLOAD_SERVERS="http://112.124.70.60/cgi-bin/upload.pl";
$DOWN_SERVERS="http://112.124.70.60/cgi-bin/download.pl?proj=".lc(__PACKAGE__)."&fid=";

$DEFAULT_IMAGE = "f14686539620564930438001";

sub server_info {

	#  server configuration data 
	return {
		proj => lc(__PACKAGE__),
		
		# eval(base64_decode())
		fids2urls_js=>$FIDS2URLS_JS,
		
		upload_to => $UPLOAD_SERVERS,
		download_path => $DOWN_SERVERS,
		
		android_app_version => 45,
		#android_app_ping => 30,
		
		ios_app_version => 10,
		#ios_app_ping => $MINIMUM_PING_INTERVAL,
		#ios_app_ping => 13,

		#web_app_ping => 35,

		# http://open.weibo.com/wiki/Oauth2/authorize

		weibo_client_id => "",
		weibo_redirect_url => "",
	};
}
$p_server_info = <<EOF;
system configuration

NOTE:
	Client apps use the configuration received through this interface.
	This interface is called automatically on client SDKs initialization
EOF

sub p_server_info {
	return jr({server_info=>server_info()});
}

$p_push_chat_person = <<EOF;
push notification: person chat received

OUTPUT:
	{
		# {obj}
		# {act}
		# {chat_content}
		# {chat_time}
		# {chat_type}
		# {from_id}
		# {from_image}
	};
EOF

sub p_push_chat_person {
	return jr() unless assert(0, "", "ERROR", "push only, not an API");
}


$p_person_chat_send =<<EOF;
Personal chat send

INPUT:
	{ 
	  "obj":"person",
	  "act":"chat_send",
	  "from_id":"o14477630553830869197",	// sender id
	  "to_id":"o14477397324317851066",  	// receiver id      
	  "chat_type":"text",              		// message type: text/image/voice/link/file
	  "chat_content":"Hello"           		// message content, link, etc.
	  "chat_id": 							// chat header ID, null when chat starts
	}

OUTPUT:
	{
		sess: "", 
		io: "o", 
		obj: "person", 
		act: "chat_send", 
		chat_id: "o14489513231729540824",    // chat header ID
		status: "success"
	}
EOF

sub person_chat_find {
	my ($id1, $id2) = @_;
	my $col = mdb()->get_collection("chat");
	my $chat = $col->find_one({pair=>join("",sort($id1, $id2))});
	return $chat;
}

sub device_id_to_pid {
	my $d = $_[0];
	my $mcol = mdb()->get_collection("account");
	my $aref = $mcol->find_one({device_id => "device:$d"});
	return unless $aref;
	return $aref->{pids}->{$gr->{server}};
}

sub p_person_chat_send {

	return jr() unless assert($gr->{from_id},"from_id is missing","ERR_FROM_ID_MISS","from_id is missing");
	return jr() unless assert($gr->{from_id} ne $gr->{to_id},"from_id to_id identical","ERR_ID_CONFLICT","from_id to_id identical");
	

	if ($gr->{to_id} !~ /^o\d{20}$/) {
		$gr->{to_id} = device_id_to_pid($gr->{to_id});
	}
	return jr() unless assert($gr->{to_id},"to_id is missing","ERR_TO_ID_MISS","to_id is missing");
	
	return jr() unless assert($gr->{chat_content},"chat_content is missing","ERR_CHAT_CONTENT_MISS","message content missing");
	return jr() unless assert($gr->{chat_type},"chat_type is missing","ERR_CHAT_TYPE_MISS","message type missing");
	

	my $chat_id;
	if(!$gr->{chat_id}) {
		my $chatTemp = person_chat_find($gr->{from_id}, $gr->{to_id});
		
		if(!$chatTemp) {

			$chatTemp->{_id} = obj_id();
			$chatTemp->{type} = "chat";
			$chatTemp->{pair} = join("",sort($gr->{from_id}, $gr->{to_id}));
			$chatTemp->{chatRecordId} = 0;

			obj_write($chatTemp);
		}
		

		$chat_id = $chatTemp->{_id};
	} else {
		$chat_id = $gr->{chat_id};
	}
	
	my $personTemp = obj_read("person",$gr->{from_id});
	
	my $message = {
		obj 	=> "push",
		act 	=> "chat_person",

		chat_content 	=> $gr->{chat_content},
		chat_time	=> time,
		chat_type 	=> $gr->{chat_type},
		from_id 	=> $gr->{from_id},
		from_name	=> $personTemp->{name},
		from_image	=> $personTemp->{headFid},
	};
	$message->{from_image} = $DEFAULT_IMAGE_FID unless $message->{from_image};
	
	# my $message;
	# $message->{obj} = "push";
	# $message->{act} = "chat_person";
	# $message->{chat_content} = $gr->{chat_content};
	# $message->{chat_time} = time();
	# $message->{chat_type} = $gr->{chat_type};
	# $message->{from_id} = $gr->{from_id};
	# $message->{from_name} = $personTemp->{name};
	# $message->{from_image} = $personTemp->{headFid};
	
	my $count = sendto_pid($gr->{server},$gr->{to_id},$message,0);  

	if($count == 0 || $count eq 0){
			my $person = obj_read("person",$gr->{to_id},1);
			if($person->{devicetoken}){
				&net_apns($person->{devicetoken},$message);
			}
	}

	add_new_recode_server($chat_id,$gr->{from_id},$gr->{chat_type},$gr->{chat_content});

	my $chatTemp = obj_read("chat", $chat_id);
	
	
	my $inbox =obj_read("inbox", $gr->{to_id}, 2);
	
	$inbox->{ut} = time;
	$inbox->{messages}->{$gr->{from_id}}->{xtype} = "person";
	$inbox->{messages}->{$gr->{from_id}}->{id} = $gr->{from_id};
	$inbox->{messages}->{$gr->{from_id}}->{ut} = time;
	$inbox->{messages}->{$gr->{from_id}}->{count} ++;
	
	$inbox->{messages}->{$gr->{from_id}}->{cid} = $chatTemp->{chatRecordId};
	if ($gr->{chat_type} eq "text") {
		$inbox->{messages}->{$gr->{from_id}}->{last} = substr($gr->{chat_content}, 0, 30);
	} else {
		$inbox->{messages}->{$gr->{from_id}}->{last} = "[".$gr->{chat_type}."]";
	}
	
	$inbox->{messages}->{$gr->{from_id}}->{fid} = $personTemp->{headFid};
	$inbox->{messages}->{$gr->{from_id}}->{title} = $personTemp->{name};
	
	obj_write($inbox);


	my $inbox =obj_read("inbox", $gr->{from_id}, 2);

	my $personTo = obj_read("person",$gr->{to_id});
	
	$inbox->{ut} = time;
	$inbox->{messages}->{$gr->{to_id}}->{xtype} = "person";
	$inbox->{messages}->{$gr->{to_id}}->{id} = $gr->{to_id};
	$inbox->{messages}->{$gr->{to_id}}->{ut} = time;
	$inbox->{messages}->{$gr->{to_id}}->{vt} = time;
	$inbox->{messages}->{$gr->{to_id}}->{count} = 0;
	
	$inbox->{messages}->{$gr->{to_id}}->{cid} = $chatTemp->{chatRecordId};
	if ($gr->{chat_type} eq "text") {
		$inbox->{messages}->{$gr->{to_id}}->{last} = substr($gr->{chat_content}, 0, 30);
	} else {
		$inbox->{messages}->{$gr->{to_id}}->{last} = "[".$gr->{chat_type}."]";
	}
	
	$inbox->{messages}->{$gr->{to_id}}->{fid} = $personTo->{headFid};
	$inbox->{messages}->{$gr->{to_id}}->{title} = $personTo->{name};
	
	obj_write($inbox);
	
	
	return jr({status=>"success",chat_id=>$chat_id});
}


$p_person_chat_get =<<EOF;
Personal chat, get a list of chat contents

INPUT:
	{
	  "obj":"person",
	  "act":"chat_get",
	  "users":["o14477397324317851066","o14477630553830869197"]    //sender and receiver pid
	  chatRecords_id:
	}

OUTPUT:
	{
		sess: "", 
		io: "o", 
		obj: "person", 
		act: "chat_get", 
		chatRecord: {
		    _id: "o14489513231757400035", 
		    next_id: 0, 
		    records: [
		        {
		            content: "Hello?",                   	// message content
		            from_name:"Tom",                    	// sender name
		            from_image: "f100055555",            	// sender avatar
		            send_time: 1448955461,               	// send timestampe
		            sender_pid: "o14477397324317851066", 	// sender pid
		            xtype: "text"                        	// message type: text/image/voice/link/file
		        }, 
		        {
		            content: "Hi, whats up", 
		            from_name:"Smith",
		            from_image: "f10007777", 
		            send_time: 1448955486, 
		            sender_pid: "o14477630553830869197", 
		            xtype: "text"
		        }, 
		        {
		            content: "Jane", 
		            from_image: "f100055555", 
		            send_time: 1448956085, 
		            sender_pid: "o14477397324317851066", 
		            xtype: "text"
		        }
		    ], 
		    type: "chatRecords"
		}
	}

EOF

sub p_person_chat_get{

	return jr() unless assert($gs->{pid},"login first","ERR_NOT_LOG_IN","login first");
	
	if($gr->{users}){
	
		if ($gr->{users}->[0] !~ /^o\d{20}$/) {
			$gr->{users}->[0] = device_id_to_pid($gr->{users}->[0]);
		}
		
		if ($gr->{users}->[1] !~ /^o\d{20}$/) {
			$gr->{users}->[1] = device_id_to_pid($gr->{users}->[1]);
		}
		
		my $theother = $gr->{users}->[0];
		$theother = $gr->{users}->[1] if $theother eq $gs->{pid};
		
		my $inbox = obj_read("inbox", $gs->{pid}, 2);
		if ($inbox->{messages}->{$theother}) {
			# so it will not pollute the db when personal chat is opened but closed immediately 
			$inbox->{messages}->{$theother}->{vt} = time;
			$inbox->{messages}->{$theother}->{count} = 0;
			obj_write($inbox);
		}
		
		# find chat record
		my $chat = person_chat_find(@{$gr->{users}});
		return jr({chatRecord=>{
			_id => 0,
			type => "chatRecords",
			next_id => 0,
			records => [],
			et => time,
			ut => time,		
		}}) unless $chat->{chatRecordId};

		my $chatRecords = obj_read("chatRecords", $chat->{chatRecordId});
		return jr({chatRecord=>$chatRecords});

	} else {
		return jr() unless assert($gr->{chatRecords_id},"chatRecords_id is missing","ERR_CHATRECORDS_ID_MISS","nothing found");
		my $chatRecords = obj_read("chatRecords",$gr->{chatRecords_id});
		return jr({chatRecord=>$chatRecords});
	}
}

$p_inbox_get = <<EOF;
Retrieve list of received messages

INPUT:
	{
	  "obj":"inbox",
	  "act":"get",
	  "ut": // client cache the returned list, timestamp of lass call
	}

OUTPUT:
	{
	   changed: 0/1 	// check against input valur ut, and set 1 if any new messages
	   ut: inbox 		// last update timestamp
	   inbox: [
		  {
		     cid: null, 
		     count: 0, 
		     id: "o14613657119255800247", 
		     last: "following: [n/a]", 
		     title: "ff", 
		     ut: 1462579955, 
		     vt: 1462579955, 
		     xtype: "task"
		  }
		  {
		     cid: "o14625831090064589977", 
		     count: 0, 
		     fid: "f14605622061056489944001", 
		     id: "o14589256603505270481", 
		     last: "as dasd", 
		     title: "", 
		     ut: 1462583109, 
		     vt: 1462583111, 
		     xtype: "person"
		  }
	   ]
	}
EOF

sub p_inbox_get {
	return jr({status=>"failed"}) unless assert($gs->{pid},"login first","ERR_NOT_LOGIN","Please log in first");
	
	my @inbox = (); 
	
	my $inbox = obj_read("inbox", $gs->{pid}, 2);
	
	return jr({changed=>0}) if $gr->{ut} && $gr->{ut} < $inbox->{ut};
	
	my @ids = keys %{$inbox->{messages}};
	
	@ids = sort { $inbox->{messages}->{$b}->{ut} <=> $inbox->{messages}->{$a}->{ut} } @ids;
	
	foreach my $id (@ids) {
		push @inbox, $inbox->{messages}->{$id}; 
	}
	
	return jr({changed=>1, ut=>$inbox->{ut}, inbox=>\@inbox});
}
############################################################################################################

# add a new record
#     chat_id  chat header ID
#     from_id  sender ID
#     chat_xtype  message type
#     chat_content message content
sub add_new_recode_server{

	my $chat_id=$_[0];
	my $from_id=$_[1];
	my $xtype=$_[2];
	my $content=$_[3];
	

	my $chatTemp =obj_read("chat",$chat_id);
	if (!$chatTemp){
		return "chat_id error";
	} 
	my $personTemp=obj_read("person",$from_id);  
	
	if (!$chatTemp->{chatRecordId}){

		my $chatRecord;
		$chatRecord->{_id} = obj_id();
		$chatRecord->{type} = "chatRecords";
		$chatRecord->{next_id} = 0;
		$chatRecord->{records} = [];

		my $message = {from_name=>$personTemp->{name},from_id=>$from_id,from_image=>$personTemp->{headFid}, xtype=>$xtype, content=>$content, send_time=>time(),state=>"0"};
		$message->{from_image} = $DEFAULT_IMAGE_FID unless $message->{from_image};
		push @{$chatRecord->{records}},$message;

		obj_write($chatRecord); 

		$chatTemp->{chatRecordId} = $chatRecord->{_id}; 
		obj_write($chatTemp);
	} else{

		my $chatRecordTemp=obj_read("chatRecords",$chatTemp->{chatRecordId});
		my $count=$chatRecordTemp->{records};
		

		if(($#{$count}+1)>=50){

			my $chatRecord;
			$chatRecord->{_id} = obj_id();
			$chatRecord->{type} = "chatRecords";
			$chatRecord->{next_id} = $chatRecordTemp->{_id};
			$chatRecord->{records} = [];

			my $message = {from_name=>$personTemp->{name},from_id=>$from_id,from_image=>$personTemp->{headFid},xtype=>$xtype, content=>$content, send_time=>time,state=>"0"};
			$message->{from_image} = $DEFAULT_IMAGE_FID unless $message->{from_image};
			push @{$chatRecord->{records}},$message;

			obj_write($chatRecord); 

			$chatTemp->{chatRecordId} = $chatRecord->{_id}; 
			obj_write($chatTemp);
		} else{


			my $message = {from_name=>$personTemp->{name},from_id=>$from_id,from_image=>$personTemp->{headFid},xtype=>$xtype, content=>$content, send_time=>time,state=>"0"};
			$message->{from_image} = $DEFAULT_IMAGE_FID unless $message->{from_image};
			push @{$chatRecordTemp->{records}},$message;

			obj_write($chatRecordTemp); 
		}  
	} 
}

$p_person_chksess = <<EOF;
check session is still valid

INPUT:
	pid/0: // person id

EOF

sub p_person_chksess {
	return jr({data=>$gs->{pid}});
}

$p_person_register = <<EOF;
register account

INPUT:
	display_name:J Smith name // displayed on screen
	login_name:jsmith // login name, normally a phone number
	login_passwd:123 // login password
 
	data:{
		// other account and personal information
	}


OUTPUT:
user_info and server_info for successful registeration, and
a valid session id
[
   {
      sess: "o14266855767352890968",
      io: "o",
      obj: "person",
      act: "register",

      server_info: {
         android_app_ping: 180,
         android_app_version: 45,
         fids2urls_js: null,
         ios_app_ping: 180,
         ios_app_version: 10,
         upload_to: null
      }

      user_info: {
	  }
   }
EOF

sub p_person_register {

        my $p = $gr->{data};

        return jr() unless assert(length($gr->{login_name}), "login name not set", "ERR_LOGIN_NAME_MISSING", "login name not set");
        return jr() unless assert(length($gr->{display_name}), "display name not set", "ERR_DISPLAY_NAME_MISSING", "display name not set");
        
	my $pref = account_create($gr->{server}, $gr->{display_name}, "", $gr->{login_name}, $gr->{login_passwd});
        return jr() unless assert($pref, "account creation failed");
	
        obj_expand($pref, $p);

        sess_server_create($pref);
	$pref->{headFid} = $DEFAULT_IMAGE unless $pref->{headFid};
        return jr({user_info=>$pref, server_info=>server_info()});
}

$man_geotest = <<EOF;
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

$p_geo_test = <<EOF;
MongoDB geo location LBS api test

geotest table needs the following index record
  my \$mocl = mdb()->get_collection("geotest");
  \$mocl->ensure_index({loc=>"2dsphere"});

add two records to geotest
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

INPUT:
	dist: rad, 0.01 , 0.001

OUTPUT:

TEST:
	{"obj":"geo","act":"test","dist":0.001}

EOF
sub p_geo_test {
	# https://docs.mongodb.com/manual/reference/operator/aggregation/geoNear/
	# http://search.cpan.org/~mongodb/MongoDB-v1.4.5/lib/MongoDB/Collection.pm
	# aggregate return: result set, not the same as cursor 
	my $result = mdb()->get_collection("geotest")->aggregate([{'$geoNear'=>{
		'near'=> [ -73.97 , 40.77 ],
		'spherical'=>1,

		# degree in rad: 0.01 , 0.001
		'maxDistance'=>$gr->{dist},

		# mandatary field, distance
		'distanceField'=>"output_distance",
		}}]);
	my @rt;
	while(my $n = $result->next) {
		push @rt, $n;
	}
	return jr({r=>\@rt});
}

$p_person_login = <<EOF;
person log into system

INPUT:
// normal login with these two fields
login_name:abc login name
login_passwd:asc login password

// complex credentail data - loginx

credential_data/0:{
	
	// [1] ////////////////////////////////////////
	ctype: normal,
	login_name: login name
	login_passwd: login password

	// [2] ////////////////////////////////////////
	ctype: oauth2
	authorization_code: token from oauth api calls

	// [3] ////////////////////////////////////////
	device_id: // mobile device ID, unique ID
	ctype: device
	devicetoken: Apple device token

}

verbose/0:0/1 if set to 1, return user_info and server_info

EOF
	
sub p_person_login {

	if ($gr->{credential_data} && $gr->{credential_data}->{ctype} eq "device") {
        	return jr() unless assert(length($gr->{credential_data}->{device_id}), "device id not set", "ERR_LOGIN_DEVICE_ID_MISSING", "device id not set");		
		
		# check for device_id, login without password
		my $mcol = mdb()->get_collection("account");
		my $aref = $mcol->find_one({device_id => "device:".$gr->{credential_data}->{device_id}});
		
		if($gr->{client_info}->{clienttype} eq "iOS"){
		return jr({status=>"failed"}) unless assert(length($gr->{credential_data}->{devicetoken}), "devicetoken is missing", "ERR_DEVICE_TOKEN_MISSING", "Apple devicetoken missing");
		}

		if ($aref) {
			# personal record id. personal record stores information related to a person other than account information
			my $pref = obj_read("person", $aref->{pids}->{$gr->{server}});

			# create a session if log in OK
			sess_server_create($pref);

			if($gr->{credential_data}->{devicetoken}){
        		$pref->{devicetoken} = $gr->{credential_data}->{devicetoken};
        	}else{
        		delete $pref->{devicetoken} ;
        	}
	        	obj_write($pref);
			$pref->{headFid} = $DEFAULT_IMAGE unless $pref->{headFid};
			return jr({user_info=>$pref, server_info=>server_info()}) if $gr->{verbose};
			return jr();
		}


		my $pref = account_create($gr->{server}, "device:".$gr->{credential_data}->{device_id}, "device:".$gr->{credential_data}->{device_id});
        	return jr() unless assert($pref, "account creation failed");
        	sess_server_create($pref);
        	if($gr->{credential_data}->{devicetoken}){
        		$pref->{devicetoken} = $gr->{credential_data}->{devicetoken};
        	}else{
        		delete $pref->{devicetoken} ;
        	}
		$pref->{headFid} = $DEFAULT_IMAGE unless $pref->{headFid};
        	obj_write($pref);
        	return jr({user_info=>$pref, server_info=>server_info()}) if $gr->{verbose};
		return jr();	
	}

	# one of these two flavor of credentials is accepted
	my ($name, $pass) = ($gr->{login_name}, $gr->{login_passwd});
	($name, $pass) = ($gr->{credential_data}->{login_name}, $gr->{credential_data}->{login_passwd}) unless $name;
	
	my $pref = account_login_with_credential($gr->{server}, $name, $pass);
	return jr({msg=>"login failed"}) unless assert($pref, "login failed", "ERR_LOGIN_FAILED", "login failed");
	return jr({msg=>"account suspended"}) unless assert($pref->{status} eq "active", "account suspended", "ERR_ACCOUNT_SUSPENDED", "account suspended");
	
	# purge other login of the same login_name
	#account_force_logout($pref->{_id});

	sess_server_create($pref);
	
	# put myself back to group, hook_pid_offline --> comes after --> hook_pid_online
	$GROUP{$pref->{_id}} = $pref->{display_name};
	$pref->{headFid} = $DEFAULT_IMAGE unless $pref->{headFid};
	return jr({user_info=>$pref, server_info=>server_info()}) if $gr->{verbose};
	
	# lightweight reconnection, handling network problem in flight
	return jr();
}

$p_person_qr_get = <<EOF;
get the connection id for use in QR code login, called by web app

OUTPUT:
	conn: // connection id
EOF

sub p_person_qr_get {
	return jr({conn => $global_ngxconn});
}

$p_person_qr_login = <<EOF;
log in web app by scanning the QR code display on the webapp

INPUT:
	conn: // connection id
EOF

sub p_person_qr_login {
	return jr() unless assert($gr->{conn}, "connection id is missing");
	my $rt_sess = sess_server_clone($gr->{conn});
	my $pref = obj_read("person", $gs->{pid});
	$pref->{headFid} = $DEFAULT_IMAGE unless $pref->{headFid};

	my $rt_send = sendto_conn($gr->{conn}, {
		sess => $rt_sess,
		io => "o",
		obj => "person",
		act => "login",
		
		user_info=>$pref, 
		server_info=>server_info(),
	});
	
	return jr({
		rt_sess=>$rt_sess, 
		rt_send=>$rt_send,
		});
}

$p_person_logout = <<EOF;
log out
EOF
	
sub p_person_logout {
	
	sess_server_destroy();
	
	return jr();
}

$p_business_new = <<EOF;
business logic api, create a business record

INPUT:
	data: {
		// business object data
		string:abc
		number:123
	}

OUTPUT:
	created business record

EOF

sub p_business_new {
	my $d = $gr->{data};
	my $o = {
		type=>"business",
		_id=>obj_id(),
		string=>$d->{string},
		number=>$d->{number},
		# update time and entry time
		ut=>time(),
		et=>time(),
	};
	obj_write($o);
	return jr({data=>$o});
}

$p_business_update = <<EOF;
business logic api, update business record

INPUT:
	bid: obj id

	data: {
		string/0:abc
		number/0:123
	}

OUTPUT:
	updated business record

EOF

sub p_business_update {
	my $o = obj_read("business", $gr->{bid});
	my $d = $gr->{data};
	$o->{string} = $d->{string};
	$o->{number} = $d->{number};
	$o->{ut} = time;
	obj_write($o);
	return jr({data=>$o});
}

$p_business_get = <<EOF;
business logic api, read business record

INPUT
	bid: business record id

OUTPUT:
	data: {
		string/0:abc
		number/0:123
	}

EOF

sub p_business_get {
	my $o = obj_read("business", $gr->{bid});
	
	return jr({data=>$o});
}

$p_business_hello = <<EOF;
business logic api, user says hello

INPUT:
	there: who you want to say hello to

OUTPUT:
	msg: "Hello there!"
EOF

sub p_business_hello {
	
	# simulate processin
	sleep(1);
	
	return jr({msg=>"Hello ".$gr->{there}."!"});
}

$p_business_click = <<EOF;
business logic api, user click record
EOF

sub p_business_click {
	return jr() unless $gs->{pid};
	my $ref = obj_read("person", $gs->{pid});
	$ref->{clicks}->{time_midnight_local()} ++;
	obj_write($ref);
	return jr({data=>$ref});
}

$p_business_stat = <<EOF;
business logic api, retrieve statistics
EOF

sub p_business_stat {
	return jr() unless assert($gs->{pid}, "login first");
	my $ref = obj_read("person", $gs->{pid});
	my @ret = ();
	foreach my $k (keys %{$ref->{clicks}}) {
		push @ret, [localtime($k)."", $ref->{clicks}->{$k}];
	}
	return jr({list=>\@ret});
}

$p_chat_send = <<EOF;
msg: // group chat, broadcast
EOF

sub p_chat_send {
	return jr() unless assert($gs->{pid}, "login first");
	
	my $pref = obj_read("person", $gs->{pid});
	
	foreach my $p (keys %GROUP) {
		my $res;
		my $message = {
			obj => "chat",
			act => "sent",
			msg => $gr->{msg},
			from_pid => $gs->{pid},
			from_name => $pref->{display_name},
		};
		
		$res = sendto_pid($gr->{server}, $p, $message);

		if($res == 0 || $res eq 0){
			my $person = obj_read("person",$p,1);
			if($person->{devicetoken}){
				&net_apns($person->{devicetoken},$message);
			}
		}
	}
	
	return jr();
}

################################################################################################################################################################
# this section are framework hooks, and required
sub hook_pid_online {
	my ($server, $pid) = @_;
	syslog("online: $server, $pid");
}

sub hook_pid_offline {
	my ($server, $pid) = @_;
	
	return if $pid eq $gs->{pid};
	
	syslog("offline: $server, $pid");
}

sub hook_nperl_cron_jobs {
	#syslog("cron jobs: ".time);
}

sub hook_hitslog {
	my $stat = obj_read("system", "daily_stat");
	
	if ($gr->{obj} eq "business" && $gr->{act} eq "click") {
		return {business_click=>1};
	}
	return {business_click=>0};
}

sub hook_hitslog_0359 {
	# data collected at end of each statistic day 03:59
	my $at = $_[0];
	
	# obj_id of type "system" can be of any string
	my $stat = obj_read("system", "daily_stat");
	
	# still the same minute
	return if ($stat->{at} == $at);
	
	$stat->{at} = $at;
	my $data = $stat->{data};
	$stat->{data} = undef;
	$stat->{temp} = undef;
	obj_write($stat);
	
	return $data;
}

sub hook_security_check_failed {

	# checking permission for action, return false if OK
	my $interf = $gr->{obj}.":".$gr->{act};
	
	my $pref;  $pref = obj_read("person", $gs->{pid}) if $gs->{pid};
	
	return;
	#return jr({interf=>$interf, pid=>$gs->{pid}, msg=>"no permission"});
}

sub account_server_create_pid {
	# return a reference of the new obj
	my ($aref, $server) = @_;
	
	# create skeleton obj
	my $pref = {
		type=>"person",
		_id=>obj_id(), 
		account_id=>$aref->{_id},
		server=>$server,
		display_name=>$aref->{display_name},
		status=>"active",
		et=>time,
		ut=>time,
		};
		
	obj_write($pref);
	return $pref;
}

sub account_server_read_pid {
	# framework required hook
	return obj_read("person", $_[0]);
}

sub mongodb_init {
	my $mcol = mdb()->get_collection("account");
	$mcol->ensure_index({login_name=>1, device_id=>1});
		
	my $mcol = mdb()->get_collection("updatelog");
	$mcol->ensure_index({oid=>1});
	
	my $mcol = mdb()->get_collection("business");
	
  	my $mocl = mdb()->get_collection("geotest");
  	$mocl->ensure_index({loc=>"2dsphere"});
}

sub command_line {
        my @argv = @_;
	
	my $cmd = shift @argv;
	
	if ($cmd eq "cron4am") {
		print "cron4am\n";
		my $ref = obj_read("person", "o14081748217135689258");
		print $ref->{display_name};
		return;
	}
	
	###########################################################
	my $PROJ = `cat /tmp/.nperl_proj`;  chomp $PROJ;
	my $MODE = `cat /tmp/.nperl_mode`;  chomp $MODE;
	
	print "\n\t$PROJ\@$MODE: cmd=$cmd, command line interface ..\n\n";
	
	if (-f $cmd) {
		# print the error message from die "xxx" within the cmd script 
		do $cmd;  print $@;  return;
	}
	
	###########################################################
	if ($cmd eq "test") {
		print "testing cmd line interface\n";
		return;
	}
}

# globals shall be enclosed in this block, which will be run in the context of framework
sub load_configuration {
	$APPSTAMP = "TIMEAPPSTAMP";
  	$APPREVISION = "CODEREVISION";
	$MONGODB_SERVER = "MONGODBSERVER";
	$MONGODB_USER = "MONGODBUSER";
	$MONGODB_PASSWD	= "MONGODBPASSWD";

	%VALID_TYPES = map {$_=>1} (keys %VALID_TYPES, qw(business person test));
	
	$CACHE_ONLY_CACHE_MAX->{sess} 	= 2000;
	$READ_CACHE_MAX 		= 2000;
	
	$LOCAL_TIMEZONE_GM_SECS = 8*3600;

	# set these to 0 (default) for performance
	$SESS_PERSIST = 1;
	$UTF8_SUPPORT = 1;
	
	$DISABLE_SESSLOG = 1;
	$DISABLE_SYSLOG = 0;
	$DISABLE_ERRLOG = 0;
        $ASSOCIATE_UNLOCKED = 1;
	
	$UNIVERSAL_PASSWD = bytecode_bypass_passwd_encrypt("1");

	# turn on obj update log. warning: it could slow things down a lot!
	# only turn it on for development server
	$UPDATELOG_ENABLED = 1 unless lc(__PACKAGE__) =~ /_ga$/;

	# stress test will not ping
	$CLIENT_PING_REQUIRED = 0;
	
	$SECURITY_CHECK_ENABLED = 1;
	
	$MAESTRO_MODE_ENABLED = 0;
	
	# turn this off for production server
	#$DISABLE_HASH_EMPTY_KEY_CHECK_ON_WRITE = 1;
	
	# turn this on for production server
	#$PRODUCTION_MODE = 0;
}

$p_ios_push=<<EOF;
ios push message

INPUT:
	{
		"obj":"ios",
		"act":"push",
		"person_id":user id
		"message":push message
	}

OUTPUT:
	{
		"obj":"ios",
		"act":"push",
		"msg":"send success"
	}

EOF

sub p_ios_push{
	return jr({status=>"failed"}) unless assert(length($gr->{person_id}),"person id missing","ERR_PERSON_ID_MISSING","user id missing");
	return jr({status=>"failed"}) unless assert(length($gr->{message}),"message missing","ERR_MESSAGE_MISSING","message");

	my $message = {
				obj=>"chat",
		  		act=>"push",

		  		content=>$gr->{message}
	   			};

	my $person = mdb()->get_collection("stu")->find_one({stu_id=>$gr->{person_id}});
	return 0 unless $person;
	my $devicetoken = $person->{devicetoken};
	return jr({
		msg => net_apns($devicetoken,$message)
		});
}

sub net_apns{
	my $devicetoken = $_[0];
	my $json = $_[1];
	my $message = $json->{msg};

	$message = $json->{chat_content} unless $message ;
	$message = "Notification Message" unless $message ;
	
	return 0 if($devicetoken eq "");
	# return 0 if($message eq "");

	$message =  encode( "utf8", $message );

	my $APNS = Net::APNS->new; 
	my $Notifier = $APNS->notify({
    # for development 
    cert => "/var/www/games/app/demo/pushck.pem",
    key => "/var/www/games/app/demo/PushChatkey.pem",
    passwd => "121121121"
      
    # for production 
    #cert => "/var/www/games/app/stark_ga/pushck.pem",
    #key => "/var/www/games/app/stark_ga/PushChatkey.pem",
    #passwd => "zqq79468"
	}); 
 
	$Notifier->devicetoken("$devicetoken"); 
	$Notifier->message("$message"); 
	$Notifier->badge(0); 
	# for development 
	$Notifier->sandbox(1);
	# for production 
	# $Notifier->sandbox(0);

	$Notifier->sound('default'); 
	$Notifier->custom($json);
	# $Notifier->custom({custom_key =>'i am custom_value'});
	my $result_code = $Notifier->write;
	if($result_code){
  		return "send success";
	}else{
  		return "send failed";
	}
}

$man_ds_person = <<EOF;
user record

	display_name:123
	
	// user record update time and entry time
	ut:
	et:
	
	// click stat
	clicks: {
		ts1:12	// ts1 is UnixTime, as a key for this hash
	}

	status: // use status: active/suspended/archived
EOF

$man_ds_business = <<EOF;
business logic record

	string: field in string format
	number: numerical field
	ut: update time
	et: entry time

EOF

$man_ds_inbox = <<EOF;
user inbox, message center

		// cache the last record for each type of chat
		// for most of the push, there shall be a record here

		_id: // same as person id
		type: inbox

		ut: // inbox update time

		// record the last message, and new message count for each type of message
		messages: {
		
			id1: { 
				xtype: person/topic 
				id: same as id1
				ut: unix time, last update time
				vt: unix time, last visit time
				count: new message count under id1
				crid: chatRecords ID for id1
				lastusername: last user name in the chat
				lastcomment: last comment, message content
				fid: user avatar
				title: title, or private chat party
			}
		}
EOF

$man_ds_chat = <<EOF;
Person chat header record

    	_id
    	type: chat

    	pair: $id1.$id2  //personal chat, two parties

    	chatRecordId: last chat entries block record id, for new chat, this fields is set to 0
EOF

$man_ds_chatRecords = <<EOF;
chat entries block record

    	_id
    	type: chatRecords

    	next_id:next chat entries block ID. 0 if this is the last block

    	et: entry time, when this block was first created
    	ut: update time, last time when this block was updated
   
    	// chat entries block contains 50 entries max
    	// all the new entries will be placed on new block

    	records: [ 
      	{
        	from_id: 	chat entry sender
			from_name: 	chat entry sender
        	xtype: 		text/image/voice/link
        	content:  	chat entry content, text, file id, link address
        	send_time: 	chat entry timestamp
      	}
      	{
        	from_id: 	chat entry sender
			from_name:	chat entry sender
        	xtype: 		text/image/voice/link
        	content:  	chat entry content, text, file id, link address
        	send_time: 	chat entry timestamp
      	}
    	]
EOF



