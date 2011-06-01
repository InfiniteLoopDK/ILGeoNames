//
//  ILGeoNamesSearchController.h
//
//  Created by Claus Broch on 15/07/10.
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

#import <UIKit/UIKit.h>

#import "ILGeoNamesLookup.h"

@protocol ILGeoNamesSearchControllerDelegate;

/** The ILGeoNamesSearchController class creates a controller object that manages a table view with built-in support for searching for named locations from geonames.org.
 */
@interface ILGeoNamesSearchController : UITableViewController <UISearchBarDelegate, UISearchDisplayDelegate, ILGeoNamesLookupDelegate>
{
@private
	id <ILGeoNamesSearchControllerDelegate> delegate;
	NSMutableArray	*searchResults;
	ILGeoNamesLookup	*geoNamesSearch;
}

/** The delegate object you wish to receive the results. */
@property(nonatomic, assign) id <ILGeoNamesSearchControllerDelegate> delegate;

@end


/** Protocol for the search controller to communicate with its delegate. */
@protocol ILGeoNamesSearchControllerDelegate

@required
/** Called by the search controller to obtain the user ID for use in the search query
 
 The delegate must return a string containing a valid user ID obtained from geonames.org.
 @param controller The search controller.
 @return The user ID.
 */
- (NSString*)geoNamesUserIDForSearchController:(ILGeoNamesSearchController*)controller;

/** Called by the search controller when the user taps a search result or cancels the search.
 
 When this method is called the geolocation selected by the user will be contained in _result_.
 If the user taps the "Cancel" button the _result_ will be `nil`.
 @param controller The search controller.
 @param result The result of the user action.
 */
- (void)geoNamesSearchController:(ILGeoNamesSearchController*)controller didFinishWithResult:(NSDictionary*)result;

@end