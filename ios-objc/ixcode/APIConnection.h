#ifndef APIConnection_h
#define APIConnection_h

#import <Foundation/Foundation.h>

#define JSONObject NSMutableDictionary
#define JSONArray NSMutableArray

@interface JSONObject (SafeJSONAccess)

- (id)opt:              (NSString *)key;
- (NSString *)optString:(NSString *)key;
- (int)optInt:			(NSString *)key;
- (long)optLong:		(NSString *)key;
- (float)optFloat:		(NSString *)key;
- (double)optDouble:	(NSString *)key;
- (BOOL)optBOOL:		(NSString *)key;

- (JSONObject *)optJSONObject:	(NSString *)key;
- (JSONArray *)optJSONArray:	(NSString *)key;

- (id)opt:              (NSString *)key		defaultValue:(id)defaultValue;
- (NSString *)optString:(NSString *)key		defaultValue:(NSString *)defaultValue;
- (int)optInt:			(NSString *)key		defaultValue:(int)defaultValue;
- (long)optLong:		(NSString *)key		defaultValue:(long)defaultValue;
- (float)optFloat:		(NSString *)key		defaultValue:(float)defaultValue;
- (double)optDouble:	(NSString *)key		defaultValue:(double)defaultValue;
- (BOOL)optBOOL:		(NSString *)key		defaultValue:(BOOL)defaultValue;

// shortcuts
- (NSString *)s:    (NSString *)key;
- (int)i:			(NSString *)key;
- (long)l:          (NSString *)key;
- (float)f:         (NSString *)key;
- (double)d:        (NSString *)key;
- (BOOL)b:          (NSString *)key;
- (JSONObject *)o:	(NSString *)key;
- (JSONArray *)a:	(NSString *)key;
- (NSString *)s:    (NSString *)key		d:(NSString *)defaultValue;
- (int)i:			(NSString *)key		d:(int)defaultValue;
- (long)l:          (NSString *)key		d:(long)defaultValue;
- (float)f:         (NSString *)key		d:(float)defaultValue;
- (double)d:        (NSString *)key		d:(double)defaultValue;
- (BOOL)b:          (NSString *)key		d:(BOOL)defaultValue;

@end

@interface JSONArray (SafeJSONAccess)

- (id)opt:              (int)index;
- (NSString *)optString:(int)index;
- (int)optInt:			(int)index;
- (long)optLong:		(int)index;
- (float)optFloat:		(int)index;
- (double)optDouble:	(int)index;
- (BOOL)optBOOL:		(int)index;

- (JSONObject *)optJSONObject:	(int)index;
- (JSONArray *)optJSONArray:	(int)index;

- (id)opt:              (int)index		defaultValue:(id)defaultValue;
- (NSString *)optString:(int)index		defaultValue:(NSString *)defaultValue;
- (int)optInt:			(int)index		defaultValue:(int)defaultValue;
- (long)optLong:		(int)index		defaultValue:(long)defaultValue;
- (float)optFloat:		(int)index		defaultValue:(float)defaultValue;
- (double)optDouble:	(int)index		defaultValue:(double)defaultValue;
- (BOOL)optBOOL:		(int)index		defaultValue:(BOOL)defaultValue;

// shortcuts
- (NSString *)s:    (int)index;
- (int)i:			(int)index;
- (long)l:          (int)index;
- (float)f:         (int)index;
- (double)d:        (int)index;
- (BOOL)b:          (int)index;
- (JSONObject *)o:	(int)index;
- (JSONArray *)a:	(int)index;
- (NSString *)s:    (int)index		d:(NSString *)defaultValue;
- (int)i:			(int)index		d:(int)defaultValue;
- (long)l:          (int)index		d:(long)defaultValue;
- (float)f:         (int)index		d:(float)defaultValue;
- (double)d:        (int)index		d:(double)defaultValue;
- (BOOL)b:          (int)index		d:(BOOL)defaultValue;

@end

typedef enum {

	LOGIN_SCREEN_SHOWN      = 1,
	SERVERINFO_REQ          = 2,
	LOGIN_SCREEN_ENABLED    = 3,
	GUEST_SEND				= 4,
	INITIAL_LOGIN           = 5,
	IN_SESSION              = 6,
	SESSION_LOGIN           = 7,
	REGISTRATION            = 8,
	CONNECTING            	= 9,
    
} ConnStates;

@interface APIConnection : NSObject;

    // public accessible variable, this class is implemented as a singleton

    @property NSString* wsURL;

    @property ConnStates state;
    @property ConnStates from_state;
    @property ConnStates target_state;

    // if this present, it will go ahead and do the registration
    @property JSONObject* registration;

    @property JSONObject* server_info;
    @property JSONObject* user_info;
    @property JSONObject* user_data;

    // client info set by client app
    @property JSONObject* client_info;

    // string key/value settings, "true" and "false" and number is rpresented as string as well
    @property JSONObject* user_pref;

    // response json structure received from server and saved here, and processed immediately by observer

    // A notification center delivers notifications to observers synchronously. In other words,
    // the postNotification: methods do not return until all observers have received and
    // processed the notification. To send notifications asynchronously use NSNotificationQueue.
    @property JSONObject* response;

    - (void)connect;
    - (void)credential:(NSString*)name withPasswd:(NSString*)passwd;
    - (void)credentialx:(JSONObject*)cred;
    - (void)login:(NSString*)name withPasswd:(NSString*)passwd;
    - (void)loginx:(JSONObject*)cred;
    - (void)logout;
    - (void)register:(JSONObject*)reg;
    - (BOOL)send:(JSONObject*)req;
    - (BOOL)send_str:(NSString*)req;
    - (NSString*)version;
    - (BOOL)is_logged_in;
    - (void)log_add:(NSString*)logstr;
	
	// persistent data
    - (JSONObject*)user_joread;
    - (void)user_jowrite:(JSONObject*)data;

    // notifcation will fire on these names
    @property (readonly) NSString* stateChangedNotification;
    @property (readonly) NSString* responseReceivedNotification;

    // called when sdk does a logsend, send extra info here
    @property (nonatomic, copy) NSString* (^log_extra) (void);
    
    // utilities
    - (BOOL)isScreenOff;
    - (void)playRingTone:(BOOL)p;
    - (int)ios_app_version;
    - (int)getUnixTime;

@end

#endif
