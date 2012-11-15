//
//  UnityAdsAnalyticsUploader.m
//  UnityAdsExample
//
//  Created by Johan Halin on 13.9.2012.
//  Copyright (c) 2012 Unity Technologies. All rights reserved.
//

#import "UnityAdsAnalyticsUploader.h"
#import "../UnityAdsCampaign/UnityAdsCampaign.h"
#import "../UnityAds.h"
#import "../UnityAdsProperties/UnityAdsProperties.h"

NSString * const kUnityAdsTrackingPath = @"gamers/";
NSString * const kUnityAdsInstallTrackingPath = @"games/";
NSString * const kUnityAdsAnalyticsUploaderRequestKey = @"kUnityAdsAnalyticsUploaderRequestKey";
NSString * const kUnityAdsAnalyticsUploaderConnectionKey = @"kUnityAdsAnalyticsUploaderConnectionKey";
NSString * const kUnityAdsAnalyticsSavedUploadsKey = @"kUnityAdsAnalyticsSavedUploadsKey";
NSString * const kUnityAdsAnalyticsSavedUploadURLKey = @"kUnityAdsAnalyticsSavedUploadURLKey";
NSString * const kUnityAdsAnalyticsSavedUploadBodyKey = @"kUnityAdsAnalyticsSavedUploadBodyKey";
NSString * const kUnityAdsAnalyticsSavedUploadHTTPMethodKey = @"kUnityAdsAnalyticsSavedUploadHTTPMethodKey";
NSString * const kUnityAdsQueryDictionaryQueryKey = @"kUnityAdsQueryDictionaryQueryKey";
NSString * const kUnityAdsQueryDictionaryBodyKey = @"kUnityAdsQueryDictionaryBodyKey";

@interface UnityAdsAnalyticsUploader () <NSURLConnectionDelegate>
@property (nonatomic, strong) NSMutableArray *uploadQueue;
@property (nonatomic, strong) NSDictionary *currentUpload;
@property (nonatomic, assign) dispatch_queue_t analyticsQueue;
@property (nonatomic, strong) NSThread *backgroundThread;
@end

@implementation UnityAdsAnalyticsUploader

#pragma mark - Private

- (void)_backgroundRunLoop:(id)dummy {
	@autoreleasepool
	{
		NSPort *port = [[NSPort alloc] init];
		[port scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		
		while([[NSThread currentThread] isCancelled] == NO)
		{
			@autoreleasepool
			{
				[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:3.0]];
			}
		}
	}
}

- (void)_saveFailedUpload:(NSDictionary *)upload {
	if (upload == nil) {
		UALOG_DEBUG(@"Input is nil.");
		return;
	}
	
	NSMutableArray *existingFailedUploads = [[[NSUserDefaults standardUserDefaults] arrayForKey:kUnityAdsAnalyticsSavedUploadsKey] mutableCopy];
	
	if (existingFailedUploads == nil) {
    existingFailedUploads = [NSMutableArray array];
  }
  
	NSURLRequest *request = [upload objectForKey:kUnityAdsAnalyticsUploaderRequestKey];
	NSMutableDictionary *failedUpload = [NSMutableDictionary dictionary];
	
  if ([request URL] != nil) {
		[failedUpload setObject:[[request URL] absoluteString] forKey:kUnityAdsAnalyticsSavedUploadURLKey];
		
		if ([request HTTPBody] != nil) {
			NSString *bodyString = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];
			[failedUpload setObject:bodyString forKey:kUnityAdsAnalyticsSavedUploadBodyKey];
		}
		
		[failedUpload setObject:[request HTTPMethod] forKey:kUnityAdsAnalyticsSavedUploadHTTPMethodKey];
		[existingFailedUploads addObject:failedUpload];
		
		UALOG_DEBUG(@"%@", existingFailedUploads);
		[[NSUserDefaults standardUserDefaults] setObject:existingFailedUploads forKey:kUnityAdsAnalyticsSavedUploadsKey];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}

- (BOOL)_startNextUpload {
	if (self.currentUpload != nil || [self.uploadQueue count] == 0)
		return NO;
	
	self.currentUpload = [self.uploadQueue objectAtIndex:0];
	
	NSURLConnection *connection = [self.currentUpload objectForKey:kUnityAdsAnalyticsUploaderConnectionKey];
	[connection start];
	
	[self.uploadQueue removeObjectAtIndex:0];
	
	return YES;
}

- (void)_queueURL:(NSURL *)url body:(NSData *)body httpMethod:(NSString *)httpMethod {
	if (url == nil) {
		UALOG_DEBUG(@"Invalid input.");
		return;
	}
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];

	if (request == nil) {
		UALOG_ERROR(@"Could not create request with url '%@'.", url);
		return;
	}
	
	[request setHTTPMethod:httpMethod];
	if (body != nil)
		[request setHTTPBody:body];
	
	UALOG_DEBUG(@"queueing %@", [request URL]);
	
	NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
	NSDictionary *uploadDictionary = @{ kUnityAdsAnalyticsUploaderRequestKey : request, kUnityAdsAnalyticsUploaderConnectionKey : connection };
	[self.uploadQueue addObject:uploadDictionary];
	
	if ([self.uploadQueue count] == 1)
		[self _startNextUpload];
}

- (void)_queueWithURLString:(NSString *)urlString queryString:(NSString *)queryString httpMethod:(NSString *)httpMethod {
	NSURL *url = [NSURL URLWithString:urlString];
	NSData *body = nil;
	if (queryString != nil)
		body = [queryString dataUsingEncoding:NSUTF8StringEncoding];

	[self _queueURL:url body:body httpMethod:httpMethod];
}


#pragma mark - Public

static UnityAdsAnalyticsUploader *sharedUnityAdsInstanceAnalyticsUploader = nil;

