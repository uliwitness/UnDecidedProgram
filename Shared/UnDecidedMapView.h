//
//  UnDecidedMapView.h
//  UnDecidedServer
//
//  Created by Uli Kusterer on 06.01.18.
//  Copyright © 2018 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class UnDecidedPlayer;
@class UnDecidedMapView;


@protocol UnDecidedMapDelegate <NSObject>
-(void)mapView: (UnDecidedMapView*)sender moveBy: (NSPoint)distance;
@end


@interface UnDecidedMapView : NSView

@property (strong, nonatomic) NSArray<UnDecidedPlayer *> * connections;
@property (weak, nonatomic) IBOutlet NSObject<UnDecidedMapDelegate> * delegate;

@end
