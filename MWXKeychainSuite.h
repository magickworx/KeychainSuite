/*****************************************************************************
 *
 * FILE:	MWXKeychainSuite.h
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
 * $Id: MWXKeychainSuite.h,v 1.1 2011/12/03 20:17:35 kouichi Exp $
 *
 *****************************************************************************/

#import <Foundation/Foundation.h>

@interface MWXKeychainSuite : NSObject
{
@private
  NSString *		_identifier;	// App ID or Bundle ID
  NSString *		_accessGroup;
  NSMutableDictionary *	_items;
  NSMutableDictionary *	_query;
}

@property (nonatomic,readonly) NSString *	identifier;
@property (nonatomic,readonly) NSString *	accessGroup;

+(MWXKeychainSuite *)sharedInstance;

-(id)init;
-(id)initWithIdentifier:(NSString *)identifier;
-(id)initWithIdentifier:(NSString *)identifier accessGroup:(NSString *)accessGroup;

-(void)setObject:(id)object forKey:(NSString *)key;
-(id)objectForKey:(NSString *)key;

-(BOOL)containsObjectForKey:(NSString *)key;

-(NSString *)stringForKey:(NSString *)key;
-(NSNumber *)numberForKey:(NSString *)key;
-(NSArray *)arrayForKey:(NSString *)key;
-(NSDictionary *)dictionaryForKey:(NSString *)key;
-(NSData *)dataForKey:(NSString *)key;

-(NSInteger)integerForKey:(NSString *)key;
-(float)floatForKey:(NSString *)key;
-(double)doubleForKey:(NSString *)key;
-(BOOL)boolForKey:(NSString *)key;

-(void)setInteger:(NSInteger)value forKey:(NSString *)key;
-(void)setFloat:(float)value forKey:(NSString *)key;
-(void)setDouble:(double)value forKey:(NSString *)key;
-(void)setBool:(BOOL)value forKey:(NSString *)key;

-(void)removeObjectForKey:(NSString *)key;
-(void)removeAllObjects;

-(void)synchronize;

@end
