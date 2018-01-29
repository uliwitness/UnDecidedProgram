//
//  UnDecidedCharacterImageEditView.m
//  UnDecidedEditor
//
//  Created by Uli Kusterer on 29.01.18.
//  Copyright © 2018 Uli Kusterer. All rights reserved.
//

#import "UnDecidedCharacterImageEditView.h"

@implementation UnDecidedCharacterImageEditView

-(void) drawRect:(NSRect)dirtyRect
{
	[super drawRect: dirtyRect];
	
	[_characterImage forEachBoneAddOffset:NSZeroPoint andDo:^(NSUInteger x, NSPoint tl, NSPoint tr, NSPoint br, NSPoint bl) {
		if( x == _selectedBoneIndex )
		{
			NSBezierPath * clickPath = [NSBezierPath bezierPath];
			[clickPath moveToPoint: tl];
			[clickPath lineToPoint: tr];
			[clickPath lineToPoint: br];
			[clickPath lineToPoint: bl];
			[clickPath lineToPoint: tl];
			[NSColor.cyanColor set];
			[clickPath stroke];
		}
	}];
}


-(void)	mouseDown:(NSEvent *)event
{
	NSPoint pos = [self convertPoint: event.locationInWindow fromView: nil];
	__block NSUInteger clickedIndex = NSNotFound;
	
	[_characterImage forEachBoneAddOffset:NSZeroPoint andDo:^(NSUInteger x, NSPoint tl, NSPoint tr, NSPoint br, NSPoint bl) {
		NSBezierPath * clickPath = [NSBezierPath bezierPath];
		[clickPath moveToPoint: tl];
		[clickPath lineToPoint: tr];
		[clickPath lineToPoint: br];
		[clickPath lineToPoint: bl];
		[clickPath lineToPoint: tl];
		
		if( [clickPath containsPoint: pos] )
			clickedIndex = x;
	}];
	
	_selectedBoneIndex = clickedIndex;
	[self setNeedsDisplay: YES];
}


-(void)	setCharacterImage: (UnDecidedCharacterImage *)characterImage
{
	_characterImage = characterImage;
	NSImage * cocoaImage = characterImage.image;
	self.image = cocoaImage;
}

@end
