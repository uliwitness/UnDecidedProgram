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
}

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *messageField;
@property (weak) IBOutlet UnDecidedMapView* mapView;
@property (strong) NSMutableDictionary *playerPositions;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	self.playerPositions = [NSMutableDictionary dictionary];
	
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
	
	[self sendOneMessage: @"HEY"];
}


-(void) applicationWillFinishLaunching:(NSNotification *)notification
{
	[self sendOneMessage: @"BYE"];
}


-(void) handleOneMessage: (NSString*)inString
{
	NSLog(@"Received: %@", inString);
	
	if( [inString hasPrefix: @"MEP:"] )
	{
		NSArray *parts = [inString componentsSeparatedByString: @":"];
		if( parts.count < 2 ) return;
		NSString * positionString = parts[1];
		
		myPosition = NSPointFromString(positionString);
		NSLog(@"Server confirmed our position as %f,%f", myPosition.x, myPosition.y);
	}
	else if( [inString hasPrefix: @"POS:"] )
	{
		NSArray *parts = [inString componentsSeparatedByString: @":"];
		if( parts.count < 4 ) return;
		NSString * ipAddress = parts[1];
		NSString * portNumberObj = parts[2];
		NSString * positionString = parts[3];
		
		UnDecidedPlayer * playerObj = [UnDecidedPlayer new];
		playerObj.playerPosition = NSPointFromString(positionString);
		NSString * theKey = [NSString stringWithFormat: @"%@:%@", ipAddress, portNumberObj];
		self.playerPositions[ theKey ] = playerObj;
		NSLog(@"Server updated position of %@ as %f,%f", theKey, myPosition.x, myPosition.y);

		self.mapView.connections = self.playerPositions.allValues;
	}
}


-(void)applicationWillTerminate:(NSNotification *)notification
{
	close(s);
}


-(IBAction) sendMessage: (id)sender
{
	[self sendOneMessage: self.messageField.stringValue];
}


-(void) sendOneMessage: (NSString*)msg
{
	const char* message = msg.UTF8String;
	
	//send the message
	if( sendto(s, message, strlen(message), 0, (struct sockaddr *) &si_other, sizeof(si_other) ) == -1 )
	{
		perror("sendto()");
	}
	else
	{
		NSLog(@"Sent: %s", message);
	}
}


-(void) udpClientThread
{
	socklen_t slen=sizeof(si_other);

	while(true)
	{
		//receive a reply and print it
		char buf[BUFLEN] = {};

		//try to receive some data, this is a blocking call
		NSLog(@"waiting for reply.");
		if( recvfrom(s, buf, BUFLEN, 0, (struct sockaddr *) &si_other, &slen) == -1 )
		{
			perror("recvfrom()");
			continue;
		}
		NSLog(@"\thandling reply.");

		NSString * message = [NSString stringWithUTF8String: buf];
		[self performSelectorOnMainThread: @selector(handleOneMessage:) withObject: message waitUntilDone: NO];
	}
}


-(void)mapView: (UnDecidedMapView*)sender moveBy: (NSPoint)distance
{
	myPosition.x += distance.x;
	myPosition.y += distance.y;
	
	[self sendOneMessage: [NSString stringWithFormat: @"MOV:{%f,%f}", myPosition.x, myPosition.y]];
}

@end
