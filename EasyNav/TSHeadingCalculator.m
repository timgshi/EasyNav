//
//  TSHeadingCalculator.m
//  EasyNav2
//
//  Created by Tim Shi on 11/2/11.
//  Copyright (c) 2011 www.timshi.com. All rights reserved.
//

#import "TSHeadingCalculator.h"
#import <tgmath.h>

@implementation TSHeadingCalculator

+ (double)bearingToDestination:(CLLocation *)destination fromOrigin:(CLLocation *)origin
{
    double bearing = 0;
    double lon1 = origin.coordinate.longitude;
    double lat1 = origin.coordinate.latitude;
    double lon2 = destination.coordinate.longitude;
    double lat2 = destination.coordinate.latitude;
//    double y = sin(lon2 - lon1) * cos(lat2);
//    double x = (cos(lat1) * sin(lat2)) - (sin(lat1) * cos(lat2) * cos(lon2 - lon1));
    double y = lon2 - lon1;
    double x = lat2 - lat1;
    bearing = atan2(y, x);
    bearing = bearing * (180 / M_PI);
    bearing = fmod((bearing + 360), 360);
    return bearing;
}

@end