+ (id)sharedInstance {
	@synchronized(self)
	{
		if (sharedUnityAdsInstanceAnalyticsUploader == nil)
      sharedUnityAdsInstanceAnalyticsUploader = [[UnityAdsAnalyticsUploader alloc] init];
	}
	
	return sharedUnityAdsInstanceAnalyticsUploader;
}

- (id)init {
	if ((self = [super init])) {
		_uploadQueue = [NSMutableArray array];
    self.analyticsQueue = dispatch_queue_create("com.unity3d.ads.analytics", NULL);
    self.backgroundThread = [[NSThread alloc] initWithTarget:self selector:@selector(_backgroundRunLoop:) object:nil];
		[self.backgroundThread start];
	}
	
	return self;
}

- (void)dealloc {
  dispatch_release(self.analyticsQueue);
}

- (void)logVideoAnalyticsWithPosition:(VideoAnalyticsPosition)videoPosition campaign:(UnityAdsCampaign *)campaign {
	if (campaign == nil) {
		UALOG_DEBUG(@"Campaign is nil.");
		return;
	}
	
	dispatch_async(self.analyticsQueue, ^{
		NSString *positionString = nil;
		NSString *trackingString = nil;
    
		if (videoPosition == kVideoAnalyticsPositionStart) {
			positionString = @"video_start";
			trackingString = @"start";
		}
		else if (videoPosition == kVideoAnalyticsPositionFirstQuartile)
			positionString = @"first_quartile";
		else if (videoPosition == kVideoAnalyticsPositionMidPoint)
			positionString = @"mid_point";
		else if (videoPosition == kVideoAnalyticsPositionThirdQuartile)
			positionString = @"third_quartile";
		else if (videoPosition == kVideoAnalyticsPositionEnd) {
			positionString = @"video_end";
			trackingString = @"view";
		}
		
     NSString *query = [NSString stringWithFormat:@"gameId=%@&type=%@&trackingId=%@&providerId=%@", [[UnityAdsProperties sharedInstance] adsGameId], positionString, [[UnityAdsProperties sharedInstance] gamerId], campaign.id];
    
    [self performSelector:@selector(sendViewReportWithQueryString:) onThread:self.backgroundThread withObject:query waitUntilDone:NO];
     
     if (trackingString != nil) {
       NSString *trackingQuery = [NSString stringWithFormat:@"%@/%@/%@?gameId=%@", [[UnityAdsProperties sharedInstance] gamerId], trackingString, campaign.id, [[UnityAdsProperties sharedInstance] adsGameId]];
       [self performSelector:@selector(sendTrackingCallWithQueryString:) onThread:self.backgroundThread withObject:trackingQuery waitUntilDone:NO];
     }
	});
}

- (void)sendViewReportWithQueryString:(NSString *)queryString {
	UAAssert( ! [NSThread isMainThread]);
	
	if (queryString == nil || [queryString length] == 0) {
		UALOG_DEBUG(@"Invalid input.");
		return;
	}
	
	[self _queueWithURLString:[[UnityAdsProperties sharedInstance] analyticsBaseUrl] queryString:queryString httpMethod:@"POST"];
}

- (void)sendTrackingCallWithQueryString:(NSString *)queryString {
	UAAssert( ! [NSThread isMainThread]);
	
	if (queryString == nil || [queryString length] == 0) {
		UALOG_DEBUG(@"Invalid input.");
		return;
	}
  
	[self _queueWithURLString:[NSString stringWithFormat:@"%@%@", [[UnityAdsProperties sharedInstance] adsBaseUrl], kUnityAdsTrackingPath] queryString:nil httpMethod:@"GET"];
}

- (void)sendInstallTrackingCallWithQueryDictionary:(NSDictionary *)queryDictionary {
	UAAssert( ! [NSThread isMainThread]);
	
	if (queryDictionary == nil) {
		UALOG_DEBUG(@"Invalid input.");
		return;
	}
	
	NSString *query = [queryDictionary objectForKey:kUnityAdsQueryDictionaryQueryKey];
	NSString *body = [queryDictionary objectForKey:kUnityAdsQueryDictionaryBodyKey];
	
	if (query == nil || [query length] == 0 || body == nil || [body length] == 0) {
		UALOG_DEBUG(@"Invalid parameters in query dictionary.");
		return;
	}
	
  [self _queueWithURLString:[NSString stringWithFormat:@"%@%@", [[UnityAdsProperties sharedInstance] adsBaseUrl], kUnityAdsInstallTrackingPath] queryString:nil httpMethod:@"GET"];
}

- (void)retryFailedUploads {
	UAAssert( ! [NSThread isMainThread]);
	
	NSArray *uploads = [[NSUserDefaults standardUserDefaults] arrayForKey:kUnityAdsAnalyticsSavedUploadsKey];
	if (uploads != nil) {
		for (NSDictionary *upload in uploads) {
			NSString *url = [upload objectForKey:kUnityAdsAnalyticsSavedUploadURLKey];
			NSString *body = [upload objectForKey:kUnityAdsAnalyticsSavedUploadBodyKey];
			NSString *httpMethod = [upload objectForKey:kUnityAdsAnalyticsSavedUploadHTTPMethodKey];
			[self _queueURL:[NSURL URLWithString:url] body:[body dataUsingEncoding:NSUTF8StringEncoding] httpMethod:httpMethod];
		}
		
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:kUnityAdsAnalyticsSavedUploadsKey];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}


#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	UALOG_DEBUG(@"analytics upload finished");
	
	self.currentUpload = nil;	
	[self _startNextUpload];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	UALOG_DEBUG(@"%@", error);
	
	[self _saveFailedUpload:self.currentUpload];
	self.currentUpload = nil;
	[self _startNextUpload];
}

@end