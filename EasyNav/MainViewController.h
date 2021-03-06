//
//  MainViewController.h
//  EasyNav2
//
//  Created by Tim Shi on 8/10/11.
//  Copyright 2011 www.timshi.com. All rights reserved.
//

#import "FlipsideViewController.h"
#import <MapKit/MapKit.h>
#import <iAd/iAd.h>
#import "AdWhirlDelegateProtocol.h"
#import "AdWhirlView.h"
#import "GAITrackedViewController.h"

@interface MainViewController : GAITrackedViewController <FlipsideViewControllerDelegate, UITableViewDelegate, UITableViewDataSource, UISearchDisplayDelegate, UISearchBarDelegate, CLLocationManagerDelegate, ADBannerViewDelegate, AdWhirlDelegate> {
}

@property (strong, nonatomic) IBOutlet UIButton *stopButton;

@end
