/*
 * DiffView.m
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

#import <AppKit/AppKit.h>
#import "DiffView.h"
#include <math.h>


@interface DiffScrollView : NSScrollView
{
}
@end

@implementation DiffScrollView
- (void) scrollWheel: (NSEvent *)theEvent
{
  if ([self nextResponder])
    return [[self nextResponder] scrollWheel: theEvent];
  else
    return [self noResponderFor: @selector(scrollWheel:)];
}
@end

@implementation DiffView

- (id) initWithFrame: (NSRect) aRect
{
  [super initWithFrame: aRect];


  middleView = [[DiffMiddleView alloc]
		 initWithFrame:NSZeroRect];

  {
    leftView = [[DiffScrollView alloc] 
		    initWithFrame: NSMakeRect(0, 0, 1000, 100)];
    [leftView setHasHorizontalScroller: YES];
    [leftView setHasVerticalScroller: NO];
  }
  {
    rightView = [[DiffScrollView alloc] 
		    initWithFrame: NSMakeRect(0, 0, 1000, 100)];
    [rightView setHasHorizontalScroller: YES];
    [rightView setHasVerticalScroller: NO];
  }
 
  {
    leftTextView = [[DiffTextView alloc]
		 initWithFrame: NSMakeRect(0, 0, 1000, 100)];
    
    [leftTextView setVerticallyResizable: YES];
    [leftTextView setHorizontallyResizable: NO];
    [[leftTextView textContainer] setContainerSize: NSMakeSize(5000, 1e7)];
    
    [[leftTextView textContainer] setHeightTracksTextView: NO];
    [[leftTextView textContainer] setWidthTracksTextView: NO];
    [leftTextView setString: @" "];
    [leftTextView setFont: [NSFont userFixedPitchFontOfSize: 12]];
  }


  {
    rightTextView = [[DiffTextView alloc]
		      initWithFrame: NSMakeRect(0, 0, 1000, 100)];
    
    [rightTextView setVerticallyResizable: YES];
    [rightTextView setHorizontallyResizable: NO];
    [[rightTextView textContainer] setContainerSize: NSMakeSize(5000, 1e7)];
    
    [[rightTextView textContainer] setHeightTracksTextView: NO];
    [[rightTextView textContainer] setWidthTracksTextView: NO];
    [rightTextView setString: @" "];
    [rightTextView setFont: [NSFont userFixedPitchFontOfSize: 12]];
  }

  {
    [leftView setDocumentView: leftTextView];
    RELEASE(leftTextView);
    [[leftView contentView] setPostsBoundsChangedNotifications: YES];
    [[leftView contentView] setPostsFrameChangedNotifications: YES];
  }
  {
    [rightView setDocumentView: rightTextView];
    RELEASE(rightTextView);
    [[rightView contentView] setPostsBoundsChangedNotifications: YES];
    [[rightView contentView] setPostsFrameChangedNotifications: YES];
  }


  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(leftViewBoundsDidChange:)
    name: NSViewBoundsDidChangeNotification
    object: [leftView contentView]];

  [[NSNotificationCenter defaultCenter]
    addObserver: leftTextView
    selector: @selector(superviewFrameChanged:)
    name: NSViewFrameDidChangeNotification
    object: [leftView contentView]];

  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(rightViewBoundsDidChange:)
    name: NSViewBoundsDidChangeNotification
    object: [rightView contentView]];

  [[NSNotificationCenter defaultCenter]
    addObserver: rightTextView
    selector: @selector(superviewFrameChanged:)
    name: NSViewFrameDidChangeNotification
    object: [rightView contentView]];


  [middleView setLeftView: leftTextView];
  [middleView setRightView: rightTextView];
  [self addSubview: middleView];
  [self addSubview: rightView];
  [self addSubview: leftView];
  RELEASE(middleView);
  RELEASE(rightView);
  RELEASE(leftView);

  return self;
}

- (void) setLeftString: (NSString *) aString
{
  [leftTextView setString: aString];

  //  [leftTextView computeAllLineRanges];
  [[leftView contentView] scrollToPoint: NSMakePoint(0,0)];
}

- (void) setRightString: (NSString *) aString
{
  [rightTextView setString: aString];
  
  //  [rightTextView computeAllLineRanges];
  
  [[rightView contentView] scrollToPoint: NSMakePoint(0,0)];
}


- (void) setLeftChanges: (NSArray *) leftArray
	andRightChanges: (NSArray *) rightArray
{
  [middleView setLeftChanges: leftArray
	      andRightChanges: rightArray];

  [leftTextView setChanges: leftArray];
  [rightTextView setChanges: rightArray];
}


- (void) setLeftLineRanges: (NSArray *) leftLineRanges
	andRightLineRanges: (NSArray *) rightLineRanges
{
  [leftTextView setLineRanges: leftLineRanges];
  [rightTextView setLineRanges: rightLineRanges];
  [leftTextView computeLineRangesFromUpTo: 1000];
  [rightTextView computeLineRangesFromUpTo: 1000];
}

- (void) resizeSubviewsWithOldSize: (NSSize) oldFrameSize
{
  [self tile];
}


- (void) tile
{
  NSSize size = [self bounds].size;
  float width;

  width = (size.width - 80) / 2;

  width = ceilf(width);
  
  [leftView setFrame: 
	      NSMakeRect(0, 0,
			 width, size.height)];
  [rightView setFrame:
	       NSMakeRect(size.width - width, 0,
			  width, size.height)];
  [middleView setFrame:
		NSMakeRect(width, 21,
			   size.width - 2 * width, 
			   size.height - 23)];
  [middleView tile];

}

- (void) rightViewBoundsDidChange: (NSNotification *) aNotification
{
  //  [middleView display];
}

- (void) leftViewBoundsDidChange: (NSNotification *) aNotification
{
  //  [middleView display];
}

#define NWF(x) [NSNumber numberWithFloat: (X)]
#ifndef MIN
#define MIN(a,b) ((a) > (b) ? (b) : (a))
#endif
#ifndef MAX
#define MAX(a,b) ((a) > (b) ? (a) : (b))
#endif

- (void) computeScrollerSize
{
  int i;
  int count = [leftTextView->changes count];
  int length = count + 2;
  float visibleHeight;


  if ([leftView documentVisibleRect].size.height >
      [rightView documentVisibleRect].size.height)
    {
      visibleHeight = [rightView documentVisibleRect].size.height;
    }
  else
    {
      visibleHeight = [leftView documentVisibleRect].size.height;
    }    

    
  lSP = (float *) NSZoneMalloc([self zone],
			       sizeof(float) * length);
  rSP = (float *) NSZoneMalloc([self zone],
			       sizeof(float) * length);
  mSP = (float *) NSZoneMalloc([self zone],
			       sizeof(float) * length);


  
  
  scroller->position = (float *) NSZoneMalloc([self zone],
					      sizeof(float) * length);
  scroller->position[0] = 0;
  /*
  */
  //  scroller->position = mSP;
  scroller->length = length;
  

  NSDebugLog(@"visibleHeight %f", visibleHeight);
  
  for ( i = 0; i < length; i++ )
    {
      lSP[i] = MAX(MIN(leftTextView->separationPosition[i],
		       leftTextView->separationPosition[length - 1] -
		       visibleHeight / 2.),
		   visibleHeight / 2.);
      rSP[i] = MAX(MIN(rightTextView->separationPosition[i],
		       rightTextView->separationPosition[length - 1] -
		       visibleHeight / 2.),
		   visibleHeight / 2.);

      
      NSDebugLog(@"%f %f", leftTextView->separationPosition[i],
	    rightTextView->separationPosition[i]);
    }



  mSP[0] = visibleHeight / 2.;
  i = 0;
  NSDebugLog(@"i: %d  l: %f  r: %f  m: %f\n", i, lSP[i], rSP[i], mSP[i]); 

  for ( i = 1; i < length; i++ )
    {
      mSP[i] = mSP[i-1] +
	MAX(lSP[i] - lSP[i-1],
	    rSP[i] - rSP[i-1]);

      NSDebugLog(@"i: %d  l: %f  r: %f  m: %f\n", i, lSP[i], rSP[i], mSP[i]); 
    }


  {
    BOOL start = NO;
    for ( i = 1; i < length; i++ )
      {
	if (mSP[i] > visibleHeight / 2.)
	  {
	    start = YES;
	    scroller->position[i-1] = mSP[i-1];
	  }

	if (start)
	  scroller->position[i] =
	    scroller->position[i-1]+
	    MAX(leftTextView->separationPosition[i] -
		leftTextView->separationPosition[i-1],
		rightTextView->separationPosition[i] -
		rightTextView->separationPosition[i-1]);

	
      }
  }

  mergeFileHeight = mSP[length - 1] + visibleHeight / 2.;


  scroller->height = mergeFileHeight;// + visibleHeight / 2.;
   
}

