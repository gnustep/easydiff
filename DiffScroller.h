#ifndef __DIFFSCROLLER_H
#define __DIFFSCROLLER_H

#include <AppKit/AppKit.h>

@interface DiffScroller : NSScroller
{
@public
  float *position;
  int length;
  float height;
  
}
@end

#endif

