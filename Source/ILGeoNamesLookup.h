//
//  ILGeoNamesLookup.h
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
//
//  Use of the data is subject to the terms detailed on http://www.geonames.org/export/#terms
//

#import <Foundation/Foundation.h>

/** @name GeoNames error codes */

/**
 * Error codes returned by the geonames service according to http://www.geonames.org/export/webservice-exception.html 
 */
typedef enum GeoNamesError {
    /** Authorization Exception */
	kILGeoNamesAuthorizationExceptionError = 10,
    /** record does not exist */
	kILGeoNamesRecordDoesNotExistError = 11,
	kILGeoNamesOtherError = 12,
	kILGeoNamesDatabaseTimeoutError = 13,
	kILGeoNamesInvalidParameterError = 14,
	kILGeoNamesNoResultsFoundError = 15,
	kILGeoNamesDuplicateExceptionError = 16,
	kILGeoNamesPostalCodeNotFoundError = 17,
	kILGeoNamesDailyCreditLimitExceededError = 18,
	kILGeoNamesHourlyCreditLimitExceededError = 19,
	kILGeoNamesWeeklyCreditLimitExceededError = 20,
	kILGeoNamesInvalidInputError = 21,
	kILGeoNamesServerOverloadError = 22,
	kILGeoNamesServiceNotImplementedError = 23
} GeoNamesError;

extern NSString *const kILGeoNamesErrorDomain;

@protocol ILGeoNamesLookupDelegate;

/** Wrapper class for accessing the geonames.org services */
@interface ILGeoNamesLookup : NSObject {
	@private
    NSURLConnection		*dataConnection;
    BOOL				done;
    NSMutableData		*dataBuffer;
	NSString			*userID;
    id <ILGeoNamesLookupDelegate> delegate;
	
}

/** The delegate object you wish to receive the results. */
@property (nonatomic, assign) id <ILGeoNamesLookupDelegate> delegate;

/** The user ID used in the calls to the geonames.org services. */
@property (nonatomic, copy) NSString *userID;

/** Initialize a new instance with the user ID obtained from geonames.org 
 
 The user ID provided in _userID_ will be used for all subsequent calls to the geonames.org services.
 @param userID A user ID obtained from geonames.org.
 */
- (id)initWithUserID:(NSString*)userID;

/** Query the geonames.org service for the name of the place near the given position (WGS84) 
 
 @param latitude The latitude for the position.
 @param longitude The longitude for the position.
 */
- (void)findNearbyPlaceNameForLatitude:(double)latitude longitude:(double)longitude;

/** Query the geonames.org service for the nearby toponyms for the given position (WGS84) 
 
 @param latitude The latitude for the position.
 @param longitude The longitude for the position.
 @param maxRows The maximum number of results to return.
 @param radius The maximum search radius in km.
 */
- (void)findNearbyToponymsForLatitude:(double)latitude longitude:(double)longitude maxRows:(NSInteger)maxRows radius:(double)radius;

/** Query the geonames.org service for the nearby Wikipedia articles for the given position (WGS84) 
 
 @param latitude The latitude for the position.
 @param longitude The longitude for the position.
 @param maxRows The maximum number of results to return.
 @param radius The maximum search radius in km.
 @param languageCode language code, e.g. 'en'.
 */
- (void)findNearbyWikipediaForLatitude:(double)latitude longitude:(double)longitude maxRows:(NSInteger)maxRows radius:(double)radius languageCode:(NSString *)languageCode;

/** Query the geonames.org service for a number of geolocations matching the query 
 
 Performs a search over all attributes of a place : place name, country name, continent, admin codes, etc.
 It is possible to narrow a search by providing multiple terms separated by ',' in the _query_ parameter, e.g.:
    "Berlin" will return all locations containing Berlin in any of the attributes.
    "Berlin, hospital, wisconsin" will only return hospitals containing the name Berlin within the state of Wisconsin.
 The number of returned results can be limited using the _maxRows_ parameter. By specifying an index in the _startRow_ parameter, it is possible to iterate over larger results in small steps.
 
 @param query The search query.
 @param maxRows The maximum number of results to return.
 @param startRow The index of the first result to return.
 @param langCode A 2-letter ISO-636 language code. Specifying `nil` will return the english names (default).
 */
- (void)search:(NSString*)query maxRows:(NSInteger)maxRows startRow:(NSUInteger)startRow language:(NSString*)langCode;

/** Cancel any outstanding request */
- (void)cancel;

