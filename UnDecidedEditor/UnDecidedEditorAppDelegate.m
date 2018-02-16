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
@property (weak) IBOutlet NSButton *goNextSkeletonButton;
@property (weak) IBOutlet NSButton *goPreviousSkeletonButton;
@property (weak) IBOutlet NSTextField *currentPoseField;

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
	[self updateUIAfterSkeletonChange];

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


-(void) updateUIAfterSkeletonChange
{
	[self.editView.characterImage display];
	self.editView.image = self.editView.characterImage.image;

	NSUInteger idx = self.editView.characterImage.selectedPoseIndex;
	NSUInteger maxPoseIdx = (self.editView.characterImage.poses.count -1);

	self.goPreviousSkeletonButton.enabled = (idx != 0);
	self.goNextSkeletonButton.enabled = (idx != maxPoseIdx);
	
	self.currentPoseField.stringValue = [NSString stringWithFormat: @"%lu of %lu", (long)idx +1L, (long)maxPoseIdx +1L];
}


-(IBAction) goNextSkeleton: (id)sender
{
	NSUInteger idx = self.editView.characterImage.selectedPoseIndex;
	NSUInteger maxPoseIdx = (self.editView.characterImage.poses.count -1);
	
	if( idx >= maxPoseIdx ) return;
	
	self.editView.characterImage.selectedPoseIndex = ++idx;
	
	[self updateUIAfterSkeletonChange];
}


-(IBAction) goPreviousSkeleton: (id)sender
{
	NSUInteger idx = self.editView.characterImage.selectedPoseIndex;

	if( idx == 0 ) return;
	
	self.editView.characterImage.selectedPoseIndex = --idx;
	
	[self updateUIAfterSkeletonChange];
}


-(IBAction)	addNewPose: (id)sender
{
	NSUInteger idxForNewSkeleton = self.editView.characterImage.poses.count;
	NSMutableArray<UnDecidedSkeleton *> * poses = [self.editView.characterImage.poses mutableCopy];
	
	[poses addObject: [self.editView.characterImage.poses.lastObject copy]];
	
	self.editView.characterImage.poses = poses;
	self.editView.characterImage.selectedPoseIndex = idxForNewSkeleton;
	
	[self updateUIAfterSkeletonChange];
}

@end
