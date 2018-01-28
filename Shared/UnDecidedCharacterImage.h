//
//  UnDecidedCharacterImage.h
//  UnDecidedServer
//
//  Created by Uli Kusterer on 27.01.18.
//  Copyright © 2018 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface UnDecidedSkeleton : NSObject

-(instancetype) initWithContentsOfFile: (NSString*)inPath;

-(NSUInteger)	count;
-(NSPoint) pointAtIndex: (NSUInteger)idx;
-(CGFloat) rotationAtIndex: (NSUInteger)idx;

@end


@interface UnDecidedCharacterImage : NSObject

@property(copy) NSArray<NSImage *> * inputImages;
@property(copy) NSArray<UnDecidedSkeleton *> * poses;

@property(strong, readonly) NSImage * image;
@property(assign, nonatomic) NSUInteger selectedPoseIndex;

-(instancetype) initWithContentsOfDirectory: (NSString*)inPath;

-(void) forEachBoneAddOffset: (NSPoint)offs andDo: (void(^)(NSUInteger x,NSPoint tl,NSPoint tr, NSPoint br, NSPoint bl))forEachCallback;

@end
