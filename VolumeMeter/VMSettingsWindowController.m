//
//  VMSettingsWindowController.m
//  VolumeMeter
//
//  Created by Michael Starke on 14.04.13.
//  Copyright (c) 2013 Michael Starke. All rights reserved.
//

#import "VMSettingsWindowController.h"

NSString *const VMSettingsKeyStatusURL = @"StatusURL";
NSString *const VMSettingsKeyUpdateIntervall = @"UpdateInterval";

@interface VMSettingsWindowController ()

@property (weak) IBOutlet NSPopUpButton *updateIntervallPopup;
@property (weak) IBOutlet NSTextField *statusURLTextfield;
@property (assign) BOOL statusUrlOk;
@property (weak) IBOutlet NSTextField *errorTextField;

- (void)_didChangeUserDefaults:(NSNotification *)notification;
- (IBAction)_reset:(id)sender;

@end

@implementation VMSettingsWindowController

+ (void)registerDefaults {
  NSDictionary *userDefaults = @{
                                 VMSettingsKeyStatusURL: @"http://center.vodafone.de/vfcenter/verbrauch.html",
                                 VMSettingsKeyUpdateIntervall: @60
                                 };
  [[NSUserDefaults standardUserDefaults] registerDefaults:userDefaults];
}

- (id)init {
  return [self initWithWindowNibName:@"SettingsWindow"];
}

- (id)initWithWindow:(NSWindow *)window {
  self = [super initWithWindow:window];
  if(self) {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    _statusUrlOk = YES;
    [notificationCenter addObserver:self selector:@selector(_didChangeUserDefaults:) name:NSUserDefaultsDidChangeNotification object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)windowDidLoad {;
  [super windowDidLoad];
  NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
  NSString *intervallKeyPath = [NSString stringWithFormat:@"values.%@", VMSettingsKeyUpdateIntervall];
  NSString *statusURLKeyPath = [NSString stringWithFormat:@"values.%@", VMSettingsKeyStatusURL];
  [self.updateIntervallPopup bind:NSSelectedTagBinding toObject:defaultsController withKeyPath:intervallKeyPath options:nil];
  [self.statusURLTextfield bind:NSValueBinding toObject:defaultsController withKeyPath:statusURLKeyPath options:nil];
  [self.errorTextField bind:NSHiddenBinding toObject:self withKeyPath:@"statusUrlOk" options:nil];
}

- (void)showSettings {
  [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
  [[self window] makeKeyAndOrderFront:nil];
}

- (void)_didChangeUserDefaults:(NSNotification *)notification {
  NSURL *statusUrl = [NSURL URLWithString:[[NSUserDefaults standardUserDefaults] stringForKey:VMSettingsKeyStatusURL]];
  dispatch_queue_t backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
  dispatch_async(backgroundQueue, ^{
    NSError *error = nil;
    NSStringEncoding encoding;
    NSString *website = [NSString stringWithContentsOfURL:statusUrl usedEncoding:&encoding error:&error];
    dispatch_async(dispatch_get_main_queue(), ^{
      self.statusUrlOk = (website && !error);
    });
  });
}

- (IBAction)_reset:(id)sender {
  [NSUserDefaults resetStandardUserDefaults];
}

@end
