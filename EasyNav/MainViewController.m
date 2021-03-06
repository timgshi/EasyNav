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
#import <MapKit/MapKit.h>

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
@property (strong, nonatomic) IBOutlet UIImageView *searchIndicatorImageView;

@property (strong, nonatomic) CLGeocoder *geocoder;

@property (nonatomic) BOOL usingMeters;
@property BOOL isNavigating, isSearching;

@property (strong, nonatomic) AdWhirlView *adWhirlView;

- (void)adjustAdSize;
@end


@implementation MainViewController
@synthesize stopButton = _stopButton;

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
@synthesize searchIndicatorImageView = _searchIndicatorImageView;
@synthesize isNavigating, usingMeters, isSearching;
@synthesize adWhirlView = _adWhirlView;
@synthesize geocoder = _geocoder;

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

- (CLGeocoder *)geocoder
{
    if (!_geocoder) {
        _geocoder = [[CLGeocoder alloc] init];
    }
    return _geocoder;
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
    [self.searchIndicatorImageView setHidden:!hidden];
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
    self.trackedViewName = @"Main Screen";
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
    [self.stopButton setHidden:YES];
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
    [self setSearchIndicatorImageView:nil];
    [self setGeocoder:nil];
    [self setStopButton:nil];
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
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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
        [self.locationManager startUpdatingLocation];
        [self.locationManager startUpdatingHeading];
        NSString *name = [_selectedVenue objectForKey:@"name"];
        NSString *address = [self addressStringFromLocation:[_selectedVenue objectForKey:@"location"]];
        [_locationNameLabel setText:name];
        [_locationAddressLabel setText:address];
        [self updateDistanceDisplay];
        [self setLocationInfoHidden:NO];
        [self.stopButton setHidden:NO];
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
    if (_selectedVenue) {
        isNavigating = NO;
        [self setLocationInfoHidden:YES];
//        [self.locationManager stopUpdatingHeading];
//        [self.locationManager stopUpdatingLocation];
    }
}

- (void)pauseNavigation
{
    
}

- (IBAction)stopButtonPressed 
{
    [self stopNavigation];
    [self.stopButton setHidden:YES];
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

- (void)searchForAddress:(NSString *)address
{
    [self.geocoder geocodeAddressString:address completionHandler:^(NSArray *placemarks, NSError *error) {
        for (CLPlacemark *placemark in placemarks) {
            NSMutableDictionary *locationDict = [NSMutableDictionary dictionary];
            [locationDict setObject:[NSNumber numberWithDouble:placemark.location.coordinate.latitude] forKey:@"lat"];
            [locationDict setObject:[NSNumber numberWithDouble:placemark.location.coordinate.longitude] forKey:@"lng"];
            [locationDict setObject:[NSString stringWithFormat:@"%@ %@", placemark.subThoroughfare, placemark.thoroughfare] forKey:@"address"];
            [locationDict setObject:placemark.locality forKey:@"city"];
            [locationDict setObject:placemark.administrativeArea forKey:@"state"];
            NSString *addressString = [self addressStringFromLocation:locationDict];
            NSDictionary *venueDict = [NSDictionary dictionaryWithObjectsAndKeys:locationDict, @"location", addressString, @"name", address, @"searchAddress", @"yes", @"isAddress", nil];
            [self.resultsArray insertObject:venueDict atIndex:0];
            [self.searchDisplayController.searchResultsTableView reloadData];
        }
    }];
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
        [self.locationManager startUpdatingHeading];
        [self.locationManager startUpdatingLocation];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        [self searchForAddress:searchBar.text];
        [FoursquareFetcher foursqureVenuesForQuery:searchBar.text location:_currentLocation completionBlock:^(NSArray *venues){
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            NSMutableArray *tempArray = [NSMutableArray array];
            for (NSDictionary *dict in self.resultsArray) {
                NSString *searchAddress = [dict objectForKey:@"searchAddress"];
                if ([searchAddress isEqualToString:searchBar.text]) {
                    [tempArray addObject:dict];
                }
            }
            [self.resultsArray removeAllObjects];
            [self.resultsArray addObjectsFromArray:venues];
            for (NSDictionary *dict in tempArray) {
                [self.resultsArray insertObject:dict atIndex:0];
            }
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
    } else {
        [self.locationManager stopUpdatingLocation];
        [self.locationManager performSelector:@selector(startUpdatingLocation) withObject:nil afterDelay:10];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    _currentHeading = newHeading;
    if (isNavigating) {
        [self updateCompassDisplay];
    } else {
        [self.locationManager stopUpdatingHeading];
        [self.locationManager performSelector:@selector(startUpdatingHeading) withObject:nil afterDelay:5];
    }
}


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
