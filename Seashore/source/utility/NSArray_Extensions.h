#import <Foundation/Foundation.h>

@interface NSArray(MyExtensions)
- (BOOL)containsObjectIdenticalTo:(id)object;
@end

@interface NSMutableArray<ObjectType> (MyExtensions)
- (void)insertObjectsFromArray:(NSArray<ObjectType> *)array atIndex:(NSInteger)index;
@end

