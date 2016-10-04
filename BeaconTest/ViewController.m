//
//  ViewController.m
//  BeaconTest
//
//  Created by ParkSanggeon on 30/09/16.
//  Copyright © 2016 sensorberg. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>

@interface ViewController () <CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonnull, nonatomic, strong) CLLocationManager *locationManager;
@property (nullable, nonatomic, weak) IBOutlet UITableView *tableView;
@property (nullable, nonatomic, weak) IBOutlet UILabel *rangedCountLabel;
@property (nullable, nonatomic, weak) IBOutlet UILabel *unrangedCountLabel;
@property (nonnull, nonatomic, strong) NSMutableArray *tableViewDataArray;
@property (nonnull, nonatomic, strong) NSMutableArray *logDataArray;

@property (nonnull, nonatomic, strong) NSNumber *rangedCount;
@property (nonnull, nonatomic, strong) NSNumber *unrangedCount;

@property (nonnull, nonatomic, strong) NSDateFormatter *dateFormatter;

@property (nonatomic, assign) NSTimeInterval lastCheckTime;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.dateFormatter = [NSDateFormatter new];
    [self.dateFormatter setLocale:[NSLocale currentLocale]];
    self.dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss ZZZZZ";
    self.lastCheckTime = [NSDate date].timeIntervalSince1970;
    [self.tableViewDataArray addObject:self.logDataArray];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateData) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.locationManager requestAlwaysAuthorization];
}
#pragma mark - UITalbeViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.tableViewDataArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.tableViewDataArray objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TableViewCell" forIndexPath:indexPath];
    NSDictionary *logData = [[self.tableViewDataArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    cell.textLabel.text = logData[@"status"];
    NSDate *date = logData[@"time"];
    cell.detailTextLabel.text = [self.dateFormatter stringFromDate:date];
    UIColor *bgColor = logData[@"color"];
    cell.contentView.backgroundColor = bgColor;
    cell.textLabel.backgroundColor = bgColor;
    cell.detailTextLabel.backgroundColor = bgColor;
    
    return cell;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSDictionary *logData = [[self.tableViewDataArray objectAtIndex:section] firstObject];
    NSDate *date = logData[@"time"];
    return [self.dateFormatter stringFromDate:date];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusAuthorizedAlways)
    {
        [self startMonitoring];
    }
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    if ([region isKindOfClass:[CLBeaconRegion class]])
    {
        [self.locationManager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    
}

- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray<CLBeacon *> *)beacons inRegion:(CLBeaconRegion *)region
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground)
        {
            return;
        }
        
        NSTimeInterval currentTimeinterval = [NSDate date].timeIntervalSince1970;
        
        if (currentTimeinterval - strongSelf.lastCheckTime > 3.0f && self.logDataArray.count)
        {
            strongSelf.logDataArray = [NSMutableArray new];
            [strongSelf.tableViewDataArray addObject:self.logDataArray];
        }
        
        NSMutableDictionary *logDict = [NSMutableDictionary new];
        [logDict setObject:[NSDate date] forKey:@"time"];
        if (beacons.count)
        {
            [logDict setObject:[UIColor whiteColor] forKey:@"color"];
            [logDict setObject:@"Ranged" forKey:@"status"];
            strongSelf.rangedCount = @(self.rangedCount.integerValue + 1);
        }
        else
        {
            [logDict setObject:@"Unranged" forKey:@"status"];
            [logDict setObject:[UIColor grayColor] forKey:@"color"];
            strongSelf.unrangedCount = @(self.unrangedCount.integerValue + 1);
        }
        
        [strongSelf.logDataArray addObject:logDict];
        strongSelf.lastCheckTime = currentTimeinterval;
    });
}

#pragma mark - InternalMethod

- (void)startMonitoring
{
    NSString *regionUUID = @"73676723-7400-0000-FFFF-0000FFFF0007";
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:regionUUID];
    CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:[@"sensorberg." stringByAppendingPathExtension:regionUUID]];
    beaconRegion.notifyEntryStateOnDisplay = YES;
    //
    [beaconRegion setNotifyOnEntry:YES];
    [beaconRegion setNotifyOnExit:YES];
    
    [self.locationManager startMonitoringForRegion:beaconRegion];
    [self.locationManager startUpdatingLocation];
}

- (void)updateData
{
    self.rangedCountLabel.text = [NSString stringWithFormat:@"Ranged : %@", self.rangedCount];
    self.unrangedCountLabel.text = [NSString stringWithFormat:@"Unranged : %@", self.unrangedCount];
    [self.tableView reloadData];
}

#pragma mark - Accessors

- (CLLocationManager *)locationManager
{
    if (!_locationManager)
    {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
    }
    
    return _locationManager;
}

- (NSMutableArray *)tableViewDataArray
{
    if (!_tableViewDataArray)
    {
        _tableViewDataArray = [NSMutableArray new];
    }
    return _tableViewDataArray;
}

- (NSMutableArray *)logDataArray
{
    if (!_logDataArray)
    {
        _logDataArray = [NSMutableArray new];
    }
    return _logDataArray;
}

- (NSNumber *)rangedCount
{
    if (!_rangedCount)
    {
        _rangedCount = @(0);
    }
    return _rangedCount;
}

- (NSNumber *)unrangedCount
{
    if (!_unrangedCount)
    {
        _unrangedCount = @(0);
    }
    return _unrangedCount;
}

@end
