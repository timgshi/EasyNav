//
//  KIFTestScenario+ENAdditions.m
//  EasyNav
//
//  Created by Tim Shi on 12/28/11.
//  Copyright (c) 2011 www.timshi.com. All rights reserved.
//

#import "KIFTestScenario+ENAdditions.h"
#import "KIFTestStep.h"

@implementation KIFTestScenario (ENAdditions)

+ (id)scenarioToTestSearchBar
{
    KIFTestScenario *scenario = [KIFTestScenario scenarioWithDescription:@"Tests a search"];
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Search Bar"]];
    return scenario;
}

@end
