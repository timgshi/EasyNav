//
//  MainViewController.m
//  EasyNav2
//
//  Created by Tim Shi on 8/10/11.
//  Copyright 2011 www.timshi.com. All rights reserved.
//

#import "MainViewController.h"
#import "FoursquareFetcher.h"
#import "TSHeadingCalculator.h"
#import "ENTestController.h"

#define MILES_PER_METER 0.000621371192


@interface MainViewController()
{
    NSString *_previousSearchText;
}
@property (strong, nonatomic) NSMutableArray *resultsArray;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *currentLocation;
@property (strong, nonatomic) CLHeading *currentHeading;
@property (strong, nonatomic) ADBannerView *bannerView;
@property (strong, nonatomic) NSDictionary *selectedVenue;

@property (strong, nonatomic) IBOutlet UILabel *locationNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *locationAddressLabel;
@property (strong, nonatomic) IBOutlet UIImageView *locationBackgroundImageView;
@property (strong, nonatomic) IBOutlet UIImageView *arrowImageView;
@property (strong, nonatomic) IBOutlet UILabel *distanceLabel;
@property (strong, nonatomic) IBOutlet UILabel *distanceUnitsLabel;

@property BOOL isNavigating, usingMeters;

@property (strong, nonatomic) AdWhirlView *adWhirlView;

- (void)adjustAdSize;
@end


@implementation MainViewController

@synthesize resultsArray = _resultsArray;
@synthesize locationManager = _locationManager;
@synthesize currentLocation = _currentLocation;
@synthesize currentHeading = _currentHeading;
@synthesize bannerView = _bannerView;
@synthesize selectedVenue = _selectedVenue;
@synthesize locationNameLabel = _locationNameLabel;
@synthesize locationAddressLabel = _locationAddressLabel;
@synthesize locationBackgroundImageView = _locationBackgroundImageView;
@synthesize arrowImageView = _arrowImageView;
@synthesize distanceLabel = _distanceLabel;
@synthesize distanceUnitsLabel = _distanceUnitsLabel;
@synthesize isNavigating, usingMeters;
@synthesize adWhirlView = _adWhirlView;

- (NSMutableArray *)resultsArray
{
    if (!_resultsArray) {
        _resultsArray = [NSMutableArray array];
    }
    return _resultsArray;
}



- (CLLocationManager *)locationManager
{
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    }
    return _locationManager;
}

- (ADBannerView *)bannerView
{
    if (!_bannerView) {
        CGRect bannerFrame;
        bannerFrame.origin = CGPointMake(0.0, CGRectGetMaxY(self.view.bounds));
        bannerFrame.size = [ADBannerView sizeFromBannerContentSizeIdentifier:ADBannerContentSizeIdentifierPortrait];
        _bannerView = [[ADBannerView alloc] initWithFrame:bannerFrame];
        _bannerView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
        _bannerView.delegate = self;
    }
    return _bannerView;
}

- (AdWhirlView *)adWhirlView
{
    if (!_adWhirlView) {
        _adWhirlView = [AdWhirlView requestAdWhirlViewWithDelegate:self];
    }
    return _adWhirlView;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)setLocationInfoHidden:(BOOL)hidden
{
    [_locationNameLabel setHidden:hidden];
    [_locationAddressLabel setHidden:hidden];
    [_locationBackgroundImageView setHidden:hidden];
    [_arrowImageView setHidden:hidden];
    [_distanceLabel setHidden:hidden];
    [_distanceUnitsLabel setHidden:hidden];
}

#define PREFERRED_UNITS @"Preferred Units"

- (void)viewDidLoad
{
    [super viewDidLoad];
    isNavigating = NO;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *storedUnitPreference = [defaults objectForKey:PREFERRED_UNITS];
    if (storedUnitPreference) {
        usingMeters = [storedUnitPreference boolValue];
    } else {
        storedUnitPreference = [NSNumber numberWithBool:NO];
        [defaults setObject:storedUnitPreference forKey:PREFERRED_UNITS];
        [defaults synchronize];
        usingMeters = NO;
    }
	[self setLocationInfoHidden:YES];
    [self.searchDisplayController.searchBar setBarStyle:UIBarStyleBlack];
    [self.searchDisplayController.searchBar setBackgroundColor:[UIColor blackColor]];
    [self.searchDisplayController.searchBar setTranslucent:YES];
    [self.searchDisplayController.searchBar setTintColor:[UIColor clearColor]];
#ifndef DEBUG
    CLLocation *origin = [[CLLocation alloc] initWithLatitude:0 longitude:0];
    CLLocation *destination = [[CLLocation alloc] initWithLatitude:0 longitude:-45];
    double testbearing = [TSHeadingCalculator bearingToDestination:destination fromOrigin:origin];
    NSLog(@"BEARING TEST \nOrigin: %@ \nDestination: %@ \nBearing: %f", origin, destination, testbearing);
#endif
    UIDevice *device = [UIDevice currentDevice];
    if ([device respondsToSelector:@selector(isMultitaskingSupported)] &&
        [device isMultitaskingSupported]) {
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(enterForeground:)
         name:UIApplicationWillEnterForegroundNotification
         object:nil];
    }
