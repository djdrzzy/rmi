//
//  RemoteMessageInterface.m
//  
//  This class is in the public domain.
//  Originally created by Daniel Drzimotta on Wed May 11 2011

// Make sure you are linked to CFNetwork.framework

#import <Foundation/Foundation.h>

@class AsyncSocket;

@protocol RemoteMessageInterfaceDelegate;

@interface RemoteMessageInterface : NSObject
@property (nonatomic, readwrite, assign) id<RemoteMessageInterfaceDelegate> delegate;
@property (nonatomic, readwrite, copy) NSString *welcomeMessage;
@property (nonatomic, readwrite, copy) NSString *prompt;
@property (nonatomic, readwrite, assign) BOOL squelchClientLogging;
@property (nonatomic, readwrite, copy) NSString *branding;
-(id) initWithWelcomeMessage:(NSString*)message andPrompt:(NSString*)prompt;
-(void) startOnSocket:(int)port;
-(void) end;

// To get the current connect ip address that we are on and the port that is
// open
-(NSString*) getIPAddress;
-(NSString*) port;
@end


@protocol RemoteMessageInterfaceDelegate <NSObject>
@required
// What is returned is what is echo'd back to the user connected.
-(NSString*) remoteMessageInterface:(RemoteMessageInterface*)interface
											receivedMessage:(NSString*)message;
@end