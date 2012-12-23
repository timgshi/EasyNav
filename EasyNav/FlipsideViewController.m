//
//  FlipsideViewController.m
//  EasyNav2
//
//  Created by Tim Shi on 8/10/11.
//  Copyright 2011 www.timshi.com. All rights reserved.
//

#import "FlipsideViewController.h"
#import "GANTracker.h"

@implementation FlipsideViewController

@synthesize flipDelegate = _flipDelegate;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Settings";
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
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
    [[GANTracker sharedTracker] trackPageview:@"/info" withError:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 0) {
        return @"www.easynavapp.com \n\n Developed by Tim Shi \n @timothyshi \n Designed by Eric Ertmann \n @bonatapus";
    }
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Settings Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
    }
    cell.textLabel.text = @"Use Metric System";
    UISwitch *metricSwitch = [[UISwitch alloc] init];
    CGRect switchFrame = CGRectMake(cell.frame.size.width - (metricSwitch.frame.size.width + 25), 8, metricSwitch.frame.size.width, metricSwitch.frame.size.height);
    metricSwitch.frame = switchFrame;
    metricSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:kUNITS_PREF_KEY];
    [metricSwitch addTarget:self action:@selector(metricSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    [cell.contentView addSubview:metricSwitch];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

#pragma mark - Actions

- (IBAction)done:(id)sender
{
//    [self.flipDelegate flipsideViewControllerDidFinish:self];
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"flipsideViewControllerDidFinish" object:nil]];
}

- (void)metricSwitchChanged:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]]) {
        UISwitch *metricSwitch = (UISwitch *)sender;
        BOOL useMetrics = metricSwitch.on;
        [[NSUserDefaults standardUserDefaults] setBool:useMetrics forKey:kUNITS_PREF_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

@end
