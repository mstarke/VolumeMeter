//
//  VMStatusItemController.m
//  VolumeMeter
//
//  Created by Michael Starke on 28.12.12.
//  Copyright (c) 2012 Michael Starke. All rights reserved.
//

#import "VMStatusItemController.h"
#import "VMConnectionThread.h"

@interface VMStatusItemController ()

@property (strong) NSStatusItem *statusItem;
@property (weak) NSMenuItem *statusInfoMenuItem;

- (void)didChangeAvailableVolume:(NSNotification *)notification;
- (void)createStatusItem;
- (void)setStatusItemUsedVolume:(NSNumber *)usedVolume availableVolume:(NSNumber *)availableVolume;
- (NSImage *)statusImage:(NSNumber *)percentage;
- (void)openWebsite:(id)sender;

@end

@implementation VMStatusItemController

- (id)init
{
  self = [super init];
  if (self) {
    /*
     register for notifications
     */
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self
                      selector:@selector(didChangeAvailableVolume:)
                          name:VMConnectionThreadVolumeChangedNotification
                        object:nil];
    [self createStatusItem];
  }
  return self;
}

- (void)didChangeAvailableVolume:(NSNotification *)notification {
  if([NSThread isMainThread]) {
    [self performSelectorOnMainThread:@selector(didChangeAvailableVolume:) withObject:notification waitUntilDone:NO];
  }
  else {
    NSDictionary *userInfo = [notification userInfo];
    NSNumber *usedVolume = userInfo[VMConnectionThreadUsedVolumeKey];
    NSNumber *availableVolume = userInfo[VMConnectionThreadAvailableVolumeKey];
    [self setStatusItemUsedVolume:usedVolume availableVolume:availableVolume];
  }
}

- (void)createStatusItem {
  NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
  self.statusItem = [statusBar statusItemWithLength:NSVariableStatusItemLength];
  [self.statusItem setHighlightMode:YES];
  NSMenu *menu = [[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""];
  NSMenuItem *statusMenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"" action:NULL keyEquivalent:@""];
  NSMenuItem *quitMenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@""];
  NSMenuItem *openWebsiteItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Open Website" action:@selector(openWebsite:) keyEquivalent:@""];
  [quitMenuItem setTarget:[NSApplication sharedApplication]];
  [openWebsiteItem setTarget:self];
  [menu addItem:statusMenuItem];
  [menu addItem:[NSMenuItem separatorItem]];
  [menu addItem:openWebsiteItem];
  [menu addItem:quitMenuItem];
  
  [self.statusItem setMenu:menu];
  self.statusInfoMenuItem = statusMenuItem;
  [self setStatusItemUsedVolume:@0.0 availableVolume:@0.0];
}

- (void)setStatusItemUsedVolume:(NSNumber *)usedVolume availableVolume:(NSNumber *)availableVolume {
  //NSDictionary *attributes = @{ NSFontAttributeName:[NSFont systemFontOfSize:14.0] };
  NSString *statusString;
  if( [availableVolume doubleValue] > 0 ) {
    double quota = [availableVolume doubleValue] + [usedVolume doubleValue];
    NSNumber *percentage = @(100 * [usedVolume doubleValue] / quota );
    statusString = [NSString stringWithFormat:@"%@Gb of %.1fGb used", usedVolume, quota ];
    [self.statusItem setImage:[self statusImage:percentage]];
  }
  else {
    statusString = @"Updating...";
    [self.statusItem setImage:[self statusImage:nil]];
  }
  //NSAttributedString *title = [[NSAttributedString alloc] initWithString:titleString attributes:attributes];
  [self.statusInfoMenuItem setTitle:statusString];
}

- (NSImage *)statusImage:(NSNumber *)percentage {
  NSRect imageRect = NSMakeRect(0, 0, 10, 16);
  NSBitmapImageRep* offscreenRep = nil;
  
  offscreenRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil
                                                         pixelsWide:imageRect.size.width
                                                         pixelsHigh:imageRect.size.height
                                                      bitsPerSample:8
                                                    samplesPerPixel:4
                                                           hasAlpha:YES
                                                           isPlanar:NO
                                                     colorSpaceName:NSCalibratedRGBColorSpace
                                                       bitmapFormat:0
                                                        bytesPerRow:(4 * imageRect.size.width)
                                                       bitsPerPixel:32];
  
  [NSGraphicsContext saveGraphicsState];
  [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:offscreenRep]];
  
  //percentage valid
  if(percentage != nil) {
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
    
  }
  else {
    
  }
  [NSGraphicsContext restoreGraphicsState];
  NSImage *image = [[NSImage alloc] initWithSize:imageRect.size];
  [image addRepresentation:offscreenRep];
  [image setTemplate:YES];
  return image;
}

- (void)openWebsite:(id)sender {
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://center.vodafone.de/vfcenter/verbrauch.html" ]];
}

@end
