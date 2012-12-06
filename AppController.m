/*
 * AppController.m
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
#import "AppController.h"
#import "DiffWindowController.h"
#import "DiffFileChooser.h"

#include <math.h>

@implementation AppController

- (void)dealloc
{
  [vcExecPaths release];
  [super dealloc];
}

- (void) awakeFromNib
{
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotif
{
  NSUserDefaults *defaults;
  NSDictionary *dict;
  Class stringClass;

  /* read the user preferences */
  defaults = [NSUserDefaults standardUserDefaults];
  dict = [defaults dictionaryForKey: @"VcExecutablePaths"];
  if (dict == nil)
    {
      vcExecPaths = [NSMutableDictionary new];
    }
  else
    {
      vcExecPaths = [dict mutableCopy];
    }

  stringClass = [NSString class];
  if (![[vcExecPaths objectForKey: @"CVS"] isKindOfClass: stringClass])
    {
      // Backward compatibility
      NSString *str = [defaults stringForKey: @"CvsExecutablePath"];
      if (str == nil)
	str = @"cvs";
      [vcExecPaths setObject: str forKey: @"CVS"];
    }
  if (![[vcExecPaths objectForKey: @"Subversion"] isKindOfClass: stringClass])
    {
      [vcExecPaths setObject: @"svn" forKey: @"Subversion"];
    }
  if (![[vcExecPaths objectForKey: @"Git"] isKindOfClass: stringClass])
    {
      [vcExecPaths setObject: @"git" forKey: @"Git"];
    }
  if (![[vcExecPaths objectForKey: @"Mercurial"] isKindOfClass: stringClass])
    {
      [vcExecPaths setObject: @"hg" forKey: @"Mercurial"];
    }
  if (![[vcExecPaths objectForKey: @"Darcs"] isKindOfClass: stringClass])
    {
      [vcExecPaths setObject: @"darcs" forKey: @"Darcs"];
    }
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
  if ([filenames count] == 2)
    {
      [diffFileChooser showWindow:self];
      [diffFileChooser setLeftFileName:[filenames objectAtIndex:0]];
      [diffFileChooser setRightFileName:[filenames objectAtIndex:1]];
    }
}

- (NSString *)getVCPath: (NSString *)fileName
{
  int i, n;
  BOOL isDir;
  NSString *vcDir, *dir;
  NSFileManager *fm;
  NSArray *vcs;

  fm = [NSFileManager defaultManager];
  dir = [fileName stringByDeletingLastPathComponent];

  // CVS (and SVN up to version 1.6) saves a meta directory in every version
  // controlled directory, hence we only need to look in the current directory
  vcDir = @"CVS";
  if ([fm fileExistsAtPath: vcDir isDirectory: &isDir] && isDir)
    return vcDir;

  // SVN (since version 1.7), git, Mercurial, and Darcs use a single meta
  // directory at the root of of a version controlled tree, hence we may
  // have to travel all the way up to the root to find that directory
  vcs = [NSArray arrayWithObjects: @".svn", @".git", @".hg", @"_darcs", nil];
  for (n = [[dir pathComponents] count]; n > 0; n--)
    {
      for (i = 0; i < [vcs count]; i++)
	{
	  vcDir = [dir stringByAppendingPathComponent: [vcs objectAtIndex: i]];
	  if ([fm fileExistsAtPath: vcDir isDirectory: &isDir] && isDir)
	    return vcDir;
	}
      dir = [dir stringByDeletingLastPathComponent];
    }

  // no VC directory found
  return nil;
}

