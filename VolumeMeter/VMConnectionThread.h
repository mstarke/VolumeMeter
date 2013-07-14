//
//  VMConnectionThread.h
//  VolumeMeter
//
//  Created by Michael Starke on 28.12.12.
//  Copyright (c) 2012 Michael Starke. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Notification if a error occured on a update of the status values
 
 The userInfo dictionary contains the following keys:
 VMConnectionThreadConnectionErrorTypeKey
 */
APPKIT_EXTERN NSString *const VMConnectionThreadConnectionErrorOccuredNotification;
/**
 NSNumber containin a enum of typ VMConnectionThreadErrorType
 */
APPKIT_EXTERN NSString *const VMConnectionThreadConnectionErrorTypeKey;

/**
 Notification that the availabe volume has changed (fired at least one time after successfull inital update)
 
 The userInfo dictionary contains the following keys
 VMConnectionThreadUsedVolumeKey,  VMConnectionThreadAvailableVolumeKey
 */
APPKIT_EXTERN NSString *const VMConnectionThreadVolumeChangedNotification;

/**
 NSNumber containg a double with the used volume in MegaBytes (binary)
 */
APPKIT_EXTERN NSString *const VMConnectionThreadUsedVolumeKey;
/**
 NSNumber containing a double with the availabe volume in MegaBytes (binary)
 */
APPKIT_EXTERN NSString *const VMConnectionThreadAvailableVolumeKey;


typedef NS_ENUM(NSUInteger, VMConnectionThreadErrorType) {
  VMConnectionThreadErrorNone, // No error
  VMConnectionThreadErrorOffline, // Offline, no way to contact server
  VMConnectionThreadErrorParsingError, // Error while parsing the Values
  VMConnectionThreadErrorNoValidStatusURL // Status URL is not valid (404, etc)
};

@interface VMConnectionThread : NSThread

@end
