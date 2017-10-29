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
		# 服务端配置的用于微博平台的登录用的
		weibo_client_id => "",
		weibo_redirect_url => "",
	};
}
$p_server_info = <<EOF;
获取系统配置信息
返回: 
打印出服务端的配置信息
客户端可以使用这里的配置，以后更新，配置也都在这里
EOF

sub p_server_info {
	return jr({server_info=>server_info()});
}

$p_push_chat_person = <<EOF;
非接口，推送：私聊对方会收到
推送:
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
	return jr({msg=>"非接口，其他接口调用导致的或系统发生的推送"});
}


$p_person_chat_send =<<EOF;
私聊发送
输入:
{ 
  "obj":"person",
  "act":"chat_send",
  "from_id":"o14477630553830869197",      //发送者id
  "to_id":"o14477397324317851066",        //接收者id， 或者对方业务账号（非IM账号），会自动转换成对方的自动注册的 oXXX ID       
  "chat_type":"text",                     //消息类型text/image/voice/link/file文字内容,图片ID，或 语音ID，或 链接地址 文件
  "chat_content":"你好"                   //发送的内容文字内容,图片ID，或 语音ID，或 链接地址 文件
  "chat_id": // 一开始没有ID
}
输出:
{
    sess: "", 
    io: "o", 
    obj: "person", 
    act: "chat_send", 
    chat_id: "o14489513231729540824",    //聊天id
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

	return jr() unless assert($gr->{from_id},"from_id is missing","ERR_FROM_ID_MISS","发送者ID丢失");
	return jr() unless assert($gr->{from_id} ne $gr->{to_id},"from_id to_id same","ERR_ID_CONFLICT","发送者ID就是接受者");
	
	# 如果 to_id 不是规范ID 我们当做 设备ID处理，自动做个转换
	if ($gr->{to_id} !~ /^o\d{20}$/) {
		$gr->{to_id} = device_id_to_pid($gr->{to_id});
	}
	return jr() unless assert($gr->{to_id},"to_id is missing","ERR_TO_ID_MISS","接受者ID丢失");
	
	return jr() unless assert($gr->{chat_content},"chat_content is missing","ERR_CHAT_CONTENT_MISS","信息内容丢失");
	return jr() unless assert($gr->{chat_type},"chat_type is missing","ERR_CHAT_TYPE_MISS","信息类型丢失");
	
	#判断chat_id是否存在，不存在需要在chat表中查询是否有相应的ID 没有就生成新的ID
	my $chat_id;
	if(!$gr->{chat_id}) {
		#没有chat_id，去表中查询
		#根据from_id与to_id在user中查找符合的记录
		my $chatTemp = person_chat_find($gr->{from_id}, $gr->{to_id});
		
		if(!$chatTemp) {
			#如果聊天记录表中没有两者的聊天记录，就新建一个聊天记录表
			$chatTemp->{_id} = obj_id();
			$chatTemp->{type} = "chat";
			$chatTemp->{pair} = join("",sort($gr->{from_id}, $gr->{to_id}));
			$chatTemp->{chatRecordId} = 0;
			#保存到数据库中
			obj_write($chatTemp);
		}
		
		#赋值给局部变量
		$chat_id = $chatTemp->{_id};
	} else {
		$chat_id = $gr->{chat_id};
	}
	
	my $personTemp = obj_read("person",$gr->{from_id});
	
	my $message = {
		obj 	=> "push",
		act 	=> "chat_person",
		#说明当前推送的是什么类型的推送，客户端根据这个判断该如何处理此通知
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
	
	#给用户发送消息 
	my $count = sendto_pid($gr->{server},$gr->{to_id},$message,0); #(?最后一个参数0具体含义？多点登录端口是否都会推送？第二个参数是否支持数组？) 

	if($count == 0 || $count eq 0){
			my $person = obj_read("person",$gr->{to_id},1);
			if($person->{devicetoken}){
				&net_apns($person->{devicetoken},$message);
			}
	}

	#保存消息记录到聊天记录表中
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
私聊接收消息
输入:
{
  "obj":"person",
  "act":"chat_get",
  "users":["o14477397324317851066","o14477630553830869197"]    //发送，接收者的id
  chatRecords_id // 或者这个，下拉时
}
输出:
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
                content: "在",                       //发送内容
                from_name:"黄浩",                    //发送者的名字
                from_image: "f100055555",            //发送者的头像
                send_time: 1448955461,               //发送信息的时间
                sender_pid: "o14477397324317851066", //发送者ID
                xtype: "text"                        //消息类型text/image/voice/link/file文字内容图片ID，或 语音ID，或 链接地址 文件
            }, 
            {
                content: "恩恩", 
                from_name:"桃发",
                from_image: "f10007777", 
                send_time: 1448955486, 
                sender_pid: "o14477630553830869197", 
                xtype: "text"
            }, 
            {
                content: "那个啥", 
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
		
		#查找chat记录
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
		return jr() unless assert($gr->{chatRecords_id},"chatRecords_id is missing","ERR_CHATRECORDS_ID_MISS","已经到尽头了");
		my $chatRecords = obj_read("chatRecords",$gr->{chatRecords_id});
		return jr({chatRecord=>$chatRecords});
	}
}

