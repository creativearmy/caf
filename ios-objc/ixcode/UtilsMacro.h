//
//  UtilsMacro.h
//  Offers
//
//  Created by hehuo100 on 11/10/15.
//  Copyright © 2015 zt.td. All rights reserved.
//

#ifndef UtilsMacro_h
#define UtilsMacro_h


#define RGB(R,G,B)		[UIColor colorWithRed:R/255.0f green:G/255.0f blue:B/255.0f alpha:1.0f]

#define Person(R)        [[NSUserDefaults standardUserDefaults] objectForKey:R]
#define setObjectPerson(key,value) [[NSUserDefaults standardUserDefaults] setObject:value forKey:key]

#define SYNTHESIZE_SINGLETON_FOR_CLASS(classname) \
static classname *shared##classname = nil; \
+ (classname *)instance \
{\
@synchronized(self) \
{\
if (shared##classname == nil) \
{\
shared##classname = [[self alloc] init]; \
} \
} \
return shared##classname; \
} \
+ (id)allocWithZone:(NSZone *)zone \
{\
@synchronized(self) \
{\
if (shared##classname == nil) \
{\
shared##classname = [super allocWithZone:zone]; \
return shared##classname; \
} \
} \
return nil; \
} \
- (id)copyWithZone:(NSZone *)zone \
{ \
return self; \
} \

#define SYNTHESIZE_SINGLETON_FOR_HEADER(className) \
\
+ (className *)shared##className;

#define SYNTHESIZE_LAZY_FOR_CLASS(className) \
\
+ (className *)shared##className { \
static className *shared##className = nil; \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
shared##className = [[self alloc] init]; \
}); \
return shared##className; \
}



#endif /* UtilsMacro_h */
