/*****************************************************************************
 *
 * FILE:	MWXKeychainSuite.m
 * DESCRIPTION:	MagickWorX: NSUserDefaults-like Keychain Wrapper Class
 * DATE:	Thu, Dec  1 2011
 * UPDATED:	Mon, Dec  5 2011
 * AUTHOR:	Kouichi ABE (WALL) / 阿部康一
 * E-MAIL:	kouichi@MagickWorX.COM
 * URL:		http://www.MagickWorX.COM/
 * COPYRIGHT:	(c) 2011 阿部康一／Kouichi ABE (WALL), All rights reserved.
 * LICENSE:
 *
 *  Copyright (c) 2011 Kouichi ABE (WALL) <kouichi@MagickWorX.COM>,
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *
 *   1. Redistributions of source code must retain the above copyright
 *      notice, this list of conditions and the following disclaimer.
 *
 *   2. Redistributions in binary form must reproduce the above copyright
 *      notice, this list of conditions and the following disclaimer in the
 *      documentation and/or other materials provided with the distribution.
 *
 *   THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 *   ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 *   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 *   PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
 *   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 *   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 *   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 *   INTERRUPTION)  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 *   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 *   THE POSSIBILITY OF SUCH DAMAGE.
 *
 * $Id: MWXKeychainSuite.m,v 1.1 2011/12/03 20:17:35 kouichi Exp $
 *
 *****************************************************************************/

#import <Security/Security.h>
#import "MWXKeychainSuite.h"

@interface MWXKeychainSuite ()
@property (nonatomic,retain) NSMutableDictionary *	items;
@property (nonatomic,retain) NSMutableDictionary *	query;
@end

@interface MWXKeychainSuite (Private)
-(void)setItem:(id)item forKey:(NSString *)key;
-(void)removeItemForKey:(NSString *)key;
-(NSArray *)allItems;
@end

@implementation MWXKeychainSuite

@synthesize	identifier	= _identifier;
@synthesize	accessGroup	= _accessGroup;
@synthesize	items		= _items;
@synthesize	query		= _query;

-(id)init
{
  return [self initWithIdentifier:[[NSBundle mainBundle] bundleIdentifier]
	       accessGroup:nil];
}

-(id)initWithIdentifier:(NSString *)identifier
{
  return [self initWithIdentifier:identifier accessGroup:nil];
}

