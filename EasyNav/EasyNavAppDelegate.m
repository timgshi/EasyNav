//
//  EasyNavAppDelegate.m
//  EasyNav
//
//  Created by Tim Shi on 8/10/11.
//  Copyright 2011 www.timshi.com. All rights reserved.
//

#import "EasyNavAppDelegate.h"
#import "GAI.h"

@implementation EasyNavAppDelegate

@synthesize window = _window;

#define kTestflightTeamID @"bec48ec49683f9bd58d587615fca9894_MjQ3NDAyMDExLTExLTAxIDIzOjIzOjMwLjM0NjI0Mg" 
#define kGOOGLE_ANALYTICS_ID @"UA-28594569-1"

static const NSInteger kGANDispatchPeriodSec = 10;

- (void)setupPreferences
{
    NSString *unitsPrefKey = kUNITS_PREF_KEY;
    id testObj = [[NSUserDefaults standardUserDefaults] objectForKey:unitsPrefKey];
	if (!testObj)
	{
		// no default values have been set, create them here based on what's in our Settings bundle info
		//
		NSString *pathStr = [[NSBundle mainBundle] bundlePath];
		NSString *settingsBundlePath = [pathStr stringByAppendingPathComponent:@"Settings.bundle"];
		NSString *finalPath = [settingsBundlePath stringByAppendingPathComponent:@"Root.plist"];
        
		NSDictionary *settingsDict = [NSDictionary dictionaryWithContentsOfFile:finalPath];
		NSArray *prefSpecifierArray = [settingsDict objectForKey:@"PreferenceSpecifiers"];
        
		NSDictionary *prefItem;
        
        NSNumber *unitsPreferenceDefault;
        
		for (prefItem in prefSpecifierArray)
		{
			NSString *keyValueStr = [prefItem objectForKey:@"Key"];
			id defaultValue = [prefItem objectForKey:@"DefaultValue"];
			if ([keyValueStr isEqualToString:unitsPrefKey]) {
                unitsPreferenceDefault = defaultValue;
            }
		}
        
		// since no default values have been set (i.e. no preferences file created), create it here		
		NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
                                     unitsPreferenceDefault, unitsPrefKey,
                                     nil];
        
		[[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}

}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self setupPreferences];
//    [TestFlight takeOff:kTestflightTeamID];
//#if RUN_KIF_TESTS
//    [[ENTestController sharedInstance] startTestingWithCompletionBlock:^{
//        // Exit after the tests complete so that CI knows we're done
//        exit([[ENTestController sharedInstance] failureCount]);
//    }];
//#endif
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    [[GAI sharedInstance] trackerWithTrackingId:kGOOGLE_ANALYTICS_ID];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

@end
