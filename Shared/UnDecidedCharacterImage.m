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
		NSMutableData * pointsArray = [NSMutableData dataWithLength: plistRepresentation.count * sizeof(struct UnDecidedSkeletonPoint)];
		
		struct UnDecidedSkeletonPoint * points = [pointsArray mutableBytes];
		for( NSUInteger x = 0; x < plistRepresentation.count; ++x )
		{
			NSDictionary<NSString*,id> * currPoint = plistRepresentation[x];
			points[x].position = NSPointFromString(currPoint[@"position"]);
			points[x].rotation = [currPoint[@"rotation"] doubleValue];
		}
		
		self.pointsArray = pointsArray;
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

-(void) setSelectedPoseIndex: (NSUInteger)selectedPoseIndex
{
	_selectedPoseIndex = selectedPoseIndex;
	
	UnDecidedSkeleton * skeleton = self.poses[selectedPoseIndex];
	
	NSImage * posedImage = [[NSImage alloc] initWithSize: NSSize(128,128)];
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
				[inputImage drawAtPoint: NSMakePoint(-truncf(inputImage.size.width / 2.0), -truncf(inputImage.size.height / 2.0))
							   fromRect: NSZeroRect
							  operation: NSCompositingOperationSourceAtop
							   fraction: 1.0];
			[NSGraphicsContext restoreGraphicsState];
		}
	[posedImage unlockFocus];
	
	self.image = posedImage;
}

@end
