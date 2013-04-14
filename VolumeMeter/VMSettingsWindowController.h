//
//  VMSettingsWindowController.h
//  VolumeMeter
//
//  Created by Michael Starke on 14.04.13.
//  Copyright (c) 2013 Michael Starke. All rights reserved.
//

#import <Cocoa/Cocoa.h>

APPKIT_EXTERN NSString *const VMSettingsKeyStatusURL;
APPKIT_EXTERN NSString *const VMSettingsKeyUpdateIntervall;

@interface VMSettingsWindowController : NSWindowController

+ (void)registerDefaults;
- (void)showSettings;

@end
