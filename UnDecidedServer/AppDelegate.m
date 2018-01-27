//
//  AppDelegate.m
//  UnDecidedProgram
//
//  Created by Uli Kusterer on 05.01.18.
//  Copyright © 2018 Uli Kusterer. All rights reserved.
//

// Based on an example from http://www.binarytides.com/programming-udp-sockets-c-linux/

#import "AppDelegate.h"
#include<stdio.h> //printf
#include<string.h> //memset
#include<stdlib.h> //exit(0);
#include<arpa/inet.h>
#include<sys/socket.h>
#import "UnDecidedServerConnection.h"
#import "UnDecidedMapView.h"


#define BUFLEN 512  //Max length of buffer
#define PORT 13762   //The port on which to listen for incoming data
#define MIN_PASSWORD_LENGTH 6


@interface AppDelegate ()
{
	int s;
	BOOL keepRunning;
}

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet UnDecidedMapView *mapView;
@property NSMutableDictionary<NSString *,NSString *> *passwordsForUsernames;
@property (strong) NSMutableArray<UnDecidedServerConnection *> *connections;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	self.connections = [NSMutableArray array];
	NSString * passwordsFile = [@"~/Library/Application Support/UnDecidedServer/Passwords.plist" stringByExpandingTildeInPath];
	NSError *error = nil;
	[[NSFileManager defaultManager] createDirectoryAtPath: [passwordsFile stringByDeletingLastPathComponent] withIntermediateDirectories: NO attributes: nil error: &error];
	self.passwordsForUsernames = [NSMutableDictionary dictionaryWithContentsOfFile: passwordsFile];
	if( self.passwordsForUsernames == nil )
	{
		self.passwordsForUsernames = [NSMutableDictionary dictionaryWithObjectsAndKeys: @"Insecure", @"admin", nil];
		[self.passwordsForUsernames writeToFile: passwordsFile atomically: YES];
	}
	
	struct sockaddr_in si_me = {};
	
	//create a UDP socket
	if ((s=socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) == -1)
	{
		perror("socket");
		return;
	}
	
	int reuse = 1;
	if( setsockopt(s, SOL_SOCKET, SO_REUSEADDR, &reuse, sizeof(reuse)) < 0 )
	{
		perror("SO_REUSEADDR");
		close(s);
		return;
	}
	
	if( setsockopt(s, SOL_SOCKET, SO_REUSEPORT, &reuse, sizeof(reuse)) < 0 )
	{
		perror("SO_REUSEPORT");
		close(s);
		return;
	}

	si_me.sin_family = AF_INET;
	si_me.sin_port = htons(PORT);
	si_me.sin_addr.s_addr = htonl(INADDR_ANY);
	
	//bind socket to port
	if( bind(s, (struct sockaddr*)&si_me, sizeof(si_me) ) == -1)
	{
		perror("bind");
		close(s);
		s = -1;
		return;
	}
	
	keepRunning = YES;
	[NSThread detachNewThreadSelector: @selector(udpServerMainThread) toTarget: self withObject: nil];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	keepRunning = NO;
	close(s);
}


-(int) socketFD
{
	return s;
}

