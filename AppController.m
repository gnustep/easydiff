/*
 * AppController.m
 *
 * Copyright (c) 2002 Pierre-Yves Rivaille <pyrivail@ens-lyon.fr>
 * Copyright (c) 2002-2009, GNUstep Project
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
#import "AppController.h"
#import "DiffWindowController.h"

#include <math.h>

@implementation AppController

- (void) awakeFromNib
{
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotif
{
  NSUserDefaults *defaults;
  NSString *str;

  /* read the user preferences */
  defaults = [NSUserDefaults standardUserDefaults];
  str = [defaults stringForKey:@"CvsExecutablePath"];
  if (str == nil)
    str = @"cvs";
  cvsExecPath = str;
}


- (IBAction) compareFileToCVS: (id)sender
{
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
    
    [taskCVS setLaunchPath: cvsExecPath];
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
	RELEASE(taskCVS);
	return;
      }

    fh = [NSFileHandle fileHandleForWritingAtPath: filename2];

    if (fh == nil)
      {
	NSLog(@"aye 2");
	RELEASE(taskCVS);
	return;
      }
    [taskCVS setStandardOutput: fh];
	           
    [taskCVS launch];
    [taskCVS waitUntilExit];
    RELEASE(taskCVS);

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
    // NB The controller will be released when its window is closed
    [[DiffWindowController alloc] initWithFilename: filename1
				   andTempFilename: filename2];
  }
}

/* preference panel methods */

- (IBAction)showPrefPanel: (id)sender
{
  [prefPanel makeKeyAndOrderFront:self];
  
  [cvsPathField setStringValue:cvsExecPath];
}

- (IBAction)prefApply: (id)sender
{
  NSUserDefaults *defaults;
  NSString *str;
  
  defaults = [NSUserDefaults standardUserDefaults];
  
  str = [cvsPathField stringValue];

  if ((str != nil) && ([str length] > 0) && [[NSFileManager defaultManager] fileExistsAtPath:str])
    {
      cvsExecPath = str;
      [defaults setObject:cvsExecPath forKey:@"CvsExecutablePath"];
    }
  else
    {
      NSRunAlertPanel(@"CVS Tool not found!",
	          	   @"File %@ is invalid!",
      		        @"OK", nil, nil, str);
    }
    
  [prefPanel performClose:nil];
  [defaults synchronize];
}

- (IBAction)prefChooseCvsExec: (id)sender
{
  NSString    *file;
  NSOpenPanel *openPanel;

  openPanel = [NSOpenPanel openPanel];
  [openPanel setAllowsMultipleSelection:NO];
  [openPanel setCanChooseDirectories:NO];
  [openPanel setCanChooseFiles:YES];

  if ([openPanel runModal] == NSOKButton) 
    {
      file = [[openPanel filenames] objectAtIndex:0];
      [cvsPathField setStringValue:file];
    }
}

- (IBAction)prefCancel:(id)sender
{
  [prefPanel performClose:nil];
}

@end
