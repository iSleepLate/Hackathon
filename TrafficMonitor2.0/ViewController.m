//
//  ViewController.m
//  TrafficMonitor2.0
//
//  Created by David Neubauer on 3/12/15.
//  Copyright (c) 2015 TalkNerdyToMe. All rights reserved.
//

#import "ViewController.h"
@import CoreLocation;
@import MapKit;

@interface ViewController () <MKMapViewDelegate, CLLocationManagerDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSArray *searchResults;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.mapView.showsUserLocation = YES;
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    [self.locationManager startUpdatingLocation];
}

- (void)viewWillAppear:(BOOL)animated
{
    MKCoordinateRegion mapRegion;
    mapRegion.center = self.mapView.userLocation.coordinate;
    mapRegion.span.latitudeDelta = 0.2;
    mapRegion.span.longitudeDelta = 0.2;
    
    [self.mapView setRegion:mapRegion animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    MKCoordinateRegion mapRegion;
    mapRegion.center = self.mapView.userLocation.coordinate;
    mapRegion.span.latitudeDelta = 0.2;
    mapRegion.span.longitudeDelta = 0.2;
    
    [self.mapView setRegion:mapRegion animated:YES];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *query = [textField.text stringByReplacingCharactersInRange:range withString:string];
    [self localSearchWithQuery:query];
    
    return YES;
}

- (void)localSearchWithQuery:(NSString *)query
{
    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
    request.naturalLanguageQuery = query;
    request.region = self.mapView.region;
    
    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];
    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
        if (error) {
            NSLog(@"FUCK! Error: %@", error.localizedDescription);
        } else {
            self.searchResults = response.mapItems;
            [self.tableView reloadData];
        }
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.searchResults ? self.searchResults.count : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:@"cell"];
    }
    
    MKMapItem *mapItem = self.searchResults[indexPath.row];
    cell.textLabel.text = mapItem.name;
    
    return cell;
}

- (void)getDirectionsTo:(MKMapItem *)item
{
    MKDirectionsRequest *request = [[MKDirectionsRequest alloc] init];
    request.source = [MKMapItem mapItemForCurrentLocation];
    request.destination = item;
    request.requestsAlternateRoutes = NO;
    
    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        if (error) {
            NSLog(@"SHIT! Error: %@", error.localizedDescription);
        } else {
            [self showRoute:response.routes];
        }
    }];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
    renderer.strokeColor = [UIColor redColor];
    renderer.lineWidth = 4;
    
    return  renderer;
}

- (void)showRoute:(NSArray *)routes
{
    for (MKRoute *route in routes) {
        [self.mapView addOverlay:route.polyline level:MKOverlayLevelAboveRoads];
        [self.textField resignFirstResponder];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    MKMapItem *item = self.searchResults[indexPath.row];
    [self getDirectionsTo:item];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.tableView.hidden = NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.tableView.hidden = YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}

@end
