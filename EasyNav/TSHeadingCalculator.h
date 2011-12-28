//
//  TSHeadingCalculator.h
//  EasyNav2
//
//  Created by Tim Shi on 11/2/11.
//  Copyright (c) 2011 www.timshi.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface TSHeadingCalculator : NSObject

+ (double)bearingToDestination:(CLLocation *)destination fromOrigin:(CLLocation *)origin;

@end
