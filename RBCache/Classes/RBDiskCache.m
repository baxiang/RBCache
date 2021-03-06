//
//  RBDiskCache.m
//  Pods
//
//  Created by baxiang on 2017/1/18.
//
//

#import "RBDiskCache.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <CommonCrypto/CommonCrypto.h>
#import "RBCacheDefines.h"
#import "RBKVItem.h"
#import "RBKVStore.h"

static NSString *MD5String (NSString *string) {
    if (!string) return nil;
    const char *cStr = [string UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0],  result[1],  result[2],  result[3],
            result[4],  result[5],  result[6],  result[7],
            result[8],  result[9],  result[10], result[11],
            result[12], result[13], result[14], result[15]];
}


#pragma mark - DiskCachesPool

static NSMapTable<NSString *, RBDiskCache *> *globalDiskCaches;
static dispatch_semaphore_t globalDiskCachesLock;

static void CZDiskCachesPoolInit()
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        globalDiskCachesLock = dispatch_semaphore_create(1);
        globalDiskCaches = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory
                                                     valueOptions:NSPointerFunctionsWeakMemory
                                                         capacity:2];
    });
}

static RBDiskCache *dequeueReusableCacheWithKey(NSString *key)
{
    if (0 == key.length) return nil;
    CZDiskCachesPoolInit();
    dispatch_semaphore_wait(globalDiskCachesLock, DISPATCH_TIME_FOREVER);
    RBDiskCache *cache = [globalDiskCaches objectForKey:key];
    dispatch_semaphore_signal(globalDiskCachesLock);
    return cache;
}

static void setReusableCache(RBDiskCache *cache)
{
    if (0 == cache.path.length) return;
    CZDiskCachesPoolInit();
    dispatch_semaphore_wait(globalDiskCachesLock, DISPATCH_TIME_FOREVER);
    [globalDiskCaches setObject:cache forKey:cache.path];
    dispatch_semaphore_signal(globalDiskCachesLock);
}


#pragma mark - CZDiskCache Implementation

@implementation RBDiskCache {
    RBKVStore *kvStore;
    dispatch_queue_t accessQueue;
    dispatch_semaphore_t lockSignal;
}


#pragma mark - Life Cycle

- (instancetype)initWithDirectory:(NSString *)directory
{
    return [self initWithDirectory:directory dbStoreThreshold:16 * 1024];
}

