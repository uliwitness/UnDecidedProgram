//
//  UnDecidedPlayer.m
//  UnDecidedProgram
//
//  Created by Uli Kusterer on 06.01.18.
//  Copyright © 2018 Uli Kusterer. All rights reserved.
//

#import "UnDecidedPlayer.h"


@implementation UnDecidedPlayer

-(NSString*) description
{
	return [NSString stringWithFormat: @"<%@ %p>{ userName = %@, costume = %ld, animation = %ld }", self.className, self, self.userName, (long)self.costumeID, (long)self.animationID];
}

@end