$p_inbox_get = <<EOF;
获取收件箱内容接口，用于展示消息中心

输入:
{
  "obj":"inbox",
  "act":"get",
  "ut": 客户端缓存的上次返回列表时间
}
输出:
{
   changed: 0/1 如果输入 ut, inbox 内容是不是改变了
   ut: inbox 内容改变时间
   inbox: [
      { // inbox 内容参见 inbox 数据结构定义
      },
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
	return jr({status=>"failed"}) unless assert($gs->{pid},"login first","ERR_NOT_LOGIN","请登录");
	
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
################################################################子程序############################################################################################################

#增加一个聊天记录
#     chat_id  聊天记录表的ID
#     from_id  消息发送者的ID
#     chat_xtype  消息发送的类型
#     chat_content 消息内容
sub add_new_recode_server{

	my $chat_id=$_[0];
	my $from_id=$_[1];
	my $xtype=$_[2];
	my $content=$_[3];
	
	#先判断chat_id表中所悬挂的聊天块是否存在
	my $chatTemp =obj_read("chat",$chat_id);
	if (!$chatTemp){
		return "chat_id error";
	} 
	my $personTemp=obj_read("person",$from_id);  
	
	if (!$chatTemp->{chatRecordId}){
		#不存在的话就要新建一个聊天记录块,并且和chat表挂钩
		my $chatRecord;
		$chatRecord->{_id} = obj_id();
		$chatRecord->{type} = "chatRecords";
		$chatRecord->{next_id} = 0;
		$chatRecord->{records} = [];
		#构造一条消息
		my $message = {from_name=>$personTemp->{name},from_id=>$from_id,from_image=>$personTemp->{headFid}, xtype=>$xtype, content=>$content, send_time=>time(),state=>"0"};
		$message->{from_image} = $DEFAULT_IMAGE_FID unless $message->{from_image};
		push @{$chatRecord->{records}},$message;
		#保存到数据库中
		obj_write($chatRecord); 
		#更新chat中的最近聊天块
		$chatTemp->{chatRecordId} = $chatRecord->{_id}; 
		obj_write($chatTemp);
	} else{
		#如果存在chatrecordsID,
		my $chatRecordTemp=obj_read("chatRecords",$chatTemp->{chatRecordId});
		my $count=$chatRecordTemp->{records};
		
		#判断当聊天记录是否已经满50条了
		if(($#{$count}+1)>=50){
			#满足50条了，就要创建新的聊天块
			my $chatRecord;
			$chatRecord->{_id} = obj_id();
			$chatRecord->{type} = "chatRecords";
			$chatRecord->{next_id} = $chatRecordTemp->{_id};
			$chatRecord->{records} = [];
			#构造一条消息
			my $message = {from_name=>$personTemp->{name},from_id=>$from_id,from_image=>$personTemp->{headFid},xtype=>$xtype, content=>$content, send_time=>time,state=>"0"};
			$message->{from_image} = $DEFAULT_IMAGE_FID unless $message->{from_image};
			push @{$chatRecord->{records}},$message;
			#保存到数据库中
			obj_write($chatRecord); 
			#更新chat中的最近聊天块
			$chatTemp->{chatRecordId} = $chatRecord->{_id}; 
			obj_write($chatTemp);
		} else{
			#没有满足50条则继续写入
			#构造一条消息
			my $message = {from_name=>$personTemp->{name},from_id=>$from_id,from_image=>$personTemp->{headFid},xtype=>$xtype, content=>$content, send_time=>time,state=>"0"};
			$message->{from_image} = $DEFAULT_IMAGE_FID unless $message->{from_image};
			push @{$chatRecordTemp->{records}},$message;
			#保存到数据库中
			obj_write($chatRecordTemp); 
		}  
	} 
}

$p_person_chksess = <<EOF;
检验session
pid/0: // person id
EOF

sub p_person_chksess {
	return jr({data=>$gs->{pid}});
}

$p_person_register = <<EOF;
注册用户 (待修改)
输入：  

普通注册
	display_name:J Smith 注册是昵称/显示名字
	login_name:jsmith 登录名
	login_passwd:123 密码
 
	data:{
		//其他信息可以放在这个结构 
	}

返回：
如果成功注册，会返回两个字段 user_info 和 server_info
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
MongoDB 地理计算LBS 例子 geo:test
geotest 表要建立下面索引
  my \$mocl = mdb()->get_collection("geotest");
  \$mocl->ensure_index({loc=>"2dsphere"});

在geotest 表插入下面两个数据
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

输入:{
	dist: 半径, 0.01 , 0.001
}
输出:{
}

测试例子: {"obj":"geo","act":"test","dist":0.001}

EOF
sub p_geo_test {
	# https://docs.mongodb.com/manual/reference/operator/aggregation/geoNear/
	# http://search.cpan.org/~mongodb/MongoDB-v1.4.5/lib/MongoDB/Collection.pm
	# aggregate 返回的是 result set, 和 cursor 还不一样
	my $result = mdb()->get_collection("geotest")->aggregate([{'$geoNear'=>{
		'near'=> [ -73.97 , 40.77 ],
		'spherical'=>1,
		# 弧度 rad, 比如0.01 , 0.001
		'maxDistance'=>$gr->{dist},
		# 这个字段是必须的, 就是返回的点离上面点的距离
		'distanceField'=>"output_distance",
		}}]);
	my @rt;
	while(my $n = $result->next) {
		push @rt, $n;
	}
	return jr({r=>\@rt});
}

$p_userdata_useradd = <<EOF;
增加手机注册用户接口
		"type":"userdata",
		"_id":"obj_id()",
		"ut":"time()",
		"et":"time()",
		"phonenumber:"phonenumber",
		"authcode:"authcode",
		"password":"password",
		"scale":"scale",
		"company_name":"company_name",
		"company_address":"company_address",
		"email":"email"
		status:active/suspended/archived

EOF

sub p_userdata_useradd {
	my $d = $gr->{data};
	my $new = {
		type=>"userdata",
		_id=>obj_id(),
		ut=>time(),
		et=>time(),
		phonenumber=>$d->{phonenumber},
		authcode=>$d->{authcode},
		password=>$d->{password},
		scale=>$d->{scale},
		company_name=>$d->{company_name},
		company_address=>$d->{company_address},
		email=>$d->{email},
	};
	obj_write($new);
	return jr({mgs=>$new});
}

$p_userdata_userdel = <<EOF;
删除手机注册用户接口
	输入：
		_id	//用户唯一标识符
	输出：
		被指定_id的用户数据删除成功

EOF

sub p_userdata_userdel {
	my $did = $gr->{data};
	obj_delete("userdata",$gr->{_id});
	return jr({msg=>$gr->{_id}."'s userdata delete sucess!"});
}

$p_userdata_usersearch = <<EOF;
查找手机注册用户接口
	输入：
		_id	//用户唯一标识符
	输出：
		指定_id用户的所有数据信息

EOF

sub p_userdata_usersearch {
	my $d = $gr->{data};
	my $user = obj_read("userdata",$gr->{_id});
	return jr({msg=>$user});
}

$p_userdata_userupdate = <<EOF;
更新手机注册用户接口
	输入：
		_id	//用户唯一标识符
		data 	//用户需要更新的数据
	输出：
		更新后用户的新的数据信息

EOF

sub p_userdata_userupdate {
	#判断输入是否指定id
	return jr({msg=>"failed"}) unless assert($gr->{_id}, "user _id is missing");
	#判断输入id是否存在
	my $old_user = obj_read("userdata",$gr->{_id});
	return jr({msg=>"this _id is no recored"}) unless assert($old_user, "this _id is no exists");
	#判断输入是否包含更新数据
	my $d = $gr->{data};
	return jr({msg=>"no new data to update"}) unless assert($d,"no new data input");

	$old_user->{phonenumber} = $d->{phonenumber} unless !$d->{phonenumber};
	$old_user->{password} = $d->{password} unless !$d->{password};
	$old_user->{scale} = $d->{scale} unless !$d->{scale};
	$old_user->{company_name} = $d->{company_name} unless !$d->{company_name};
	$old_user->{company_address} = $d->{company_address} unless !$d->{company_address};
	$old_user->{email} = $d->{email} unless !$d->{email};
	obj_write($old_user);
	return jr({msg=>$old_user});
}

$p_person_qr_login = <<EOF;
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

$p_person_login = <<EOF;
登录

输入：
// 客户端SDK调用： credential（login_name， login_passwd）
login_name:abc 登录名
login_passwd:asc 密码

// 另一种登录也支持: credentialx（credential_data）
credential_data/0:{
	
	// [1] ////////////////////////////////////////
	ctype: normal,
	login_name:登录名
	login_passwd密码 

	// [2] ////////////////////////////////////////
	// http://open.weibo.com/wiki/Oauth2/authorize
	// 或者用微博第三方登录，这里放客户端用户授权后获得的 authorization code
	// 手机客户端用webview 或可能的SDK，展示给 用户，并使用服务端配置项
	// server_info.weibo_client_id, server_info.weibo_redirect_url
	ctype: weibo
	authorization_code: 客户端用户授权后获得的

	// [3] ////////////////////////////////////////
	device_id: // 用设备号登录，自动注册
	ctype: device
	devicetoken:如果是苹果设备，则需要传入最新的devicetoken

}

verbose/0:0/1 要不要返回user_info 和 server_info

EOF
	
sub p_person_login {

	if ($gr->{credential_data} && $gr->{credential_data}->{ctype} eq "device") {
        	return jr() unless assert(length($gr->{credential_data}->{device_id}), "device id not set", "ERR_LOGIN_DEVICE_ID_MISSING", "device id not set");		
		
		# 先查看看缓存有没有 帐号用过这个 authorization_code
		my $mcol = mdb()->get_collection("account");
		my $aref = $mcol->find_one({device_id => "device:".$gr->{credential_data}->{device_id}});
		
		if($gr->{client_info}->{clienttype} eq "iOS"){
		return jr({status=>"failed"}) unless assert(length($gr->{credential_data}->{devicetoken}), "devicetoken is missing", "ERR_DEVICE_TOKEN_MISSING", "苹果设备devicetoken信息丢失");
		}

		if ($aref) {
			# 帐号这个字段保存 pid
			my $pref = obj_read("person", $aref->{pids}->{$gr->{server}});

			# 直接创建会话，登录成功
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

	if ($gr->{credential_data} && $gr->{credential_data}->{ctype} eq "weibo") {
		# 没有测试，只是伪码

		# 先查看看缓存有没有 帐号用过这个 authorization_code
		my $mcol = mdb()->get_collection("account");
		my $aref = $mcol->find_one({authorization_code => "weibo:".$gr->{credential_data}->{authorization_code}});
		
		if ($aref) {
			# 帐号这个字段保存 pid
			my $pref = obj_read("person", $aref->{pids}->{$gr->{server}});

			# 直接创建会话，登录成功
			sess_server_create($pref);
			$pref->{headFid} = $DEFAULT_IMAGE unless $pref->{headFid};
			return jr({user_info=>$pref, server_info=>server_info()}) if $gr->{verbose};
			return jr();
		}

		my $json = JSON->new();	
	
		my $ua = LWP::UserAgent->new();
		
		# 从客户端端给的 authorization code 获取 access token
		my $uri = "https://api.weibo.com/oauth2/access_token?client_id=xxx&client_secret=xxx".
			"&grant_type=authorization_code&code=".$gr->{credential_data}->{authorization_code};

		my $req = HTTP::Request->new('POST', $uri);

		my $response = $ua->request($req);

		my $ret = $json->decode($response->decoded_content());
		
		# 用 access token 获取 用户信息
		my $uri = "https://api.weibo.com/oauth2/get_token_info?access_token=".$ret->{access_token};

		my $req = HTTP::Request->new('POST', $uri);

		my $response = $ua->request($req);

		my $ret = $json->decode($response->decoded_content());
		
		my $uid = $ret->{uid};
		
		# 可能还有其他第三方登录。。这里加 weibo: 就可以区别不同的uid了
		my $pid = account_find_pid_by_device_id($gr->{server}, "weibo:$uid");

		# 如果没找到，立即创建帐号, "weibo:$uid" 相当于 device id 
		#my $pref = account_create($gr->{server}, $gr->{display_name}, $gr->{device_id})；
		my $pref = account_create($gr->{server}, "", "weibo:$uid");
		
		# 创建会话，登录成功
		sess_server_create($pref);

		# 缓存这个 authorization code 以便下次直接登录
		my $aref = obj_read("account", $pref->{account_id});
		$aref->{authorization_code} = "weibo:".$gr->{credential_data}->{authorization_code};
		obj_write($aref);

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

$p_person_logout = <<EOF;
登出
EOF
	
sub p_person_logout {
	
	sess_server_destroy();
	
	return jr();
}

$p_business_new = <<EOF;
创建新业务
说明：新增一个业务数据

输入：
data: {
	//具体业务数据
	string:abc
	number:123
}

返回：业务数据结构体

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
更新数据
说明：更新业务数据

输入：
bid: obj id

data: {
	string/0:abc
	number/0:123
}

返回：更新后的业务数据结构体

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
获取业务
说明：获取业务数据

输入：
bid: obj id

返回：业务数据结构体
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
业务之一
说明：测试
输入：
iam: 随便一个名词

返回：
msg: "Hello " 字段msg是 Hello 和刚才那个输入的iam字段 
EOF

sub p_business_hello {
	
	# simulate processin
	sleep(1);
	
	return jr({msg=>"你好 ".$gr->{iam}."!"});
}

$p_business_click = <<EOF;
点击业务
EOF

sub p_business_click {
	# 打印出统计数据来
	return jr() unless $gs->{pid};
	my $ref = obj_read("person", $gs->{pid});
	$ref->{clicks}->{time_midnight_local()} ++;
	obj_write($ref);
	return jr({data=>$ref});
}

$p_business_stat = <<EOF;
统计接口
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

$p_group_apply=<<EOF;
创建社团
EOF

sub  p_group_apply {
	my $mdata=$gr->{applydata};
	#对用户输入的数据进行校验，判断是否为空
	return jr() unless assert ($mdata,"applydata is miss","请求数据为空");
	return jr() unless assert ($mdata->{pid},"pid is miss","pid 为空");
	return jr() unless assert ($mdata->{captainId},"captainId is miss ","captainId 为空");
	return jr() unless assert($mdata->{labels},"labels is missing","ERR_LABELS_MISS","社团标签缺失");
	return jr() unless assert($mdata->{slogan},"slogan is missing","ERR_SLOGAN_MISS","社团口号缺失");
	return jr() unless assert($mdata->{image},"image is missing","ERR_IMAGE_MISS","社团图片缺失");
	return jr() unless assert($mdata->{level},"level is missing","ERR_LEVEL_MISS","社团级别缺失");
 	return jr() unless assert($mdata->{introduce},"introduce is missing","ERR_INTRODUCE_MISS","社团介绍缺失");
 	#对用户输入的数据进行构建
 	my $groupTemp;
	#填写常规的字段,ID只要调用obj_id函数就可以生成。type已经是定好的。
	$groupTemp->{_id}=obj_id();
	$groupTemp->{type}="group";
	$groupTemp->{title}=$mdata->{title};
	$groupTemp->{slogan}=$mdata->{slogan};
	$groupTemp->{introduce}=$mdata->{introduce};	
	$groupTemp->{image}=$mdata->{image};
	$groupTemp->{level}=$mdata->{level};
	$groupTemp->{captainId}=$mdata->{pid};
    $groupTemp->{creatorId}=$mdata->{pid};
    $groupTemp->{et}=time;
    $groupTemp->{status}="apply";

  	#添加活动字段
  	$groupTemp->{events}={};
  	#添加相册字段
  	$groupTemp->{groupImages}->{"默认相册"}={};
  	#添加申请人字段
  	$groupTemp->{apply_members}={};

  	#添加标签，标签是一个表，根据id识别对应的标签，
  	my $i=0;
  	foreach my $obj(@{$gr->{applydata}->{labels}}){
  		my $labletemp = obj_read{"label",$obj};
  		return jr() unless assert($labelTemp,"labels_id is error","ERR_INTRODUCE_MISS","社团标签ID不存在");
   		$groupTemp->{labels}->{$obj}=1;
   		$i=$i+1;
  	}
  	#寻找pid中记录，如果不存在就返回无该用户
  	my $perssontemp = obj_read ("person",$gr->{applydata}->{pid});
  	return jr() unless assert ($perssontemp,"pid is error","ERR_PERSONID_ERR","无用户记录"); 

  	#将该用户存放到group表中
  	$groupTemp->{members}->{$perssontemp->{_id}}->{par_time}=time;
  	$groupTemp->{members}->{$perssontemp->{_id}}->{role}="manager";

  	#添加学校,需要将其ID赋值。
  	$groupTemp->{school}=$perssontemp->{school}->{id};

  	#判断当前学校是否已经有这个名字的社团了
  	my $group_list = mdb()->get_collection("group")->find({school=>$perssontemp->{school}->{_id}});
  	while (my $obj = $group_list->next) {
  		if ($obj->{title} eq $groupTemp->{title}) {
  			return jr() unless assert (0,"group name is exist","ERR_GROUPNAME_EXIST","社团名称太拉风，贵校已经有人捷足先登啦");	 		
  		}
  	}
   obj_write($groupTemp);

   #把用户对应的groups加上相应的字段
   $perssontemp->{groups}->{$groupTemp->{_id}}->{role}="manager";
   obj_write($perssontemp);

   my $admin_list = mdb()->get_collection("person")->find({identity=>"admin"});
   my @admin=();
   while (my $obj=$admin_list->next) {
   push  @admin,$obj->{_id};
}
  return jr({status=>"success",data=>$groupTemp});

}


#发送通知给多个用户(给单个用户发送通知也请调用此接口,只要person_ids数组里面存放你要发送的pid即可)
#  "person_ids":["o14367541307193710803","o14364142684637520313","o14365195518900918960"],
#  "announce_titile":"多人推送标题",
#  "announce_body":"多人通知内容",
#  "announce_pic":"pid124452345234829347",
#  "announce_person":"测试员"
sub group_annServer{
  
  #创建一条通知
  my $announce;
  $announce->{_id}=obj_id();
  my $ids=$_[0];
  $announce->{announce_titile} =$_[1];
  $announce->{announce_body} =$_[2];
  $announce->{announce_time} =time;
  $announce->{announce_pic}=$_[3];
  $announce->{announce_person} = $_[4];
  $announce->{announce_isread}="false";
  $announce->{announce_targetType}=$_[7];  
  $announce->{announce_targetId}=$_[8];  
  my $announce_alert =$_[6];


  my $message = {
      obj=>"announce",
      act=>"recive",
      push_type=>"announce_push",
      announce_id=>$announce->{_id},
      announce_alert=>$announce_alert
  };
  #增加返回字段
  if($announce->{announce_targetType} eq "group"){
    $message->{group_id} = $announce->{announce_targetId};
    $message->{person_id} = $_[9] if($_[9]);
    #消息详情中加入相关action（分别社团申请、用户申请加入）
    $announce->{announce_action} = $_[10];
  }
  elsif($announce->{announce_targetType} eq "event"){
    $message->{event_id} = $announce->{announce_targetId};
    $announce->{event_creatorId} = $_[9];
    $announce->{announce_action} = $_[10];
  }
  
  
  #key就是person_id
  foreach my $key(@$ids){
    #发送推送
    my $res;
    $res = sendto_pid($_[5],$key,$message,1);
    if($res == 0 || $res eq 0){
			my $person = obj_read("person",$key,1);
			if($person->{devicetoken}){
				&net_apns($person->{devicetoken},$message);
			}
		}
    #把具体通知消息和用户关联起来
    #读取一个用户的收件箱
    my $inbox = obj_read("inbox",$key,2);
    return "failed" unless assert($inbox,"inbox read error");
    $inbox->{_id}=$key;
    $inbox->{recived}->{$announce->{_id}} = $announce;
    #保存到数据库中
    obj_write($inbox);
    
  }
  #返回成功状态
  return "success";
   
}
################################################################################################################################################################
# this section are framework hooks, and required
sub hook_pid_online {
	my ($server, $pid) = @_;
	syslog("online: $server, $pid");
=h	
	my $p = obj_read("person", $pid);
	$GROUP{$pid} = $p->{display_name};
	
	my $all = join "; ", values %GROUP;
	$all = "[join: ".$p->{display_name}."] ONLINE: ".$all;
	
	foreach my $p (keys %GROUP) {
		my $res;
		my $message = {
			obj => "push",
			act => "group_members",
			members => $all,
		};
		$res = sendto_pid($server, $p, $message);

		if($res == 0 || $res eq 0){
			my $person = obj_read("person",$p,1);
			if($person->{devicetoken}){
				&net_apns($person->{devicetoken},$message);
			}
		}
	}
=cut
}

sub hook_pid_offline {
	my ($server, $pid) = @_;
	
	return if $pid eq $gs->{pid};
	
	syslog("offline: $server, $pid");
=h	
	
	delete $GROUP{$pid};
	
	my $p = obj_read("person", $pid);
	
	my $all = join "; ", values %GROUP;
	$all = "[left: ".$p->{display_name}."] ONLINE: ".$all;
	
	foreach my $p (keys %GROUP) {
		my $res;
		my $message = {
			obj => "push",
			act => "group_members",
			members => $all,
		};
		$res = sendto_pid($server, $p, $message);

		if($res == 0 || $res eq 0){
			my $person = obj_read("person",$p,1);
			if($person->{devicetoken}){
				&net_apns($person->{devicetoken},$message);
			}
		}
	}
=cut
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
苹果推送
输入:
{
	"obj":"ios",
	"act":"push",
	"person_id":用户id
	"message":推送消息文案
}

输出:
{
	"obj":"ios",
	"act":"push",
	"msg":"send success"
}

EOF

sub p_ios_push{
	return jr({status=>"failed"}) unless assert(length($gr->{person_id}),"person id missing","ERR_PERSON_ID_MISSING","用户id信息丢失");
	return jr({status=>"failed"}) unless assert(length($gr->{message}),"message missing","ERR_MESSAGE_MISSING","message");

my $message = {
			obj=>"chat",
      		act=>"push",
      		# title=>"离线通知",
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
	$message = "您收到一条通知" unless $message ;
	
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
用户表
	display_name:123
	
	metro:fuzhou/guangzhou/shanghai/beijing
	loc:gulou
	commission:2 // percentage
	
	// login_name is phone
	
	// update time and entry time	
	ut:
	et:
	
	// 记录每天点击数
	clicks: {
		ts1:12	//时间錯
	}
	status:active/suspended/archived
EOF

$man_ds_business = <<EOF;
业务表	
	
	status:active/withdrawn/accepted/pending_cancel/canceled
	
	// update time and entry time	
	ut: update time
	et: entry time 
EOF

$man_ds_advertisement  = <<EOF;
广告表

	_id         //主键
  type        //表名
  ad_own      //广告所属的模块:社团(group)、活动(event)
  image_fid   //广告的图片id
  et          //创建时间
  href        //超链接

   status:active/suspended/archived
EOF

$man_ds_persons = <<EOF;
手机注册表
  _id         //主键
  type        //表名
  phone //电话号码

EOF

$man_ds_userdata = <<EOF;
手机注册用户数据表
	_id 	//UID
	type:userdata
	// update time and entry time	
	ut:
	et:
	data:{
	"phonenumber":15280888420,
	"authcode":123456,
	"password":"abc123456",
	"scale":"simple",
	"company_name":"brainstrong",
	"company_address":"gulou",
	"email":"A1B2C3"
	}
	
	status:active/suspended/archived

EOF

$man_ds_group  = <<EOF;

社团表

    _id:    
    type: group 
    title:    //社团名字
    labels: {          //社团标签（类别）
      labels_id1:1
    } 
    captainId:  //社长id，manager
    creatorId: // 创建者

    slogan:  //社团口号
   	introduce: //社团介绍 
    image:  //社团封面图片
    school:    //学校ID
		
    level: //社团级别（school校级/college院级）
    status:  //社团目前状态(apply审核中/runing经营中)
    et:      //社团成立时间
    members:{   //社团成员cha
    	personId1: {
        par_time:       //加入时间
        role:manager   //成员在里面的角色是什么
      }

    	personId2: {
        par_time:
        role:member
      }
    }

    //社团图片，有多个
    groupImages: {
        imageId1: {
            title, //图片标题
            author,//发布者
        }
        imageId2 {
            title,
            author,
        }
        
    }

    //社友圈  ,可能有变动先不处理
    socialCircle: {

        personId1: {
            nick: //昵称
            information:  //发布的文字信息
            image: {     //发布的图片信息
                id1:1,
                id2:1,
            }
            support: {  //点赞人id和昵称
                id1: {
                    nick:
                }
                id2: {
                    nick:
                } 
            }
            comment: {  //评论人id，昵称，信息
                commentInfo: {
                    nick:
                    information: 
                }
            }
        }


    }

    events: {//活动id
    	
      id1:{
    		
    	}

    	id2: {

    	}
    }

EOF

$man_ds_label=<<EOF;
标签表(可用在社团类别中，也可以用在其他需要标签的地方)
	_id:  //主键
	type: label
	labelName:  标签名字
  labelImage: 标签图片
  labelType:  标签类别(group、event)
EOF

$man_ds_table2 =<<EOF;
输入：
	_id
输出：
	_//sss  

EOF

$man_ds_table =<<EOF;
输入：
	_id
输出：
	_//sss  

EOF



$man_ds_pet =<<EOF;
输入：
	_id
输出
	//date
EOF

$man_ds_pig =<<EOF;
输入：
	_id
输出：
	_//sss

EOF

$man_ds_inbox =<<EOF;
收件箱，消息中心，未读个数
    	// 最近一条未读数据要从最近的 chatRecords 块中读取，缓存这里的
    	// 如果其他地方没有永久记录的消息类型，系统推送也可以放在这里永久记录等用户来取

    	_id: // 就是这个用户 id
    	type: inbox

   	ut: // 收件箱上次更新时间，客户端缓存的列表需要刷新吗

        // 私聊相关的 话题相关的（话题列表显示未读个数，只有关注的才有） 任务评论相关的（任务列表显示未读个数，只有关注的才有）
	messages: { // MAX 300 暂时没有限制，获取时候排序下发
		id1: { 
			xtype: person/task/topic // 类型：私聊 话题 任务评论
			id: 就是这里的 id1
			ut: unix 时间，最近更新时间
			vt: unix 时间，上次客户端IM详情访问时间
			count: 上次访问以来未读个数,count
			cid: 对应的chatRecords ID
			last: username:lastcomment 用户名：最后一次评论限制长度哦，个人就没有名字了
			fid: 如果个人，个人头像ID
			title: 标题或人名
		}
	}
EOF

$man_ds_chat = <<EOF;
两个人私聊记录表头
    	_id
    	type: chat

    	pair: $id1.$id2  //参与者两个ID 从小到大排序，拼接

    	chatRecordId: 最近的一个聊天链接块的ID，没有聊天记录就为 0
EOF

$man_ds_chatRecords = <<EOF;
私聊，话题，任务评论：共用的记录块（链接块）

    	_id
    	type: chatRecords

    	next_id：下一个链接块ID，0 就是到最后一个了

    	et:编辑时间/第一条记录时间
    	ut:更新时间/最后一条记录时间
   
    	// 50 个聊天言语（段），超出50，就产生新的链接块 
    	// 新来的往后面堆   
    	records: [ 
      	{
        	from_id: 	发言者
		from_name:
        	xtype: text/image/voice/link
        	content:  文字内容，或 图片ID，或 语音ID，或 链接地址
        	send_time: 发表时间 UNIX时间
      	}
      	{
        	from_id: //发言者
		from_name:
        	xtype: text/image/voice/link
        	content:  //文字内容，或 图片ID，或 语音ID，或 链接地址
        	send_time: //发表时间 UNIX时间
      	}
    	］
EOF



