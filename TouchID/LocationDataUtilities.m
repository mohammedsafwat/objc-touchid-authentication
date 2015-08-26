//
//  LocationDataUtilities.m
//  TouchID
//
//  Created by Mohammed Safwat on 8/26/15.
//  Copyright (c) 2015 safwat. All rights reserved.
//

#import "LocationDataUtilities.h"
#define GOOGLE_MAPS_BASE_URL @"http://maps.google.com/maps/api/geocode/json?sensor=false&address=%@"

@implementation LocationDataUtilities
+ (CLLocationCoordinate2D)getLocationCoordinatesFromAddress:(NSString *)address{
    double latitude = 0;
    double longitude = 0;
    
    NSString *formattedAddress =  [address stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *requestURL = [NSString stringWithFormat:GOOGLE_MAPS_BASE_URL, formattedAddress];
    NSString *result = [NSString stringWithContentsOfURL:[NSURL URLWithString:requestURL] encoding:NSUTF8StringEncoding error:NULL];
    if (result) {
        NSScanner *scanner = [NSScanner scannerWithString:result];
        if ([scanner scanUpToString:@"\"lat\" :" intoString:nil] && [scanner scanString:@"\"lat\" :" intoString:nil]) {
            [scanner scanDouble:&latitude];
            if ([scanner scanUpToString:@"\"lng\" :" intoString:nil] && [scanner scanString:@"\"lng\" :" intoString:nil]) {
                [scanner scanDouble:&longitude];
            }
        }
    }
    CLLocationCoordinate2D center;
    center.latitude = latitude;
    center.longitude = longitude;
    return center;
}
@end
