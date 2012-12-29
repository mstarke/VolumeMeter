//
//  VMAppDelegate.m
//  VolumeMeter
//
//  Created by Michael Starke on 28.12.12.
//  Copyright (c) 2012 Michael Starke. All rights reserved.
//

#import "VMAppDelegate.h"
#import "VMConnectionThread.h"
#import "VMStatusItemController.h"

@interface VMAppDelegate ()

@property (strong) VMConnectionThread *thread;
@property (strong) VMStatusItemController *menuController;

@end

@implementation VMAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  self.menuController = [[VMStatusItemController alloc] init];
  self.thread = [[VMConnectionThread alloc] init];
  [self.thread start];
}

@end
