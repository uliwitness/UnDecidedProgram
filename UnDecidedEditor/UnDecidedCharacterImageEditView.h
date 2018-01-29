//
//  UnDecidedCharacterImageEditView.h
//  UnDecidedEditor
//
//  Created by Uli Kusterer on 29.01.18.
//  Copyright © 2018 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UnDecidedCharacterImage.h"


@interface UnDecidedCharacterImageEditView : NSImageView

@property (strong, nonatomic) UnDecidedCharacterImage * characterImage;
@property NSUInteger selectedBoneIndex;

@end
