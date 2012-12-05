/*
 * DiffWindowController.m
 *
 * Copyright (c) 2002 Pierre-Yves Rivaille <pyrivail@ens-lyon.fr>
 * Copyright (c) 2002-2012, GNUstep Project
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
//#include "DiffTextView.h"
//#include "DiffMiddleView.h"
#import "DiffView.h"
#import "DiffWindowController.h"
#import "DiffWrapper.h"

//extern void tasktest(NSString *file1, NSString *file2,
//                     NSMutableArray **r1, NSMutableArray **r2);


@interface PatchData : NSObject
{
@public
  NSMutableString *patchString;
  int start;
  int end;
  int lineDifference;
} 
@end

@implementation PatchData
@end




@interface DiffWindowController (Private)
- (void) diffViewFrameDidChange: (NSNotification*) aNotification;
- (id) _initWithFilename: (NSString *) filename1
	     andFilename: (NSString *) filename2;
- (NSMutableString *) _patchMutableString: (int) direction;
- (void) saveMergedAt: (NSString *) mergedName;
@end

@implementation DiffWindowController


- (id) initWithFilename: (NSString *) filename1
	andTempFilename: (NSString *) filename2
{
  /* Switch filenames so the VC version is on the left */
  [self _initWithFilename: filename2
	andFilename: filename1];
  if (self)
    {
      tempFilename = filename2;

      [[self window] setTitle:
		       [NSString 
			 stringWithFormat: 
			   @"Comparing %@ to the VC version",
			 [filename1 lastPathComponent]]];
		   
      [[self window] makeKeyAndOrderFront: self];

      leftFileName = nil;
      rightFileName = [filename1 retain];
    }
  return self;
}

- (id) initWithFilename: (NSString *) filename1
	    andFilename: (NSString *) filename2
{
  [self _initWithFilename: filename1
	andFilename: filename2];

  if (self)
    {
      tempFilename = nil;

      [[self window] setTitle:
		       [NSString 
			 stringWithFormat: 
			   @"Comparing %@ to %@",
			 [filename1 lastPathComponent],
			 [filename2 lastPathComponent]]];


      [[self window] makeKeyAndOrderFront: self];


      leftFileName = [filename1 retain];
      rightFileName = [filename2 retain];

      NSDebugLog(@"windowsMenu %@", [NSApp windowsMenu]);
    }
  return self;
}


- (id) _initWithFilename: (NSString *) filename1
	     andFilename: (NSString *) filename2
{
  self = [super initWithWindowNibName: @"window"];

  if (self)
    {
      [self window];


      NSDebugLog(@"%@", scroller);
      [scroller setArrowsPosition: NSScrollerArrowsMaxEnd];
      [scroller setFloatValue:0.5 knobProportion:0.2];
      [scroller setEnabled: YES];

      diffWrapper = [[DiffWrapper alloc] initWithFilename: filename1
					      andFilename: filename2];

      [diffWrapper compare];

      leftChanges = [diffWrapper leftChanges];
      rightChanges = [diffWrapper rightChanges];
      //  tasktest(filename1, filename2, &leftChanges, &rightChanges);

      [leftChanges retain];
      [rightChanges retain];

      {
	NSString *string1;
	NSString *string2;

	string1 = [NSString stringWithContentsOfFile: filename1];
	string2 = [NSString stringWithContentsOfFile: filename2];

    
	[diffView setLeftString: string1];
	[diffView setRightString: string2];

	[diffView setLeftChanges: leftChanges
		 andRightChanges: rightChanges];

	[diffView setLeftLineRanges: [diffWrapper leftLineRanges]
		 andRightLineRanges: [diffWrapper rightLineRanges]];

	[scroller setFloatValue: 0.
		 knobProportion: 
		    ([diffView frame].size.height /
		     [diffView mergeFileHeight])];

	[diffView tile];

	[diffView setPostsFrameChangedNotifications: YES];
	[[NSNotificationCenter defaultCenter]
	  addObserver: self
	     selector: @selector(diffViewFrameDidChange:)
		 name: NSViewFrameDidChangeNotification
	       object: diffView];

	choices = (int *) calloc([leftChanges count], sizeof(int));

      }

      [self diffViewFrameDidChange: nil];
  
    }
  return self;
  
}

- (void) diffViewFrameDidChange: (NSNotification*) aNotification
{

  [diffView computeScrollerSize];

  if ([diffView frame].size.height >= [diffView mergeFileHeight])
    {
      [scroller setEnabled: NO];
    }
  else
    {
      [scroller setEnabled: YES];
      [scroller setFloatValue: [scroller floatValue]
		knobProportion: 
		  ([diffView frame].size.height /
		   [diffView mergeFileHeight])];
      [diffView doScroll: scroller];
    }
}