- (IBAction)compareFileToVC: (id)sender
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
    NSTask *taskVC;
    NSString *vcPath, *vcDir, *vcFile;
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

    // determine the version control system and the root of the version
    // controlled tree
    vcPath = [self getVCPath: filename1];
    if (vcPath == nil)
      {
	NSRunAlertPanel(@"No VC system",
			@"File %@ is not under version control",
			@"OK", nil, nil, filename1);
	return;
      }
    path = [vcPath stringByDeletingLastPathComponent];
    vcFile = [filename1 substringFromIndex: [path length] + 1];

    // set up the VC task
    taskVC = [[NSTask alloc] init];
    [taskVC setCurrentDirectoryPath: path];
    vcDir = [vcPath lastPathComponent];
    if ([vcDir isEqualToString: @"CVS"])
      {
	[taskVC setLaunchPath: [vcExecPaths objectForKey: @"CVS"]];
	[taskVC setArguments:
	  [NSArray arrayWithObjects: @"update", @"-p", vcFile, nil]];
      }
    else if ([vcDir isEqualToString: @".svn"])
      {
	[taskVC setLaunchPath: [vcExecPaths objectForKey: @"Subversion"]];
	[taskVC setArguments: [NSArray arrayWithObjects: @"cat", vcFile, nil]];
      }
    else if ([vcDir isEqualToString: @".git"])
      {
	[taskVC setLaunchPath: [vcExecPaths objectForKey: @"Git"]];
	[taskVC setArguments:
	  [NSArray arrayWithObjects: @"show",
	    [@"HEAD:" stringByAppendingString: vcFile],
	    nil]];
      }
    else if ([vcDir isEqualToString: @".hg"])
      {
	[taskVC setLaunchPath: [vcExecPaths objectForKey: @"Mercurial"]];
	[taskVC setArguments: [NSArray arrayWithObjects: @"cat", vcFile, nil]];
      }
    else if ([vcDir isEqualToString: @"_darcs"])
      {
	[taskVC setLaunchPath: [vcExecPaths objectForKey: @"Darcs"]];
	[taskVC setArguments:
	  [NSArray arrayWithObjects: @"show", @"contents", vcFile, nil]];
      }
    else
      {
	NSLog(@"unsupported VC?");
	[taskVC release];
	return;
      }
    
    if ([[NSFileManager defaultManager] createFileAtPath: filename2
					contents: nil
					attributes: nil] == NO)
      {
	[taskVC release];
	return;
      }

    fh = [NSFileHandle fileHandleForWritingAtPath: filename2];

    if (fh == nil)
      {
	[taskVC release];
	return;
      }
    [taskVC setStandardOutput: fh];
	           
    [taskVC launch];
    [taskVC waitUntilExit];
    [taskVC release];

    [fh closeFile];

    if ([[[[NSFileManager defaultManager]
	   fileAttributesAtPath: filename2
	   traverseLink: NO] objectForKey: NSFileSize] intValue]
	== 0)
      {
	NSLog(@"file does not exist on VC repository");
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
  NSString *str;

  [prefPanel makeKeyAndOrderFront:self];
  str = [vcExecPaths objectForKey: [vcPopUp titleOfSelectedItem]];
  [vcPathField setStringValue: str];
}

- (IBAction)prefApply: (id)sender
{
  NSUserDefaults *defaults;
  NSString *str;
  
  defaults = [NSUserDefaults standardUserDefaults];
  
  str = [vcPathField stringValue];

  if ((str != nil) && ([str length] > 0)
    && [[NSFileManager defaultManager] fileExistsAtPath:str])
    {
      [vcExecPaths setObject: str forKey: [vcPopUp titleOfSelectedItem]];
      [defaults setObject: vcExecPaths forKey: @"VcExecutablePaths"];
    }
  else
    {
      NSRunAlertPanel(@"VC Tool not found!",
		      @"File %@ is invalid!",
		      @"OK", nil, nil, str);
    }
    
  [prefPanel performClose:nil];
  [defaults synchronize];
}

- (IBAction)prefChooseVC: (id)sender
{
  NSString *str;
  
  str = [vcExecPaths objectForKey: [vcPopUp titleOfSelectedItem]];
  [vcPathField setStringValue:str];
 }

- (IBAction)prefChooseVCExec: (id)sender
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
      [vcPathField setStringValue:file];
    }
}

- (IBAction)prefCancel:(id)sender
{
  [prefPanel performClose:nil];
}

@end
