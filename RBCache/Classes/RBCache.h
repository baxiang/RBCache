//
//  RBCache.h
//  Pods
//
//  Created by baxiang on 2017/1/18.
//
//

#import <Foundation/Foundation.h>
#import "RBMemoryCache.h"
#import "RBDiskCache.h"
NS_ASSUME_NONNULL_BEGIN
@interface RBCache : NSObject

@property (copy, readonly) NSString *name;

@property (readonly) NSString *storagePath;

@property (strong, readonly) RBMemoryCache *memoryCache;

@property (strong, readonly) RBDiskCache *diskCache;

#pragma mark - Initializer

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;


+ (nullable instancetype)defaultCache;
+ (nullable instancetype)cacheInCachesDirectoryWithName:(NSString *)name;


+ (nullable instancetype)cacheInDocumentDirectoryWithName:(NSString *)name;

- (nullable instancetype)initWithName:(NSString *)name directory:(nullable NSString *)directory NS_DESIGNATED_INITIALIZER;

- (nullable id<NSCoding>)objectForKey:(NSString *)akey;

- (nullable NSString *)descriptionForKeyValue:(NSString *)aKey;


- (nullable NSData *)extendedDataForKeyValue:(NSString *)aKey;

- (BOOL)containsObjectForKey:(NSString *)aKey;

- (void)setObject:(nullable id<NSCoding>)anObject forKey:(NSString *)aKey;

- (void)setObject:(nullable id<NSCoding>)anObject forKey:(NSString *)aKey description:(nullable NSString *)desc;

- (void)setObject:(nullable id<NSCoding>)anObject forKey:(NSString *)aKey lifeTime:(NSTimeInterval)lifetime;


- (void)setObject:(nullable id<NSCoding>)anObject
           forKey:(NSString *)aKey
         lifeTime:(NSTimeInterval)lifetime
     extendedData:(nullable NSData *)extendedData;


- (void)removeObjectForKey:(NSString *)aKey;


- (void)removeAllObjects;

- (nullable id<NSCoding>)objectForKeyedSubscript:(NSString *)aKey;
- (void)setObject:(nullable id<NSCoding>)anObject forKeyedSubscript:(NSString *)aKey;

@end


#pragma mark - Async Access Methods

@interface RBCache (RBCacheAsyncAccess)

typedef void (^RBCacheObjectBlock)(RBCache *cache, NSString *key, _Nullable id<NSCoding> object);

- (void)objectForKey:(NSString *)aKey completion:(RBCacheObjectBlock)completion;


- (void)containsObjectForKey:(NSString *)aKey completion:(void(^)(NSString *key, BOOL contains))completion;

- (void)setObject:(nullable id<NSCoding>)anObject
           forKey:(NSString *)aKey
         lifeTime:(NSTimeInterval)lifetime
       completion:(nullable RBCacheObjectBlock)completion;

- (void)removeObjectForKey:(NSString *)aKey completion:(nullable void (^)(NSString * key))completion;

- (void)removeAllObjectsAsync:(nullable RBCacheNoParamsBlock)completion;
@end
NS_ASSUME_NONNULL_END
