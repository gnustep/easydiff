/*
 * DiffWrapper.m
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


//#include <AppKit/AppKit.h>
#include "DiffWrapper.h"

void tasktest(NSString *file1, NSString *file2, NSMutableArray **r1, NSMutableArray **r2);


@implementation DiffWrapper
- (id) initWithFilename: (NSString *) file1
	    andFilename: (NSString *) file2
{
  filename1 = RETAIN(file1);
  filename2 = RETAIN(file2);

  leftChanges = nil;
  rightChanges = nil;

  leftString = RETAIN([NSString stringWithContentsOfFile: 
				  file1]);
  rightString = RETAIN([NSString stringWithContentsOfFile: 
				   file2]);

  {
    int length = [leftString length];
    int end;
    leftLineRangesArray = [[NSMutableArray alloc] init];
    [leftLineRangesArray addObject:
			   [NSNumber numberWithInt: -1]];

    end = -1;
    while (end < length - 1)
      {
	[leftString getLineStart: NULL
		    end: NULL
		    contentsEnd: &end
		    forRange: NSMakeRange(end + 1, 0)];
	if (end >= length)
	  {
	    [leftLineRangesArray addObject: 
				   [NSNumber numberWithInt: length - 1]];
	  }
	else
	  {
	    [leftLineRangesArray addObject: 
				   [NSNumber numberWithInt: end]];
	  }
      }
  }

  {
    int length = [rightString length];
    int end;
    rightLineRangesArray = [[NSMutableArray alloc] init];
    [rightLineRangesArray addObject:
			   [NSNumber numberWithInt: -1]];

    end = -1;
    while (end < length - 1)
      {
	[rightString getLineStart: NULL
		    end: NULL
		    contentsEnd: &end
		    forRange: NSMakeRange(end + 1, 0)];
	if (end >= length)
	  {
	    [rightLineRangesArray addObject: 
				   [NSNumber numberWithInt: length - 1]];
	  }
	else
	  {
	    [rightLineRangesArray addObject: 
				   [NSNumber numberWithInt: end]];
	  }
      }
  }



  return self;
}

- (void) dealloc
{
  TEST_RELEASE(filename1);
  TEST_RELEASE(filename2);
  TEST_RELEASE(leftString);
  TEST_RELEASE(rightString);
  TEST_RELEASE(leftChanges);
  TEST_RELEASE(rightChanges);
  TEST_RELEASE(leftLineRangesArray);
  TEST_RELEASE(rightLineRangesArray);
}

- (NSArray *) leftLineRanges
{
  return leftLineRangesArray;
}

- (NSArray *) rightLineRanges
{
  return rightLineRangesArray;
}

- (void) compare
{
  
  TEST_RELEASE(rightChanges);
  TEST_RELEASE(leftChanges);

  tasktest(filename1, filename2, &leftChanges, &rightChanges);
}

- (void) alternateCompare
{
  [self compare];
}

- (NSArray *) leftChanges
{
  return leftChanges;
}

- (NSArray *) rightChanges
{
  return rightChanges;
}


- (NSString *) leftString
{
  return leftString;
}

- (NSString *) rightString
{
  return rightString;
}
@end

void tasktest(NSString *file1, NSString *file2, NSMutableArray **r1, NSMutableArray **r2)
{
  NSTask *taskDiff, *taskGrep;
  NSPipe *pipe1, *pipe2;
  NSData *data;
  NSArray *resultsArray;
  NSMutableArray *leftChanges, *rightChanges;
  NSFileHandle *fileHandle;

  pipe1 = [[NSPipe alloc] init];
  taskDiff = [[NSTask alloc] init];
  [taskDiff setLaunchPath: @"diff"];
  [taskDiff setArguments: 
	   [NSArray arrayWithObjects: file1, file2, nil]];
  [taskDiff setStandardOutput: pipe1];

  pipe2 = [[NSPipe alloc] init];
  taskGrep = [[NSTask alloc] init];
  [taskGrep setLaunchPath: @"grep"];
  [taskGrep setArguments: 
	   [NSArray arrayWithObjects: @"^[^<>-]", nil]];
  [taskGrep setStandardInput: pipe1];
  [taskGrep setStandardOutput: pipe2];
  
  fileHandle = [pipe2 fileHandleForReading];

  {
    [taskDiff launch];
    [taskGrep launch];
  }

  data = [fileHandle readDataToEndOfFile];


  {
    NSString *result;
    result = [[NSString alloc] initWithData: data
			       encoding: NSNonLossyASCIIStringEncoding];
    resultsArray = [result componentsSeparatedByString:@"\n"];
    RELEASE(result);
  }

  {
    int i;
    int count = [resultsArray count];
    int r1a, r1b;
    int r2a, r2b;
    NSScanner *scanner;
    NSString *operation;
    NSCharacterSet *cs_sep = 
      [NSCharacterSet characterSetWithCharactersInString: @","];
    NSCharacterSet *cs_type = 
      [NSCharacterSet characterSetWithCharactersInString: @"adc"];

    leftChanges = [[NSMutableArray alloc]
		    initWithCapacity: 2 * count];
    rightChanges = [[NSMutableArray alloc]
		     initWithCapacity: 2 * count];

    for (i = 0; i < count - 1; i++)
      {
	scanner = [NSScanner scannerWithString: 
			       [resultsArray objectAtIndex: i]];
	[scanner scanInt: &r1a];
	if ([scanner scanCharactersFromSet: cs_sep
		     intoString: NULL])
	  {
	    [scanner scanInt: &r1b];
	  }
	else
	  {
	    r1b = -1;
	  }
	
	[scanner scanCharactersFromSet: cs_type
		 intoString: &operation];
	  
	[scanner scanInt: &r2a];
	if ([scanner scanCharactersFromSet: cs_sep
		     intoString: NULL])
	  {
	    [scanner scanInt: &r2b];
	  }
	else
	  {
	    r2b = -1;
	  }

	if ([operation isEqualToString: @"c"])
	  {
	    if (r1b == -1)
	      r1b = r1a + 1;
	    else
	      r1b++;
	    if (r2b == -1)
	      r2b = r2a + 1;
	    else
	      r2b++;
	  }
	else if ([operation isEqualToString: @"a"])
	  {
	    r1a++;
	    r1b = r1a;


	    if (r2b == -1)
	      r2b = r2a + 1;
	    else
	      r2b++;
	    
	  }
	else if ([operation isEqualToString: @"d"])
	  {
	    if (r1b == -1)
	      r1b = r1a + 1;
	    else
	      r1b++;

	    r2a++;
	    r2b = r2a;
	  }

	[leftChanges addObject: 
		       [NSNumber numberWithInt: r1a-1]];
	[leftChanges addObject: 
		       [NSNumber numberWithInt: r1b-1]];
	[rightChanges addObject: 
			[NSNumber numberWithInt: r2a-1]];
	[rightChanges addObject: 
			[NSNumber numberWithInt: r2b-1]];
      }
  }
  //  NSLog(@"%@", [leftChanges description]);
  //  NSLog(@"%@", [rightChanges description]);

  *r1 = leftChanges;
  *r2 = rightChanges;
}