- (instancetype)initWithDirectory:(NSString *)directory dbStoreThreshold:(NSUInteger)threshold
{
    RBDiskCache *reuseCache = dequeueReusableCacheWithKey(directory);
    if (reuseCache) return reuseCache;
    if (self = [super init]) {
        NSError *error = nil;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:directory
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:&error]) {
            NSLog(@"CZDiskCache directory create error:%@", error);
            return nil;
        }
        
        kvStore = [[RBKVStore alloc] initWithDirectory:directory];
        if (!kvStore) return nil;
        
        _path = directory;
        _sizeLimit = NSIntegerMax;
        _countLimit = NSIntegerMax;
        _dbStoreThreshold = threshold;
        lockSignal = dispatch_semaphore_create(1);
        accessQueue = dispatch_queue_create("com.roobo.disk", DISPATCH_QUEUE_CONCURRENT);
        setReusableCache(self);
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(cz_backgroundCleanDisk:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(cz_appWillTerminate:)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Public
#pragma mark - Access Methods

- (id<NSCoding>)objectForKey:(NSString *)key
{
    return [self objectForKey:key remainLife:NULL];
}

- (id<NSCoding>)objectForKey:(NSString *)key remainLife:(NSTimeInterval *)remainLife
{
    if (!key) return nil;
    [self lock];
    RBKVItem *item = [kvStore getItemForKey:key];
    [self unlock];
    if (!item.value) return nil;
    
    id object = nil;
    if (_customUnarchiveBlock) {
        object = _customUnarchiveBlock(item.value);
    } else {
        object = [NSKeyedUnarchiver unarchiveObjectWithData:item.value];
    }
    if (object && item.extendedData) {
        [RBDiskCache setExtendedData:item.extendedData forObject:object];
    }
    if (remainLife) *remainLife = item.remainLife;
    
    return object;
}

- (BOOL)containsObjectForKey:(NSString *)key
{
    return [self objectForKey:key remainLife:NULL] ? YES : NO;
}

- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key
{
    [self setObject:object forKey:key lifetime:CZ_LIVE_FOREVER];
}

- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key lifetime:(NSTimeInterval)lifetime
{
    if (!key) return;
    if (!object) {
        [self removeObjectForKey:key];
        return;
    }
    
    NSData *extendedData = [RBDiskCache extendedDataForObject:object];
    NSData *valueData = nil;
    if (_customArchiveBlock) {
        valueData = _customArchiveBlock(object);
    } else {
        valueData = [NSKeyedArchiver archivedDataWithRootObject:object];
    }
    if (!valueData) return;
    
    NSString *filename = nil;
    if (valueData.length > _dbStoreThreshold){
        filename = [self filenameForKey:key];
    }
    
    [self lock];
    [kvStore saveItemWithKey:key value:valueData filename:filename lifetime:lifetime extendedData:extendedData];
    [self unlock];
}

- (void)removeObjectForKey:(NSString *)key
{
    if (!key) return;
    [self lock];
    [kvStore removeItemForKey:key];
    [self unlock];
}

- (void)removeAllObjects
{
    [self lock];
    [kvStore removeAllItems];
    [self unlock];
}


#pragma mark Async Access Methods

- (void)objectForKey:(NSString *)key completion:(RBDiskCacheObjectBlock)completion
{
    if (!completion) return;
    __weak typeof (&*self) weakSelf = self;
    dispatch_async(accessQueue, ^{
        __strong typeof (&*weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        NSTimeInterval remainLife = 0.0;
        id<NSCoding> object = [self objectForKey:key remainLife:&remainLife];
        completion(strongSelf, key, object, remainLife);
    });
}

- (void)containsObjectForKey:(NSString *)key completion:(void(^)(NSString *key, BOOL contains))completion
{
    if (!completion) return;
    __weak typeof (&*self) weakSelf = self;
    dispatch_async(accessQueue, ^{
        __strong typeof (&*weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        BOOL result = [self containsObjectForKey:key];
        completion(key, result);
    });
}

- (void)setObject:(id<NSCoding>)object
           forKey:(NSString *)key
         lifetime:(NSTimeInterval)lifetime
       completion:(RBDiskCacheObjectBlock)completion
{
    __weak typeof (&*self) weakSelf = self;
    dispatch_async(accessQueue, ^{
        __strong typeof (&*weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        [self setObject:object forKey:key lifetime:lifetime];
        if (completion) completion(strongSelf, key, object, lifetime);
    });
}

- (void)removeObjectForKey:(NSString *)key completion:(void (^)(NSString *key))completion
{
    __weak typeof (&*self) weakSelf = self;
    dispatch_async(accessQueue, ^{
        __strong typeof (&*weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        [self removeObjectForKey:key];
        if (completion) completion(key);
    });
}

- (void)removeAllObjectsAsync:(void (^)(void))completion
{
    __weak typeof (&*self) weakSelf = self;
    dispatch_async(accessQueue, ^{
        __strong typeof (&*weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        [self removeAllObjects];
        if (completion) completion();
    });
}


#pragma mark CZExtendedData

static void *kExtendedDataKey = "kExtendedDataKey";

+ (NSData *)extendedDataForObject:(id)anObject
{
    if (!anObject) return nil;
    return (NSData *)objc_getAssociatedObject(anObject, kExtendedDataKey);
}

+ (void)setExtendedData:(NSData *)extendedData forObject:(id)anObject
{
    if (!anObject) return;
    objc_setAssociatedObject(anObject, kExtendedDataKey, extendedData, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


#pragma mark Trim

- (void)trimToSizeLimit:(NSInteger)size
{
    [self lock];
    if (size < NSIntegerMax && size >= 0) {
        [kvStore removeItemsWithSizeLimit:size];
    }
    [self unlock];
}

- (void)trimToCountLimit:(NSInteger)count
{
    [self lock];
    if (count < NSIntegerMax && count >= 0) {
        [kvStore removeItemsWithCountLimit:count];
    }
    [self unlock];
}


#pragma mark - Private
#pragma mark - Clean

- (void)cleanExpireKeyValues
{
    [self lock];
    [kvStore removeItemsEarlierThanDate:time(NULL)];
    [self unlock];
}

- (void)cz_cleanDiskWithCompletion:(RBCacheNoParamsBlock)completion
{
    dispatch_async(accessQueue, ^{
        [self lock];
        [kvStore removeItemsEarlierThanDate:time(NULL)];
        
        if (_sizeLimit < NSIntegerMax && _sizeLimit >= 0) {
            [kvStore removeItemsWithSizeLimit:_sizeLimit];
        }
        
        if (_countLimit < NSIntegerMax && _countLimit >= 0) {
            [kvStore removeItemsWithCountLimit:_countLimit];
        }
        [self unlock];
        /*
         [self cleanExpireKeyValues];
         [self trimToSizeLimit:self.sizeLimit];
         [self trimToCountLimit:self.countLimit];
         */
        if (completion) {
            completion();
        }
    });
}


#pragma mark Notification Handler

- (void)cz_appWillTerminate:(NSNotification *)notification
{
    [self cz_cleanDiskWithCompletion:^{
        [self lock];
        kvStore = nil;
        [self unlock];
    }];
}

- (void)cz_backgroundCleanDisk:(NSNotification *)notification
{
    Class UIApplicationClass = NSClassFromString(@"UIApplication");
    if (!UIApplicationClass || ![UIApplicationClass respondsToSelector:@selector(sharedApplication)]) {
        return;
    }
    
    UIApplication *application = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier taskId = [application beginBackgroundTaskWithExpirationHandler:^{
        [application endBackgroundTask:taskId];
        taskId = UIBackgroundTaskInvalid;
    }];
    
    [self cz_cleanDiskWithCompletion:^{
        [application endBackgroundTask:taskId];
        taskId = UIBackgroundTaskInvalid;
    }];
}


#pragma mark Lock & Unlock

- (void)lock
{
    dispatch_semaphore_wait(lockSignal, DISPATCH_TIME_FOREVER);
}

- (void)unlock
{
    dispatch_semaphore_signal(lockSignal);
}


#pragma mark Getter

- (NSInteger)totalCount
{
    [self lock];
    NSInteger count = [kvStore totalItemsCount];
    [self unlock];
    return count;
}

- (NSInteger)totalSize
{
    [self lock];
    NSInteger size = [kvStore totalItemsSize];
    [self unlock];
    return size;
}

- (NSString *)filenameForKey:(NSString *)key
{
    return MD5String(key);
}

- (NSString *)description
{
    if (_name) {
        return [NSString stringWithFormat:@"<%@: %p> [%@, %@]", [self class], self, _name, _path];
    } else {
        return [NSString stringWithFormat:@"<%@: %p> [%@]", [self class], self, _path];
    }
}

@end

