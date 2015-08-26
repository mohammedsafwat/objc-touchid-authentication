//
//  MainViewController.m
//  TouchID
//
//  Created by Mohammed Safwat on 8/24/15.
//  Copyright (c) 2015 safwat. All rights reserved.
//

#import "MainViewController.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import "MBProgressHUD.h"
#import "LocationDataUtilities.h"

#define AUTHENTICATION_ERROR_TAG 0
#define AUTHENTICATION_SUCCESSFUL_TAG 1
#define DEVICE_NOT_SUPPORTED_TAG 2
#define LOCATION_MANAGER_ACCESS_DISABLED_TAG 3
#define AUTHENTICATION_WITH_PASSWORD_ALERT_TAG 4
#define APPLICATION_PASSWORD @"21iLAB"

#define MAP_ZOOM_LEVEL 8
#define DESTINATION_ADDRESS @"Pflugstrasse 10/12, 9490 Vaduz, Liechtenstein."

@import GoogleMaps;

@interface MainViewController ()
@property (weak, nonatomic) IBOutlet UIButton *authenticateButton;
@property (nonatomic, strong) GMSMapView *mapView;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL canStartRetrievingLocation;
@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initializeValues];
}

- (void)initializeValues {
    self.mapView.alpha = 0;
    self.locationManager = [[CLLocationManager alloc]init];
    self.locationManager.delegate = self;
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
}

- (IBAction)onAuthenticateButtonPressed:(id)sender {
    LAContext *context = [[LAContext alloc]init];
    NSError *error = nil;
    if([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
        //Authenticate user
        [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:@"User authentication is required" reply:^(BOOL success, NSError *error) {
            if (success) {
                [self displayAlertViewWithTitle:@"Authentication Success" message:@"User authenticated successfully." cancelButtonTitle:@"OK" tag:AUTHENTICATION_SUCCESSFUL_TAG];
                self.canStartRetrievingLocation = YES;
                [self getCurrentLocationCoordinates];
            }
            if (error) {
                switch (error.code) {
                    case kLAErrorAuthenticationFailed:
                        [self displayAlertViewWithTitle:@"Authentication Error" message:@"There was a problem verifying your identity." cancelButtonTitle:@"OK" tag:AUTHENTICATION_ERROR_TAG];
                        break;
                    case kLAErrorUserCancel:
                        NSLog(@"User has cancelled the authentication");
                    case kLAErrorUserFallback:
                        [self showAuthenticationWithPassword];
                    default:
                        break;
                }
                return;
            }
        }];
    }
    else {
        [self displayAlertViewWithTitle:@"Authentication Error" message:@"Your device cannot authenticate using TouchID." cancelButtonTitle:@"OK" tag:DEVICE_NOT_SUPPORTED_TAG];
    }
}

- (void)getCurrentLocationCoordinates {
    if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self startLocationUpdates];
    }
    else if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted) {
        [self displayAlertViewWithTitle:@"Error" message:@"Please give access the application the permission to access your location from your settings." cancelButtonTitle:@"OK" tag:LOCATION_MANAGER_ACCESS_DISABLED_TAG];
    }
    else if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined){
        [self.locationManager requestWhenInUseAuthorization];
    }
}

- (void)startLocationUpdates {
    MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"Retrieving current location..";
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [self.locationManager startUpdatingLocation];
    });
}

- (void)showAuthenticationWithPassword {
    UIAlertView *authenticationWithPassword = [[UIAlertView alloc]
                                  initWithTitle:@"Authentication With Password"
                                  message:@"Please type your password"
                                  delegate:self
                                  cancelButtonTitle:@"Cancel"
                                  otherButtonTitles:@"OK", nil];
    authenticationWithPassword.delegate = self;
    authenticationWithPassword.tag = AUTHENTICATION_WITH_PASSWORD_ALERT_TAG;
    [authenticationWithPassword setAlertViewStyle:UIAlertViewStyleSecureTextInput];
    [authenticationWithPassword show];
}

#pragma mark - Drawing map methods

- (void)drawMapViewRouteFromCoordinate:(CLLocationCoordinate2D)fromCoordinate toCoordinate:(CLLocationCoordinate2D)toCoordinate{
    GMSCameraPosition *cameraPosition = [GMSCameraPosition cameraWithLatitude:fromCoordinate.latitude longitude:fromCoordinate.longitude zoom:MAP_ZOOM_LEVEL];
    self.mapView = [GMSMapView mapWithFrame:CGRectZero camera:cameraPosition];
    self.mapView.myLocationEnabled=YES;
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mapView.alpha = 1;
    
    GMSMarker *marker = [[GMSMarker alloc]init];
    marker.position = CLLocationCoordinate2DMake(toCoordinate.latitude, toCoordinate.longitude);
    marker.groundAnchor = CGPointMake(0.5,0.5);
    marker.map = self.mapView;
    
    GMSMutablePath *path = [GMSMutablePath path];
    [path addCoordinate:CLLocationCoordinate2DMake(fromCoordinate.latitude, fromCoordinate.longitude)];
    [path addCoordinate:CLLocationCoordinate2DMake(toCoordinate.latitude, toCoordinate.longitude)];
    
    GMSPolyline *rectangle = [GMSPolyline polylineWithPath:path];
    rectangle.strokeWidth = 2.f;
    rectangle.map = self.mapView;
    self.view = self.mapView;
}

#pragma mark - CLLocationManager delegates

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if(status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        if(self.canStartRetrievingLocation) {
            [self startLocationUpdates];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    [UIView animateWithDuration:1 animations:^{
        self.authenticateButton.alpha = 0;
    } completion:^(BOOL finished) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            [self.locationManager stopUpdatingLocation];
        });
        
        [self drawMapViewRouteFromCoordinate:manager.location.coordinate toCoordinate:[LocationDataUtilities getLocationCoordinatesFromAddress:DESTINATION_ADDRESS]];
    }];
}

#pragma mark - Displaying AlertView methods

- (void)displayAlertViewWithTitle:(NSString*)title message:(NSString*)message cancelButtonTitle:(NSString*)cancelButtonTitle tag:(NSInteger)tag{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:cancelButtonTitle
                                          otherButtonTitles:nil];
    alert.tag = tag;
    alert.delegate = self;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == AUTHENTICATION_SUCCESSFUL_TAG) {
        if(buttonIndex == 0) {
            self.canStartRetrievingLocation = YES;
            [self getCurrentLocationCoordinates];
        }
    }
    if(alertView.tag == AUTHENTICATION_WITH_PASSWORD_ALERT_TAG) {
        if(buttonIndex == 1) {
            if(![[alertView textFieldAtIndex:0].text isEqualToString:@""]) {
                if([[alertView textFieldAtIndex:0].text isEqualToString:APPLICATION_PASSWORD]){
                    self.canStartRetrievingLocation = YES;
                    [self getCurrentLocationCoordinates];
                }
                else {
                    [self showAuthenticationWithPassword];
                }
            }
            else {
                [self showAuthenticationWithPassword];
            }
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