- (void) windowWillClose: (id) sender
{
  NSDebugLog(@"windowWillClose called");
  //  RELEASE([self window]);
  [self autorelease];
}

- (void) dealloc
{
  NSDebugLog(@"dealloc called");
  [[NSNotificationCenter defaultCenter]
    removeObserver: self
    name: NSViewFrameDidChangeNotification
    object: diffView];
  if (tempFilename != nil)
    {
      if ([[NSFileManager defaultManager]
	    removeFileAtPath: tempFilename
	    handler: nil] == NO)
	NSLog(@"We could not delete %@", tempFilename);
    }
  [leftChanges release];
  [rightChanges release];
  [leftFileName release];
  [rightFileName release];
  [diffWrapper release];
  free(choices);
  [super dealloc];
}


- (void) matrixButtonClicked: (id) sender
{
  int oldChoice = choices[[sender tag]];

  NSDebugLog(@"matrixButtonClicked %d, %d", [sender tag],
	     [sender selectedColumn]);

 
  choices[[sender tag]] = [sender selectedColumn] - 1;

  if ((oldChoice == -1) && (choices[[sender tag]] != -1))
    {
      [[diffView leftTextView] setColor: 
				 [NSColor colorWithDeviceRed:0.7 
					   green:0.7 
					   blue:1. 
					   alpha:1.]
			       forChangeNumber: [sender tag]];
    }
  else if ((oldChoice != -1) && (choices[[sender tag]] == -1))
    {
      [[diffView leftTextView] setColor: 
				 [NSColor whiteColor]
			       forChangeNumber: [sender tag]];
    }

  if ((oldChoice == 1) && (choices[[sender tag]] != 1))
    {
      [[diffView rightTextView] setColor: 
				  [NSColor colorWithDeviceRed:0.7 
					    green:0.7 
					    blue:1. 
					    alpha:1.]
				forChangeNumber: [sender tag]];
    }
  else if ((oldChoice != 1) && (choices[[sender tag]] == 1))
    {
      [[diffView rightTextView] setColor: 
				  [NSColor whiteColor]
				forChangeNumber: [sender tag]];
    }
}

- (void) selectAllLeftChanges: (id) sender
{
  int i;
  NSArray *matrixArray = [[diffView middleView] matrixArray];
  int count = [matrixArray count];

  for ( i = 0; i < count; i ++ )
    {
      if (choices[i] != - 1)
	{
	  choices[i] = -1;
	  [[diffView leftTextView] setColor: 
				     [NSColor whiteColor]
				   forChangeNumber: i];
	  [[diffView rightTextView] setColor: 
				  [NSColor colorWithDeviceRed:0.7 
					    green:0.7 
					    blue:1. 
					    alpha:1.]
				forChangeNumber: i];
	  [[matrixArray objectAtIndex: i] selectCellAtRow: 0 column:0];
	}
    }
}

- (void) selectAllRightChanges: (id) sender
{
  int i;
  NSArray *matrixArray = [[diffView middleView] matrixArray];
  int count = [matrixArray count];

  for ( i = 0; i < count; i ++ )
    {
      if (choices[i] != 1)
	{
	  choices[i] = 1;
	  [[diffView rightTextView] setColor: 
				     [NSColor whiteColor]
				   forChangeNumber: i];
	  [[diffView leftTextView] setColor: 
				  [NSColor colorWithDeviceRed:0.7 
					    green:0.7 
					    blue:1. 
					    alpha:1.]
				forChangeNumber: i];
	  [[matrixArray objectAtIndex: i] selectCellAtRow: 0 column:2];
	}
    }
}


- (void) selectNoChanges: (id) sender
{
  int i;
  NSArray *matrixArray = [[diffView middleView] matrixArray];
  int count = [matrixArray count];

  for ( i = 0; i < count; i ++ )
    {
      if (choices[i] != 0)
	{
	  choices[i] = 0;
	  [[diffView leftTextView] setColor: 
				     [NSColor colorWithDeviceRed:0.7 
					      green:0.7 
					      blue:1. 
					      alpha:1.]
				   forChangeNumber: i];
	  [[diffView rightTextView] setColor: 
				      [NSColor colorWithDeviceRed:0.7 
					       green:0.7 
					       blue:1. 
					       alpha:1.]
				    forChangeNumber: i];
	  [[matrixArray objectAtIndex: i] selectCellAtRow: 0 column:1];
	}
    }
  
}

