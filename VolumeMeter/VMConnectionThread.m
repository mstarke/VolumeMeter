//
//  VMConnectionThread.m
//  VolumeMeter
//
//  Created by Michael Starke on 28.12.12.
//  Copyright (c) 2012 Michael Starke. All rights reserved.
//

#import "VMConnectionThread.h"

NSString *const VMConnectionThreadVolumeChangedNotification = @"VMConnectionThreadVolumeChangedNotification";
NSString *const VMConnectionThreadUsedVolumeKey = @"VMConnectionThreadUsedVolumeKey";
NSString *const VMConnectionThreadAvailableVolumeKey = @"VMConnectionThreadAvailableVolumeKey";

/*
 private constants
 */
NSString *const kStatusURL = @"http://center.vodafone.de/vfcenter/verbrauch.html";
NSString *const kUsageString = @"Nutzung im aktuellen Abrechnungszeitraum:";
NSTimeInterval const kSleepTime = 10.0;

@interface VMConnectionThread ()

@property (nonatomic, assign) double usedVolume;

- (void)updateUsedVolume:(NSString *)htmlString;
- (void)postVolumeChangedNotification;

@end

@implementation VMConnectionThread

- (void)main {
  NSURL *volumeURL = [NSURL URLWithString:kStatusURL];
  NSStringEncoding encoding;
  NSError *error = nil;
  NSString *html = [NSString stringWithContentsOfURL:volumeURL usedEncoding:&encoding error:&error];
  if(html != nil) {
    [self updateUsedVolume:html];
  }
  else {
    // set error?
  }
  [NSThread sleepForTimeInterval:kSleepTime];
}

- (void)updateUsedVolume:(NSString *)htmlString {
  if(htmlString == nil) {
    NSException *exception = [NSException exceptionWithName:NSInvalidArgumentException reason:@"htmlString cannot be nil" userInfo:nil];
    @throw exception;
  }
  NSRange usageStringRange = [htmlString rangeOfString:kUsageString options:NSCaseInsensitiveSearch];
  if(usageStringRange.location == NSNotFound) {
    return; // nothing found;
  }
  NSRange searchRange = NSMakeRange(usageStringRange.location + [kUsageString length], 20);
  NSRange endOfLine = [htmlString rangeOfString:@"<br/>" options:NSCaseInsensitiveSearch range:searchRange];
  if( endOfLine.location == NSNotFound) {
    return;// nothing to parse
  }
  NSRange scanRange = NSMakeRange(searchRange.location, endOfLine.location - searchRange.location);
  NSString *parseString = [htmlString substringWithRange:scanRange];
  NSScanner *volumeScanner = [NSScanner scannerWithString:parseString];
  NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"];
  [volumeScanner setLocale:locale];
  double freeVolume = 0;
  if( [volumeScanner scanDouble:&freeVolume] ) {
      self.usedVolume = freeVolume;
  }
}

- (void)postVolumeChangedNotification {
  double availableVolume = 10.0 - self.usedVolume;
  NSDictionary *userInfo = @{ VMConnectionThreadAvailableVolumeKey: @(availableVolume), VMConnectionThreadUsedVolumeKey: @(self.usedVolume) };
  [[NSNotificationCenter defaultCenter] postNotificationName:VMConnectionThreadVolumeChangedNotification object:self userInfo:userInfo];
}

- (void)setUsedVolume:(double)usedVolume {
  if(_usedVolume != usedVolume) {
    _usedVolume = usedVolume;
    [self postVolumeChangedNotification];
  }
}

@end