- (void)udpServerMainThread
{
	//keep listening for data
	while(keepRunning)
	{
		fflush(stdout);
		
		//try to receive some data, this is a blocking call
		struct sockaddr_in si_other = {};
		ssize_t recv_len;
		socklen_t slen = sizeof(si_other);
		char buf[BUFLEN +1] = {};	// +1 to ensure it's always terminated.
		if ((recv_len = recvfrom(s, buf, BUFLEN, 0, (struct sockaddr *) &si_other, &slen)) == -1)
		{
			perror("recvfrom()");
			continue;
		}
		NSLog(@"Received %zu bytes", recv_len);
		
		NSString * loggedInUserName = nil;
		UnDecidedServerConnection* foundConnection = nil;
		NSString * message = [NSString stringWithUTF8String: buf];
		NSArray<NSString *> *messageParts = [message componentsSeparatedByString: @":"];
		if( [messageParts.firstObject isEqualToString: @"HEY"] )
		{
			if( messageParts.count < 3 ) { NSLog(@"Ignoring. Only %ld components in HEY.", (long)messageParts.count); continue; }
			NSString * requestedUserName = messageParts[1].stringByRemovingPercentEncoding;
			if( [requestedUserName rangeOfString: @"/"].location != NSNotFound || [requestedUserName rangeOfString: @".."].location != NSNotFound )
			{
				continue;
			}
			
			NSString * password = messageParts[2].stringByRemovingPercentEncoding;
			
			NSString * actualPassword = self.passwordsForUsernames[requestedUserName];
			if( [actualPassword isEqualToString: password] && [actualPassword length] > MIN_PASSWORD_LENGTH )
				loggedInUserName = requestedUserName;

			@synchronized(self.connections)
			{
				for( UnDecidedServerConnection* currConnection in self.connections )
				{
					if( [loggedInUserName isEqualToString: currConnection.userName]  )
					{
						if( si_other.sin_family != currConnection.socketAddress.sin_family
						   || si_other.sin_addr.s_addr != currConnection.socketAddress.sin_addr.s_addr
						   || si_other.sin_port != currConnection.socketAddress.sin_port )
						{
							[self closeConnection: currConnection];	// Log out old session, below will make a new one.
							break;
						}
						else
							foundConnection = currConnection;
						break;
					}
				}
			}
			
			if( !foundConnection )
			{
				foundConnection = [[UnDecidedServerConnection alloc] initWithAddress: si_other owner: self];
				foundConnection.userName = loggedInUserName;
				@synchronized(self.connections)
				{
					[self.connections addObject: foundConnection];
				}
			}
			else
			{
				NSLog(@"Re-using connection %@", foundConnection);
			}
		}
		else
		{
			if( messageParts.count < 2 ) { NSLog(@"Ignoring. Only %ld components in command.", (long)messageParts.count); continue; }
			
			NSString * sessionID = messageParts[1];
			
			@synchronized(self.connections)
			{
				for( UnDecidedServerConnection* currConnection in self.connections )
				{
					if( [sessionID isEqualToString: currConnection.sessionID]  )
					{
						if( si_other.sin_family != currConnection.socketAddress.sin_family
						   || si_other.sin_addr.s_addr != currConnection.socketAddress.sin_addr.s_addr
						   || si_other.sin_port != currConnection.socketAddress.sin_port )
						{
							[self closeConnection: currConnection];
							break;
						}
						else
							foundConnection = currConnection;
						break;
					}
				}
			}
		}
		
		if( !foundConnection )
		{
			NSLog(@"No valid connection found for session '%@'.", (messageParts.count > 1) ? messageParts[1] : @"");
			const char* buf = [@"ERR:NotLoggedIn" UTF8String];
			
			if (sendto(s, buf, strlen(buf), 0, (struct sockaddr*) &si_other, sizeof(si_other)) == -1)
			{
				perror("sendto()");
			}
			continue;
		}
		
		NSLog(@"Using connection %@", foundConnection);
		
		[foundConnection performSelectorOnMainThread: @selector(handleOneMessageString:) withObject: message waitUntilDone: NO];
	}
}


-(void) sendOneMessageToAll: (NSString*)msg;
{
	dispatch_async( dispatch_get_main_queue(), ^{
		@synchronized(self.connections)
		{
			[self.connections makeObjectsPerformSelector: @selector(sendMessageString:) withObject: msg];
			[self.mapView setConnections: [self.connections copy]];
		}
	});
}


-(void) sendLocationMessagesTo: (UnDecidedServerConnection*)inReceiver
{
	dispatch_async( dispatch_get_main_queue(), ^{
		@synchronized(self.connections)
		{
			[self.connections makeObjectsPerformSelector: @selector(sendLocationMessageTo:) withObject: inReceiver];
			[self.mapView setConnections: [self.connections copy]];
		}
	});
}


-(void) closeConnection: (UnDecidedServerConnection*)inReceiver
{
	dispatch_async( dispatch_get_main_queue(), ^{
		[inReceiver performSelectorOnMainThread: @selector(sendMessageString:) withObject: @"BYE" waitUntilDone: NO];
		@synchronized(self.connections)
		{
			[self.connections removeObject: inReceiver];
			[self.mapView setConnections: [self.connections copy]];
		}
	});
}

@end