- (void) savePatchFromRight: (id) sender
{
  NSMutableString *patchString;

  int result;
  NSSavePanel *sPanel;
  NSString *path = [[NSUserDefaults standardUserDefaults] 
		    objectForKey:@"OpenDirectory"];
  NSString *mergedName;


  sPanel = [NSSavePanel savePanel];
  //  [sPanel setAllowsMultipleSelection:NO];
  result = [sPanel runModalForDirectory: path
		   file: @""];
  
  if (result != NSOKButton)
    return;

  path = [sPanel directory];

  mergedName = [sPanel filename];

  [[NSUserDefaults standardUserDefaults] 
    setObject: path
    forKey:@"OpenDirectory"]; 


  patchString = [self _patchMutableString: -1];
  [patchString insertString: [NSString stringWithFormat: @"+++ %@\n", 
				       leftFileName]
	       atIndex: 0];
  if (rightFileName)
    {
      [patchString insertString: [NSString stringWithFormat: @"--- %@\n", 
					   rightFileName]
		   atIndex: 0];
    }
  else
    {
      [patchString insertString: [NSString stringWithFormat: @"--- %@\n", 
					   leftFileName]
		   atIndex: 0];
    }
    
  [patchString writeToFile: mergedName atomically: YES];
}

- (void) savePatchFromLeft: (id) sender
{
  NSMutableString *patchString;

  int result;
  NSSavePanel *sPanel;
  NSString *path = [[NSUserDefaults standardUserDefaults] 
		    objectForKey:@"OpenDirectory"];
  NSString *mergedName;


  sPanel = [NSSavePanel savePanel];
  //  [sPanel setAllowsMultipleSelection:NO];
  result = [sPanel runModalForDirectory: path
		   file: @""];
  
  if (result != NSOKButton)
    return;

  path = [sPanel directory];

  mergedName = [sPanel filename];

  [[NSUserDefaults standardUserDefaults] 
    setObject: path
    forKey:@"OpenDirectory"]; 


  patchString = [self _patchMutableString: 1];
  if (rightFileName)
    {
      [patchString insertString: [NSString stringWithFormat: @"+++ %@\n", 
					   rightFileName]
		   atIndex: 0];
    }
  else
    {
      [patchString insertString: [NSString stringWithFormat: @"+++ %@\n", 
					   leftFileName]
		   atIndex: 0];
    }
  [patchString insertString: [NSString stringWithFormat: @"--- %@\n", 
				       leftFileName]
	       atIndex: 0];
  

  [patchString writeToFile: mergedName atomically: YES];
}

