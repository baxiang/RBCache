//
//  RBMemoryCache.h
//  Pods
//
//  Created by baxiang on 2017/1/18.
//
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@class RBMemoryCache;
typedef void (^CZMemCacheCallBack)(RBMemoryCache *cache);


@interface RBMemoryCache <KeyType, ObjectType> : NSObject

@property (nullable, copy) NSString *name;

@property (readonly) NSUInteger totalCount;

@property (assign) NSUInteger countLimit;


@property (assign) NSTimeInterval autoTrimInterval;

@property (assign) BOOL enableExpireClean;


@property (assign) BOOL releaseOnMainThread;


@property (assign) BOOL releaseAsynchronously;

@property (assign) BOOL shouldRemoveAllObjectsWhenMemoryWarning;
@property (assign) BOOL shouldRemoveAllObjectsWhenEnteringBackground;
@property (copy, nullable) CZMemCacheCallBack didReceiveMemoryWarningBlock;
@property (copy, nullable) CZMemCacheCallBack didEnterBackgroundBlock;


- (nullable instancetype)initWithName:(nullable NSString *)name NS_DESIGNATED_INITIALIZER;


- (void)setObject:(nullable ObjectType)object forKey:(KeyType)key;


- (void)setObject:(nullable ObjectType)object forKey:(KeyType)key lifeTime:(NSTimeInterval)lifetime;


- (nullable ObjectType)objectForKey:(KeyType)key;


- (BOOL)containsObjectForKey:(KeyType)key;


- (void)removeObjectForKey:(KeyType)key;


- (void)removeAllObjects;


- (void)trimToCountLimit:(NSUInteger)count;

@end

NS_ASSUME_NONNULL_END
