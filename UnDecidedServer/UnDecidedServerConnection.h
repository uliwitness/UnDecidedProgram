//
//  UnDecidedServerConnection.h
//  UnDecidedServer
//
//  Created by Uli Kusterer on 06.01.18.
//  Copyright © 2018 Uli Kusterer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UnDecidedPlayer.h"


@class AppDelegate;

@interface UnDecidedServerConnection : UnDecidedPlayer

-(instancetype) initWithAddress: (struct sockaddr_in)inAddress owner: (AppDelegate*)owner;

@property (copy,readonly) NSString *sessionID;

-(struct sockaddr_in) socketAddress;
-(NSTimeInterval) lastUsedTime;

-(void) sendMessageString: (NSString*)msg;
-(void) handleOneMessageString: (NSString*)msg;
-(void)	sendLocationMessageTo: (UnDecidedServerConnection*)inReceiver;

@end
