//
//  STPAPIClient+Private.h
//  Stripe
//
//  Created by Jack Flintermann on 10/14/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIClient.h"
#import "STPAPIRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class STPEphemeralKey;

@interface STPAPIClient()

// TODO: [joeydong] Can we hide any of these from the private header?

+ (NSString *)apiVersion;

- (instancetype)initWithPublishableKey:(NSString *)publishableKey
                               baseURL:(NSString *)baseURL;

- (void)createTokenWithParameters:(NSDictionary *)parameters
                       completion:(STPTokenCompletionBlock)completion;

- (NSURLSessionDataTask *)retrieveSourceWithId:(NSString *)identifier clientSecret:(NSString *)secret responseCompletion:(STPAPIResponseBlock)completion;

@property (nonatomic, readwrite) NSURL *apiURL;
@property (nonatomic, readwrite) NSURLSession *urlSession;

@end

@interface STPAPIClient (Customers)

/**
 * Retrieve a customer
 *
 * @see https://stripe.com/docs/api#retrieve_customer
 */
+ (void)retrieveCustomerUsingKey:(STPEphemeralKey *)ephemeralKey
                      completion:(STPCustomerCompletionBlock)completion;

/**
 * Add a source to a customer
 *
 * @see https://stripe.com/docs/api#create_card
 */
+ (void)addSource:(NSString *)sourceID
toCustomerUsingKey:(STPEphemeralKey *)ephemeralKey
       completion:(STPSourceProtocolCompletionBlock)completion;

/**
 * Update a customer with parameters
 *
 * @see https://stripe.com/docs/api#update_customer
 */
+ (void)updateCustomerWithParameters:(NSDictionary *)parameters
                            usingKey:(STPEphemeralKey *)ephemeralKey
                          completion:(STPCustomerCompletionBlock)completion;

/**
 * Detach a source from a customer
 *
 * @see https://stripe.com/docs/api#delete_card
 */
+ (void)detachSource:(NSString *)sourceID
fromCustomerUsingKey:(STPEphemeralKey *)ephemeralKey
          completion:(STPSourceProtocolCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
