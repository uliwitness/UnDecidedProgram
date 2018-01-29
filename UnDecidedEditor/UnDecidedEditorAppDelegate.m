//
//  UnDecidedEditorAppDelegate.m
//  UnDecidedEditor
//
//  Created by Uli Kusterer on 29.01.18.
//  Copyright © 2018 Uli Kusterer. All rights reserved.
//

#import "UnDecidedEditorAppDelegate.h"
#import "UnDecidedCharacterImage.h"
#import "UnDecidedCharacterImageEditView.h"


@interface UnDecidedEditorAppDelegate ()

@property (strong) UnDecidedCharacterImage * characterImage;

@property (weak) IBOutlet NSWindow * window;
@property (weak) IBOutlet UnDecidedCharacterImageEditView * editView;

@end

@implementation UnDecidedEditorAppDelegate

- (void)applicationDidFinishLaunching: (NSNotification *)aNotification
{
	// Insert code here to initialize your application
}


-(void)	applicationWillTerminate: (NSNotification *)aNotification
{
	// Insert code here to tear down your application
}


-(BOOL)	application: (NSApplication *)sender openFile: (NSString *)filename
{
	self.characterImage = [[UnDecidedCharacterImage alloc] initWithContentsOfDirectory: filename];
	self.characterImage.selectedPoseIndex = 0;
	_editView.characterImage = self.characterImage;
	[_editView setNeedsDisplay: YES];
	
	return YES;
}

@end
