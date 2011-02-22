//
//  ILGeoNamesLookup.m
//
//  Created by Claus Broch on 20/06/10.
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

#import "ILGeoNamesLookup.h"
#import "CJSONDeserializer.h"

static NSString *kILGeoNamesFindNearbyURL = @"http://api.geonames.org/findNearbyJSON?lat=%.8f&lng=%.8f&style=FULL&username=%@";
static NSString *kILGeoNamesSearchURL = @"http://api.geonames.org/searchJSON?q=%@&maxRows=%d&startRow=%d&lang=%@&isNameRequired=true&style=FULL&username=%@";

NSString *const kILGeoNamesErrorDomain = @"org.geonames";

@interface ILGeoNamesLookup ()

- (void)downloadStarted;
- (void)parseEnded:(NSDictionary*)result;
- (void)parseError:(NSError*)error;

@property BOOL done;
@property (nonatomic, retain) NSURLConnection *dataConnection;
@property (nonatomic, retain) NSMutableData *dataBuffer;

@end


@implementation ILGeoNamesLookup

@synthesize done;
@synthesize dataConnection;
@synthesize dataBuffer;
@synthesize delegate;

#pragma mark -
#pragma mark Data request handling

- (id)initWithUserID:(NSString*)aUserID {
	self = [super init];
	if(self) {
		userID = [aUserID copyWithZone:nil];
	}
	return self;
}

- (void)dealloc {
	[userID release];
	
	[super dealloc];
}

- (void)sendRequestWithURLString:(NSString*)urlString
{
    NSAutoreleasePool *downloadPool = [[NSAutoreleasePool alloc] init];
	
	NSURLRequest	*request;
	
	// TODO - handle multiple outstanding requests
	
	@synchronized(self) {
		done = NO;
		self.dataBuffer = [NSMutableData data];
		// Create the request
		request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]
								   cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
							   timeoutInterval:60.0];
		// Create the connection with the request and start loading the data
		dataConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	}
	
	// Just sit spinning in the run loop until all is done
	if(self.dataConnection)
	{
		[self performSelectorOnMainThread:@selector(downloadStarted) withObject:nil waitUntilDone:NO];
        while (!done) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:5.0]];
        }
	}
	
    // Release resources used only in this thread.
	@synchronized(self) {
		self.dataBuffer = nil;
		self.dataConnection = nil;
	}
	
	[downloadPool release];
}

- (void)findNearbyPlaceNameForLatitude:(double)latitude longitude:(double)longitude
{
	NSString	*urlString;
	
	// Request formatted according to http://www.geonames.org/export/web-services.html#findNearby
	urlString = [NSString stringWithFormat:kILGeoNamesFindNearbyURL, latitude, longitude, userID];
	
	// Detach a thread to fetch the placename
	[NSThread detachNewThreadSelector:@selector(sendRequestWithURLString:) toTarget:self withObject:urlString];
}

- (void)search:(NSString*)query maxRows:(NSInteger)maxRows startRow:(NSUInteger)startRow language:(NSString*)langCode
{
	NSString	*urlString;
	
	// Sanitize parameters
	if(!langCode) {
		NSBundle *bundle = [NSBundle bundleForClass:[self class]];
		NSArray	*localizations = [bundle preferredLocalizations];
		if([localizations count])
			langCode = [localizations objectAtIndex:0];
		else
			langCode = @"en";
	}
	if(maxRows > 1000)
		maxRows = 1000;

	// Request formatted according to http://www.geonames.org/export/geonames-search.html
	NSString *escQuery = [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	urlString = [NSString stringWithFormat:kILGeoNamesSearchURL, escQuery, maxRows, startRow, langCode, userID];
	
	// Detach a thread to fetch the placename
	[NSThread detachNewThreadSelector:@selector(sendRequestWithURLString:) toTarget:self withObject:urlString];
}

- (void)cancel
{
	@synchronized(self) {
		[self.dataConnection cancel];
		done = YES;
	}
}

#pragma mark -
#pragma mark Internal callback handling

- (void)downloadStarted
{
    NSAssert2([NSThread isMainThread], @"%s at line %d called on secondary thread", __FUNCTION__, __LINE__);
	
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(geoNamesLookup:networkIsActive:)]) 
        [self.delegate geoNamesLookup:self networkIsActive:YES];
}

