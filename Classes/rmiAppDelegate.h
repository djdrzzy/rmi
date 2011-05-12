//
//  rmiAppDelegate.h
//  rmi
//
//  Created by Daniel Drzimotta on 11-05-11.
//  Copyright 2011 Daniel Drzimotta. All rights reserved.
//

#import <UIKit/UIKit.h>

@class rmiViewController;

@interface rmiAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    rmiViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet rmiViewController *viewController;

@end

