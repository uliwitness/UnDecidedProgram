//
//  UnDecidedMapView.m
//  UnDecidedServer
//
//  Created by Uli Kusterer on 06.01.18.
//  Copyright © 2018 Uli Kusterer. All rights reserved.
//

#import "UnDecidedMapView.h"
#import "UnDecidedPlayer.h"
#import "UnDecidedCharacterImage.h"


@interface UnDecidedMapView ()
{
	BOOL isFirstResponder;
}
@end


@implementation UnDecidedMapView

-(void)	setConnections: (NSArray<UnDecidedPlayer *> *)inConnections
{
	_connections = inConnections;
	[self setNeedsDisplay: YES];
}


- (void)drawRect:(NSRect)dirtyRect
{
	NSString * costumesPath = [[NSString stringWithFormat: @"~/Library/Application Support/%@/Costumes/", [[NSBundle mainBundle].executablePath lastPathComponent]] stringByExpandingTildeInPath];
    for( UnDecidedPlayer * currPlayer in self.connections)
	{
		NSRect	box = { .origin = currPlayer.playerPosition, .size = NSZeroSize };
		box = NSInsetRect(box, -4, -4);
		[[NSBezierPath bezierPathWithOvalInRect: box] fill];
		[currPlayer.userName drawAtPoint:NSMakePoint(NSMaxX(box) +4 , NSMinY(box))
						  withAttributes: @{
											NSFontAttributeName: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]
											}];
		NSString * currPath = [costumesPath stringByAppendingPathComponent: [NSString stringWithFormat: @"%ld/", currPlayer.costumeID]];
		UnDecidedCharacterImage * characterImage = [[UnDecidedCharacterImage alloc] initWithContentsOfDirectory: currPath];
		characterImage.selectedPoseIndex = 0;
		[characterImage.image drawAtPoint: box.origin fromRect: NSZeroRect operation: NSCompositingOperationSourceOver fraction: 1.0];
		
		[NSColor.greenColor set];
		[characterImage forEachBoneAddOffset: box.origin andDo: ^(NSUInteger x, NSPoint tl, NSPoint tr, NSPoint br, NSPoint bl) {
			NSBezierPath * highlightPath = [NSBezierPath bezierPath];
			[highlightPath moveToPoint: tl];
			[highlightPath lineToPoint: tr];
			[highlightPath lineToPoint: br];
			[highlightPath lineToPoint: bl];
			[highlightPath lineToPoint: tl];
			[highlightPath stroke];
		}];
		[NSColor.blackColor set];
	}
}


-(void) mouseDown:(NSEvent *)event
{
	[self.window makeFirstResponder: self];
}


-(BOOL) acceptsFirstResponder
{
	return YES;
}


-(BOOL)becomeFirstResponder
{
	isFirstResponder = YES;
	[self setNeedsDisplay: YES];
	return YES;
}


-(BOOL) resignFirstResponder
{
	isFirstResponder = NO;
	[self setNeedsDisplay: YES];
	return YES;
}


-(void) moveUp:(id)sender
{
	[self.delegate mapView: self moveBy: NSMakePoint(0,5)];
}


-(void) moveDown:(id)sender
{
	[self.delegate mapView: self moveBy: NSMakePoint(0,-5)];
}


-(void) moveLeft:(id)sender
{
	[self.delegate mapView: self moveBy: NSMakePoint(-5,0)];
}


-(void) moveRight:(id)sender
{
	[self.delegate mapView: self moveBy: NSMakePoint(5,0)];
}

@end
