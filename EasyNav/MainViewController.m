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


@interface MainViewController() <UIAlertViewDelegate>
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

@property (nonatomic) BOOL usingMeters;
@property BOOL isNavigating, isSearching;

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
@synthesize isNavigating, usingMeters, isSearching;
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

- (BOOL)usingMeters
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kUNITS_PREF_KEY];
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

- (void)setupAccessibility
{
    [self.searchDisplayController setAccessibilityTraits:UIAccessibilityTraitSearchField];
    [self.searchDisplayController.searchBar setAccessibilityLabel:@"Search Bar"];
    [self.searchDisplayController.searchResultsTableView setAccessibilityLabel:@"Results Tableview"];
}

#define PREFERRED_UNITS @"Preferred Units"

- (void)viewDidLoad
{
    [super viewDidLoad];
    isNavigating = NO;
	[self setLocationInfoHidden:YES];
    [self.searchDisplayController.searchBar setBarStyle:UIBarStyleBlack];
    [self.searchDisplayController.searchBar setBackgroundColor:[UIColor blackColor]];
    [self.searchDisplayController.searchBar setTranslucent:YES];
    [self.searchDisplayController.searchBar setTintColor:[UIColor clearColor]];
    UIDevice *device = [UIDevice currentDevice];
    if ([device respondsToSelector:@selector(isMultitaskingSupported)] &&
        [device isMultitaskingSupported]) {
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(enterForeground:)
         name:UIApplicationWillEnterForegroundNotification
         object:nil];
    }
    [self setupAccessibility];
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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    CGRect adFrame = [self.adWhirlView frame];
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    adFrame.origin.y = screenBounds.size.height
    - adFrame.size.height;
    [self.adWhirlView setFrame:adFrame];
    [self.view addSubview:self.adWhirlView];
    [self adjustAdSize];
#if RUN_KIF_TESTS
    [[ENTestController sharedInstance] startTestingWithCompletionBlock:^{
        // Exit after the tests complete so that CI knows we're done
        exit([[ENTestController sharedInstance] failureCount]);
    }];
#endif
    if ([CLLocationManager locationServicesEnabled]) {
        [self.locationManager startUpdatingLocation];
        [self.locationManager startUpdatingHeading];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
//    [self.bannerView removeFromSuperview];
    [self.adWhirlView removeFromSuperview];
    [self.locationManager stopUpdatingHeading];
    [self.locationManager stopUpdatingLocation];
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
    if (street && city && state) {
        address = [address stringByAppendingFormat:@"%@ %@, %@", street, city, state];
    }
    return address;
}

- (CLLocation *)locationFromVenue:(NSDictionary *)venue
{
    NSDictionary *location = [venue objectForKey:@"location"];
    double lat = [[location objectForKey:@"lat"] doubleValue];
    double lng = [[location objectForKey:@"lng"] doubleValue];
    CLLocation *venueLocation = [[CLLocation alloc] initWithLatitude:lat longitude:lng]; 
    return venueLocation;
}

- (NSString *)distanceFromCurrentLocationToLocation:(NSDictionary *)location
{
    NSNumber *distance = nil;
    if (_currentLocation) {
        double lat = [[location objectForKey:@"lat"] doubleValue];
        double lng = [[location objectForKey:@"lng"] doubleValue];
        CLLocation *venueLocation = [[CLLocation alloc] initWithLatitude:lat longitude:lng];
        CLLocationDistance distanceFromHere = [venueLocation distanceFromLocation:_currentLocation];
        if (self.usingMeters) {
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
    NSString *units = (self.usingMeters) ? @"m" : @"mi";
    [_distanceLabel setText:distance];
    [_distanceUnitsLabel setText:units];
}

- (void)updateCompassDisplay
{
    double bearing = [TSHeadingCalculator bearingToDestination:[self locationFromVenue:_selectedVenue] fromOrigin:self.currentLocation];
    double heading = self.currentHeading.magneticHeading;
    double diff = heading - bearing;
    double radDiff = diff * (M_PI / 180) * -1;
    self.arrowImageView.transform = CGAffineTransformMakeRotation(radDiff);
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
//        [self.locationManager startUpdatingLocation];
//        [self.locationManager startUpdatingHeading];
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
                                              otherButtonTitles:nil];
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
        double lat = [[locationDict objectForKey:@"lat"] doubleValue];
        double lng = [[locationDict objectForKey:@"lng"] doubleValue];
        CLLocation *venueLocation = [[CLLocation alloc] initWithLatitude:lat longitude:lng];
        CLLocationDistance distanceFromHere = [venueLocation distanceFromLocation:_currentLocation];
        double milesFromHere = distanceFromHere * MILES_PER_METER;
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setPositiveFormat:@"0.##"];
        if (self.usingMeters) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ meters away", [numberFormatter stringFromNumber:[NSNumber numberWithDouble:distanceFromHere]]];
        } else {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ miles away", [numberFormatter stringFromNumber:[NSNumber numberWithDouble:milesFromHere]]];
        }
    } else {
        cell.textLabel.text = @"";
        cell.detailTextLabel.text = @"";
    }
    if (isSearching) {
        cell.textLabel.text = @"Searching";
        cell.detailTextLabel.text = @"";
    }
    [cell setAccessibilityLabel:cell.textLabel.text];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _selectedVenue = [self.resultsArray objectAtIndex:indexPath.row];
    [self.searchDisplayController setActive:NO animated:YES];
    [self.searchDisplayController.searchBar setPlaceholder:@"Search for another location"];
    [self startNavigation];
}

#pragma mark - UISearchDisplayDelegate Methods


- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
//    if ([CLLocationManager locationServicesEnabled]) {
//        [self.locationManager startUpdatingLocation];
//    }

}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
//    [self.locationManager stopUpdatingLocation];
//    _locationManager = nil;
//    
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    return YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    if ([CLLocationManager locationServicesEnabled]) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        [FoursquareFetcher foursqureVenuesForQuery:searchBar.text location:_currentLocation completionBlock:^(NSArray *venues){
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            [self.resultsArray removeAllObjects];
            [self.resultsArray addObjectsFromArray:venues];
            self.resultsArray = [FoursquareFetcher sortFoursquareVenues:self.resultsArray isAscending:YES];
            [self.searchDisplayController.searchResultsTableView reloadData];
        }];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Location Services" 
                                                        message:@"You must have location services enabled to search for a location" 
                                                       delegate:self 
                                              cancelButtonTitle:@"Cancel" 
                                              otherButtonTitles: @"Settings", nil];
        [alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView.title isEqualToString:@"Location Services"]) {
        if (buttonIndex == 1) {
            NSURL *locationServicesURL = [NSURL URLWithString:@"prefs:root=LOCATION_SERVICES"];
            [[UIApplication sharedApplication] openURL:locationServicesURL];
        }
    }
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

//#ifndef DEBUG
//- (BOOL)adWhirlTestMode
//{
//    return YES;
//}
//#endif

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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(flipsideViewControllerDidFinish:) name:@"flipsideViewControllerDidFinish" object:nil];
    }
}

@end
