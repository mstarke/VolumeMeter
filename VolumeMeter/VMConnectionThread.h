//
//  VMConnectionThread.h
//  VolumeMeter
//
//  Created by Michael Starke on 28.12.12.
//  Copyright (c) 2012 Michael Starke. All rights reserved.
//

#import <Foundation/Foundation.h>

APPKIT_EXTERN NSString *const VMConnectionThreadVolumeChangedNotification;
APPKIT_EXTERN NSString *const VMConnectionThreadUsedVolumeKey;
APPKIT_EXTERN NSString *const VMConnectionThreadAvailableVolumeKey;

@interface VMConnectionThread : NSThread

@end
