/*
 * DiffTextView.m
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


#import "DiffTextView.h"
#include <math.h>

//static NSRect rectsToFill[500];

@implementation DiffTextView

- (id) initWithFrame: (NSRect) aRect
{
  [super initWithFrame: aRect];

  lineRangesArray = nil;
  blockCharacterRangesArray = [[NSMutableArray alloc] init];
  blockRectsArray = NSZoneMalloc([self zone], sizeof(NSRect)*10);
  blockRectsArraySize = 10;
  blockRectsArrayFirstFree = 0;
  lastLine = 0;
  firstCharOfLastLine = 0;

  [self setEditable: NO];
  [self setSelectable: YES];
  [self setDrawsBackground: NO];

  return self;
}

- (void) dealloc
{
  RELEASE(lineRangesArray);
  RELEASE(changes);
  RELEASE(colors);
  [super dealloc];
}

- (void) setChanges: (NSArray *)anArray
{
  int i;
  int count;
  ASSIGN(changes, anArray);
  
  RELEASE(colors);

  count = [changes count] / 2;

  colors = [[NSMutableArray alloc] initWithCapacity: count];

  for (i = 0; i < count; i++)
    {
      [colors addObject: [NSColor colorWithDeviceRed:0.7 
				  green:0.7 
				  blue:1. 
				  alpha:1.]];
    }

  //  NSLog(@"changes count %d", [changes count]);
}

- (void) setColor: (NSColor *) aColor
  forChangeNumber: (int) number
{
  if (colors == nil)
    return;

  [colors replaceObjectAtIndex: number
	  withObject: aColor];

  blockRectsArray[number].size.width = [self visibleRect].size.width;
  blockRectsArray[number].origin.x = [self visibleRect].origin.x;

  [self setNeedsDisplayInRect: 
	  blockRectsArray[number]];
}

- (void) computeLineRangesFromUpTo: (int) number
{
  NSArray *array;
  int count;

  NSLayoutManager *lm = [self layoutManager];
  NSTextContainer *tc = [self textContainer];

  array = changes;

  count = [array count];

  NSDebugLog(@"count %d", count);
  {
    NSString *internalString = [self string];
    int startLine;
    int endLine;
    int currentLine;
    NSUInteger firstCharOfLine = firstCharOfLastLine;
    NSUInteger firstCharOfNextLine;
    int i;
    int a, b;

    separationPosition = (float *)
      NSZoneMalloc([self zone], sizeof(float) *
		   (count + 2));

    separationDiff = (float *)
      NSZoneMalloc([self zone], sizeof(float) *
		   (count + 1));

    separationPosition[0] = 0;

    currentLine = lastLine;
    for (i = 0; i < count; i += 2)
      {
	startLine = [[array objectAtIndex: i] intValue];
	endLine = [[array objectAtIndex: i+1] intValue] - 1;

	while (currentLine < startLine)
	  {
	    [internalString getLineStart: NULL
			    end: &firstCharOfNextLine
			    contentsEnd: NULL
			    forRange: NSMakeRange(firstCharOfLine, 0)];
	    currentLine ++;
	    firstCharOfLine = firstCharOfNextLine;
	  }

	a = firstCharOfLine;
	[blockCharacterRangesArray 
	  addObject: [NSNumber numberWithInt: firstCharOfLine]];
			
	while (currentLine <= endLine)
	  {
	    [internalString getLineStart: NULL
			    end: &firstCharOfNextLine
			    contentsEnd: NULL
			    forRange: NSMakeRange(firstCharOfLine, 0)];
	    currentLine ++;
	    firstCharOfLine = firstCharOfNextLine;
	  }

	b = firstCharOfLine - 1;

	[blockCharacterRangesArray 
	   addObject: [NSNumber numberWithInt: firstCharOfLine - 1]];

	//	NSLog(@"%d %d", blockRectsArraySize, blockRectsArrayFirstFree);
	if (blockRectsArraySize == blockRectsArrayFirstFree)
	  {
	    blockRectsArray = 
	      NSZoneRealloc([self zone], 
			    blockRectsArray,
			    blockRectsArraySize * 2 * sizeof(NSRect));
	    blockRectsArraySize *= 2;
	  }

	//	NSLog(@"a=%d b=%d", a, b);

        if (a == [internalString length])
          {
	    blockRectsArray[blockRectsArrayFirstFree++] =
	      [lm boundingRectForGlyphRange:
		    [lm glyphRangeForCharacterRange:
			  NSMakeRange(a-1, 1)
			actualCharacterRange:NULL]
		  inTextContainer:tc];
	    blockRectsArray[blockRectsArrayFirstFree - 1].origin.y =
              NSMaxY(blockRectsArray[blockRectsArrayFirstFree - 1]);
	    blockRectsArray[blockRectsArrayFirstFree - 1].size.height = 0;

	    separationPosition[i + 1] = 
	      NSMinY(blockRectsArray[blockRectsArrayFirstFree - 1]);

	    separationPosition[i + 2] = 
	      NSMinY(blockRectsArray[blockRectsArrayFirstFree - 1]);

	    separationDiff[i] = separationPosition[i+1] -
	      separationPosition[i];

	    separationDiff[i+1] = separationPosition[i+2] -
	      separationPosition[i+1];

	    blockRectsArray[blockRectsArrayFirstFree - 1].size.height = 2;
	    blockRectsArray[blockRectsArrayFirstFree - 1].origin.y--;
          }
	else if (a >= b)
	  {
	    blockRectsArray[blockRectsArrayFirstFree++] =
	      [lm boundingRectForGlyphRange:
		    [lm glyphRangeForCharacterRange:
			  NSMakeRange(a, 1)
			actualCharacterRange:NULL]
		  inTextContainer:tc];

	    separationPosition[i + 1] = 
	      NSMinY(blockRectsArray[blockRectsArrayFirstFree - 1]);

	    separationPosition[i + 2] = 
	      NSMinY(blockRectsArray[blockRectsArrayFirstFree - 1]);

	    NSDebugLog(@"a %d %f", i + 1, separationPosition[i + 1]);
	    NSDebugLog(@"a %d %f", i + 2, separationPosition[i + 2]);

	    separationDiff[i] = separationPosition[i+1] -
	      separationPosition[i];

	    separationDiff[i+1] = separationPosition[i+2] -
	      separationPosition[i+1];


	    blockRectsArray[blockRectsArrayFirstFree - 1].size.height = 2;
	    blockRectsArray[blockRectsArrayFirstFree - 1].origin.y--;
	  }
	else
	  {
	    blockRectsArray[blockRectsArrayFirstFree++] =
	      [lm boundingRectForGlyphRange:
		    [lm glyphRangeForCharacterRange:
			  NSMakeRange(a, b - a)
			actualCharacterRange:NULL]
		  inTextContainer:tc];

	    separationPosition[i + 1] = 
	      NSMinY(blockRectsArray[blockRectsArrayFirstFree - 1]);

	    separationPosition[i + 2] = 
	      NSMaxY(blockRectsArray[blockRectsArrayFirstFree - 1]);


	    NSDebugLog(@"b %d %f", i + 1, separationPosition[i + 1]);
	    NSDebugLog(@"b %d %f", i + 2, separationPosition[i + 2]);

	    separationDiff[i] = separationPosition[i+1] -
	      separationPosition[i];

	    separationDiff[i+1] = separationPosition[i+2] -
	      separationPosition[i+1];
	  }


	//	NSLog(@"%@", NSStringFromRect
	//	      (blockRectsArray[blockRectsArrayFirstFree-1]));

      }

    separationPosition[count + 1] = NSMaxY([self bounds]);
    separationDiff[count] = separationPosition[count + 1] - 
      separationPosition[count];

    firstCharOfLastLine = firstCharOfLine;
    lastLine = currentLine;

    
    //    NSLog(@"%d %@", [blockCharacterRangesArray count],
    //	  [blockCharacterRangesArray description]);
  }

  {
    
  }
  
}

/*
- (void) computeAllLineRanges
{
  NSString *internalString = [self string];
  int end;
  int len = [internalString length];

  RELEASE(lineRangesArray);
  lineRangesArray = [[NSMutableArray alloc] init];
  [lineRangesArray addObject:
		     [NSNumber numberWithInt: -1]];

  end = -1;
  while (end < len - 1)
    {
      [internalString getLineStart: NULL
		      end: NULL
		      contentsEnd: &end
		      forRange: NSMakeRange(end + 1, 0)];
      if (end >= len)
	{
	  [lineRangesArray addObject: 
			     [NSNumber numberWithInt: len - 1]];
	}
      else
	{
	  [lineRangesArray addObject: 
			     [NSNumber numberWithInt: end]];
	}
    }
}
*/

