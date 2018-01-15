//
//  UnDecidedPlayer.h
//  UnDecidedProgram
//
//  Created by Uli Kusterer on 06.01.18.
//  Copyright © 2018 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface UnDecidedPlayer : NSObject

@property (copy) NSString *userName;
@property (assign) NSPoint playerPosition;
@property (assign) uint32_t costumeID;
@property (assign) uint32_t animationID;

@end
