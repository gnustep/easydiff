/*
 * DiffMiddleView.m
 *
 * Copyright (c) 2002 Pierre-Yves Rivaille <pyrivail@ens-lyon.fr>
 *
 * This file is part of EasyDiff.app.
 *
 * EasyDiff.app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * EasyDiff.app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with EasyDiff.app; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 */

#include "DiffMiddleView.h"

@implementation DiffMiddleView
- (void) dealloc
{
  TEST_RELEASE(leftChanges);
  TEST_RELEASE(rightChanges);
  [super dealloc];
}

- (NSArray *)matrixArray
{
  return matrixArray;
}


- (DiffTextView *)leftView { return leftView; }
- (void) setLeftView: (DiffTextView *)aView
{ 
  leftView = aView;
}

- (DiffTextView *)rightView { return rightView; }
- (void) setRightView: (DiffTextView *)aView 
{ 
  rightView = aView;
} 

- (void) setLeftChanges: (NSArray *) leftArray
	andRightChanges: (NSArray *) rightArray
{
  if (leftChanges)
    RELEASE(leftChanges);
  leftChanges = RETAIN(leftArray);

  if (rightChanges)
    RELEASE(rightChanges);
  rightChanges = RETAIN(rightArray);

  if ([rightChanges count] != [leftChanges count])
    NSLog(@"[rightChanges count] != [leftChanges count]");

  matrixArray = [[NSMutableArray alloc]
		  initWithCapacity: [rightChanges count] / 2];

  {
    NSMatrix *matrix;
    int i;


    for ( i = 0; i < [rightChanges count] / 2; i++ )
      {
	matrix = [[NSMatrix alloc] initWithFrame: 
				     NSMakeRect(0, 0, 36, 12)];
	[matrix setCellClass: [NSButtonCell class]];
	[matrix addColumn];
	[matrix addColumn];
	[matrix addColumn];
	[[matrix cellAtRow: 0
		 column: 0] setButtonType: NSOnOffButton];
	[[matrix cellAtRow: 0
		 column: 0] setStringValue: @"<"];
	[[matrix cellAtRow: 0
		 column: 1] setButtonType: NSOnOffButton];
	[[matrix cellAtRow: 0
		 column: 1] setStringValue: @"x"];
	[[matrix cellAtRow: 0
		 column: 2] setButtonType: NSOnOffButton];
	[[matrix cellAtRow: 0
		 column: 2] setStringValue: @">"];
	//	[matrix deselectAllCells];
	[matrix selectCellAtRow: 0
		column: 1];

	[matrix setTag: i];
	[matrix setAction: @selector(matrixButtonClicked:)];

	[matrix setCellSize: NSMakeSize(12, 12)];
	[matrix setIntercellSpacing: NSMakeSize(0, 0)];
	[matrix setMode: NSRadioModeMatrix];


	[matrixArray addObject: matrix];
	[self addSubview: matrix];
	RELEASE(matrix);
      }
    
  }
}
/*
- (void) setLeftChanges: (NSArray *) anArray
{
  if (leftChanges)
    RELEASE(leftChanges);
  leftChanges = RETAIN(anArray);
}

- (void) setRightChanges: (NSArray *) anArray
{
  if (rightChanges)
    RELEASE(rightChanges);
  rightChanges = RETAIN(anArray);
}
*/
- (void) tile
{
  int lstart, lend;
  int lfirstChange, llastChange;
  int rstart, rend;
  int rfirstChange, rlastChange;
  int count = [matrixArray count];
  NSRect lrect, rrect;
  float y1, y2, y3, y4;
  int i;
  int firstChange, lastChange;
  NSRect widgetRect;

  {
    NSRange range;
    range = [leftView lineRangesForRect: 
			 [leftView visibleRect]];
    lstart = range.location;
    lend = NSMaxRange(range);
  }

  {
    int i, j;
    int   count = [leftChanges count];
    for (i = 0; i < count; i += 2)
      {
	if ([[leftChanges objectAtIndex: i+1] intValue] >= lstart)
	  break;
      }
    
    for (j = i; j < count; j += 2)
      {
	if ([[leftChanges objectAtIndex: j] intValue] > lend)
	  break;
      }  
    lfirstChange = i/2;
    llastChange = j/2;
  }
  
  {
    NSRange range;
    range = [rightView lineRangesForRect: 
			 [rightView visibleRect]];
    rstart = range.location;
    rend = NSMaxRange(range);
  }

  {
    int i, j;
    int   count = [rightChanges count];
    for (i = 0; i < count; i += 2)
      {
	if ([[rightChanges objectAtIndex: i+1] intValue] >= rstart)
	  break;
      }
    
    for (j = i; j < count; j += 2)
      {
	if ([[rightChanges objectAtIndex: j] intValue] > rend)
	  break;
      }  
    rfirstChange = i/2;
    rlastChange = j/2;
  }
  
  firstChange = (rfirstChange < lfirstChange) ? rfirstChange : lfirstChange;
  lastChange = (rlastChange > llastChange) ? rlastChange : llastChange;

  //  NSLog(@"%d %d %d", rfirstChange, lfirstChange, firstChange);



  for ( i = 0 ; i < firstChange; i++ )
    {
      [[matrixArray objectAtIndex: i] setFrameOrigin: NSMakePoint(-100, -100)];
    }

  for ( i = firstChange; (i < lastChange) && (i < count); i++ )
    {
      lrect = [self convertRect: leftView->blockRectsArray[i]
		    fromView: leftView];
      rrect = [self convertRect: rightView->blockRectsArray[i]
		    fromView: rightView];
      y1 = NSMinY(lrect);
      y2 = NSMaxY(lrect);
      y3 = NSMaxY(rrect);
      y4 = NSMinY(rrect);

      widgetRect.origin.x = 22;
      widgetRect.size.width = 36;
      
      widgetRect.size.height = 12;
      
      widgetRect.origin.y = (y1 + y2 + y3 + y4) / 4. - 6.;

      //      NSLog(@"%d", i);
    
      [[matrixArray objectAtIndex: i] setFrame: widgetRect];
    }

  for ( i = lastChange; i < count; i++ )
    {
      [[matrixArray objectAtIndex: i] setFrameOrigin: NSMakePoint(-100, -100)];
    }


  //  [self setNeedsDisplay: YES];
}

