//
//  ILGeoNamesSearchController.m
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

#import "ILGeoNamesSearchController.h"


@interface ILGeoNamesSearchController ()

@property (nonatomic, retain) NSMutableArray *searchResults;
@property (nonatomic, retain) ILGeoNamesLookup *geoNamesSearch;

@end

@implementation ILGeoNamesSearchController

@synthesize searchResults;
@synthesize delegate;
@synthesize geoNamesSearch;

#pragma mark -
#pragma mark View lifecycle

- (id)init {
	self = [super initWithNibName:@"ILGeoNamesSearchController" bundle:nil];
	if (self) {
		
	}
	
	return self;
}

- (NSMutableArray *)searchResults
{
	if(!searchResults)
		searchResults = [[NSMutableArray alloc] init];
	
	return searchResults;
}

- (void)viewDidLoad {
    [super viewDidLoad];

	if(!geoNamesSearch) {
		NSString *userID = [self.delegate geoNamesUserIDForSearchController:self];
		geoNamesSearch = [[ILGeoNamesLookup alloc] initWithUserID:userID];
	}
	geoNamesSearch.delegate = self;
	
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	//[self view].isAccessibilityElement = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
	self.searchDisplayController.searchBar.prompt = NSLocalizedStringFromTable(@"ILGEONAMES_SEARCH_PROMPT", @"ILGeoNames", @"");
	[self.searchDisplayController setActive:YES animated:NO];
	[self.searchDisplayController.searchBar becomeFirstResponder];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	
    // when the view slides in, its significant enough that a screen change notification should be posted
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.

    return [self.searchResults count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
	NSDictionary	*geoname = [self.searchResults objectAtIndex:indexPath.row];
	if(geoname) {
		NSString	*name = [geoname objectForKey:kILGeoNamesNameKey];
		cell.textLabel.text = name;
		NSString	*subString = [geoname objectForKey:kILGeoNamesCountryNameKey];
		if(subString && ![subString isEqualToString:@""]) {
			NSString	*admin1 = [geoname objectForKey:kILGeoNamesAdminName1Key];
			if(admin1 && ![admin1 isEqualToString:@""]) {
				subString = [admin1 stringByAppendingFormat:@", %@", subString];
				NSString *admin2 = [geoname objectForKey:kILGeoNamesAdminName2Key];
				if(admin2 && ![admin2 isEqualToString:@""]) {
					subString = [admin2 stringByAppendingFormat:@", %@", subString];
				}
			}
		}
		else {
			subString = [geoname objectForKey:kILGeoNamesFeatureClassNameKey];
		}
		cell.detailTextLabel.text = subString;
		cell.isAccessibilityElement = YES;
		cell.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", name, subString];
	}
	
	return cell;
}



#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[self.geoNamesSearch cancel];
	self.geoNamesSearch.delegate = nil;
	
	[self.delegate geoNamesSearchController:self didFinishWithResult:[self.searchResults objectAtIndex:indexPath.row]];
}

#pragma mark -
#pragma mark Search bar delegate

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[self.geoNamesSearch cancel];
	self.geoNamesSearch.delegate = nil;
	
	[self.delegate geoNamesSearchController:self didFinishWithResult:nil];
}


#pragma mark -
#pragma mark Search display delegate

- (void)delayedSearch:(NSString*)searchString
{
	[self.geoNamesSearch cancel];
	[self.geoNamesSearch search:searchString
						maxRows:20
					   startRow:0
					   language:nil];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
	self.searchDisplayController.searchBar.prompt = NSLocalizedStringFromTable(@"ILGEONAMES_SEARCHING", @"ILGeoNames", @"");
	[self.searchResults removeAllObjects];
	
	// Delay the search 1 second to minimize outstanding requests
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[self performSelector:@selector(delayedSearch:) withObject:searchString afterDelay:1.0];
	
	return YES;
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
	self.geoNamesSearch.delegate = nil;
	self.geoNamesSearch = nil;
	self.searchResults = nil;
}


- (void)dealloc {
	[searchResults release];
	geoNamesSearch.delegate = nil;
	[geoNamesSearch release];
    [super dealloc];
}

#pragma mark -
#pragma mark ILGeoNamesLookupDelegate

- (void)geoNamesLookup:(ILGeoNamesLookup *)handler networkIsActive:(BOOL)isActive
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = isActive;
}

- (void)geoNamesLookup:(ILGeoNamesLookup *)handler didFindGeoNames:(NSArray *)geoNames totalFound:(NSUInteger)total
{
	//NSLog(@"didFindPlaceName: %@", [placeName description]);
	
	// Grab the results
	if ([geoNames count]) {
		self.searchDisplayController.searchBar.prompt = NSLocalizedStringFromTable(@"ILGEONAMES_SEARCH_PROMPT", @"ILGeoNames", @"");
		[self.searchResults setArray:geoNames];
	}
	else {
		self.searchDisplayController.searchBar.prompt = NSLocalizedStringFromTable(@"ILGEONAMES_NO_RESULTS", @"ILGeoNames", @"");
		[self.searchResults removeAllObjects];
	}

	[self.searchDisplayController.searchResultsTableView reloadData];
	
    // when the table view is repopulated, its significant enough that a screen change notification should be posted
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

- (void)geoNamesLookup:(ILGeoNamesLookup *)handler didFailWithError:(NSError *)error
{
	// TODO error handling
    NSLog(@"ILGeoNamesLookup has failed: %@", [error localizedDescription]);
	self.searchDisplayController.searchBar.prompt = NSLocalizedStringFromTable(@"ILGEONAMES_SEARCH_ERR", @"ILGeoNames", @"");
}

@end