@end

/** Protocol for the ILGeoNamesLookup handler to communicate with its delegate. */
@protocol ILGeoNamesLookupDelegate <NSObject>

@optional

/** Called by the ILGeoNamesLookup handler when starting and stopping network activity.
 
 @param handler The handler reporting the event.
 @param isActive A boolean flag indicating whether network activity is about to start or stop.
 */
- (void)geoNamesLookup:(ILGeoNamesLookup *)handler networkIsActive:(BOOL)isActive;

/** Called by the ILGeoNamesLookup handler in case of an error in one of the underlying services.
 
 @param handler The handler reporting the event.
 @param error The error object containing the reason why the request failed.
 */
- (void)geoNamesLookup:(ILGeoNamesLookup *)handler didFailWithError:(NSError *)error;

/** Called by the ILGeoNamesLookup handler when the previous request have finished sucessfully.
 
 @param handler The handler reporting the event.
 @param geoNames An array containg the requested result.
 @param total The total number of results available for the request.
 */
- (void)geoNamesLookup:(ILGeoNamesLookup *)handler didFindGeoNames:(NSArray *)geoNames totalFound:(NSUInteger)total;

@end

/// Keys used to parse the response from GeoNames services
extern NSString *const kILGeoNamesResultsKey;
extern NSString *const kILGeoNamesTotalResultsCountKey;

extern NSString *const kILGeoNamesAdminCode1Key;
extern NSString *const kILGeoNamesAdminCode2Key;
extern NSString *const kILGeoNamesAdminCode3Key;
extern NSString *const kILGeoNamesAdminName1Key;
extern NSString *const kILGeoNamesAdminName2Key;
extern NSString *const kILGeoNamesAdminName3Key;
extern NSString *const kILGeoNamesAdminName4Key;
extern NSString *const kILGeoNamesNameKey;
extern NSString *const kILGeoNamesToponymNameKey;
extern NSString *const kILGeoNamesContinentCodeKey;
extern NSString *const kILGeoNamesCountryCodeKey;
extern NSString *const kILGeoNamesCountryNameKey;
extern NSString *const kILGeoNamesPopulationKey;
extern NSString *const kILGeoNamesTitleKey;			// Wikipedia requests only
extern NSString *const kILGeoNamesSummaryKey;		// Wikipedia requests only
extern NSString *const kILGeoNamesWikipediaURLKey;	// Wikipedia requests only

extern NSString *const kILGeoNamesAlternateNamesKey;
extern NSString *const kILGeoNamesAlternateNameKey;
extern NSString *const kILGeoNamesAlternateLanguageKey;

extern NSString *const kILGeoNamesIDKey;
extern NSString *const kILGeoNamesFeatureKey;	// Wikipedia requests only
extern NSString *const kILGeoNamesFeatureClassKey;
extern NSString *const kILGeoNamesFeatureCodeKey;
extern NSString *const kILGeoNamesFeatureClassNameKey;
extern NSString *const kILGeoNamesFeatureNameKey;
extern NSString *const kILGeoNamesScoreKey;

extern NSString *const kILGeoNamesLatitudeKey;
extern NSString *const kILGeoNamesLongitudeKey;
extern NSString *const kILGeoNamesDistanceKey;
extern NSString *const kILGeoNamesElevationKey;
extern NSString *const kILGeoNamesLanguageKey;	// Wikipedia requests only
extern NSString *const kILGeoNamesRankKey;		// Wikipedia requests only

extern NSString *const kILGeoNamesTimeZoneInfoKey;
extern NSString *const kILGeoNamesTimeZoneDSTOffsetKey;
extern NSString *const kILGeoNamesTimeZoneGMTOffsetKey;
extern NSString *const kILGeoNamesTimeZoneIDKey;

extern NSString *const kILGeoNamesErrorResponseKey;
extern NSString *const kILGeoNamesErrorMessageKey;
extern NSString *const kILGeoNamesErrorCodeKey;

/// Keys used to parse the response from GeoNames services when requesting nearby Wikipedia articles
// kILGeoNamesCountryCodeKey
// kILGeoNamesDistanceKey
// kILGeoNamesElevationKey
// kILGeoNamesFeatureKey
// kILGeoNamesLanguageKey
// kILGeoNamesLatitudeKey
// kILGeoNamesLongitudeKey
// kILGeoNamesRankKey
// kILGeoNamesSummaryKey
// kILGeoNamesTitleKey
// kILGeoNamesWikipediaURLKey
