//
//  UnDecidedServerConnection.m
//  UnDecidedServer
//
//  Created by Uli Kusterer on 06.01.18.
//  Copyright © 2018 Uli Kusterer. All rights reserved.
//

#import "UnDecidedServerConnection.h"
#include<arpa/inet.h>
#include<sys/socket.h>
#import "AppDelegate.h"


@interface UnDecidedServerConnection ()
{
	struct sockaddr_in si_other;
	NSTimeInterval lastUsedTime;
}

@property (weak) AppDelegate* owner;
@property (copy,readwrite) NSString *sessionID;

@end


@implementation UnDecidedServerConnection

-(instancetype) initWithAddress: (struct sockaddr_in)inAddress owner: (AppDelegate*)inOwner
{
	self = [super init];
	if( self )
	{
		si_other = inAddress;
		self.owner = inOwner;
		self.sessionID = [NSString stringWithFormat: @"%08llx", ((uint64_t)arc4random()) | (((uint64_t)arc4random()) << 32)];
		lastUsedTime = [NSDate timeIntervalSinceReferenceDate];

		[NSTimer scheduledTimerWithTimeInterval: 1.0 repeats: YES block:^(NSTimer * _Nonnull timer) {
			[self sendMessageString: [NSString stringWithFormat: @"Message at %@", [NSDate date]]];
		}];
		
		NSLog(@"Connection created: %@", self);
	}
	return self;
}


-(struct sockaddr_in) socketAddress
{
	return si_other;
}


-(NSTimeInterval) lastUsedTime
{
	return lastUsedTime;
}


-(void) sendMessageString: (NSString*)msg
{
	//print details of the client/peer and the data received
	NSLog(@"Sent: %@" , msg);
	
	const char* buf = [msg UTF8String];
	
	//now reply the client with the same data
	if (sendto(self.owner.socketFD, buf, strlen(buf), 0, (struct sockaddr*) &si_other, sizeof(si_other)) == -1)
	{
		perror("sendto()");
	}
	
	lastUsedTime = [NSDate timeIntervalSinceReferenceDate];
}


