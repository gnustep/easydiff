#import <AppKit/AppKit.h>

@interface DiffScroller : NSScroller
{
@public
  float *position;
  int length;
  float height;
  
}
@end
