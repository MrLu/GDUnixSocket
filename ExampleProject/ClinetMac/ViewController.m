//
//  ViewController.m
//  ClinetMac
//
//  Created by Mrlu on 2019/7/7.
//  Copyright © 2019 Alexey Gordiyenko. All rights reserved.
//

#import "ViewController.h"
#import "GDUnixSocketClient.h"
#import <TargetConditionals.h>

@interface ViewController ()

@property GDUnixSocketClient *clientConnection;
@property (nonatomic, strong) NSTimer * timer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self connectTapped];
    // Do any additional setup after loading the view.

    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self sendMessage];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(sendMessage) userInfo:nil repeats:true];
        [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    });
    
}

- (void)showErrorWithTitle:(NSString *)title text:(NSString *)text {
    NSLog(@"title: %@, text: %@", title, text);
}

- (void)showErrorWithText:(NSString *)text {
    [self showErrorWithTitle:@"Error" text:text];
}

- (void)sendMessageToServer:(NSDictionary *)message fromClientConnection:(GDUnixSocketClient *)clientConnection {
    NSData *data = [NSJSONSerialization dataWithJSONObject:message options:0 error:nil];
    [clientConnection writeData:data completion:^(NSError *error, ssize_t size) {
        if (error) {
            [self showErrorWithTitle:[NSString stringWithFormat:@"%@ failed to send message to server", clientConnection.uniqueID] text:error.localizedDescription];
        }
    }];
}

- (void)connectTapped {
    GDUnixSocketClient *connection = self.clientConnection;
    
    if (!connection) {
        NSString *socketPath = @"/tmp/Socket";
        connection = [[GDUnixSocketClient alloc] initWithSocketPath:socketPath];
    }
    
    NSError *error;
    connection.delegate = self;
    if ([connection connectWithAutoRead:YES error:&error]) {
        
    } else {
        [self showErrorWithTitle:@"Can't connect" text:error.localizedDescription];
    }
}

- (void)sendMessage {
    NSLog(@"-----");
    
    [self sendMessageToServer:@{@"name":[NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]]} fromClientConnection:self.clientConnection];
}

#pragma mark - GDUnixSocketClientDelegate

- (void)unixSocketClient:(GDUnixSocketClient *)unixSocketClient didReceiveData:(NSData *)data {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSString *dataSting = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    // For now we just loop through clients (I know it's not optimal but it's for now, pleaase)
    
//    if ([dataSting isEqualToString:@"Your name?"]) {
//        // Tell server your name
//        [self sendMessageToServer:@{@"name": @"hahah"} fromClientConnection:self.clientConnection];
//    }
}

- (void)unixSocketClient:(GDUnixSocketClient *)unixSocketClient didFailToReadWithError:(NSError *)error {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
