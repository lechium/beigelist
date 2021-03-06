//
//  BLAppManager.m
//  beigelist / Espresso
//
//  Created by Brandon Holland on 12-03-08.
//  beigelist and espresso merged / updated and modified by Kevin Bradley
//  Copyright 2012 What a Nutbar Software. All rights reserved.
//

#import "BLAppManager.h"
#include <objc/runtime.h>
//#import "BLAppLegacyMerchant.h"


@implementation BLAppManager

#pragma mark -
#pragma mark Creation + Destruction
#pragma mark

- (id) init
{
    if((self = [super init]))
    {
		
        _appliances = [[NSMutableArray alloc] init];
		_applianceIdentifiers = [[NSMutableArray alloc] init];
        _appliancesLoaded = NO;
    }
    return self;
}

- (void) dealloc
{
	[_appliances release];
	[_applianceIdentifiers release];
    [super dealloc];
}

#pragma mark -
#pragma mark Class Methods
#pragma mark

+ (id) sharedAppManager
{
    static BLAppManager *appManager = nil;
    if(!appManager)
    { appManager = [[BLAppManager alloc] init]; }
    return appManager;
}

#pragma mark -
#pragma mark Private Methods
#pragma mark

/*
 
 need to check and see if the afformentioned applicance is in the ATVMainMenuController, check by identifier
 if that controller contains the identifier, filter the item out from merchants
 
 
 */

- (id)applianceIdentifierList
{
	NSMutableArray *identifierList = [[NSMutableArray alloc] init];
	
	if (_appliancesLoaded)
	{
		if (_appliances != nil)
		{
			for (id theAppliance in _appliances)
			{
				NSString *identifier = [theAppliance identifier];
				if (identifier != nil)[identifierList addObject:identifierList];
			}
		}
	} else {
		
		[self _loadAppliances];
		
		if (_appliances != nil)
		{
			for (id theAppliance in _appliances)
			{
				NSString *identifier = [theAppliance identifier];
				if (identifier != nil)[identifierList addObject:identifierList];
			}
		}
	}
	
	return [identifierList autorelease];
}

- (NSArray *) applianceIdentifiers
{
	return _applianceIdentifiers;
}

- (id)applianceWithIdentifier:(NSString *)theId
{
	for (id appliance in _appliances)
	{
		if ([[appliance identifier] isEqualToString:theId])
		{
			NSLog(@"got a match: %@", appliance);
			return appliance;
		}
	}
	return nil;
}

- (void) _loadAppliances
{    
	
	NSString *appleTVPath = [[NSBundle mainBundle] bundlePath];
	NSString *frappPath = [appleTVPath stringByAppendingPathComponent: @"Appliances"];
	NSDirectoryEnumerator *iterator = [[NSFileManager defaultManager] enumeratorAtPath: frappPath];
    NSString *filePath = nil;
	while((filePath = [iterator nextObject]))
    {
        if([[filePath pathExtension] isEqualToString: @"frappliance"]) 
		{
			NSString *fullPath = [frappPath stringByAppendingPathComponent: filePath];
			NSBundle *frappBundle = [NSBundle bundleWithPath: fullPath];
			NSLog(@"BLAppManager -> attempting to load legacy %@...", [filePath lastPathComponent]);
            
            if([frappBundle load])
            {
                Class frappClass = [frappBundle principalClass];
                NSDictionary *frappBundleInfoDict = [frappBundle infoDictionary];
                NSDictionary *candidate = nil;
				Class cls = objc_getClass("BLAppLegacyMerchant");
				Class mi = objc_getClass("BLAppMerchantInfo");
				
				id frappMerchant = [cls merchant];
                [frappMerchant setLegacyApplianceClass:frappClass];
       
				
                NSString *title = [[frappBundle localizedInfoDictionary] objectForKey: (NSString *)kCFBundleNameKey];
                { [frappMerchant setTitle: title]; }
                
                NSString *identifier = [frappBundleInfoDict objectForKey: (NSString *)kCFBundleIdentifierKey];
                if(identifier)
                { 
					[frappMerchant setIdentifier: identifier]; 
					[_applianceIdentifiers addObject:identifier];
					candidate = [NSDictionary dictionaryWithObject:fullPath forKey:identifier];
				}
                
                NSString *imagePath = [frappBundle pathForResource: @"AppIcon" ofType: @"png"];
                if(imagePath)
                {
                    NSURL *imageURL = [NSURL fileURLWithPath: imagePath];
                    [frappMerchant setIconURL: imageURL];
                }
                //add another key, if it doesnt exist, revert to preferred order... DURR
				
                NSNumber *preferredOrder = [frappBundleInfoDict objectForKey:kBLPreferedOrder];
				BOOL forceLegacyNav = [[frappBundleInfoDict objectForKey:kBLForceLegacyNav] boolValue];
				if (!preferredOrder)
				{
					preferredOrder = [frappBundleInfoDict objectForKey: @"FRAppliancePreferedOrderValue"];
                }
				[frappMerchant setForceLegacyNav:forceLegacyNav];
				
				if(preferredOrder)
                { [frappMerchant setPreferredOrder: [preferredOrder floatValue]]; }
				
				[frappMerchant setShowInTopRow:[[frappBundleInfoDict objectForKey:kBLShowInTopRow] boolValue]];
                
	
				if (frappMerchant != nil)
				{
					[_appliances addObject: frappMerchant];
					NSLog(@"BLAppManager -> loaded legacy %@", NSStringFromClass(frappClass));
				}
					
				

                
            }
            else
            { NSLog(@"BLAppManager -> failed to load legacy %@", [filePath lastPathComponent]); }
		}
    }
	
    _appliancesLoaded = YES;
}

- (id)builtInPluginForApplianceIdentifier:(NSString *)applianceID
{
    id singleton = [objc_getClass("BRApplianceManager") singleton];
    NSArray *applianceInfoList = [singleton applianceInfoList];
    for (id applianceInfo in applianceInfoList)
    {
        NSString *appID = [applianceInfo key];
        if ([appID isEqualToString:applianceID])
        {
           return [singleton _applianceForInfo:applianceInfo];
        }
    }
    return nil;
}

#pragma mark -
#pragma mark Public Methods
#pragma mark

- (NSArray *) appliances
{ return _appliances; }

- (BOOL) appliancesLoaded
{ return _appliancesLoaded; }

- (void) clearAppliances
{
    [_appliances removeAllObjects];
    _appliancesLoaded = NO;
}

- (void) reloadAppliances
{
    [self clearAppliances];
    [self _loadAppliances];
}

- (void) loadAppliances
{
    if(!_appliancesLoaded)
    { [self _loadAppliances]; }
}

@end
