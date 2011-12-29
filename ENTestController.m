//
//  ENTestController.m
//  EasyNav
//
//  Created by Tim Shi on 12/28/11.
//  Copyright (c) 2011 www.timshi.com. All rights reserved.
//

#import "ENTestController.h"
#import "KIFTestScenario+ENAdditions.h"

@implementation ENTestController

- (void)initializeScenarios
{
//    [super initializeScenarios];
    KIFTestScenario *scenario = [KIFTestScenario scenarioWithDescription:@"Tests a search"];
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Search Bar"]];
    [scenario addStep:[KIFTestStep stepToEnterText:@"safeway" intoViewWithAccessibilityLabel:@"Search Bar"]];
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"search"]];
//    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Safeway"]];
//    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Safeway"]];
    [scenario addStep:[KIFTestStep stepToWaitForTimeInterval:3 description:@"3 second pause"]];
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Safeway"]];
    [scenario addStep:[KIFTestStep stepToWaitForTimeInterval:2 description:@"2 second pause"]];
    [self addScenario:scenario];
    
}

@end
