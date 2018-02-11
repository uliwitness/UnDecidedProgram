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


-(BOOL)	acceptsFirstResponder
{
	return YES;
}


-(BOOL)	becomeFirstResponder
{
	return YES;
}


-(void)	keyDown:(NSEvent *)event
{
	NSString * typedCharacters = event.charactersIgnoringModifiers;
	unichar typedCharacter = typedCharacters.length > 0 ? [typedCharacters characterAtIndex: 0] : 0;
	switch( typedCharacter )
	{
		case NSLeftArrowFunctionKey:
		{
			NSPoint pos = [_characterImage.selectedPose pointAtIndex: _selectedBoneIndex];
			pos.x -= 1;
			[_characterImage.selectedPose setPoint: pos atIndex: _selectedBoneIndex];
			[_characterImage display];
			self.image = _characterImage.image;
			[self setNeedsDisplay: YES];
			break;
		}
		
		case NSRightArrowFunctionKey:
		{
			NSPoint pos = [_characterImage.selectedPose pointAtIndex: _selectedBoneIndex];
			pos.x += 1;
			[_characterImage.selectedPose setPoint: pos atIndex: _selectedBoneIndex];
			[_characterImage display];
			self.image = _characterImage.image;
			[self setNeedsDisplay: YES];
			break;
		}

		case NSUpArrowFunctionKey:
		{
			NSPoint pos = [_characterImage.selectedPose pointAtIndex: _selectedBoneIndex];
			pos.y += 1;
			[_characterImage.selectedPose setPoint: pos atIndex: _selectedBoneIndex];
			[_characterImage display];
			self.image = _characterImage.image;
			[self setNeedsDisplay: YES];
			break;
		}
			
		case NSDownArrowFunctionKey:
		{
			NSPoint pos = [_characterImage.selectedPose pointAtIndex: _selectedBoneIndex];
			pos.y -= 1;
			[_characterImage.selectedPose setPoint: pos atIndex: _selectedBoneIndex];
			[_characterImage display];
			self.image = _characterImage.image;
			[self setNeedsDisplay: YES];
			break;
		}
			
		case 'a':
		case 'w':
		{
			CGFloat angle = [_characterImage.selectedPose rotationAtIndex: _selectedBoneIndex];
			angle -= 10;
			if( angle < 0 ) angle = 350;
			[_characterImage.selectedPose setRotation: angle atIndex: _selectedBoneIndex];
			[_characterImage display];
			self.image = _characterImage.image;
			[self setNeedsDisplay: YES];
			break;
		}
			
		case 'd':
		case 's':
		{
			CGFloat angle = [_characterImage.selectedPose rotationAtIndex: _selectedBoneIndex];
			angle += 10;
			if( angle > 359 ) angle = 0;
			[_characterImage.selectedPose setRotation: angle atIndex: _selectedBoneIndex];
			[_characterImage display];
			self.image = _characterImage.image;
			[self setNeedsDisplay: YES];
			break;
		}
			
		case 0x19:
		{
			if( _selectedBoneIndex > 0 )
			{
				--_selectedBoneIndex;
				[self.window selectPreviousKeyView: self];
			}
			[self setNeedsDisplay: YES];
			break;
		}
			
		case '\t':
		{
			++_selectedBoneIndex;
			if( _selectedBoneIndex >= _characterImage.selectedPose.count )
			{
				_selectedBoneIndex = 0;
				[self.window selectNextKeyView: self];
			}
			[self setNeedsDisplay: YES];
			break;
		}
	}
}


-(void)	mouseDown:(NSEvent *)event
{
	[self.window makeFirstResponder: self];
	
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
