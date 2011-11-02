//
//  MainViewController.m
//  EasyNav2
//
//  Created by Tim Shi on 8/10/11.
//  Copyright 2011 www.timshi.com. All rights reserved.
//

#import "MainViewController.h"
#import "FoursquareFetcher.h"


@interface MainViewController()
{
    NSString *_previousSearchText;
    IBOutlet UILabel *locationNameLabel;
    IBOutlet UILabel *locationAddressLabel;
    IBOutlet UIImageView *locationTextBackgroundImageView;
    IBOutlet UIImageView *arrowImageView;
}
@property (strong, nonatomic) NSMutableArray *resultsArray;
@property (strong, nonatomic) CLGeocoder *geocoder;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *currentLocation;
@property (strong, nonatomic) CLRegion *searchRegion;
@property (strong, nonatomic) ADBannerView *bannerView;
@property (strong, nonatomic) NSDictionary *selectedVenue;
@end

#define kDefaultSearchRadiusMeters 10000
#define kSearchRegionIdentifier @"searchRegion"

@implementation MainViewController

@synthesize resultsArray = _resultsArray;
@synthesize geocoder = _geocoder;
@synthesize locationManager = _locationManager;
@synthesize currentLocation = _currentLocation;
@synthesize searchRegion = _searchRegion;
@synthesize bannerView = _bannerView;
@synthesize selectedVenue = _selectedVenue;

- (NSMutableArray *)resultsArray
{
    if (!_resultsArray) {
        _resultsArray = [NSMutableArray array];
    }
    return _resultsArray;
}

- (CLGeocoder *)geocoder
{
    if (!_geocoder) {
        _geocoder = [[CLGeocoder alloc] init];
    }
    return _geocoder;
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    locationNameLabel = nil;
    locationAddressLabel = nil;
    locationTextBackgroundImageView = nil;
    arrowImageView = nil;
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
    [self.view addSubview:self.bannerView];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    [self.bannerView removeFromSuperview];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (NSString *)addressStringFromPlacemark:(CLPlacemark *)placemark
{
    NSString *streetNumber = placemark.subThoroughfare;
    NSString *streetName = placemark.thoroughfare;
    NSString *city = placemark.locality;
    NSString *state = placemark.administrativeArea;
    NSString *postalCode = placemark.postalCode;
    NSString *address = @"";
    address = [address stringByAppendingFormat:@"%@ %@, %@, %@ %@", streetNumber, streetName, city, state, postalCode];
    return address;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
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
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%f meters away", distanceFromHere];
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
}

#pragma mark - UISearchDisplayDelegate Methods


- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    if (self.geocoder.geocoding) {
        [self.geocoder cancelGeocode];
    }
    if ([CLLocationManager locationServicesEnabled]) {
        [self.locationManager startUpdatingLocation];
    }

}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
    if (self.geocoder.geocoding) {
        [self.geocoder cancelGeocode];
    }
    _geocoder = nil;
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
    /*
    [self.geocoder geocodeAddressString:searchBar.text inRegion:_searchRegion completionHandler:^(NSArray *placemarks, NSError *error) {
        [self.resultsArray removeAllObjects];
        NSLog(@"%@", placemarks);
        [self.resultsArray addObjectsFromArray:placemarks];
        [self.searchDisplayController.searchResultsTableView reloadData];
    }];
    */
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
    _searchRegion = nil;
    _searchRegion = [[CLRegion alloc] initCircularRegionWithCenter:newLocation.coordinate radius:kDefaultSearchRadiusMeters identifier:kSearchRegionIdentifier];
    //NSLog(@"%@", _currentLocation);
    //NSLog(@"%@", _searchRegion);
}

#pragma mark - ADBannerViewDelegate


-(void)layoutForCurrentOrientation:(BOOL)animated
{
    CGFloat animationDuration = animated ? 0.2f : 0.0f;
    // by default content consumes the entire view area
    CGRect contentFrame = self.view.bounds;
    // the banner still needs to be adjusted further, but this is a reasonable starting point
    // the y value will need to be adjusted by the banner height to get the final position
	CGPoint bannerOrigin = CGPointMake(CGRectGetMinX(contentFrame), CGRectGetMaxY(contentFrame));
    CGFloat bannerHeight = 0.0f;
    //_iadBannerView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
    bannerHeight = _bannerView.bounds.size.height; 
	
    // Depending on if the banner has been loaded, we adjust the content frame and banner location
    // to accomodate the ad being on or off screen.
    // This layout is for an ad at the bottom of the view.
    if(_bannerView.bannerLoaded)
    {
        contentFrame.size.height -= bannerHeight;
		bannerOrigin.y -= bannerHeight;
    }
    else
    {
		bannerOrigin.y += bannerHeight;
    }
    
    // And finally animate the changes, running layout for the content view if required.
    [UIView animateWithDuration:animationDuration
                     animations:^{
                         _bannerView.frame = CGRectMake(bannerOrigin.x, bannerOrigin.y, _bannerView.frame.size.width, _bannerView.frame.size.height);
                     }];
}
 

-(void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    [self layoutForCurrentOrientation:YES];
}

-(void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    [self layoutForCurrentOrientation:YES];
}

-(BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
    return YES;
}

-(void)bannerViewActionDidFinish:(ADBannerView *)banner
{
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