- (void) setLineRanges: (NSArray *) lineRanges
{
  ASSIGN(lineRangesArray, lineRanges);

  //  NSLog(@"lineRanges count %d", [lineRanges count]);
  
}

- (NSArray *) lineRangesArray
{
  return lineRangesArray;
}

- (NSRange) lineRangesForRect: (NSRect) aRect
{
  int i, count;
  int startLine = -1;
  int endLine = -1;

  NSRange glyphRange, characterRange;
  NSLayoutManager *lm = [self layoutManager];
  NSTextContainer *tc = [self textContainer];
  
  glyphRange = [lm glyphRangeForBoundingRect: aRect
		   inTextContainer: tc];
  characterRange = [lm characterRangeForGlyphRange: glyphRange
		       actualGlyphRange: NULL];
  
  count = [lineRangesArray count];
  i = 0;
  while (i < count)
    {
      if ((int) characterRange.location <=
	  [[lineRangesArray objectAtIndex: i] intValue] + 1)
	{
	  startLine = i;
	  break;
	}
      i++;
    }

  while (i < count)
    {
      if ((int) NSMaxRange(characterRange) <=
	  [[lineRangesArray objectAtIndex: i] intValue] + 1)
	{
	  endLine = i;
	  break;
	}
      i++;
    }

  /*
  NSLog(@"glyphRange    : %@", NSStringFromRange(glyphRange));
  NSLog(@"characterRange: %@", NSStringFromRange(characterRange));
  */

  return NSMakeRange(startLine, endLine - startLine);
}

