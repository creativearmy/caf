import 'JSONObject.dart';
import 'src/APIConnectionImpl.dart';

/// class to be mixin'ed with State<> class
class APIConnectionListener {
  void response_received(JSONObject jo) {}
  void state_changed() {}
}

/// API Connection class to call server api
abstract class APIConnection {

  /// singleton getter
  static APIConnectionImpl _inst;
  static APIConnection get inst {
    if (_inst == null) {
      _inst = new APIConnectionImpl();
    }
    return _inst;
  }

  bool DEBUG = true;
  bool ADVANCED_DEBUG = true;

  /// these expected to be assgined by the user of this module
  String wsUri = "";

  /// to store extended credential information, login_name/passwd or credential_data
  /// only one of those is valid, not both. The same is true with registration
  /// registration.login_name/login_passwd or registration.credential_data shall be true
  String login_name = "";
  String login_passwd = "";
  var credential_data = null;
  var registration = null;

  /// SDK version
  String version();
  
  /// check if connection is IN_SESSION
  bool is_logged_in();

  /// print log to console, with tag "CAFL"
  void clog(String s);

  /// get Unix style time in second
  int getUnixTime();

  /// user info after login
  JSONObject user_info;
  
  /// configuration data fetched from server
  JSONObject server_info;

  /// convenient place to hold app data in memory, globally accessible
  JSONObject user_data;

  /// persistent data, read from disk
  Future<JSONObject> user_joread();
  
  /// persistent data, save to disk
  void user_jowrite(JSONObject data);

  /// client info set by client app, to be sent along each API call
  JSONObject client_info;

  /// string key/value settings, "true" and "false" and number is presented as string as well
  JSONObject user_pref;

  /// keep tracking of the state and transition, states can be:
  /// LOGIN_SCREEN_SHOWN
  /// SERVERINFO_REQ
  /// LOGIN_SCREEN_ENABLED
  /// GUEST_SEND
  /// INITIAL_LOGIN
  /// IN_SESSION
  /// SESSION_LOGIN
  /// REGISTRATION
  /// CONNECTING
  String conn_state;

  /// from_state is the last state before transition
  String from_state;

  /// target_state is the immediate state after websocket connection is re-established
  String target_state;

  /// subscribe/unsubscribe to websocket message calback, 
  /// API call return or pushed notification from server
  /// call these in State initState/dispose overrides
  void response_received_handlers_subscribe(APIConnectionListener listener);
  void response_received_handlers_unsubscribe(APIConnectionListener listener);
  
  /// subscribe/unsubscribe to connection state change notification
  /// call these in State initState/dispose overrides
  void state_changed_handlers_subscribe(APIConnectionListener listener);
  void state_changed_handlers_unsubscribe(APIConnectionListener listener);
  
  /// connect to server after wsUri is set
  void connect();

  /// simple login
  void login(String username, String passwd);

  /// extended login, {"credential_data":{"a":"str","b":1}}
  void loginx(JSONObject cred);

  /// logout
  void logout();

  /// register a user account, simple or extended
  void register(JSONObject reg);

  /// requestion configuration data from server
  void req_server_info();

  /// log add to buffer to support toolbox log retrieval
  void log_add(String logstr);

  /// extra log hook to support toolbox log retrieval
  String log_extra();

  /// send request in JSON string
  bool send_str(String msg);

  /// return false if request is not accepted. our job queue max length is 1
  /// send - used by sdk client, limited to LOGIN_SCREEN_ENABLED and IN_SESSION state
  bool send_obj(JSONObject req);
}