-(id)initWithIdentifier:(NSString *)identifier
	accessGroup:(NSString *)accessGroup
{
  if ((self = [super init])) {
    _identifier	 = [identifier copy];
    _accessGroup = [accessGroup copy];

    NSMutableDictionary *	query;
    query = [[NSMutableDictionary alloc] init];
    [query setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
    [query setObject:identifier forKey:(id)kSecAttrService];
    if (accessGroup != nil) {
#if	TARGET_IPHONE_SIMULATOR
      /*
       * Ignore the access group if running on the iPhone simulator.
       *
       * Apps that are built for the simulator aren't signed, so there's no
       * keychain access group for the simulator to check. This means that all
       * apps can see all keychain items when run on the simulator.
       *
       * If a SecItem contains an access group attribute, SecItemAdd and
       * SecItemUpdate on the simulator will return -25243
       * (errSecNoAccessForItem).
       */
#else
      [query setObject:accessGroup forKey:(id)kSecAttrAccessGroup];
#endif	// TARGET_IPHONE_SIMULATOR
    }
    self.query = query;
    [query release];

    query = [[NSMutableDictionary alloc] initWithDictionary:_query];
    [query setObject:(id)kSecMatchLimitAll forKey:(id)kSecMatchLimit];
    [query setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnAttributes];
    [query setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];

    _items = [[NSMutableDictionary alloc] init];
    NSArray *	result = nil;
    OSStatus	status = SecItemCopyMatching((CFDictionaryRef)query,
					     (CFTypeRef)&result);
    if (status == errSecSuccess) {
      for (NSDictionary * dval in result) {
	[_items setObject:[dval objectForKey:(id)kSecValueData]
		forKey:[dval objectForKey:(id)kSecAttrGeneric]];
      }
    }
    [result release];
    [query release];
  }

  return self;
}

-(void)dealloc
{
  [_identifier release],  _identifier  = nil;
  [_accessGroup release], _accessGroup = nil;
  [_items release], _items = nil;
  [_query release], _query = nil;
  [super dealloc];
}

/*****************************************************************************/

-(void)setObject:(id)object forKey:(NSString *)key
{
  if (!key) { return; }

  if (!object) {
    [self removeObjectForKey:key];
  }
  else {
    if ([object isKindOfClass:[NSString class]]) {
      [_items setObject:[object dataUsingEncoding:NSUTF8StringEncoding]
	      forKey:key];
    }
    else if ([object isKindOfClass:[NSData class]]) {
      [_items setObject:object forKey:key];
    }
    else {
      [_items setObject:[NSKeyedArchiver archivedDataWithRootObject:object]
	      forKey:key];
    }
  }
}

-(id)objectForKey:(NSString *)key
{
  id	object = [_items objectForKey:key];

  if (!object) {
    NSMutableDictionary *	query;
    query = [[NSMutableDictionary alloc] initWithDictionary:_query];
    [query setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
    [query setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
    [query setObject:key forKey:(id)kSecAttrGeneric];
    [query setObject:key forKey:(id)kSecAttrAccount];
    NSData *	data   = nil;
    OSStatus	status = SecItemCopyMatching((CFDictionaryRef)query,
					     (CFTypeRef)&data);
    [query release];

    if (status == errSecSuccess) {
      return [data autorelease];
    }
  }

  return object;
}


-(BOOL)containsObjectForKey:(NSString *)key
{
  id	object = [self objectForKey:key];

  return (object != nil);
}


-(NSString *)stringForKey:(NSString *)key
{
  NSData *	data = [self objectForKey:key];
  if (data) {
    NSString *	sval = [[NSString alloc]
			initWithData:data encoding:NSUTF8StringEncoding];
    return [sval autorelease];
  }
  return nil;
}

-(NSNumber *)numberForKey:(NSString *)key
{
  NSData *	data = [self objectForKey:key];
  if (data) {
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
  }
  return nil;
}

-(NSArray *)arrayForKey:(NSString *)key
{
  NSData *	data = [self objectForKey:key];
  if (data) {
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
  }
  return nil;
}

-(NSDictionary *)dictionaryForKey:(NSString *)key
{
  NSData *	data = [self objectForKey:key];
  if (data) {
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
  }
  return nil;
}

-(NSData *)dataForKey:(NSString *)key
{
  return [self objectForKey:key];
}


-(void)setInteger:(NSInteger)value forKey:(NSString *)key
{
  [self setObject:[NSNumber numberWithInteger:value] forKey:key];
}

-(void)setFloat:(float)value forKey:(NSString *)key
{
  [self setObject:[NSNumber numberWithFloat:value] forKey:key];
}

-(void)setDouble:(double)value forKey:(NSString *)key
{
  [self setObject:[NSNumber numberWithDouble:value] forKey:key];
}

-(void)setBool:(BOOL)value forKey:(NSString *)key
{
  [self setObject:[NSNumber numberWithBool:value] forKey:key];
}

-(NSInteger)integerForKey:(NSString *)key
{
  NSNumber *	nval = [self numberForKey:key];

  return [nval integerValue];
}

-(float)floatForKey:(NSString *)key
{
  NSNumber *	nval = [self numberForKey:key];

  return [nval floatValue];
}

-(double)doubleForKey:(NSString *)key
{
  NSNumber *	nval = [self numberForKey:key];

  return [nval doubleValue];
}

-(BOOL)boolForKey:(NSString *)key
{
  NSNumber *	nval = [self numberForKey:key];

  return [nval boolValue];
}


-(void)removeObjectForKey:(NSString *)key
{
  if ([_items objectForKey:key]) {
    [_items removeObjectForKey:key];
  }
  [self removeItemForKey:key];
}

-(void)removeAllObjects
{
  NSArray *	items = [self allItems];
  for (NSDictionary * item in items) {
    NSMutableDictionary *	query;
    query = [[NSMutableDictionary alloc] initWithDictionary:item];
    [query setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
    OSStatus	status = SecItemDelete((CFDictionaryRef)query);
    if (status != errSecSuccess) {
#if	DEBUG
      NSLog(@"DEBUG[SecItemDelete] item=%@ %s: error(%ld)", item, __func__, status);
#endif	// DEBUG
    }
    [query release];
  }

  [_items removeAllObjects];
}


-(void)synchronize
{
  [_items enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL * stop) {
    [self setItem:obj forKey:key];
  }];
}

/*****************************************************************************/

-(void)setItem:(id)item forKey:(NSString *)key
{
  if (!key) { return; }

  NSMutableDictionary *	query;
  query = [[NSMutableDictionary alloc] initWithDictionary:_query];
  [query setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
  [query setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnAttributes];
  [query setObject:key forKey:(id)kSecAttrGeneric];
  [query setObject:key forKey:(id)kSecAttrAccount];

  NSArray *	result = nil;
  OSStatus	status = SecItemCopyMatching((CFDictionaryRef)query,
					     (CFTypeRef)&result);
  [result release];

  // XXX: 登録／更新には、以下のキーは不要なので削除
  [query removeObjectForKey:(id)kSecMatchLimit];
  [query removeObjectForKey:(id)kSecReturnAttributes];

  if (status == errSecSuccess) {
    if (item) {
      NSMutableDictionary *	attrs;
      attrs = [[NSMutableDictionary alloc] init];
      [attrs setObject:item forKey:(id)kSecValueData];
      status = SecItemUpdate((CFDictionaryRef)query, (CFDictionaryRef)attrs);
      if (status != errSecSuccess) {
#if	DEBUG
       	NSLog(@"DEBUG[SecItemUpdate] key=%@ item=%@ %s: error(%ld)", key, item, __func__, status);
#endif	// DEBUG
      }
      [attrs release];
    }
    else {
      [self removeItemForKey:key];
    }
  }
  else if (status == errSecItemNotFound) {
    NSMutableDictionary *	attrs;
    attrs = [[NSMutableDictionary alloc] initWithDictionary:query];
    [attrs setObject:item forKey:(id)kSecValueData];
    status = SecItemAdd((CFDictionaryRef)attrs, NULL);
    if (status != errSecSuccess) {
#if	DEBUG
      NSLog(@"DEBUG[SecItemAdd] key=%@ item=%@ attrs=%@ %s: error(%ld)", key, item, attrs, __func__, status);
#endif	// DEBUG
    }
    [attrs release];
  }
  else {
  }
  [query release];
}

-(void)removeItemForKey:(NSString *)key
{
  NSMutableDictionary *	query;
  query = [[NSMutableDictionary alloc] initWithDictionary:_query];
  [query setObject:key forKey:(id)kSecAttrGeneric];
  [query setObject:key forKey:(id)kSecAttrAccount];
  OSStatus	status = SecItemDelete((CFDictionaryRef)query);
  if (status != errSecSuccess && status != errSecItemNotFound) {
#if	DEBUG
    NSLog(@"DEBUG[SecItemDelete] key=%@ %s: error(%ld)", key, __func__, status);
#endif	// DEBUG
  }
  [query release];
}

-(NSArray *)allItems
{
  NSMutableDictionary *	query;
  query = [[NSMutableDictionary alloc] initWithDictionary:_query];
  [query setObject:(id)kSecMatchLimitAll forKey:(id)kSecMatchLimit];
  [query setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnAttributes];
  [query setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];

  NSArray *	result = nil;
  OSStatus	status = SecItemCopyMatching((CFDictionaryRef)query,
					     (CFTypeRef)&result);
  [query release];

  if (status == errSecSuccess || status == errSecItemNotFound) {
    return [result autorelease];
  }

  return nil;
}

/*****************************************************************************
 *
 *	Singleton
 *
 *****************************************************************************/
static MWXKeychainSuite *	sharedInstanceKeychainSuite = nil;
static dispatch_queue_t	serialQueue = NULL;

+(MWXKeychainSuite *)sharedInstance
{
  static dispatch_once_t	onceQueue;

  dispatch_once(&onceQueue, ^{
    sharedInstanceKeychainSuite = [[MWXKeychainSuite alloc] init];
  });

  return sharedInstanceKeychainSuite;
}

+(id)allocWithZone:(NSZone *)zone
{
  static dispatch_once_t	onceQueue;

  dispatch_once(&onceQueue, ^{
    serialQueue = dispatch_queue_create("com.magickworx.class.keychainSuite.serialQueue", NULL);
    if (sharedInstanceKeychainSuite == nil) {
      sharedInstanceKeychainSuite = [super allocWithZone:zone];
    }
  });

  return sharedInstanceKeychainSuite;
}

-(id)copyWithZone:(NSZone *)zone
{
  return self;
}

-(id)retain
{
  return self;
}

-(unsigned)retainCount
{
  return UINT_MAX;	// denotes an object that cannot be released
}

-(oneway void)release
{
  // do nothing
}

-(id)autorelease
{
  return self;
}

@end