- (float) mergeFileHeight
{
  return mergeFileHeight;
}

- (void) doScroll: (id)sender
{
  float visibleHeight;
  float newValue = [scroller floatValue];

  float position;
  float leftPosition;
  float rightPosition;
  float ratio;
  
  int count = [leftTextView->changes count];
  int length = count + 2;
  int i;

  if ([leftView documentVisibleRect].size.height >
      [rightView documentVisibleRect].size.height)
    {
      visibleHeight = [rightView documentVisibleRect].size.height;
    }
  else
    {
      visibleHeight = [leftView documentVisibleRect].size.height;
    }    

  switch ([scroller hitPart])
    {
    case NSScrollerIncrementLine:
      newValue += 10 / mergeFileHeight;
      [scroller setFloatValue: newValue];
      break;
    case NSScrollerDecrementLine:
      newValue -= 10 / mergeFileHeight;
      [scroller setFloatValue: newValue];
      break;
    case NSScrollerIncrementPage:
      newValue += 100 / mergeFileHeight;
      [scroller setFloatValue: newValue];
      break;
    case NSScrollerDecrementPage:
      newValue -= 100 / mergeFileHeight;
      [scroller setFloatValue: newValue];
      break;

    }

  position = [sender floatValue] * 
    (mergeFileHeight - visibleHeight) + visibleHeight / 2.;

  NSDebugLog(@"position %f", position);




  _scrolling = YES;
  [_window disableFlushWindow];

  for ( i = 0; i < length; i ++)
    {
      if ( (mSP[i] <= position)
	   && (mSP[i+1] >= position)
	   && (mSP[i] != mSP[i+1]) )
	break;
    } 

  ratio = (position - mSP[i]) / (mSP[i+1] - mSP[i]);


  // we want "ratio == (leftPosition - lSP[i]) / (lSP[i+1] - lSP[i]);"
  
  leftPosition = ratio * (lSP[i+1] - lSP[i]) + lSP[i];

  rightPosition = ratio * (rSP[i+1] - rSP[i]) + rSP[i];
  

  [leftTextView scrollPoint: 
		  NSMakePoint([leftTextView visibleRect].origin.x,
			      leftPosition - visibleHeight / 2.)];
  [rightTextView scrollPoint: 
		   NSMakePoint([rightTextView visibleRect].origin.x,
			       rightPosition - visibleHeight / 2.)];

  [middleView tile];
  [middleView display];

  [_window enableFlushWindow];
  [_window flushWindow];
  _scrolling = NO;
}

- (void) scrollWheel: (NSEvent *)theEvent
{
  float newValue = [scroller floatValue];

  if (mergeFileHeight == 0.)
    return;

  if (([theEvent modifierFlags] & NSAlternateKeyMask) == NSAlternateKeyMask)
    {
      newValue -= 100 / mergeFileHeight * [theEvent deltaY];
    }
  else
    {
      newValue -= 10 / mergeFileHeight * [theEvent deltaY];
    }
 
  [scroller setFloatValue: newValue];
  [self doScroll: scroller];
}


- (DiffTextView *)leftTextView
{
  return leftTextView;
}

- (DiffTextView *)rightTextView
{
  return rightTextView;
}


- (DiffMiddleView *)middleView
{
  return middleView;
}
@end


