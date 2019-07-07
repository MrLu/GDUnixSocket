//
//  ViewController.m
//  ServerMac
//
//  Created by Mrlu on 2019/7/7.
//  Copyright © 2019 Alexey Gordiyenko. All rights reserved.
//

#import "ViewController.h"
#import "GDUnixSocketServer.h"

@interface ViewController () <GDUnixSocketServerDelegate>

@property (nonatomic, readwrite, strong) GDUnixSocketServer *server;
@property (nonatomic, readwrite, assign) BOOL serverIsUp;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}

- (void)showErrorWithTitle:(NSString *)title text:(NSString *)text {
    NSLog(@"title: %@, text: %@", title, text);
}

- (void)showErrorWithText:(NSString *)text {
    [self showErrorWithTitle:@"Error" text:text];
}

- (IBAction)toggleServerState:(id)sender {
    if (self.serverIsUp) {
        if (self.server) {
            NSError *error;
            if ([self.server closeWithError:&error]) {
                self.serverIsUp = NO;
            } else {
                [self showErrorWithTitle:@"Server stop failed" text:error.localizedDescription];
            }
        } else {
            [self showErrorWithText:@"Server object is not initialized!"];
        }
    } else {
        if (!self.server) {
            
            NSString *socketPath = @"/tmp/Socket";
            self.server = [[GDUnixSocketServer alloc] initWithSocketPath:socketPath];
            self.server.delegate = self;
        }
        
        NSError *error;
        if ([self.server listenWithError:&error]) {
            self.serverIsUp = YES;
        } else {
            [self showErrorWithTitle:@"Couldn't start server" text:error.localizedDescription];
        }
    }
}

#pragma mark - LogView

- (void)addLogLine:(NSString *)line error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *errorString = error ? [NSString stringWithFormat:@". Error: %@", error.localizedDescription] : @"";
        NSDate *date = [NSDate date];
        NSDateFormatter *f = [NSDateFormatter new];
        f.dateFormat = @"dd-MM HH:mm:ss";
        NSString *text = [NSString stringWithFormat:@"\n[%@] %@%@", [f stringFromDate:date], line, errorString];
        NSLog(@"%@", text);
    });
}

- (void)addLogLine:(NSString *)line {
    [self addLogLine:line error:nil];
}

#pragma mark - Communication

- (void)sendMessage:(NSString *)message toClientWithID:(NSString *)clientID {
    [self.server sendData:[message dataUsingEncoding:NSUTF8StringEncoding] toClientWithID:clientID completion:^(NSError *error, ssize_t size) {
        if (error) {
            [self addLogLine:[NSString stringWithFormat:@"Failed to send message \"%@\" to client %@", message, clientID] error:error];
        } else {
            [self addLogLine:[NSString stringWithFormat:@"Sent message \"%@\" to client %@", message, clientID]];
        }
    }];
}

- (void)processMessage:(NSData *)data fromClientWithID:(NSString *)clientID {
    NSError *JSONError = nil;
    NSDictionary *message = [NSJSONSerialization JSONObjectWithData:data options:0 error:&JSONError];
    if (JSONError) {
        [self addLogLine:[NSString stringWithFormat:@"Failed to parse message from client %@: %@", clientID, JSONError]];
        return;
    }
    
    NSString *name = message[@"name"];
    NSString *cmd = message[@"cmd"];
    if (name) {
        [self sendMessage:[NSString stringWithFormat:@"Hello %@", name] toClientWithID:clientID];
        [self sendMessage:@"Usage: \"cmd\":\"time\"" toClientWithID:clientID];
        return;
    }
    
    if (cmd) {
        if ([cmd isEqualToString:@"time"]) {
            [self sendMessage:[NSString stringWithFormat:@"%@", [NSDate date]] toClientWithID:clientID];
            return;
        }
    }
    
    [self sendMessage:[NSString stringWithFormat:@"Unknown message %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]] toClientWithID:clientID];
}

#pragma mark - GDUnixSocketServerDelegate Methods

- (void)unixSocketServerDidStartListening:(GDUnixSocketServer *)unixSocketServer {
    [self addLogLine:@"Server started"];
}

- (void)unixSocketServerDidClose:(GDUnixSocketServer *)unixSocketServer error:(NSError *)error {
    [self addLogLine:@"Server stopped" error:error];
}

- (void)unixSocketServer:(GDUnixSocketServer *)unixSocketServer didAcceptClientWithID:(NSString *)newClientID {
    [self addLogLine:[NSString stringWithFormat:@"Accepted client %@", newClientID]];
    [self sendMessage:@"Your name?" toClientWithID:newClientID];
}

- (void)unixSocketServer:(GDUnixSocketServer *)unixSocketServer clientWithIDDidDisconnect:(NSString *)clientID {
    [self addLogLine:[NSString stringWithFormat:@"Client %@ disconnected", clientID]];
}

- (void)unixSocketServer:(GDUnixSocketServer *)unixSocketServer didReceiveData:(NSData *)data fromClientWithID:(NSString *)clientID {
    NSString *messageString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [self addLogLine:[NSString stringWithFormat:@"Received message from client %@\n%@", clientID, messageString]];
    [self processMessage:data fromClientWithID:clientID];
}

- (void)unixSocketServer:(GDUnixSocketServer *)unixSocketServer didFailToReadForClientID:(NSString *)clientID error:(NSError *)error {
    [self addLogLine:[NSString stringWithFormat:@"Failed to read from client %@", clientID] error:error];
}

- (void)unixSocketServerDidFailToAcceptConnection:(GDUnixSocketServer *)unixSocketServer error:(NSError *)error {
    [self addLogLine:@"Failed to accept incoming connection" error:error];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
