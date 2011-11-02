//
//  FoursquareFetcher.h
//  EasyNav2
//
//  Created by Tim Shi on 8/11/11.
//  Copyright 2011 www.timshi.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CLLocation;

@interface FoursquareFetcher : NSObject

+ (void)foursqureVenuesForQuery:(NSString *)query location:(CLLocation *)currentLocation completionBlock:(void (^)(NSArray *venues))block;

+ (NSMutableArray *)sortFoursquareVenues:(NSMutableArray *)venues isAscending:(BOOL)ascending;

@end
