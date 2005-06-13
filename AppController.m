/*
 * AppController.m
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

#include <AppKit/AppKit.h>
#include "AppController.h"
#include "DiffWindowController.h"

#include <math.h>

@implementation AppController
- (void) awakeFromNib
{
  [NSApp setWindowsMenu: [windowMenuItem submenu]];
}


- (void) compareFiles: (id) sender
{
  DiffWindowController *dwc;
  NSOpenPanel *oPanel;
  NSString *filename1, *filename2;
  int result;

  NSString *path = [[NSUserDefaults standardUserDefaults] 
		    objectForKey:@"OpenDirectory"];


  oPanel = [NSOpenPanel openPanel];
  [oPanel setAllowsMultipleSelection:NO];
  result = [oPanel runModalForDirectory: path
		   file:nil types:nil];
  
  if (result != NSOKButton)
    return;

  path = [oPanel directory];

  filename1 = [[oPanel filenames] objectAtIndex: 0];

  oPanel = [NSOpenPanel openPanel];
  [oPanel setAllowsMultipleSelection:NO];
  result = [oPanel runModalForDirectory: path
		   file:nil types:nil];

  if (result != NSOKButton)
    return;

  path = [oPanel directory];

  filename2 = [[oPanel filenames] objectAtIndex: 0];

  [[NSUserDefaults standardUserDefaults] 
    setObject: path
    forKey:@"OpenDirectory"]; 

  {
    dwc =  [[DiffWindowController alloc] initWithFilename: filename1
					 andFilename: filename2];
  }
}


- (void) compareFileToCVS: (id) sender
{
  DiffWindowController *dwc;
  NSOpenPanel *oPanel;
  NSString *filename1, *filename2;
  int result;
  NSString *path = [[NSUserDefaults standardUserDefaults] 
		    objectForKey:@"OpenDirectory"];
  
  oPanel = [NSOpenPanel openPanel];
  [oPanel setAllowsMultipleSelection:NO];
  result = [oPanel runModalForDirectory: path
		   file:nil types:nil];
  
  if (result != NSOKButton)
    return;

  path = [oPanel directory];

  filename1 = [[oPanel filenames] objectAtIndex: 0];

  [[NSUserDefaults standardUserDefaults] 
    setObject: path
    forKey:@"OpenDirectory"]; 

  {
    NSString *cvs;
    NSTask *taskCVS = [[NSTask alloc] init];
    NSFileHandle *fh;
    filename2 = [NSString stringWithFormat:@"%@/%d_%@_%@", 
			  NSTemporaryDirectory(), 
			  [[NSProcessInfo processInfo] 
			    processIdentifier],
			  [[NSDate date] 
			    descriptionWithCalendarFormat:
			      @"%j%H%M%S%F" timeZone:nil 
			    locale:nil],
			  [filename1 lastPathComponent]];
    
    cvs = [NSBundle _absolutePathOfExecutable: @"cvs"];
    if (cvs == nil)
      cvs = @"cvs";
    [taskCVS setLaunchPath: cvs];
    [taskCVS setCurrentDirectoryPath: path];
    [taskCVS setArguments:
	       [NSArray arrayWithObjects:
			  @"update",
			@"-p",
			[filename1 lastPathComponent],
			nil]];
    
    if ([[NSFileManager defaultManager] createFileAtPath: filename2
					contents: nil
					attributes: nil] == NO)
      {
	NSLog(@"aye 1");
	return;
      }

    fh = [NSFileHandle fileHandleForWritingAtPath: filename2];

    if (fh == nil)
      {
	NSLog(@"aye 2");
	return;
      }
    [taskCVS setStandardOutput: fh];
	           
    [taskCVS launch];
    [taskCVS waitUntilExit];

    [fh closeFile];

    if ([[[[NSFileManager defaultManager]
	   fileAttributesAtPath: filename2
	   traverseLink: NO] objectForKey: NSFileSize] intValue]
	== 0)
      {
	NSLog(@"file does not exist on CVS repository");
	return;
      }

  }
  {
    dwc =  [[DiffWindowController alloc] initWithFilename: filename1
					 andTempFilename: filename2];
  }
}
@end