#if RUN_KIF_TESTS
    [[ENTestController sharedInstance] startTestingWithCompletionBlock:^{
        // Exit after the tests complete so that CI knows we're done
        exit([[ENTestController sharedInstance] failureCount]);
    }];
#endif
}

- (void)viewDidUnload
{
    _locationNameLabel = nil;
    _locationAddressLabel = nil;
    _locationBackgroundImageView = nil;
    _arrowImageView = nil;
    [self setLocationNameLabel:nil];
    [self setLocationAddressLabel:nil];
    [self setLocationBackgroundImageView:nil];
    [self setArrowImageView:nil];
    [self setDistanceLabel:nil];
    [self setDistanceUnitsLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
//    [self.view addSubview:self.bannerView];
    CGRect adFrame = [self.adWhirlView frame];
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    adFrame.origin.y = screenBounds.size.height
    - adFrame.size.height;
    [self.adWhirlView setFrame:adFrame];
    [self.view addSubview:self.adWhirlView];
    [self adjustAdSize];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
//    [self.bannerView removeFromSuperview];
    [self.adWhirlView removeFromSuperview];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark multitasking methods

- (void)enterForeground:(NSNotification *)notification {
    [self.adWhirlView updateAdWhirlConfig];
}

#pragma mark - Navigation Controls

- (NSString *)addressStringFromLocation:(NSDictionary *)location
{
    NSString *street = [location objectForKey:@"address"];
    NSString *city = [location objectForKey:@"city"];
    NSString *state = [location objectForKey:@"state"];
    NSString *postalCode = [location objectForKey:postalCode];
    NSString *address = @"";
    address = [address stringByAppendingFormat:@"%@ %@, %@ %@", street, city, state, postalCode];
    return address;
}

- (NSString *)distanceFromCurrentLocationToLocation:(NSDictionary *)location
{
    NSNumber *distance = nil;
    if (_currentLocation) {
        double lat = [[location objectForKey:@"lat"] doubleValue];
        double lng = [[location objectForKey:@"lng"] doubleValue];
        CLLocation *venueLocation = [[CLLocation alloc] initWithLatitude:lat longitude:lng];
        CLLocationDistance distanceFromHere = [venueLocation distanceFromLocation:_currentLocation];
        if (usingMeters) {
            distance = [NSNumber numberWithDouble:distanceFromHere];
        } else {
            double milesFromHere = distanceFromHere * MILES_PER_METER;
            distance = [NSNumber numberWithDouble:milesFromHere];
        }
    } else {
        distance = [NSNumber numberWithDouble:0]; 
    }
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setPositiveFormat:@"0.##"];
    return [numberFormatter stringFromNumber:distance];
}

- (void)updateDistanceDisplay
{
    NSString *distance = [self distanceFromCurrentLocationToLocation:[_selectedVenue objectForKey:@"location"]];
    NSString *units = (usingMeters) ? @"m" : @"mi";
    [_distanceLabel setText:distance];
    [_distanceUnitsLabel setText:units];
}

- (void)updateCompassDisplay
{
    
}

- (void)updateNavigationDisplay
{
    [self updateCompassDisplay];
    [self updateDistanceDisplay];
}

- (void)startNavigation
{
    if (_selectedVenue) {
        isNavigating = YES;
        [self.locationManager startUpdatingLocation];
        [self.locationManager startUpdatingHeading];
        NSString *name = [_selectedVenue objectForKey:@"name"];
        NSString *address = [self addressStringFromLocation:[_selectedVenue objectForKey:@"location"]];
        [_locationNameLabel setText:name];
        [_locationAddressLabel setText:address];
        [self updateDistanceDisplay];
        [self setLocationInfoHidden:NO];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Destination!" 
                                                        message:@"Please search for a destination first" 
                                                       delegate:nil 
                                              cancelButtonTitle:@"Ok" 
                                              otherButtonTitles: nil];
        [alert show];
    }
}

- (void)stopNavigation
{
    
}

- (void)pauseNavigation
{
    
}



#pragma mark - UITableViewDelegateMethods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.resultsArray count];
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *kCellID = @"EasyNavSearchResultCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kCellID];
    }
    id obj = [self.resultsArray objectAtIndex:indexPath.row];
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *venue = (NSDictionary *)obj;
        cell.textLabel.text = [venue objectForKey:@"name"];
        NSDictionary *locationDict = [venue objectForKey:@"location"];
        NSLog(@"locationdict: %@", locationDict);
        double lat = [[locationDict objectForKey:@"lat"] doubleValue];
        double lng = [[locationDict objectForKey:@"lng"] doubleValue];
        CLLocation *venueLocation = [[CLLocation alloc] initWithLatitude:lat longitude:lng];
        CLLocationDistance distanceFromHere = [venueLocation distanceFromLocation:_currentLocation];
        double milesFromHere = distanceFromHere * MILES_PER_METER;
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setPositiveFormat:@"0.##"];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ miles away", [numberFormatter stringFromNumber:[NSNumber numberWithDouble:milesFromHere]]];
    } else {
        cell.textLabel.text = @"";
        cell.detailTextLabel.text = @"";
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _selectedVenue = [self.resultsArray objectAtIndex:indexPath.row];
    [self.searchDisplayController setActive:NO animated:YES];
    [self startNavigation];
}

