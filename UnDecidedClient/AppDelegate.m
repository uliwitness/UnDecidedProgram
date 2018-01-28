//
//  AppDelegate.m
//  UnDecidedClient
//
//  Created by Uli Kusterer on 05.01.18.
//  Copyright © 2018 Uli Kusterer. All rights reserved.
//

// Based on an example from http://www.binarytides.com/programming-udp-sockets-c-linux/

#import "AppDelegate.h"
#import "UnDecidedMapView.h"
#import "UnDecidedPlayer.h"
#include<stdio.h> //printf
#include<string.h> //memset
#include<stdlib.h> //exit(0);
#include<arpa/inet.h>
#include<sys/socket.h>


#define SERVER "127.0.0.1"
#define BUFLEN 512  //Max length of buffer
#define PORT 13762   //The port on which to send data


@interface AppDelegate () <UnDecidedMapDelegate>
{
	struct sockaddr_in si_other;
	int s;
	NSPoint myPosition;
	NSUInteger myCostumeID;
	NSUInteger myAnimationID;
	BOOL keepReceiving;
}

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *userNameField;
@property (weak) IBOutlet NSTextField *passwordField;
@property (weak) IBOutlet NSButton *logInButton;
@property (weak) IBOutlet NSButton *logOutButton;
@property (weak) IBOutlet UnDecidedMapView* mapView;
@property (strong) NSMutableDictionary *playerPositions;
@property (copy) NSString *sessionID;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	self.playerPositions = [NSMutableDictionary dictionary];
	[self updateLogInUI];

	NSError * error = nil;
	NSString * costumesPath = [[NSString stringWithFormat: @"~/Library/Application Support/%@/Costumes/", [[NSBundle mainBundle].executablePath lastPathComponent]] stringByExpandingTildeInPath];
	if( ![[NSFileManager defaultManager] fileExistsAtPath: costumesPath] )
	{
		[[NSFileManager defaultManager] createDirectoryAtPath: [costumesPath stringByDeletingLastPathComponent] withIntermediateDirectories: YES attributes: nil error: &error];
		NSString * originalPath = [[NSBundle mainBundle] pathForResource:@"Costumes" ofType:@"" inDirectory:@""];
		[[NSFileManager defaultManager] copyItemAtPath: originalPath toPath: costumesPath error: &error];
	}
}


-(void) handleOneMessage: (NSString*)inString
{
	NSLog(@"Received: %@", inString);
	
	NSArray *parts = [inString componentsSeparatedByString: @":"];
	if( [inString hasPrefix: @"HEY:"] )	// Answer to our "HEY"! We're logged in!
	{
		if( parts.count < 2 ) { NSLog(@"Ignoring. Only %ld components in HEY.", (long)parts.count); return; }
		self.sessionID = parts[1];
		self.playerPositions = [NSMutableDictionary dictionary];

		[self updateLogInUI];
	}
	else if( self.sessionID && [inString hasPrefix: @"MEP:"] )	// My position
	{
		if( parts.count < 4 ) { NSLog(@"Ignoring. Only %ld components in MEP.", (long)parts.count); return; }
		NSString * positionString = parts[1];
		myCostumeID = [parts[2] integerValue];
		myAnimationID = [parts[3] integerValue];

		myPosition = NSPointFromString(positionString);
		NSLog(@"Server confirmed our position as %f,%f and costume %ld (animation %ld)", myPosition.x, myPosition.y, (long)myCostumeID, (long)myAnimationID);
	}
	else if( self.sessionID && [inString hasPrefix: @"POS:"] ) // Some other player's position
	{
		if( parts.count < 7 ) { NSLog(@"Ignoring. Only %ld components in POS.", (long)parts.count); return; }
		NSString * ipAddress = parts[1];
		NSString * portNumberObj = parts[2];
		NSString * positionString = parts[3];
		NSInteger costumeID = [parts[4] integerValue];
		NSInteger animationID = [parts[5] integerValue];
		NSString * userName = parts[6];

		UnDecidedPlayer * playerObj = [UnDecidedPlayer new];
		playerObj.playerPosition = NSPointFromString(positionString);
		playerObj.costumeID = costumeID;
		playerObj.animationID = animationID;
		playerObj.userName = userName;
		NSString * theKey = [NSString stringWithFormat: @"%@:%@", ipAddress, portNumberObj];
		self.playerPositions[ theKey ] = playerObj;
		NSLog(@"Server updated position of %@ as %f,%f and costume %ld (animation %ld)", theKey, playerObj.playerPosition.x, playerObj.playerPosition.y, (long)costumeID, (long)animationID);

		self.mapView.connections = self.playerPositions.allValues;
	}
	else if( self.sessionID && [inString isEqualToString: @"BYE"] )
	{
		[self updateLogInUI];
	}
	else if( [inString hasPrefix: @"ERR:"] )	// Could be an error during login, so might not have a session yet.
	{
		if( self.sessionID && (parts.count > 1) && [parts[1] isEqualToString: @"NotLoggedIn"] )	// Server logged us out?
		{
			self.sessionID = nil;
			[self updateLogInUI];
		}
		NSRunAlertPanel( @"Error", @"%@", @"OK", @"", @"", inString );
	}
}


