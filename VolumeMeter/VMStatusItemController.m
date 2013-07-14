//
//  VMStatusItemController.m
//  VolumeMeter
//
//  Created by Michael Starke on 28.12.12.
//  Copyright (c) 2012 Michael Starke. All rights reserved.
//

#import "VMStatusItemController.h"
#import "VMSettingsWindowController.h"
#import "VMConnectionThread.h"

@interface VMStatusItemController ()

@property (strong) NSStatusItem *statusItem;
@property (strong) VMSettingsWindowController *settingsWindowController;
@property (weak) NSMenuItem *statusInfoMenuItem;

- (void)_didChangeAvailableVolume:(NSNotification *)notification;
- (void)_didEncounterError:(NSNotification *)notification;
- (void)_createStatusItem;
- (void)_setStatusItemUsedVolume:(NSNumber *)usedVolume availableVolume:(NSNumber *)availableVolume;
- (NSImage *)_statusImage:(NSNumber *)percentage;
- (void)_openWebsite:(id)sender;
- (void)_showPreferences:(id)sender;
- (void)_showAbout:(id)sender;

@end

@implementation VMStatusItemController

- (id)init
{
  self = [super init];
  if (self) {
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self
                      selector:@selector(_didChangeAvailableVolume:)
                          name:VMConnectionThreadVolumeChangedNotification
                        object:nil];
    
    [defaultCenter addObserver:self
                      selector:@selector(_didEncounterError:)
                          name:VMConnectionThreadConnectionErrorOccuredNotification
                        object:nil];
    [self _createStatusItem];
  }
  return self;
}

#pragma mark Notifications
- (void)_didChangeAvailableVolume:(NSNotification *)notification {
  NSDictionary *userInfo = [notification userInfo];
  NSNumber *usedVolume = userInfo[VMConnectionThreadUsedVolumeKey];
  NSNumber *availableVolume = userInfo[VMConnectionThreadAvailableVolumeKey];
  // ensure the gui update is run on the main thread;
  dispatch_async(dispatch_get_main_queue(), ^(void) {
    [self _setStatusItemUsedVolume:usedVolume availableVolume:availableVolume];
  });
}

- (void)_didEncounterError:(NSNotification *)notification {
  NSDictionary *userInfo = [notification userInfo];
  VMConnectionThreadErrorType errorType = (VMConnectionThreadErrorType)[userInfo[VMConnectionThreadConnectionErrorTypeKey] intValue];
  
  NSString *statusString = nil;
  switch (errorType) {
    case VMConnectionThreadErrorNoValidStatusURL:
      statusString = NSLocalizedString(@"ERROR_URL_INVALID", @"URL for parsing the data wasn't valid");
      break;
      
    case VMConnectionThreadErrorOffline:
      statusString = NSLocalizedString(@"ERROR_OFFLINE", @"No internet access");
      break;
      
    case VMConnectionThreadErrorParsingError:
      statusString = NSLocalizedString(@"ERROR_PARSING_ERROR", @"Error while trying to parse volume data");
      break;
      
    default:
      statusString = NSLocalizedString(@"ERROR_INVALID_ERROR", @"Error code not found");
      break;
  }
  dispatch_async(dispatch_get_main_queue(), ^(void){
    NSImage *statusImage = [[NSBundle mainBundle] imageForResource:@"warningTemplate"];
    [self.statusItem setImage:statusImage];
    [self.statusInfoMenuItem setTitle:statusString];
  });
}

#pragma mark StatusItem Setup and Updates

