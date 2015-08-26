//
//  LocationDataUtilities.h
//  TouchID
//
//  Created by Mohammed Safwat on 8/26/15.
//  Copyright (c) 2015 safwat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface LocationDataUtilities : NSObject
+ (CLLocationCoordinate2D)getLocationCoordinatesFromAddress:(NSString *)address;
@end