- (void) drawRect: (NSRect) aRect
{

  int lstart, lend;
  int lfirstChange, llastChange;
  int rstart, rend;
  int rfirstChange, rlastChange;

  {
    NSRange range;
    range = [leftView lineRangesForRect: 
			 [leftView visibleRect]];
    lstart = range.location;
    lend = NSMaxRange(range);
  }

  {
    int i, j;
    int count = [leftChanges count];
    for (i = 0; i < count; i += 2)
      {
	if ([[leftChanges objectAtIndex: i+1] intValue] >= lstart)
	  break;
      }
    
    for (j = i; j < count; j += 2)
      {
	if ([[leftChanges objectAtIndex: j] intValue] > lend)
	  break;
      }  
    lfirstChange = i/2;
    llastChange = j/2;
  }
  
  {
    NSRange range;
    range = [rightView lineRangesForRect: 
			 [rightView visibleRect]];
    rstart = range.location;
    rend = NSMaxRange(range);
  }

  {
    int i, j;
    int   count = [rightChanges count];
    for (i = 0; i < count; i += 2)
      {
	if ([[rightChanges objectAtIndex: i+1] intValue] >= rstart)
	  break;
      }
    
    for (j = i; j < count; j += 2)
      {
	if ([[rightChanges objectAtIndex: j] intValue] > rend)
	  break;
      }
    rfirstChange = i/2;
    rlastChange = j/2;
  }
  
  {
    int i;
    int firstChange, lastChange;
    NSRect lrect, rrect;
    float x1, y1, x2, y2, x3, y3, x4, y4;
    NSBezierPath *bp;

    [[NSColor lightGrayColor] set];
    NSRectFill([self bounds]);
    
    firstChange = (rfirstChange < lfirstChange) ? rfirstChange : lfirstChange;
    lastChange = (rlastChange > llastChange) ? rlastChange : llastChange;
    
    [[NSColor whiteColor] set];
    //    NSLog(@"%i %i", firstChange, lastChange);
    for ( i = firstChange; i < lastChange; i++ )
      {
	lrect = [self convertRect: leftView->blockRectsArray[i]
		      fromView: leftView];
	rrect = [self convertRect: rightView->blockRectsArray[i]
		      fromView: rightView];
	y1 = NSMinY(lrect);
	y2 = NSMaxY(lrect);
	y3 = NSMaxY(rrect);
	y4 = NSMinY(rrect);
	x1 = 0;
	x2 = 0;
	x4 = x3 = NSMaxX([self bounds]);
	
	//	NSLog(@"%f %f %f %f", y1, y2, y3, y4);
	//	NSLog(@"%f %f %f %f", x1, x2, x3, x4);


	bp = [NSBezierPath bezierPath];
	
	if (y1 > 30000)
	  y1 = 30000;
	else if (y1 < -30000)
	  y1 = -30000;
	if (y2 > 30000)
	  y2 = 30000;
	else if (y2 < -30000)
	  y2 = -30000;
	if (y3 > 30000)
	  y3 = 30000;
	else if (y3 < -30000)
	  y3 = -30000;
	if (y4 > 30000)
	  y4 = 30000;
	else if (y4 < -30000)
	  y4 = -30000;

	[bp moveToPoint: NSMakePoint(x2, y2)];
	[bp curveToPoint: NSMakePoint(x3, y3)
	    controlPoint1: NSMakePoint(x2+20, y2)
	    controlPoint2: NSMakePoint(x3-20, y3)];
	[bp lineToPoint: NSMakePoint(x4, y4)];
	[bp curveToPoint: NSMakePoint(x1, y1)
	    controlPoint1: NSMakePoint(x4-20, y4)
	    controlPoint2: NSMakePoint(x1+20, y1)];
	[bp closePath];
	//[bp stroke];

	[bp fill];

	bp = [NSBezierPath bezierPath];
	[bp moveToPoint: NSMakePoint(x2, (y1+y2)/2)];
	[bp curveToPoint: NSMakePoint(x4, (y3+y4)/2)
	    controlPoint1: NSMakePoint(x2+20, (y1+y2)/2)
	    controlPoint2: NSMakePoint(x4-20, (y3+y4)/2) ];
	[bp stroke];

	/*
	{
	  NSRect widgetRect;

	  widgetRect.origin.x = 22;
	  widgetRect.size.width = 36;

	  widgetRect.size.height = 12;

	  widgetRect.origin.y = (y1 + y2 + y3 + y4) / 4. - 6.;

	  [[NSColor darkGrayColor] set];
	  
	  NSRectFill(widgetRect);
	  //	  NSLog(@"%@", NSStringFromRect(widgetRect));
	  
	  [[NSColor whiteColor] set];
	  
	}
	*/
      }
  }

  [super drawRect: [self bounds]];
}
@end

