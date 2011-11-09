//
//  SampleAppDelegate.h
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

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

#import "ILGeoNamesLookup.h"
#import "ILGeoNamesSearchController.h"

@interface SampleAppDelegate : NSObject 
<UIApplicationDelegate, CLLocationManagerDelegate, ILGeoNamesLookupDelegate, ILGeoNamesSearchControllerDelegate> {
    UIWindow *window;
    CLLocationManager	*locationManager;
	ILGeoNamesLookup	*geocoder;
	ILGeoNamesLookup	*wikipediaGeocoder;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UIViewController *controller;
@property (nonatomic, retain) IBOutlet UIButton *currentButton;
@property (nonatomic, retain) IBOutlet UIButton *searchButton;
@property (nonatomic, retain) IBOutlet UILabel *position;
@property (nonatomic, retain) IBOutlet UILabel *locationName;
@property (nonatomic, retain) IBOutlet UILabel *locationType;
@property (nonatomic, retain) IBOutlet UILabel *country;
@property (nonatomic, retain) IBOutlet UITextView *wikipediaArticles;
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, retain) ILGeoNamesLookup *geocoder;
@property (nonatomic, retain) ILGeoNamesLookup *wikipediaGeocoder;

- (IBAction)currentPosition:(id)sender;
- (IBAction)searchLocation:(id)sender;

- (void)didFindNearbyPlaceName:(NSArray *)geoNames totalFound:(NSUInteger)total;
- (void)didFindNearbyWikipediaArticles:(NSArray *)geoNames totalFound:(NSUInteger)total;

@end

