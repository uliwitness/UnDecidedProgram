//
//  UnDecidedCharacterImage.h
//  UnDecidedServer
//
//  Created by Uli Kusterer on 27.01.18.
//  Copyright © 2018 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface UnDecidedSkeleton : NSObject <NSCopying>

-(instancetype) initWithContentsOfFile: (NSString*)inPath;

-(NSUInteger)	count;
-(NSPoint) pointAtIndex: (NSUInteger)idx;
-(void) setPoint: (NSPoint)inPoint atIndex: (NSUInteger)idx;
-(CGFloat) rotationAtIndex: (NSUInteger)idx;
-(void)	setRotation: (CGFloat)inRotation atIndex: (NSUInteger)idx;

-(BOOL)	writeToFile: (NSString*)inFilePath atomically: (BOOL)inAtomically;

-(instancetype) copyWithZone:(NSZone *)zone;

@end


@interface UnDecidedCharacterImage : NSObject

@property(copy) NSArray<NSImage *> * inputImages;
@property(copy) NSArray<UnDecidedSkeleton *> * poses;

@property(strong, readonly) NSImage * image;
@property(assign, nonatomic) NSUInteger selectedPoseIndex;
@property(readonly, nonatomic) UnDecidedSkeleton * selectedPose;

-(instancetype) initWithContentsOfDirectory: (NSString*)inPath;

-(BOOL) writeToDirectory: (NSString*)inPath;

-(void) forEachBoneAddOffset: (NSPoint)offs andDo: (void(^)(NSUInteger x,NSPoint tl,NSPoint tr, NSPoint br, NSPoint bl))forEachCallback;

-(void) display;

@end
