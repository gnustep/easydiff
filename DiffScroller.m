#include "DiffScroller.h"
#include <math.h>

@implementation DiffScroller
- (void) drawRect: (NSRect) aRect
{
  int i;
  NSRect knobRect = [self rectForPart: NSScrollerKnob];
  NSRect knobSlotRect = [self rectForPart: NSScrollerKnobSlot];
  NSRect rect1, rect2;
  NSRect rect;

  [super drawRect: aRect];

  [[NSColor lightGrayColor] set];

  rect.size.width = knobSlotRect.size.width;
  rect.origin.x = knobSlotRect.origin.x;

  rect1.size.width = knobSlotRect.size.width;
  rect1.origin.x = knobSlotRect.origin.x;

  rect2.size.width = knobSlotRect.size.width;
  rect2.origin.x = knobSlotRect.origin.x;

  for (i = 1; i < length - 2; i += 2)
    {
      //      NSLog(@"%f/%f", position[i+1], height);
      rect.origin.y = 
	floor((position[i] * knobSlotRect.size.height) / height);

      rect.size.height = 
	floor(( (position[i + 1] - position[i]) * knobSlotRect.size.height )
	      / height);
      if (rect.size.height < 1)
	rect.size.height = 1;
      
      if (NSIntersectsRect(rect, knobRect))
	{
	  if (rect.origin.y < knobRect.origin.y)
	    {
	      rect1.origin.y = rect.origin.y;
	      rect1.size.height = NSMinY(knobRect) - rect1.origin.y;
	      NSRectFill(rect1);
	    }

	  if (NSMaxY(rect) > NSMaxY(knobRect))
	    {
	      rect2.origin.y = NSMaxY(knobRect);
	      rect2.size.height = NSMaxY(rect) - rect2.origin.y;
	      NSRectFill(rect2);
	    }

	}
      else
	{
	  NSRectFill(rect);
	}
  }
  
  return;
  
  NSRectFill (rect1);
  NSRectFill (rect2);
}
@end
