//
//  ViewController.m
//  iBeaconReceiverApp
//
//  Created by MAEDAHAJIME on 2015/06/07.
//  Copyright (c) 2015年 MAEDAHAJIME. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>

#define UUID        @"D456894A-02F0-4CB0-8258-81C187DF45C2"
#define MAJOR       @"1"
#define MINOR       @"1"
#define IDENTIFIER  @"jp.classmethod.testregion"

@interface ViewController () <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager     *manager;
@property (strong, nonatomic) CLBeaconRegion        *region;

@property (strong, nonatomic) NSUUID                *proximityUUID;
@property (strong, nonatomic) NSString              *identifier;
@property uint16_t                                  major;
@property uint16_t                                  minor;

@end

@implementation ViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    if ( [CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]] ) {
        
        // Create Manager
        self.manager            = [CLLocationManager new];
        self.manager.delegate   = self;
        
        // Create parameter
        self.proximityUUID      = [[NSUUID alloc]initWithUUIDString:UUID];
        self.identifier         = IDENTIFIER;
        self.major              = (uint16_t)[MAJOR integerValue];
        self.minor              = (uint16_t)[MINOR integerValue];
        
        // Create CLBeaconRegion
        self.region = [[CLBeaconRegion alloc]initWithProximityUUID:self.proximityUUID
                                                        identifier:self.identifier];
        self.region.notifyOnEntry               = YES; // 領域に入った事を監視 YES
        self.region.notifyOnExit                = YES; // 領域を出た事を監視
        self.region.notifyEntryStateOnDisplay   = NO; // デバイスのディスプレイがオンのとき、ビーコン通知が送信されない NO

        
        /////////////////////////////////
        // iOS8の追加
        // 位置情報の取得許可を求めるメソッド
        if ([self.manager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            // requestAlwaysAuthorizationメソッドが利用できる場合(iOS8以上の場合)
            // 位置情報の取得許可を求めるメソッド
            [self.manager requestAlwaysAuthorization];
        } else {
            // requestAlwaysAuthorizationメソッドが利用できない場合(iOS8未満の場合)
            [self.manager startMonitoringForRegion: self.region];
        }
        /////////////////////////////////
        
        //[self.manager startRangingBeaconsInRegion:self.region];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    //[self.manager requestStateForRegion:self.region];
    [self sendNotification:@"地域の監視を開始 Start Monitoring Region"];
}

- (void)locationManager:(CLLocationManager *)manager
         didEnterRegion:(CLRegion *)region
{
    [self sendNotification:@"ようこそ！"];
    // Beaconの距離測定を開始する
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [self.manager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
}

- (void)locationManager:(CLLocationManager *)manager
          didExitRegion:(CLRegion *)region
{
    [self sendNotification:@"さようなら！"];
    // Beaconの距離測定を終了する
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [self.manager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
}

- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray *)beacons
               inRegion:(CLBeaconRegion *)region
{
    // init
    NSString *uuid                          = @"unknown";
    CLProximity proximity                   = CLProximityUnknown;
    CLLocationAccuracy accuracy             = 0.0;
    NSInteger rssi                          = 0;
    NSNumber *major                         = @0;
    NSNumber *minor                         = @0;
    
    // near beacon
    CLBeacon *beacon    = beacons.firstObject;
    
    uuid                = beacon.proximityUUID.UUIDString;
    proximity           = beacon.proximity;
    accuracy            = beacon.accuracy;
    rssi                = beacon.rssi;
    major               = beacon.major;
    minor               = beacon.minor;
    
    // update view
    self.uuidLabel.text         = beacon.proximityUUID.UUIDString;
    self.majorLabel.text        = [NSString stringWithFormat:@"%@", major];
    self.minorLabel.text        = [NSString stringWithFormat:@"%@", minor];
    self.accuracyLabel.text = [NSString stringWithFormat:@"%f", accuracy];
    self.rssiLabel.text = [NSString stringWithFormat:@"%ld", (long)rssi];
    
    switch (proximity) {
        case CLProximityUnknown:
            self.proximityLabel.text    = @"測距エラー";
            break;
        case CLProximityImmediate:
            self.proximityLabel.text    = @"より近い";
            break;
        case CLProximityNear:
            self.proximityLabel.text    = @"近い";
            break;
        case CLProximityFar:
            self.proximityLabel.text    = @"遠い";
            break;
        default:
            break;
    }
    
    if ( proximity == CLProximityUnknown ) {
        self.beconStateLabel.text   = @"測距エラー";
    } else {
        self.beconStateLabel.text   = @"ENTER";
    }
    
    if ( proximity == CLProximityImmediate && rssi > -40 ) {
        self.beconStateLabel.text   = @"よりより近い";
    }
}

// iOS8 ユーザの位置情報の許可状態を確認するメソッド
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusNotDetermined) {
        // ユーザが位置情報の使用を許可していない
    } else if(status == kCLAuthorizationStatusAuthorizedAlways) {
        // ユーザが位置情報の使用を常に許可している場合
        [self.manager startMonitoringForRegion: self.region];
    } else if(status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        // ユーザが位置情報の使用を使用中のみ許可している場合
        [self.manager startMonitoringForRegion: self.region];
    }
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    [self sendNotification:@"出口エリア Exit Region"];
}

#pragma mark - Private methods

- (void)sendNotification:(NSString*)message
{
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    
    notification.fireDate = [[NSDate date] init];
    notification.timeZone = [NSTimeZone defaultTimeZone];
    notification.alertBody = message;
    notification.alertAction = @"Open";
    notification.soundName = UILocalNotificationDefaultSoundName;
    
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

@end
