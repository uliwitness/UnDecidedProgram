//
//  UnDecidedCharacterImage.m
//  UnDecidedServer
//
//  Created by Uli Kusterer on 27.01.18.
//  Copyright © 2018 Uli Kusterer. All rights reserved.
//

#import "UnDecidedCharacterImage.h"


struct UnDecidedSkeletonPoint
{
	NSPoint position;
	CGFloat rotation;
};


@interface UnDecidedSkeleton ()
{
	NSData * pointsArray;
}
@end


@interface UnDecidedCharacterImage ()

@property(strong, readwrite) NSImage * image;

@end




@implementation UnDecidedSkeleton

-(instancetype) initWithContentsOfFile: (NSString*)inPath
{
	self = [super init];
	if( self )
	{
		NSArray<NSDictionary *> * plistRepresentation = [NSArray arrayWithContentsOfFile: inPath];
		if( !plistRepresentation )
		{
			NSLog(@"Error: Couldn't read %@", inPath);
			return nil;
		}
		NSMutableData * pointsArray = [NSMutableData dataWithLength: plistRepresentation.count * sizeof(struct UnDecidedSkeletonPoint)];
		
		struct UnDecidedSkeletonPoint * points = [pointsArray mutableBytes];
		for( NSUInteger x = 0; x < plistRepresentation.count; ++x )
		{
			NSDictionary<NSString*,id> * currPoint = plistRepresentation[x];
			points[x].position = NSPointFromString(currPoint[@"position"]);
			points[x].rotation = [currPoint[@"rotation"] doubleValue];
		}
		
		self->pointsArray = pointsArray;
	}
	
	return self;
}


-(NSUInteger)	count
{
	return [pointsArray length] / sizeof(struct UnDecidedSkeletonPoint);
}


-(NSPoint) pointAtIndex: (NSUInteger)idx
{
	return ((struct UnDecidedSkeletonPoint*)[pointsArray bytes])[idx].position;
}


-(CGFloat) rotationAtIndex: (NSUInteger)idx
{
	return ((struct UnDecidedSkeletonPoint*)[pointsArray bytes])[idx].rotation;
}

@end


@implementation UnDecidedCharacterImage

-(instancetype) initWithContentsOfDirectory: (NSString*)inPath
{
	self = [super init];
	if( self )
	{
		NSError * error = nil;
		NSArray<NSString *> * files = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath: inPath error: &error] sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
		if( !files )
		{
			NSLog(@"Error: %@", error);
			return nil;
		}
		NSMutableArray<UnDecidedSkeleton *> * poses = [NSMutableArray array];
		NSMutableArray<NSImage *> * images = [NSMutableArray array];

		for( NSString * currFile in files )
		{
			if( [currFile hasPrefix: @"."] )
				continue;
			NSString * currPath = [[inPath stringByAppendingString: @"/"] stringByAppendingString: currFile];
			if( [[currFile pathExtension] caseInsensitiveCompare: @"plist"] == NSOrderedSame )
			{
				UnDecidedSkeleton * skeleton = [[UnDecidedSkeleton alloc] initWithContentsOfFile: currPath];
				if( !skeleton )
				{
					NSLog(@"Error: Couldn't load %@", currPath);
					return nil;
				}
				[poses addObject: skeleton];
			}
			else
			{
				NSImage * img = [[NSImage alloc] initWithContentsOfFile: currPath];
				if( !img )
				{
					NSLog(@"No image from path %@", currPath);
					continue;
				}
				[images addObject: img];
			}
		}
		self.poses = poses;
		self.inputImages = images;
	}
	
	return self;
}


-(void) setSelectedPoseIndex: (NSUInteger)selectedPoseIndex
{
	_selectedPoseIndex = selectedPoseIndex;
	
	UnDecidedSkeleton * skeleton = self.poses[selectedPoseIndex];
	
	[NSGraphicsContext saveGraphicsState];
	NSImage * posedImage = [[NSImage alloc] initWithSize: NSMakeSize(128,128)];
	[posedImage lockFocus];
		for( NSInteger x = 0; x < skeleton.count; ++x )
		{
			NSPoint pos = [skeleton pointAtIndex: x];
			CGFloat rotation = [skeleton rotationAtIndex: x];
			NSImage * inputImage = self.inputImages[x];
			[NSGraphicsContext saveGraphicsState];
				NSAffineTransform * rotationTransform = [NSAffineTransform transform];
				[rotationTransform translateXBy: pos.x yBy: pos.y];
				[rotationTransform rotateByDegrees: rotation];
				[rotationTransform concat];
				NSPoint drawPos = NSMakePoint(-truncf(inputImage.size.width / 2.0), -truncf(inputImage.size.height / 2.0));
				[inputImage drawAtPoint: drawPos
							   fromRect: NSZeroRect
							  operation: NSCompositingOperationSourceOver
							   fraction: 1.0];
			[NSGraphicsContext restoreGraphicsState];
		}
	[[NSColor redColor] setFill];
	[posedImage unlockFocus];
	[NSGraphicsContext restoreGraphicsState];

	self.image = posedImage;
}

@end
