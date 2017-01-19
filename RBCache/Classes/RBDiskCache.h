//
//  RBDiskCache.h
//  Pods
//
//  Created by baxiang on 2017/1/18.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class RBDiskCache;
typedef void (^RBCacheNoParamsBlock)(void);
typedef void (^RBDiskCacheObjectBlock)(RBDiskCache *cache, NSString *key, _Nullable id<NSCoding> object, NSTimeInterval remainLife);
@interface RBDiskCache : NSObject

@property (copy, nullable) NSString *name;

@property (readonly) NSString *path;

@property (assign, readonly) NSUInteger dbStoreThreshold;

@property (nullable, copy) NSData *(^customArchiveBlock)(id object);
@property (nullable, copy) id (^customUnarchiveBlock)(NSData *data);

@property NSInteger countLimit;

@property NSInteger sizeLimit;


#pragma mark - Initializer

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (nullable instancetype)initWithDirectory:(NSString *)directory;


- (nullable instancetype)initWithDirectory:(NSString *)directory
                          dbStoreThreshold:(NSUInteger)threshold NS_DESIGNATED_INITIALIZER;


#pragma mark - Access Methods


- (nullable id<NSCoding>)objectForKey:(NSString *)key;


- (nullable id<NSCoding>)objectForKey:(NSString *)key remainLife:(nullable NSTimeInterval *)remainLife;


- (BOOL)containsObjectForKey:(NSString *)key;


- (void)setObject:(nullable id<NSCoding>)object forKey:(NSString *)key;


- (void)setObject:(nullable id<NSCoding>)object forKey:(NSString *)key lifetime:(NSTimeInterval)lifetime;


- (void)removeObjectForKey:(NSString *)key;

- (void)removeAllObjects;

- (NSInteger)totalSize;

- (NSInteger)totalCount;


#pragma mark - Trim Methods


- (void)trimToSizeLimit:(NSInteger)size;


- (void)trimToCountLimit:(NSInteger)count;

@end


#pragma mark - Async Access Methods

@interface RBDiskCache (RBDiskAsyncAccess)


- (void)objectForKey:(NSString *)key completion:(RBDiskCacheObjectBlock)completion;


- (void)containsObjectForKey:(NSString *)key completion:(void(^)(NSString *key, BOOL contains))completion;

- (void)setObject:(id<NSCoding>)object
           forKey:(NSString *)key
         lifetime:(NSTimeInterval)lifetime
       completion:(nullable RBDiskCacheObjectBlock)completion;

- (void)removeObjectForKey:(NSString *)key completion:(nullable void (^)(NSString *key))completion;

- (void)removeAllObjectsAsync:(nullable RBCacheNoParamsBlock)completion;

@end


#pragma mark - Extended Data

@interface RBDiskCache (CZExtendedData)

+ (nullable NSData *)extendedDataForObject:(id)anObject;

+ (void)setExtendedData:(nullable NSData *)extendedData forObject:(id)anObject;

@end

NS_ASSUME_NONNULL_END