-(void) handleOneMessageString: (NSString*)inMessage
{
	NSLog(@"Received: %@", inMessage);
	
	NSArray<NSString *> *parts = [inMessage componentsSeparatedByString: @":"];
	NSString * appSupportPath = [@"~/Library/Application Support/UnDecidedServer/Users/" stringByExpandingTildeInPath];
	NSString * userInfoPath = [appSupportPath stringByAppendingPathComponent: [NSString stringWithFormat: @"%@.plist", self.userName]];

	// All requests except "HEY" include a session ID as the second part.
	if( [parts[0] isEqualToString: @"HEY"] )	// A client just "connected".
	{
		NSError * err = nil;
		if( ![[NSFileManager defaultManager] fileExistsAtPath: appSupportPath] )
		{
			if( ![[NSFileManager defaultManager] createDirectoryAtPath: appSupportPath withIntermediateDirectories: YES attributes: nil error: &err] )
			{
				[self sendMessageString: [NSString stringWithFormat: @"ERR:NotLoggedIn:%@", err.localizedFailureReason]];
				return;
			}
		}

		NSDictionary * userInfo = nil;
		if( ![[NSFileManager defaultManager] fileExistsAtPath: userInfoPath] )
		{
			userInfo = @{ @"position": @"{0,0}", @"costumeID": @"1" };
			if( ![userInfo writeToFile: userInfoPath atomically: YES] )
			{
				[self sendMessageString: [NSString stringWithFormat: @"ERR:NotLoggedIn:%@", err.localizedFailureReason]];
				return;
			}
		} else {
			userInfo = [NSDictionary dictionaryWithContentsOfFile: userInfoPath];
		}
		
		NSString * posMessageToSelf;

		@synchronized(self)
		{
			self.playerPosition = NSPointFromString(userInfo[@"position"]);
			self.costumeID = [userInfo[@"costumeID"] integerValue];
			posMessageToSelf = [NSString stringWithFormat: @"MEP:{%f,%f}:%ld:%ld", self.playerPosition.x, self.playerPosition.y, (long)self.costumeID, (long)self.animationID];
		}
		
		// Tell the client about the session ID it should use in future requests:
		[self sendMessageString: [NSString stringWithFormat: @"HEY:%@", self.sessionID]];

		// Tell the client about its current position:
		[self sendMessageString: posMessageToSelf];
		
		// Tell the client about every other client's position:
		[self.owner sendLocationMessagesTo: self];
	}
	else if( [parts[0] isEqualToString: @"MOV"] ) // A client would like to move elsewhere.
	{
		if( parts.count < 3 )
		{
			NSLog(@"MOV command by %@ ended early.", self.userName);
			return;
		}
		NSPoint desiredPosition = NSPointFromString(parts[2]);
		CGFloat xDist = fabs(desiredPosition.x -self.playerPosition.x);
		CGFloat yDist = fabs(desiredPosition.y -self.playerPosition.y);
		CGFloat asTheCrowFlies = sqrt(xDist * xDist + yDist * yDist);
		NSLog(@"Request to move %@ (%s:%d) by %f", self.userName, inet_ntoa(si_other.sin_addr), ntohs(si_other.sin_port), asTheCrowFlies);
		if( asTheCrowFlies < 20 )
		{
			NSString * posChangeMessageToSelf;
			NSString * posChangeMessageToOthers;
			NSDictionary * userInfo;
			
			@synchronized(self)
			{
				self.playerPosition = desiredPosition;
				posChangeMessageToSelf = [NSString stringWithFormat: @"MEP:{%f,%f}:%ld:%ld", self.playerPosition.x, self.playerPosition.y, (long)self.costumeID, (long)self.animationID];
				posChangeMessageToOthers = [NSString stringWithFormat: @"POS:%s:%d:{%f,%f}:%ld:%ld:%@", inet_ntoa(si_other.sin_addr), ntohs(si_other.sin_port), self.playerPosition.x, self.playerPosition.y, (long)self.costumeID, (long)self.animationID, self.userName];
				userInfo = @{ @"position": NSStringFromPoint(self.playerPosition), @"costumeID": @(self.costumeID) };
			}
			
			[self sendMessageString: posChangeMessageToSelf];
			[self.owner sendOneMessageToAll: posChangeMessageToOthers];
			[userInfo writeToFile:userInfoPath atomically:YES];
		}
		else	// Move exceeds possible step size. Remind client of actual position.
		{
			NSString * posChangeMessageToSelf;
			NSString * posChangeMessageToOthers;

			@synchronized(self)
			{
				posChangeMessageToSelf = [NSString stringWithFormat: @"MEP:{%f,%f}:%ld:%ld", self.playerPosition.x, self.playerPosition.y, (long)self.costumeID, (long)self.animationID];
				posChangeMessageToOthers = [NSString stringWithFormat: @"POS:%s:%d:{%f,%f}:%ld:%ld:%@", inet_ntoa(si_other.sin_addr), ntohs(si_other.sin_port), self.playerPosition.x, self.playerPosition.y, (long)self.costumeID, (long)self.animationID, self.userName];
			}
			
			[self sendMessageString: posChangeMessageToSelf];
			[self sendMessageString: posChangeMessageToOthers];	// Only re-send the "outside view" message to the client, which is obviously misinformed, don't flood all other clients.
		}
	}
	else if( [parts[0] isEqualToString: @"BYE"] ) // A client is quitting, clean up the "connection" object.
	{
		NSLog(@"Request to log out %@ from %s:%d", self.userName, inet_ntoa(si_other.sin_addr), ntohs(si_other.sin_port));
		[self.owner performSelectorOnMainThread: @selector(closeConnection:) withObject: self waitUntilDone: NO];
	}
	else
	{
		NSString * cmd = parts[0];
		if( [cmd rangeOfCharacterFromSet: [[NSCharacterSet alphanumericCharacterSet] invertedSet]].location != NSNotFound )	// Commands should be alphanumeric, if not, someone's trying to inject something into our reply.
		{
			cmd = @"";
		}
		[self sendMessageString: [NSString stringWithFormat: @"ERR:UnknownCommand '%@'", cmd]];
	}

	lastUsedTime = [NSDate timeIntervalSinceReferenceDate];
}


-(void)	sendLocationMessageTo: (UnDecidedServerConnection*)inReceiver
{
	NSString * msgString = [NSString stringWithFormat: @"POS:%s:%d:{%f,%f}:%ld:%ld:%@", inet_ntoa(si_other.sin_addr), ntohs(si_other.sin_port), self.playerPosition.x, self.playerPosition.y, (long)self.costumeID, (long)self.animationID, self.userName];
	[inReceiver sendMessageString: msgString];
}


-(NSString*) description
{
	return [NSString stringWithFormat: @"<%@ %p>{ userName = %@, sessionID = %@, ip = %s, port = %d, costume = %ld, animation = %ld }", self.className, self, self.userName, self.sessionID, inet_ntoa(si_other.sin_addr), ntohs(si_other.sin_port), (long)self.costumeID, (long)self.animationID];
}

@end