- (void)_createStatusItem {
  NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
  self.statusItem = [statusBar statusItemWithLength:NSVariableStatusItemLength];
  [self.statusItem setHighlightMode:YES];
  NSMenu *menu = [[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""];
  NSString *aboutText = NSLocalizedString(@"MENU_ABOUT", @"");
  NSString *quitText = NSLocalizedString(@"MENU_QUIT", @"");
  NSString *openWebsiteText = NSLocalizedString(@"MENU_WEBSITE", @"");
  NSString *preferencesText = NSLocalizedString(@"MENU_SHOW_PREFERENCES", @"");
  NSMenuItem *aboutMenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:aboutText action:@selector(_showAbout:) keyEquivalent:@""];
  [aboutMenuItem setTarget:self];
  NSMenuItem *statusMenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"" action:NULL keyEquivalent:@""];
  NSMenuItem *prefrencesMenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:preferencesText action:@selector(_showPreferences:) keyEquivalent:@""];
  [prefrencesMenuItem setTarget:self];
  NSMenuItem *quitMenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:quitText action:@selector(terminate:) keyEquivalent:@""];
  NSMenuItem *openWebsiteItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:openWebsiteText action:@selector(_openWebsite:) keyEquivalent:@""];
  [quitMenuItem setTarget:[NSApplication sharedApplication]];
  [openWebsiteItem setTarget:self];
  
  [menu addItem:aboutMenuItem];
  [menu addItem:[NSMenuItem separatorItem]];
  [menu addItem:statusMenuItem];
  [menu addItem:[NSMenuItem separatorItem]];
  [menu addItem:prefrencesMenuItem];
  [menu addItem:openWebsiteItem];
  [menu addItem:quitMenuItem];
  
  [self.statusItem setMenu:menu];
  self.statusInfoMenuItem = statusMenuItem;
  [self _setStatusItemUsedVolume:@0.0 availableVolume:@0.0];
}

- (void)_setStatusItemUsedVolume:(NSNumber *)usedVolume availableVolume:(NSNumber *)availableVolume {
  //NSDictionary *attributes = @{ NSFontAttributeName:[NSFont systemFontOfSize:14.0] };
  NSString *statusString;
  if( [availableVolume doubleValue] > 0 ) {
    double quota = [availableVolume doubleValue] + [usedVolume doubleValue];
    NSNumber *percentage = @(100 * [usedVolume doubleValue] / quota );
    NSString *usedVolumeString = [NSByteCountFormatter stringFromByteCount:[usedVolume doubleValue]*1024*1024 countStyle:NSByteCountFormatterCountStyleBinary];
    NSString *quotaVolumeString = [NSByteCountFormatter stringFromByteCount:quota*1024*1024 countStyle:NSByteCountFormatterCountStyleBinary];
    NSString *statusTemplateString = NSLocalizedString(@"MENU_STATUS_TEMPLATE_%@_%@", @"The String needs 2 placeholders %@ 1. Used, 2. Quota");
    statusString = [NSString stringWithFormat:statusTemplateString, usedVolumeString, quotaVolumeString ];
    [self.statusItem setImage:[self _statusImage:percentage]];
  }
  else {
    statusString = @"Updating...";
    [self.statusItem setImage:[self _statusImage:nil]];
  }
  //NSAttributedString *title = [[NSAttributedString alloc] initWithString:titleString attributes:attributes];
  [self.statusInfoMenuItem setTitle:statusString];
}

- (NSImage *)_statusImage:(NSNumber *)percentage {
  
  if(!percentage) {
    return [NSImage imageNamed:NSImageNameRefreshFreestandingTemplate];
  }
  NSImage *image = [NSImage imageWithSize:NSMakeSize(10, 16) flipped:NO drawingHandler:^BOOL(NSRect imageRect) {
    NSRect strokeRect = NSInsetRect(imageRect, 0.5, 0.5);
    NSBezierPath *outlinePath = [NSBezierPath bezierPathWithRoundedRect:strokeRect xRadius:3 yRadius:3];
    CGFloat percentValue = [percentage doubleValue] / 100;
    [[NSColor blackColor] setStroke];
    [[NSColor blackColor] setFill];
    [outlinePath stroke];
    NSRect stateRect = NSInsetRect(strokeRect, 1.5, 1.5);
    stateRect.size.height *= percentValue;
    NSBezierPath *barPath = [NSBezierPath bezierPathWithRoundedRect:stateRect xRadius:2 yRadius:2];
    [barPath fill];
    return YES;
  }];
  return image;
}

#pragma mark Actions
- (void)_openWebsite:(id)sender {
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://center.vodafone.de/vfcenter/verbrauch.html" ]];
}

- (void)_showPreferences:(id)sender {
  /*
   if(!self.settingsWindowController){
   self.settingsWindowController = [[VMSettingsWindowController alloc] init];
   }
   [self.settingsWindowController showSettings];
   */
}

- (void)_showAbout:(id)sender {
  [NSApp activateIgnoringOtherApps:YES];
  id target = [NSApp targetForAction:@selector(orderFrontStandardAboutPanel:)];
  [target orderFrontStandardAboutPanel:sender];
}

@end
