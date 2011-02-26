//
//  SampleAppDelegate.m
//  SampleApp
//
//  Created by Claus Broch on 21/02/11.
//  Copyright 2011 Infinite Loop. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are permitted
//  provided that the following conditions are met:
//
//  - Redistributions of source code must retain the above copyright notice, this list of conditions 
//    and the following disclaimer.
//  - Redistributions in binary form must reproduce the above copyright notice, this list of 
//    conditions and the following disclaimer in the documentation and/or other materials provided 
//    with the distribution.
//  - Neither the name of Infinite Loop nor the names of its contributors may be used to endorse or 
//    promote products derived from this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR 
//  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR 
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
//  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY 
//  WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//  

#import "SampleAppDelegate.h"

// IMPORTANT - change the following line to use your own geonames.org account
static NSString *kGeoNamesAccountName = @"ilgeonamessample";

@implementation SampleAppDelegate

@synthesize window;
@synthesize controller;
@synthesize currentButton;
@synthesize searchButton;
@synthesize position;
@synthesize locationName;
@synthesize locationType;
@synthesize country;
@synthesize locationManager;
@synthesize geocoder;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    // Override point for customization after application launch.
    
    [self.window makeKeyAndVisible];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
}

- (IBAction)currentPosition:(id)sender {
	self.locationManager = [[[CLLocationManager alloc] init] autorelease];
	locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
	
	// Set a timeout so we don't keep searching forever
	[locationManager startUpdatingLocation];
    [locationManager performSelector:@selector(stopUpdatingLocation) withObject:nil afterDelay:30.0];
}

- (IBAction)searchLocation:(id)sender {
	ILGeoNamesSearchController *searchController = [[ILGeoNamesSearchController alloc] init];
	searchController.delegate = self;
	
	searchController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
	[self.controller presentModalViewController:searchController animated:YES];
	
	[searchController release];
}

#pragma mark -
#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    // test the age of the location measurement to determine if the measurement is cached
    // in most cases you will not want to rely on cached measurements
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge > 60.0) 
		return;
    // test that the horizontal accuracy does not indicate an invalid measurement
    if (newLocation.horizontalAccuracy < 0)
		return;
	
	// we have a measurement that meets our requirements, so we can stop updating the location
	// 
	// IMPORTANT!!! Minimize power usage by stopping the location manager as soon as possible.
	//
	[NSObject cancelPreviousPerformRequestsWithTarget:locationManager selector:@selector(stopUpdatingLocation) object:nil];
	[locationManager stopUpdatingLocation];
	
	position.text = [NSString stringWithFormat:@"%.5f%c  %.5f%c",
					 fabs(newLocation.coordinate.latitude), newLocation.coordinate.latitude >= 0.0 ? 'N' : 'S',
					 fabs(newLocation.coordinate.longitude), newLocation.coordinate.longitude >= 0.0 ? 'E' : 'W'];
	
	// Request location information from geonames.org
	self.geocoder = [[[ILGeoNamesLookup alloc] initWithUserID:kGeoNamesAccountName] autorelease];
	geocoder.delegate = self;
	[geocoder findNearbyPlaceNameForLatitude:newLocation.coordinate.latitude longitude:newLocation.coordinate.longitude];
	
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    // The location "unknown" error simply means the manager is currently unable to get the location.
    // We can ignore this error for the scenario of getting a single location fix, because we already have a 
    // timeout that will stop the location manager to save power.
    if ([error code] != kCLErrorLocationUnknown) {
	[locationManager stopUpdatingLocation];
	
	 // For now just display an alert
	 position.text = @"Unknown location";
	 UIAlertView *anAlert = [[UIAlertView alloc] initWithTitle:@"Error getting location" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	 [anAlert show];
	 [anAlert release];
	}
}

#pragma mark -
#pragma mark ILGeoNamesLookupDelegate

- (void)geoNamesLookup:(ILGeoNamesLookup *)handler networkIsActive:(BOOL)isActive
{
	// Spin the activity indicator while receiving data
	[UIApplication sharedApplication].networkActivityIndicatorVisible = isActive;
}

- (void)geoNamesLookup:(ILGeoNamesLookup *)handler didFindGeoNames:(NSArray *)geoNames totalFound:(NSUInteger)total
{
	BOOL		gotGeocode = NO;
	NSString	*name;
	
	NSLog(@"didFindGeoNames: %@", [geoNames description]);
	
	// Grab the name of the first place
	if (geoNames && [geoNames count] >= 1) {
		NSDictionary *placeName = [geoNames objectAtIndex:0];
		name = [placeName objectForKey:kILGeoNamesNameKey];
		if(name) {
			self.locationName.text = name;
			self.locationType.text = [placeName objectForKey:kILGeoNamesFeatureNameKey];
			self.country.text = [placeName objectForKey:kILGeoNamesCountryNameKey];
			gotGeocode = YES;
		}
	}
	
	if(!gotGeocode) {
		self.locationName.text = @"Unknown location";
		self.locationType.text = @"";
		self.country.text = @"";
	}
}

- (void)geoNamesLookup:(ILGeoNamesLookup *)handler didFailWithError:(NSError *)error
{
	// TODO error handling
    NSLog(@"ILGeoNamesLookup has failed: %@", [error localizedDescription]);
	self.locationName.text = @"Unknown location";
}


#pragma mark -
#pragma mark ILGeoNamesSearchControllerDelegate methods

- (NSString*)geoNamesUserIDForSearchController:(ILGeoNamesSearchController*)controller {
	return kGeoNamesAccountName;
}

- (void)geoNamesSearchController:(ILGeoNamesSearchController*)controller didFinishWithResult:(NSDictionary*)result
{
	NSLog(@"didFinishWithResult: %@", result);
	[self.controller dismissModalViewControllerAnimated:YES];
	
	if(result) {
		double latitude = [[result objectForKey:kILGeoNamesLatitudeKey] doubleValue];
		double longitude = [[result objectForKey:kILGeoNamesLongitudeKey] doubleValue];
		position.text = [NSString stringWithFormat:@"%.5f%c  %.5f%c",
						 fabs(latitude), latitude >= 0.0 ? 'N' : 'S',
						 fabs(longitude), longitude >= 0.0 ? 'E' : 'W'];
		self.locationName.text = [result objectForKey:kILGeoNamesAlternateNameKey];
		self.locationType.text = [result objectForKey:kILGeoNamesFeatureNameKey];
		self.country.text = [result objectForKey:kILGeoNamesCountryNameKey];
	}
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc {
    [window release];
	[controller release];
	[currentButton release];
	[searchButton release];
	[position release];
	[locationName release];
	[locationType release];
	[country release];
	[locationManager release];
	[geocoder release];
	
    [super dealloc];
}


@end
