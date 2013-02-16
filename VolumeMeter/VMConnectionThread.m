//
//  VMConnectionThread.m
//  VolumeMeter
//
//  Created by Michael Starke on 28.12.12.
//  Copyright (c) 2012 Michael Starke. All rights reserved.
//

#import "VMConnectionThread.h"

/*
 Notifications
 */
NSString *const VMConnectionThreadVolumeChangedNotification = @"VMConnectionThreadVolumeChangedNotification";
NSString *const VMConnectionThreadConnectionErrorOccuredNotification = @"VMConnectionThreadConnectionErrorOccuredNotification";

/*
 userInfo keys
 */
NSString *const VMConnectionThreadUsedVolumeKey = @"VMConnectionThreadUsedVolumeKey";
NSString *const VMConnectionThreadAvailableVolumeKey = @"VMConnectionThreadAvailableVolumeKey";
NSString *const VMConnectionThreadConnectionErrorTypeKey = @"VMConnectionThreadConnectionErrorTypeKey";


/*
 private constants
 */
NSString *const kStatusURL = @"http://center.vodafone.de/vfcenter/verbrauch.html";
NSString *const kUsageString = @"Nutzung im aktuellen Abrechnungszeitraum:";
NSTimeInterval const kSleepTimeInSeconds = 10.0;
const double dAvailableVolumeInMegaBytes = 10240;

@interface VMConnectionThread ()

@property (nonatomic, assign) double usedVolume;
@property (nonatomic, assign) VMConnectionThreadErrorType errorType;

- (BOOL)hasErrors;
- (void)updateUsedVolume:(NSString *)htmlString;
- (void)postVolumeChangedNotification;

@end

@implementation VMConnectionThread

- (void)main {
  while( ! [self isCancelled] ) {
    self.errorType = VMConnectionThreadErrorNone;    
    NSURL *volumeURL = [NSURL URLWithString:kStatusURL];
    NSStringEncoding encoding;
    NSError *error = nil;
    NSString *html = [NSString stringWithContentsOfURL:volumeURL usedEncoding:&encoding error:&error];
    [self updateUsedVolume:html];
    if( [self hasErrors] ) {
      [self postErrorOccuredNotification];
    }
    [NSThread sleepForTimeInterval:kSleepTimeInSeconds];
  }
}

- (void)updateUsedVolume:(NSString *)htmlString {
  if(htmlString == nil) {
    self.errorType = VMConnectionThreadErrorNoValidStatusURL;
    return; // nil string;
  }
  NSRange usageStringRange = [htmlString rangeOfString:kUsageString options:NSCaseInsensitiveSearch];
  if(usageStringRange.location == NSNotFound) {
    self.errorType = VMConnectionThreadErrorParsingError;
    return; // nothing found;
  }
  NSRange searchRange = NSMakeRange(usageStringRange.location + [kUsageString length], 20);
  NSRange endOfLine = [htmlString rangeOfString:@"<br/>" options:NSCaseInsensitiveSearch range:searchRange];
  if( endOfLine.location == NSNotFound) {
    self.errorType = VMConnectionThreadErrorParsingError;
    return;// nothing to parse
  }
  NSRange scanRange = NSMakeRange(searchRange.location, endOfLine.location - searchRange.location);
  NSString *parseString = [htmlString substringWithRange:scanRange];
  NSScanner *volumeScanner = [NSScanner scannerWithString:parseString];
  NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"];
  [volumeScanner setLocale:locale];
  double freeVolume = 0;
  if( [volumeScanner scanDouble:&freeVolume] ) {
    if( [[parseString lowercaseString] hasSuffix:@"gb"] ) {
      freeVolume *= 1024;
    }
    self.usedVolume = freeVolume;
  }
  else {
    self.errorType = VMConnectionThreadErrorParsingError;
  }
}

- (void)setUsedVolume:(double)usedVolume {
  if(_usedVolume != usedVolume) {
    _usedVolume = usedVolume;
    [self postVolumeChangedNotification];
  }
}

- (BOOL)hasErrors {
  return ( self.errorType != VMConnectionThreadErrorNone );
}

#pragma mark Notifications

- (void)postErrorOccuredNotification{
  NSDictionary *userInfo = @{ VMConnectionThreadConnectionErrorTypeKey: @(self.errorType) };
  [[NSNotificationCenter defaultCenter] postNotificationName:VMConnectionThreadConnectionErrorOccuredNotification object:self userInfo:userInfo];
}

- (void)postVolumeChangedNotification {
  double availableVolume = dAvailableVolumeInMegaBytes - self.usedVolume;
  NSDictionary *userInfo = @{ VMConnectionThreadAvailableVolumeKey: @(availableVolume), VMConnectionThreadUsedVolumeKey: @(self.usedVolume) };
  [[NSNotificationCenter defaultCenter] postNotificationName:VMConnectionThreadVolumeChangedNotification object:self userInfo:userInfo];
}


@end