/*
- (void) highlightLinesInRange: (NSRange)aRange
{
  unsigned end;
  unsigned len = [string length];

  end = -1;
  for (i = 0; i < aRange.start; i++)
    {
      [string getLineStart: nil
	      end: nil
	      contentsEnd: &end
	      forRange: NSMakeRange(end + 1, 0)];
    }
}
*/

- (void) drawRect: (NSRect) aRect
{
  NSRange glyphRange, characterRange;
  NSLayoutManager *lm = [self layoutManager];
  NSTextContainer *tc = [self textContainer];

  [[NSColor whiteColor] set];
  NSRectFill(aRect);

  glyphRange = [lm glyphRangeForBoundingRect:aRect
                   inTextContainer: tc];

  if (!NSEqualRanges(glyphRange, NSMakeRange(0, 0)))
    {
      int i = 0;
      int count = [blockCharacterRangesArray count];
      int charStart, charEnd;

      characterRange = [lm characterRangeForGlyphRange: glyphRange
                           actualGlyphRange: NULL];  

      for (i = 0; i < count; i += 2)
        {
          charEnd = [[blockCharacterRangesArray objectAtIndex: i+1]
		      intValue];
          if (charEnd >= characterRange.location)
	    {
	      break;
	    }
        }

      for (; i < count; i += 2)
        {
          charStart = [[blockCharacterRangesArray objectAtIndex: i]
		        intValue];
          if (charStart > NSMaxRange(characterRange))
	    {
	      break;
	    }

          blockRectsArray[i/2].size.width = aRect.size.width;
          blockRectsArray[i/2].origin.x = aRect.origin.x;

          [[colors objectAtIndex: i/2] set];

          NSRectFill(NSIntersectionRect(aRect, blockRectsArray[i/2]));

        }

    }

  [super drawRect: aRect];
}

- (void) superviewFrameChanged: (NSNotification *)aNotification
{
  NSSize size;
  float superWidth, selfWidth;

  superWidth = [self convertRect: [_super_view bounds]
	       fromView: _super_view].size.width;
  selfWidth = [_layoutManager 
		usedRectForTextContainer: _textContainer].size.width;

  if (superWidth > selfWidth)
    size.width = superWidth;
  else
    size.width = selfWidth;

  size.height = [self frame].size.height;

  [self setFrameSize: size];
}

- (void) scrollWheel: (NSEvent *)theEvent
{
  if ([self nextResponder])
    return [[self nextResponder] scrollWheel: theEvent];
  else
    return [self noResponderFor: @selector(scrollWheel:)];
}
@end


