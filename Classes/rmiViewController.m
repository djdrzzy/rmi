//
//  rmiViewController.m
//  rmi
//
//  Created by Daniel Drzimotta on 11-05-11.
//  Copyright 2011 Daniel Drzimotta. All rights reserved.
//

#import "rmiViewController.h"

#import "RemoteMessageInterface.h"

@interface rmiViewController () <RemoteMessageInterfaceDelegate>
@property (nonatomic, readwrite, retain) RemoteMessageInterface *rmi;
@end

@implementation rmiViewController
@synthesize rmi;


/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.rmi = [[[RemoteMessageInterface alloc] init] autorelease];
	self.rmi.delegate = self;
	[self.rmi startOnSocket:40000];
}

-(NSString*) remoteMessageInterface:(RemoteMessageInterface*)interface
										receivedMessage:(NSString*)message {
	return [NSString stringWithFormat:@"You said: %@", message];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[self.rmi end];
	self.rmi = nil;
    [super dealloc];
}

@end
