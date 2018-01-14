//
//  AppDelegate.h
//  UnDecidedProgram
//
//  Created by Uli Kusterer on 05.01.18.
//  Copyright © 2018 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class UnDecidedServerConnection;


@interface AppDelegate : NSObject <NSApplicationDelegate>

-(int) socketFD;

-(void) sendOneMessageToAll: (NSString*)msg;
-(void) sendLocationMessagesTo: (UnDecidedServerConnection*)inReceiver;

-(void) closeConnection: (UnDecidedServerConnection*)inReceiver;

@end

