//
//  AsyncSocket.m
//  
//  This class is in the public domain.
//  Originally created by Daniel Drzimotta on Wed May 11 2011
//
// Pretty much taken from the EchoServer from one of the AsyncSocket demoes.

#import "RemoteMessageInterface.h"

#import "AsyncSocket.h"

#include <ifaddrs.h>
#include <arpa/inet.h>


#define WELCOME_MSG  0
#define ECHO_MSG     1
#define WARNING_MSG  2

#define READ_TIMEOUT 600.0
#define READ_TIMEOUT_EXTENSION 60.0

#define FORMAT(format, ...) [NSString stringWithFormat:(format), ##__VA_ARGS__]

@interface RemoteMessageInterface ()
@property (nonatomic, readwrite, retain) AsyncSocket *listenSocket;
@property (nonatomic, readwrite, retain) NSMutableArray *connectedSockets;
@property (nonatomic, readwrite, assign) BOOL isRunning;
- (void)logError:(NSString *)msg;
- (void)logInfo:(NSString *)msg;
- (void)logMessage:(NSString *)msg;
-	(NSString*) getIPAddress;
@end

@implementation RemoteMessageInterface
@synthesize delegate;
@synthesize listenSocket;
@synthesize connectedSockets;
@synthesize isRunning;

- (id)init
{
	if((self = [super init]))
	{
		listenSocket = [[AsyncSocket alloc] initWithDelegate:self];
		connectedSockets = [[NSMutableArray alloc] initWithCapacity:1];
		
		isRunning = NO;
	}
	return self;
}

-(void) startOnSocket:(int)port {
	
	[listenSocket setRunLoopModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
	
	if(!isRunning) {
		if(port < 0 || port > 65535) {
			port = 0;
		}
		
		NSError *error = nil;
		if(![listenSocket acceptOnPort:port error:&error]) {
			[self logError:FORMAT(@"Error starting server: %@", error)];
			return;
		}
		
		[self logInfo:FORMAT(@"RCI server started on port %hu, ip %@", 
												 [listenSocket localPort],
												 [self getIPAddress])];
		
		isRunning = YES;
	}
}

-(void) end {
	// Stop accepting connections
	[listenSocket disconnect];
	
	// Stop any client connections
	NSUInteger i;
	for(i = 0; i < [connectedSockets count]; i++) {
		// Call disconnect on the socket,
		// which will invoke the onSocketDidDisconnect: method,
		// which will remove the socket from the list.
		[[connectedSockets objectAtIndex:i] disconnect];
	}
	
	[self logInfo:@"Stopped RCI server"];
	
	isRunning = NO;
}

#pragma mark -
#pragma mark Logging

- (void)logError:(NSString *)msg {	
	NSLog(@"RCI Error: %@\n", msg);
}

- (void)logInfo:(NSString *)msg{
	NSLog(@"RCI Info: %@\n", msg);
}

- (void)logMessage:(NSString *)msg {
	NSLog(@"RCI Message: %@\n", msg);
}

#pragma mark -
#pragma mark AsyncSocket Delegate Method Implementations

- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket {
	[connectedSockets addObject:newSocket];
}

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
	[self logInfo:FORMAT(@"Accepted client %@:%hu", host, port)];
	
	NSString *welcomeMsg = @"Welcome to the RCI Server\r\n>";
	NSData *welcomeData = [welcomeMsg dataUsingEncoding:NSUTF8StringEncoding];
	
	[sock writeData:welcomeData withTimeout:-1 tag:WELCOME_MSG];
	
	[sock readDataToData:[AsyncSocket CRLFData] withTimeout:READ_TIMEOUT tag:0];
}

- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag {
	if(tag == ECHO_MSG) {
		[sock readDataToData:[AsyncSocket CRLFData] withTimeout:READ_TIMEOUT tag:0];
	}
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
	NSData *strData = [data subdataWithRange:NSMakeRange(0, [data length] - 2)];
	NSString *msg = [[[NSString alloc] initWithData:strData encoding:NSUTF8StringEncoding] autorelease];
	if(msg) {
		[self logMessage:msg];
	}
	else {
		[self logError:@"Error converting received data into UTF-8 String"];
	}
	
	// Even if we were unable to write the incoming data to the log,
	// we're still going to echo it back to the client.
	NSString *returnString = @"";
	if ([self.delegate respondsToSelector:@selector(remoteMessageInterface:receivedMessage:)]) {
		returnString = [self.delegate remoteMessageInterface:self receivedMessage:msg];
	}
	
	
	if (!returnString) {
		returnString = @"";
	}
	
	returnString = [returnString stringByAppendingString:@"\n>"];
	
	NSData *dataToReturn = [returnString dataUsingEncoding:NSUTF8StringEncoding];
	[sock writeData:dataToReturn withTimeout:-1 tag:ECHO_MSG];
	
	
}

/**
 * This method is called if a read has timed out.
 * It allows us to optionally extend the timeout.
 * We use this method to issue a warning to the user prior to disconnecting them.
 **/
- (NSTimeInterval)onSocket:(AsyncSocket *)sock
  shouldTimeoutReadWithTag:(long)tag
									 elapsed:(NSTimeInterval)elapsed
								 bytesDone:(NSUInteger)length {
	if(elapsed <= READ_TIMEOUT) {
		NSString *warningMsg = @"\nAre you still there?\r\n>";
		NSData *warningData = [warningMsg dataUsingEncoding:NSUTF8StringEncoding];
		
		[sock writeData:warningData withTimeout:-1 tag:WARNING_MSG];
		
		return READ_TIMEOUT_EXTENSION;
	}
	
	return 0.0;
}

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err {
	[self logInfo:FORMAT(@"Client Disconnected: %@:%hu", [sock connectedHost], [sock connectedPort])];
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock {
	[connectedSockets removeObject:sock];
}


#pragma mark -
#pragma mark IP Address Retrievel

- (NSString *)getIPAddress {
  NSString *address = @"error";
  struct ifaddrs *interfaces = NULL;
  struct ifaddrs *temp_addr = NULL;
  int success = 0;
	
  // retrieve the current interfaces - returns 0 on success
  success = getifaddrs(&interfaces);
  if (success == 0)
  {
    // Loop through linked list of interfaces
    temp_addr = interfaces;
    while(temp_addr != NULL)
    {
      if(temp_addr->ifa_addr->sa_family == AF_INET)
      {
        // Check if interface is en0 which is the wifi connection on the iPhone
        if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
        {
          // Get NSString from C String
          address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
        }
      }
			
      temp_addr = temp_addr->ifa_next;
    }
  }
	
  // Free memory
  freeifaddrs(interfaces);
	
  return address;
}

@end
