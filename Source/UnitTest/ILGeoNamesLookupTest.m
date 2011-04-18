//
//  ILGeoNamesLookupTest.m
//
//  Created by Claus Broch on 28/06/10.
//  Copyright 2010-2011 Infinite Loop. All rights reserved.
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

#import <OCMock/OCMock.h>

#import "ILGeoNamesLookupTest.h"

@interface ILGeoNamesLookup(SuppressWarnings)
@property (nonatomic, retain) NSMutableData *dataBuffer;
- (void)sendRequestWithURLString:(NSString*)urlString;
@end

@implementation ILGeoNamesLookupTest

- (void)setUp
{
	parser = [[ILGeoNamesLookup alloc] initWithUserID:@"unittest"];
	parser.delegate = self;
	searchError = nil;
	searchResult = nil;
	done = NO;
	cannedResult = nil;
	cannedError = nil;
	mockParser = nil;
}

- (void)tearDown
{
	[parser release];
	[searchError release];
	[searchResult release];
	[cannedResult release];
	[cannedError release];
	mockParser = nil;
}

- (void)loadCannedResultWithName:(NSString*)cannedName {
	cannedResult = [[NSData alloc] initWithContentsOfFile:
					[[NSBundle bundleForClass:[self class]] pathForResource:cannedName ofType:@"json"]];
	STAssertNotNil(cannedResult, @"Failed to load canned result '%@'", cannedName);
}

- (void)returnCannedResultForRequest:(NSString*)request {
	// Validate request
	STAssertNotNil(request, @"Invalid request");
	NSURL *url = [NSURL URLWithString:request];
	STAssertNotNil(url, @"Failed to make request '%@' into url", request);
	STAssertEqualObjects([url scheme], @"http", @"Invalid request scheme");
	STAssertEqualObjects([url host], @"api.geonames.org", @"Invalid request host");
	STAssertEqualObjects([url path], @"/findNearbyJSON", @"Invalid request path");
	NSArray *params = [[url query] componentsSeparatedByString:@"&"];
	STAssertTrue([params containsObject:@"username=unittest"], @"Username not set correctly in request");
	
	// Return canned result or error
	if(cannedResult) {
		parser.dataBuffer = [NSMutableData data];
		[parser connection:nil didReceiveData:cannedResult];
		[parser connectionDidFinishLoading:nil];
		parser.dataBuffer = nil;
	}
	else {
		[parser connection:nil didFailWithError:cannedError];
	}
}

- (void)geoNamesLookup:(ILGeoNamesLookup *)handler didFailWithError:(NSError *)error
{
	searchError = [error retain];
	done = YES;
}

- (void)geoNamesLookup:(ILGeoNamesLookup *)handler didFindGeoNames:(NSArray *)geoNames totalFound:(NSUInteger)total;
{
	searchResult = [geoNames retain];
	done = YES;
}

- (BOOL)waitForCompletion:(NSTimeInterval)timeoutSecs
{
	NSDate	*timeoutDate = [NSDate dateWithTimeIntervalSinceNow:timeoutSecs];
	
	do {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDate];
		if([timeoutDate timeIntervalSinceNow] < 0.0)
			break;
	} while (!done);
	
	return done;
}

// Should result in the following request
// "http://api.geonames.org/findNearbyJSON?lat=-10.00000000&lng=-10.00000000&style=FULL&username=unittest"
//
- (void) testMiddleOfNowhere {
	// Mock the ILGeoNamesLookup so no actual network access is performed
	[self loadCannedResultWithName:@"MiddleOfNowhere"];
	mockParser = [OCMockObject partialMockForObject:parser];
	[[[mockParser stub] andCall:@selector(returnCannedResultForRequest:)
                 onObject:self] sendRequestWithURLString:[OCMArg any]];
	
	// Perform code under test
	[parser findNearbyPlaceNameForLatitude:-10.0 longitude:-10.0];
	
	// Validate result
	STAssertTrue([self waitForCompletion:90.0], @"Failed to get any results in time");
	STAssertEquals([searchResult count], (NSUInteger)0, @"Should not find any results in the middle of nowhere: %@", searchResult);
}

// Should result in the following request
// "http://api.geonames.org/findNearbyJSON?lat=-100.00000000&lng=-10.00000000&style=FULL&username=unittest"
//
- (void) testInvalidPosition {
	// Mock the ILGeoNamesLookup so no actual network access is performed
	[self loadCannedResultWithName:@"InvalidPosition"];
	mockParser = [OCMockObject partialMockForObject:parser];
	[[[mockParser stub] andCall:@selector(returnCannedResultForRequest:)
					   onObject:self] sendRequestWithURLString:[OCMArg any]];

	// Perform code under test
	[parser findNearbyPlaceNameForLatitude:-100.0 longitude:-10.0];
	
	// Validate result
	STAssertTrue([self waitForCompletion:90.0], @"Failed to get any results in time");
	STAssertNil(searchResult, @"Should not find any results for invalid position: %@", searchResult);
	STAssertNotNil(searchError, @"Expected an error");
	STAssertEqualObjects([searchError domain], kILGeoNamesErrorDomain, @"Unexpected error domain");
	STAssertEquals([searchError code], kILGeoNamesOtherError, @"Unexpected error code");
}


// Should result in the following request
// "http://api.geonames.org/findNearbyJSON?lat=37.33164146&lng=-122.03018903&style=FULL&username=unittest"
//
-(void) testAppleComputerHeadquarters {
	// Mock the ILGeoNamesLookup so no actual network access is performed
	[self loadCannedResultWithName:@"AppleComputerHeadquaters"];
	mockParser = [OCMockObject partialMockForObject:parser];
	[[[mockParser stub] andCall:@selector(returnCannedResultForRequest:)
					   onObject:self] sendRequestWithURLString:[OCMArg any]];
	
	// Perform code under test
	[parser findNearbyPlaceNameForLatitude:37.3316414613743 longitude:-122.030189037323];
	
	// Validate result
	STAssertTrue([self waitForCompletion:90.0], @"Failed to get any results in time");
	STAssertNotNil(searchResult, @"Didn't expect an error");
	NSDictionary	*firstResult = [searchResult objectAtIndex:0];
	STAssertNotNil(firstResult, @"Expected at least one result");
	STAssertEqualObjects([firstResult objectForKey:@"geonameId"], [NSNumber numberWithInt:6301897], @"Unexpected ID found");
	STAssertEqualObjects([firstResult objectForKey:@"name"], @"Apple Computer Headquarters", @"Unexpected place name found");
	STAssertEqualObjects([firstResult objectForKey:@"adminName1"], @"California", @"Unexpected admin name found");
	STAssertEqualObjects([firstResult objectForKey:@"adminCode1"], @"CA", @"Unexpected admin code found");
	STAssertEqualObjects([firstResult objectForKey:@"countryCode"], @"US", @"Unexpected country code found");
	STAssertEqualObjects([firstResult objectForKey:@"countryName"], @"United States", @"Unexpected country name found");
	STAssertEqualObjects([firstResult objectForKey:@"continentCode"], @"NA", @"Unexpected continent code found");
	NSDictionary *timezone = [firstResult objectForKey:@"timezone"];
	STAssertNotNil(timezone, @"Expected time zone information");
	STAssertEqualObjects([timezone objectForKey:@"gmtOffset"], [NSNumber numberWithInt:-8], @"Unexpected GMT offset found");
	STAssertEqualObjects([timezone objectForKey:@"timeZoneId"], @"America/Los_Angeles", @"Unexpected time zone found");
}


@end
