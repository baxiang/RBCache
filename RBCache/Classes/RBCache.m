//
//  RBCache.m
//  Pods
//
//  Created by baxiang on 2017/1/18.
//
//

#import "RBCache.h"
static NSString *const kStandardCacheName = @"StandardCache";
static NSString *const kDocumentStorageFolderName = @"DocumentStorage";
static NSString *const kCachesStorageFolderName = @"CachesStorage";
@implementation RBCache

+(RBCache*)defaultCache{
    static RBCache *_dafaultCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dafaultCache = [[RBCache alloc]
                         initWithName:kStandardCacheName
                         directory:[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:kCachesStorageFolderName]];
        _dafaultCache.memoryCache.countLimit = 40;
    });
    return _dafaultCache;
}
+ (instancetype)cacheInCachesDirectoryWithName:(NSString *)name
{
    return [[RBCache alloc] initWithName:name directory:NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0]];
}

+ (instancetype)cacheInDocumentDirectoryWithName:(NSString *)name
{
   return [[RBCache alloc] initWithName:name directory:NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0]];
}

- (instancetype)initWithName:(NSString *)name directory:(NSString *)directory
{
    if (!name || 0 == name.length) return nil;
    NSString *fileDirectory = directory.length > 0 ? directory :
    [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:kCachesStorageFolderName];
    if (self = [super init]) {
        _name = name;
        _storagePath = [fileDirectory stringByAppendingPathComponent:name];
        _diskCache = [[RBDiskCache alloc] initWithDirectory:_storagePath];
        if (!_diskCache) return nil;
        _memoryCache = [[RBMemoryCache alloc] initWithName:name];
    }
    return self;
}

- (id<NSCoding>)objectForKey:(NSString *)aKey
{
    id<NSCoding> object = [_memoryCache objectForKey:aKey];
    if (!object) {
        NSTimeInterval remainLife = 0;
        object = [_diskCache objectForKey:aKey remainLife:&remainLife];
        if (object) [_memoryCache setObject:object forKey:aKey lifeTime:remainLife];
    }
    return object;
}

- (NSString *)descriptionForKeyValue:(NSString *)aKey
{
    NSData *data = [RBDiskCache extendedDataForObject:[self objectForKey:aKey]];
    if (data) {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    } else {
        return nil;
    }
}

- (NSData *)extendedDataForKeyValue:(NSString *)aKey
{
    return [RBDiskCache extendedDataForObject:[self objectForKey:aKey]];
}

- (BOOL)containsObjectForKey:(NSString *)aKey
{
    return [_memoryCache containsObjectForKey:aKey] || [_diskCache containsObjectForKey:aKey];
}

- (void)setObject:(id<NSCoding>)anObject forKey:(NSString *)aKey
{
    [_memoryCache setObject:anObject forKey:aKey];
    [_diskCache setObject:anObject forKey:aKey];
}

- (void)setObject:(id<NSCoding>)anObject forKey:(NSString *)aKey description:(NSString *)desc
{
    if (desc && desc.length > 0) {
        [RBDiskCache setExtendedData:[desc dataUsingEncoding:NSUTF8StringEncoding] forObject:anObject];
    }
    [_memoryCache setObject:anObject forKey:aKey];
    [_diskCache setObject:anObject forKey:aKey];
}

- (void)setObject:(id<NSCoding>)anObject forKey:(NSString *)aKey lifeTime:(NSTimeInterval)lifetime
{
    [_memoryCache setObject:anObject forKey:aKey lifeTime:lifetime];
    [_diskCache setObject:anObject forKey:aKey lifetime:lifetime];
}

- (void)setObject:(id<NSCoding>)anObject
           forKey:(NSString *)aKey
         lifeTime:(NSTimeInterval)lifetime
     extendedData:(NSData *)extendedData
{
    if (extendedData) [RBDiskCache setExtendedData:extendedData forObject:anObject];
    [_memoryCache setObject:anObject forKey:aKey lifeTime:lifetime];
    [_diskCache setObject:anObject forKey:aKey lifetime:lifetime];
}

- (void)removeObjectForKey:(NSString *)aKey
{
    [_memoryCache removeObjectForKey:aKey];
    [_diskCache removeObjectForKey:aKey];
}

- (void)removeAllObjects
{
    [_memoryCache removeAllObjects];
    [_diskCache removeAllObjects];
}


#pragma mark - Keyed Subscript Index

- (id<NSCoding>)objectForKeyedSubscript:(NSString *)aKey
{
    return [self objectForKey:aKey];
}

- (void)setObject:(id<NSCoding>)anObject forKeyedSubscript:(NSString *)aKey
{
    [self setObject:anObject forKey:aKey];
}


#pragma mark - Async Access Methods

- (void)setObject:(id<NSCoding>)anObject
           forKey:(NSString *)aKey
         lifeTime:(NSTimeInterval)lifetime
       completion:(RBCacheObjectBlock)completion
{
    [_memoryCache setObject:anObject forKey:aKey lifeTime:lifetime];
    __weak typeof (&*self) weakSelf = self;
    [_diskCache
     setObject:anObject forKey:aKey lifetime:lifetime
     completion:^(RBDiskCache * _Nonnull cache, NSString * _Nonnull key, id<NSCoding>  _Nullable object, NSTimeInterval remainLife) {
         __strong typeof (&*weakSelf) strongSelf = weakSelf;
         if (!strongSelf) return;
         if (completion) completion(strongSelf, aKey, anObject);
     }];
}

- (void)objectForKey:(NSString *)aKey completion:(RBCacheObjectBlock)completion
{
    if (!completion) return;
    id<NSCoding> object = [_memoryCache objectForKey:aKey];
    if (object) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            completion(self, aKey, object);
        });
    } else {
        __weak typeof (&*self) weakSelf = self;
        [_diskCache
         objectForKey:aKey
         completion:^(RBDiskCache * _Nonnull cache, NSString * _Nonnull key, id<NSCoding>  _Nullable object, NSTimeInterval remainLife) {
             __strong typeof (&*weakSelf) strongSelf = weakSelf;
             if (!strongSelf) return;
             if (object) [_memoryCache setObject:object forKey:aKey lifeTime:remainLife];
             completion(strongSelf, aKey, object);
         }];
    }
}

- (void)containsObjectForKey:(NSString *)aKey completion:(void(^)(NSString *key, BOOL contains))completion
{
    if (!completion) return;
    
    if ([_memoryCache containsObjectForKey:aKey]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            completion(aKey, YES);
        });
    } else {
        [_diskCache containsObjectForKey:aKey completion:completion];
    }
}

- (void)removeObjectForKey:(NSString *)aKey completion:(void (^)(NSString *))completion
{
    [_memoryCache removeObjectForKey:aKey];
    [_diskCache removeObjectForKey:aKey completion:completion];
}

- (void)removeAllObjectsAsync:(void (^)(void))completion
{
    [_memoryCache removeAllObjects];
    [_diskCache removeAllObjectsAsync:completion];
}


#pragma mark - Description

- (NSString *)description
{
    if (_name) {
        return [NSString stringWithFormat:@"<%@: %p> [%@, %@]", [self class], self, _name, _storagePath];
    } else {
        return [NSString stringWithFormat:@"<%@: %p> [%@]", [self class], self, _storagePath];
    }
}



@end