#pragma mark - UISearchDisplayDelegate Methods


- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    if ([CLLocationManager locationServicesEnabled]) {
        [self.locationManager startUpdatingLocation];
    }

}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
    [self.locationManager stopUpdatingLocation];
    _locationManager = nil;
    
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    return NO;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    NSLog(@"%@", searchBar.text);
    [FoursquareFetcher foursqureVenuesForQuery:searchBar.text location:_currentLocation completionBlock:^(NSArray *venues){
        NSLog(@"%@", venues);
        [self.resultsArray removeAllObjects];
        [self.resultsArray addObjectsFromArray:venues];
        self.resultsArray = [FoursquareFetcher sortFoursquareVenues:self.resultsArray isAscending:YES];
        [self.searchDisplayController.searchResultsTableView reloadData];
    }];
     
}

#pragma mark - CLLocationManagerDelegate Methods

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    _currentLocation = newLocation;
    if (isNavigating) {
        [self updateDistanceDisplay];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    _currentHeading = newHeading;
    if (isNavigating) {
        [self updateCompassDisplay];
    }
}

//#pragma mark - ADBannerViewDelegate
//
//
//-(void)layoutForCurrentOrientation:(BOOL)animated
//{
//    CGFloat animationDuration = animated ? 0.2f : 0.0f;
//    // by default content consumes the entire view area
//    CGRect contentFrame = self.view.bounds;
//    // the banner still needs to be adjusted further, but this is a reasonable starting point
//    // the y value will need to be adjusted by the banner height to get the final position
//	CGPoint bannerOrigin = CGPointMake(CGRectGetMinX(contentFrame), CGRectGetMaxY(contentFrame));
//    CGFloat bannerHeight = 0.0f;
//    //_iadBannerView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
//    bannerHeight = _bannerView.bounds.size.height; 
//	
//    // Depending on if the banner has been loaded, we adjust the content frame and banner location
//    // to accomodate the ad being on or off screen.
//    // This layout is for an ad at the bottom of the view.
//    if(_bannerView.bannerLoaded)
//    {
//        contentFrame.size.height -= bannerHeight;
//		bannerOrigin.y -= bannerHeight;
//    }
//    else
//    {
//		bannerOrigin.y += bannerHeight;
//    }
//    
//    // And finally animate the changes, running layout for the content view if required.
//    [UIView animateWithDuration:animationDuration
//                     animations:^{
//                         _bannerView.frame = CGRectMake(bannerOrigin.x, bannerOrigin.y, _bannerView.frame.size.width, _bannerView.frame.size.height);
//                     }];
//}
// 
//
//-(void)bannerViewDidLoadAd:(ADBannerView *)banner
//{
//    [self layoutForCurrentOrientation:YES];
//}
//
//-(void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
//{
//    [self layoutForCurrentOrientation:YES];
//}
//
//-(BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
//{
//    return YES;
//}
//
//-(void)bannerViewActionDidFinish:(ADBannerView *)banner
//{
//}
//
#pragma mark - AdWhirlDelegate Protocol Methods

- (NSString *)adWhirlApplicationKey
{
    return kEN_ADWHIRL_KEY;
}

- (UIViewController *)viewControllerForPresentingModalView
{
    return self;
}

#ifndef DEBUG
- (BOOL)adWhirlTestMode
{
    return YES;
}
#endif

- (void)adWhirlDidReceiveAd:(AdWhirlView *)adWhirlView
{
    [UIView animateWithDuration:0.7 animations:^{
        CGSize adSize = [self.adWhirlView actualAdSize];
        CGRect newFrame = self.adWhirlView.frame;
        newFrame.size.height = adSize.height;
        newFrame.size.width = adSize.width;
        newFrame.origin.x = (self.view.bounds.size.width - adSize.width)/2;
        newFrame.origin.y = self.view.bounds.size.height - adSize.height;
        self.adWhirlView.frame = newFrame; 
    }];
}

- (void)adjustAdSize {
    [UIView animateWithDuration:0.7 animations:^{
        CGSize adSize = [self.adWhirlView actualAdSize];
        CGRect newFrame = self.adWhirlView.frame;
        newFrame.size.height = adSize.height;
        newFrame.size.width = adSize.width;
        newFrame.origin.x = (self.view.bounds.size.width - adSize.width)/2;
        newFrame.origin.y = self.view.bounds.size.height - adSize.height;
        self.adWhirlView.frame = newFrame;
    }];
}

- (void)adWhirlWillPresentFullScreenModal
{
    
}

- (void)adWhirlDidDismissFullScreenModal
{
    [self adjustAdSize];
}

- (CLLocation *)locationInfo
{
    return (self.currentLocation) ? self.currentLocation : nil;
}

#pragma mark - Flipside View

- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller
{
    
    [self dismissModalViewControllerAnimated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showAlternate"]) {
        [[segue destinationViewController] setDelegate:self];
    }
}

@end
