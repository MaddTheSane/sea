#import <Foundation/Foundation.h>

@interface NSArray<ObjectType> (MyExtensions)
- (BOOL)containsObjectIdenticalTo:(ObjectType)object;
@end

@interface NSMutableArray<ObjectType> (MyExtensions)
- (void)insertObjectsFromArray:(NSArray<ObjectType> *)array atIndex:(NSInteger)index;
@end