- (NSMutableString *) _patchMutableString: (int) direction
{
  NSArray *flr;
  NSArray *tlr;
  NSString *fstr;
  NSString *tstr;
  
  NSMutableArray *patchArray = [NSMutableArray arrayWithCapacity:
				   ([leftChanges count] / 2) + 1];

  NSMutableArray *finalArray = [NSMutableArray arrayWithCapacity:
				   ([leftChanges count] / 2) + 1];
  NSArray *fromChanges;
  NSArray *toChanges;
  NSMutableString *stringToInsert;
  PatchData *p, *pp;
  int i, j, k;
  int toStart;
  int toEnd;
  int count;
  int linesCount;

  if (direction > 0)
    {
      flr = [diffWrapper leftLineRanges];
      tlr = [diffWrapper rightLineRanges];
      fstr = [diffWrapper leftString];
      tstr = [diffWrapper rightString];
      fromChanges = leftChanges;
      toChanges = rightChanges;
    }
  else
    {
      flr = [diffWrapper rightLineRanges];
      tlr = [diffWrapper leftLineRanges];
      fstr = [diffWrapper rightString];
      tstr = [diffWrapper leftString];
      fromChanges = rightChanges;
      toChanges = leftChanges;
    }
  linesCount = [flr count] - 1;

  for (i = 0; i < [fromChanges count] - 1; i += 2)
    {
      p = [[PatchData alloc] init];
      p->patchString = [NSMutableString string];

      if (choices[i/2] * direction > 0)
	{
	  p->start = [[fromChanges objectAtIndex: i] intValue];
	  p->end = [[fromChanges objectAtIndex: i + 1] intValue];
	  toStart = [[toChanges objectAtIndex: i] intValue];
	  toEnd = [[toChanges objectAtIndex: i + 1] intValue];
	  p->lineDifference = (toEnd - toStart) - (p->end - p->start);

	  for (j = p->start; j < p->end; j++ )
	    {
	      [p->patchString appendString: @"-"];
	      [p->patchString appendString:[fstr 
					     substringWithRange: 
					       NSMakeRange
					     ([[flr objectAtIndex: j] intValue],
					      [[flr objectAtIndex: j+1] intValue] -
					      [[flr objectAtIndex: j] intValue])]];
	    }
	  for (j = toStart; j < toEnd; j++ )
	    {
	      [p->patchString appendString: @"+"];
	      [p->patchString appendString:[tstr
					     substringWithRange: 
					       NSMakeRange
					     ([[tlr objectAtIndex: j] intValue],
					      [[tlr objectAtIndex: j+1] intValue] -
					      [[tlr objectAtIndex: j] intValue])]];
	    }
	  [patchArray addObject: p];

	}
      else if (choices[i/2] * direction < 0)
	{
	}
      else if (choices[i/2] == 0)
	{
	  p->start = [[fromChanges objectAtIndex: i] intValue];
	  p->end = [[fromChanges objectAtIndex: i + 1] intValue];
	  p->lineDifference = - (p->end - p->start);

	  for (j = p->start; j < p->end; j++ )
	    {
	      [p->patchString appendString: @"-"];
	      [p->patchString appendString:[fstr 
					     substringWithRange: 
					       NSMakeRange
					     ([[flr objectAtIndex: j] intValue],
					      [[flr objectAtIndex: j+1] intValue] -
					      [[flr objectAtIndex: j] intValue])]];
	    }
	  
	  if (p->lineDifference != 0)
	    [patchArray addObject: p];
	  
	}
      [p release];
    }

  


  i = 0;
  count = [patchArray count];
  
  pp = nil;

  while (i < count)
    {
      p = [patchArray objectAtIndex: i];


      if ((pp == nil) || (p->start - pp->end >= 6))
	{
	  // two separate chunks
	  if (pp != nil)
	    {
	      j = pp->end + 3;
	      if (j >= linesCount)
		j = linesCount;
	      stringToInsert = [NSMutableString string];
	      for ( k = pp->end; k < j; k++ )
		{
		  [stringToInsert appendString: @" "];
		  [stringToInsert appendString: [fstr 
						  substringWithRange: 
						    NSMakeRange
						  ([[flr objectAtIndex: k] intValue],
						   [[flr objectAtIndex: k+1] intValue] -
						   [[flr objectAtIndex: k] intValue])]];
		}
	      [pp->patchString appendString: stringToInsert];
	      pp->end = j;
	      
	      [finalArray addObject: pp];
	    }

	  // new chunk
	  [pp release];

	  j = p->start - 3;
	  if ( j < 0)
	    j = 0;
	  pp = [[PatchData alloc] init];
	  pp->patchString = p->patchString;
	  stringToInsert = [NSMutableString string];
	  for ( k = j; k < p->start; k++ )
	    {
	      [stringToInsert appendString: @" "];
	      [stringToInsert appendString: [fstr 
					     substringWithRange: 
					       NSMakeRange
					     ([[flr objectAtIndex: k] intValue],
					      [[flr objectAtIndex: k+1] intValue] -
					      [[flr objectAtIndex: k] intValue])]];
	    }
	  [pp->patchString insertString: stringToInsert
	    atIndex: 0];
	  pp->start = j;
	  pp->end = p->end;
	  pp->lineDifference = p->lineDifference;
	  
	}
      else
	{
	  // merge the two chunks
	  stringToInsert = [NSMutableString string];
	  for ( k = pp->end; k < p->start; k++ )
	    {
	      [stringToInsert appendString: @" "];
	      [stringToInsert appendString: [fstr 
					     substringWithRange: 
					       NSMakeRange
					     ([[flr objectAtIndex: k] intValue],
					      [[flr objectAtIndex: k+1] intValue] -
					      [[flr objectAtIndex: k] intValue])]];
	    }

	  [pp->patchString appendString: stringToInsert];
	  [pp->patchString appendString: p->patchString];
	  pp->end = p->end;
	  pp->lineDifference += p->lineDifference;
	}
      i++;
    }
  
  if (pp != nil)
    {
      j = pp->end + 3;
      if (j >= linesCount)
	j = linesCount;
      stringToInsert = [NSMutableString string];
      for ( k = pp->end; k < j; k++ )
	{
	  [stringToInsert appendString: @" "];
	  [stringToInsert appendString: [fstr 
					  substringWithRange: 
					    NSMakeRange
					  ([[flr objectAtIndex: k] intValue],
					   [[flr objectAtIndex: k+1] intValue] -
					   [[flr objectAtIndex: k] intValue])]];
	}
      [pp->patchString appendString: stringToInsert];
      pp->end = j;
      
      [finalArray addObject: pp];
    }
  [pp release];


  {
    NSMutableString *patchFileString = [NSMutableString string];

    int d = 0;
    for ( i = 0; i < [finalArray count]; i++ )
      {
	p = [finalArray objectAtIndex: i];
	[patchFileString appendFormat: 
			   @"@@ -%d,%d +%d,%d @@\n%@",
			 p->start+1,
			 p->end - p->start,
			 p->start + d + 1,
			 p->end - p->start + p->lineDifference, 
			 p->patchString];
	d += p->lineDifference;
      }

    //    NSLog(@"\n%@", patchFileString);
    return patchFileString;
  }

}