-(void) updateLogInUI
{
	self.logInButton.enabled = (self.sessionID == nil);
	self.userNameField.enabled = (self.sessionID == nil);
	self.passwordField.enabled = (self.sessionID == nil);
	self.logOutButton.enabled = (self.sessionID != nil);
}


-(IBAction) logOut: (id)sender
{
	if( self.sessionID )
	{
		[self sendOneMessage: [NSString stringWithFormat: @"BYE:%@", self.sessionID]];
		[self.mapView setConnections: @[]];
		self.sessionID = nil;
	}
	[self updateLogInUI];
}


-(NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	[self logOut: self];
	return NSTerminateNow;
}


-(void)applicationWillTerminate:(NSNotification *)notification
{
	keepReceiving = NO;
	close(s);
	s = -1;
}


-(IBAction) logIn: (id)sender
{
	if( (s = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) == -1 )
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
	
	memset((char *) &si_other, 0, sizeof(si_other));
	si_other.sin_family = AF_INET;
	si_other.sin_port = htons(PORT);
	
	if (inet_aton(SERVER, &si_other.sin_addr) == 0)
	{
		fprintf(stderr, "inet_aton() failed\n");
		close(s);
		return;
	}
	
	[NSThread detachNewThreadSelector: @selector(udpClientThread) toTarget: self withObject: nil];
	
	NSCharacterSet * colonSafeCS = [[NSCharacterSet characterSetWithCharactersInString: @":\r\n"] invertedSet];
	NSString * loginMessage = [NSString stringWithFormat: @"HEY:%@:%@", [self.userNameField.stringValue stringByAddingPercentEncodingWithAllowedCharacters: colonSafeCS], [self.passwordField.stringValue stringByAddingPercentEncodingWithAllowedCharacters: colonSafeCS]];
	[self sendOneMessage: loginMessage];
}


-(void) sendOneMessage: (NSString*)msg
{
	NSLog(@"Send: %@", msg);
	
	const char* message = msg.UTF8String;
	
	//send the message
	if( sendto(s, message, strlen(message), 0, (struct sockaddr *) &si_other, sizeof(si_other) ) == -1 )
	{
		perror("sendto()");
	}
}


-(void) udpClientThread
{
	keepReceiving = YES;
	
	while(keepReceiving)
	{
		//receive a reply and print it
		char buf[BUFLEN] = {};

		struct sockaddr_in si_sender = {};
		socklen_t slen = sizeof(si_sender);
		
		//try to receive some data, this is a blocking call
		NSLog(@"waiting for reply.");
		size_t receivedAmount = recvfrom(s, buf, BUFLEN, 0, (struct sockaddr *) &si_sender, &slen);
		if(receivedAmount  == -1 )
		{
			perror("recvfrom()");
			continue;
		}
		NSLog(@"\thandling reply of length %zu.", receivedAmount);

		NSString * message = [NSString stringWithUTF8String: buf];
		[self performSelectorOnMainThread: @selector(handleOneMessage:) withObject: message waitUntilDone: NO];
	}
}


-(void)mapView: (UnDecidedMapView*)sender moveBy: (NSPoint)distance
{
	myPosition.x += distance.x;
	myPosition.y += distance.y;
	
	[self sendOneMessage: [NSString stringWithFormat: @"MOV:%@:{%f,%f}", self.sessionID, myPosition.x, myPosition.y]];
}

@end
