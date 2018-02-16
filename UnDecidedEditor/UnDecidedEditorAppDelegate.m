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
@property (copy) NSString * characterImagePath;

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
	self.characterImagePath = filename;
	self.characterImage = [[UnDecidedCharacterImage alloc] initWithContentsOfDirectory: filename];
	self.characterImage.selectedPoseIndex = 0;
	_editView.characterImage = self.characterImage;
	[_editView setNeedsDisplay: YES];
	
	[self.window setTitleWithRepresentedFilename:self.characterImagePath];

	return YES;
}


-(BOOL) validateMenuItem:(NSMenuItem *)menuItem
{
	if( menuItem.action == @selector(saveDocument:) || menuItem.action == @selector(saveDocumentAs:) )
	{
		return self.characterImagePath != nil;
	}
	else
		return [self respondsToSelector: menuItem.action];
}


-(IBAction)	saveDocument: (id)sender
{
	if( !self.characterImagePath ) return;
	
	[self.characterImage writeToDirectory: self.characterImagePath];
}


-(IBAction)	saveDocumentAs: (id)sender
{
	if( !self.characterImagePath ) return;
	
	NSSavePanel * savePanel = [NSSavePanel savePanel];
	NSModalResponse response = [savePanel runModal];
	if( response == NSModalResponseOK )
	{
		NSString * newPath = savePanel.URL.path;
		
		NSError * error = nil;
		if( ![[NSFileManager defaultManager] copyItemAtPath: self.characterImagePath toPath: newPath error: &error] )
		{
			[[NSApplication sharedApplication] presentError: error];
			return;
		}
		
		self.characterImagePath = newPath;
		[self.characterImage writeToDirectory: self.characterImagePath];
		[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL: savePanel.URL];
		[self.window setTitleWithRepresentedFilename:savePanel.URL.path];
	}

}


-(IBAction)	openDocument: (id)sender
{
	NSOpenPanel * openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles: NO];
	[openPanel setCanChooseDirectories: YES];
	
	NSModalResponse response = [openPanel runModal];
	if( response == NSModalResponseOK )
	{
		NSURL * urlToOpen = openPanel.URLs.firstObject;
		[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL: urlToOpen];
		[self application: [NSApplication sharedApplication] openFile: urlToOpen.path];
	}
}

@end