- (void) saveMergedAt: (NSString *) mergedName
{
  NSMutableString *mergedString = [NSMutableString string];
  int i;

  {
    NSArray *llr = [diffWrapper leftLineRanges];
    NSArray *rlr = [diffWrapper rightLineRanges];

    [mergedString appendString:
		    [[diffWrapper leftString] 
		      substringWithRange: 
			NSMakeRange
		      (0,
		       [[llr objectAtIndex: 
			       [[leftChanges objectAtIndex: 0] 
				 intValue]] intValue]
		       )]];
    

    for ( i = 0; i < [leftChanges count] - 1; i++ )
      {
	if (i % 2 == 1)
	  {
	    [mergedString appendString:
			    [[diffWrapper leftString] 
			      substringWithRange: 
				NSMakeRange
			      ([[llr objectAtIndex: 
				       [[leftChanges objectAtIndex: i] 
					 intValue]] intValue],
			       [[llr objectAtIndex: 
				       [[leftChanges objectAtIndex: i+1] 
					 intValue]] intValue] -
			       [[llr objectAtIndex: 
				       [[leftChanges objectAtIndex: i] 
					 intValue]] intValue]
			       )]];
	  }
	else
	  {
	    if (choices[i/2] < 0)
	      {
		[mergedString appendString:
				[[diffWrapper leftString] 
				  substringWithRange: 
				    NSMakeRange
				  ([[llr objectAtIndex: 
					   [[leftChanges objectAtIndex: i] 
					     intValue]] intValue],
				   [[llr objectAtIndex: 
					   [[leftChanges objectAtIndex: i+1] 
					     intValue]] intValue] -
				   [[llr objectAtIndex: 
					   [[leftChanges objectAtIndex: i] 
					     intValue]] intValue]
				   )]];
		
	      }
	    else if (choices[i/2] > 0)
	      {
		[mergedString appendString:
				[[diffWrapper rightString] 
				  substringWithRange: 
				    NSMakeRange
				  ([[rlr objectAtIndex: 
					   [[rightChanges objectAtIndex: i] 
					     intValue]] intValue],
				   [[rlr objectAtIndex: 
					   [[rightChanges objectAtIndex: i+1] 
					     intValue]] intValue] -
				   [[rlr objectAtIndex: 
					   [[rightChanges objectAtIndex: i] 
					     intValue]] intValue]
				   )]];
		
	      }
	    else
	      {
		
	      }
	  }
      }

    [mergedString appendString:
		    [[diffWrapper leftString] 
		      substringFromIndex: 
		      [[llr objectAtIndex: 
			       [[leftChanges objectAtIndex: 
					       [leftChanges count] - 1] 
				 intValue]] intValue]]];
    
    //    NSLog(@"%@", mergedString);
  }
  
  
  [mergedString writeToFile: mergedName atomically: YES];
}

- (void) saveMergedFile: (id) sender
{

  int result;
  NSSavePanel *sPanel;
  NSString *path = [[NSUserDefaults standardUserDefaults] 
		    objectForKey:@"OpenDirectory"];
  NSString *mergedName;


  sPanel = [NSSavePanel savePanel];
  //  [sPanel setAllowsMultipleSelection:NO];
  result = [sPanel runModalForDirectory: path
		   file: @""];
  
  if (result != NSOKButton)
    return;

  path = [sPanel directory];

  mergedName = [sPanel filename];

  [[NSUserDefaults standardUserDefaults] 
    setObject: path
    forKey:@"OpenDirectory"]; 


  //  NSLog(@"%@", mergedName);

  [self saveMergedAt: mergedName];

}
@end