- (void)parseEnded:(NSDictionary*)result
{
    NSAssert2([NSThread isMainThread], @"%s at line %d called on secondary thread", __FUNCTION__, __LINE__);
	
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(geoNamesLookup:networkIsActive:)]) {
        [self.delegate geoNamesLookup:self networkIsActive:NO];
	}
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(geoNamesLookup:didFindGeoNames:totalFound:)]) {
		
		NSArray *geoNames = [result objectForKey:@"geonames"];
		NSUInteger total = [geoNames count];
		if([result objectForKey:@"totalResultsCount"])
			total = [[result objectForKey:@"totalResultsCount"] intValue];
		
        [self.delegate geoNamesLookup:self didFindGeoNames:geoNames totalFound:total];
	}
}

- (void)parseError:(NSError*)error
{
    NSAssert2([NSThread isMainThread], @"%s at line %d called on secondary thread", __FUNCTION__, __LINE__);
	
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(geoNamesLookup:networkIsActive:)]) 
        [self.delegate geoNamesLookup:self networkIsActive:NO];
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(geoNamesLookup:didFailWithError:)]) 
        [self.delegate geoNamesLookup:self didFailWithError:error];
}

#pragma mark -
#pragma mark NSURLConnectionDelegate handling

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse 
{
    return nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // Store the downloaded chunk of data.
	@synchronized(self) {
		[self.dataBuffer appendData:data];
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	done = YES;
	
    [self performSelectorOnMainThread:@selector(parseError:) withObject:error waitUntilDone:NO];
    NSLog(@"Connection failed! Error - %@ %@", [error localizedDescription], [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSDictionary	*resultDict;
	NSError			*error = nil;
	
    // Parse the data
	@synchronized(self) {
		resultDict = [[CJSONDeserializer deserializer] deserializeAsDictionary:dataBuffer error:&error];
	}
	if(resultDict) {
		NSArray *geoNames = [resultDict objectForKey:@"geonames"];
		
		if (geoNames) {
			[self performSelectorOnMainThread:@selector(parseEnded:) withObject:resultDict waitUntilDone:NO];
		} 
		else {
			NSDictionary *status = [resultDict objectForKey:@"status"];
			if (status) {
				NSString	*message = [status objectForKey:@"message"];
				NSString	*value = [status objectForKey:@"value"];
				NSError		*error = [NSError errorWithDomain:kILGeoNamesErrorDomain 
													  code:[value intValue]
												  userInfo:[NSDictionary dictionaryWithObject:message 
																					   forKey:NSLocalizedDescriptionKey]];
				[self performSelectorOnMainThread:@selector(parseError:) withObject:error waitUntilDone:NO];
			}
			else {
				NSString	*message = NSLocalizedStringFromTable(@"ILGEONAMES_UNKNOWN_LOOKUP_ERR", @"ILGeoNames", @"");
				NSError		*error = [NSError errorWithDomain:kILGeoNamesErrorDomain 
													  code:15
												  userInfo:[NSDictionary dictionaryWithObject:message
																					   forKey:NSLocalizedDescriptionKey]];
				[self performSelectorOnMainThread:@selector(parseError:) withObject:error waitUntilDone:NO];
			}
		}
		
	}
	else
	{
		[self performSelectorOnMainThread:@selector(parseError:) withObject:error waitUntilDone:NO];
	}
	
		
    // Set the condition which ends the run loop.
	@synchronized (self) {
		done = YES; 
	}
}

@end
