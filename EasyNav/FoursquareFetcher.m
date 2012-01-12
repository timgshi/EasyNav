//
//  FoursquareFetcher.m
//  EasyNav2
//
//  Created by Tim Shi on 8/11/11.
//  Copyright 2011 www.timshi.com. All rights reserved.
//

#import "FoursquareFetcher.h"
#import <MapKit/MapKit.h>

#define FoursquareID @"4L5YY03AJUODNELYB1LATCMUBDAMJGE4MO2JKTTFCKMRYSEP"
#define FoursquareSecret @"3FNFFJMYWR4A4OPKJUSSR2LIA0R5ZGOYLDB55CJSLRQASRUB"


@implementation FoursquareFetcher

+ (void)foursqureVenuesForQuery:(NSString *)query location:(CLLocation *)currentLocation completionBlock:(void (^)(NSArray *venues))block
{
    if (currentLocation && query) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSString *requestString = [NSString stringWithFormat:@"https://api.foursquare.com/v2/venues/search?ll=%f,%f&query=%@&client_id=%@&client_secret=%@&v=20110808", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude, query, FoursquareID, FoursquareSecret];
            requestString = [requestString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSURL *requestURL = [NSURL URLWithString:requestString];
            NSString *response = [NSString stringWithContentsOfURL:requestURL encoding:NSUTF8StringEncoding error:nil];
            const char *utfstring = [response UTF8String];
            NSData *data = [NSData dataWithBytes:utfstring length:strlen(utfstring)];
            id responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSDictionary *dict = (NSDictionary *)responseDict;
            dispatch_async(dispatch_get_main_queue(), ^{
                block([[dict objectForKey:@"response"] objectForKey:@"venues"]);
            });
        });
    } else {
        block(nil);
    }
}

+ (NSMutableArray *)sortFoursquareVenues:(NSMutableArray *)venues isAscending:(BOOL)ascending
{
    return [[venues sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        if ([obj1 isKindOfClass:[NSDictionary class]] && [obj2 isKindOfClass:[NSDictionary class]]) {
            NSDictionary *venue1 = (NSDictionary *)obj1;
            NSDictionary *venue2 = (NSDictionary *)obj2;
            double distance1 = [[[venue1 objectForKey:@"location"] objectForKey:@"distance"] doubleValue];
            double distance2 = [[[venue2 objectForKey:@"location"] objectForKey:@"distance"] doubleValue];
            if (distance1 > distance2) {
                return (ascending) ? NSOrderedDescending : NSOrderedAscending;
            } else {
                return (ascending) ? NSOrderedAscending : NSOrderedDescending;
            }
        }
        return NSOrderedSame; 
    }] mutableCopy];
}



@end
