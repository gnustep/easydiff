/*
 * DiffFileChooser.m
 *
 * Copyright (c) 2011, GNUstep Project
 *
 * Author:  Wolfgang Lux <wolfgang.lux@gmail.com>
 * Date: March 2011
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

#import "DiffFileChooser.h"
#import "DiffWindowController.h"
#import "FileIconView.h"

@implementation DiffFileChooser

- (void)awakeFromNib
{
  [window setExcludedFromWindowsMenu: YES];

  [[NSNotificationCenter defaultCenter]
    addObserver: self
       selector: @selector(controlTextDidChange:)
	   name: NSControlTextDidChangeNotification
	 object: leftPath];
  [[NSNotificationCenter defaultCenter]
    addObserver: self
       selector: @selector(fileIconFileNameDidChange:)
	   name: FileIconViewFileNameDidChangeNotification
	 object: leftIcon];

  [[NSNotificationCenter defaultCenter]
    addObserver: self
       selector: @selector(controlTextDidChange:)
	   name: NSControlTextDidChangeNotification
	 object: rightPath];
  [[NSNotificationCenter defaultCenter]
    addObserver: self
       selector: @selector(fileIconFileNameDidChange:)
	   name: FileIconViewFileNameDidChangeNotification
	 object: rightIcon];
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter]
    removeObserver: self
	      name: NSControlTextDidChangeNotification
	    object: leftPath];
  [[NSNotificationCenter defaultCenter]
    removeObserver: self
	      name: FileIconViewFileNameDidChangeNotification
	    object: leftIcon];
  [[NSNotificationCenter defaultCenter]
    removeObserver: self
	      name: NSControlTextDidChangeNotification
	    object: rightPath];
  [[NSNotificationCenter defaultCenter]
    removeObserver: self
	      name: FileIconViewFileNameDidChangeNotification
	    object: rightIcon];
  [super dealloc];
}

- (NSString *)leftFileName
{
  return [leftIcon fileName];
}

- (NSString *)rightFileName
{
  return [rightIcon fileName];
}

- (IBAction)showWindow: (id)sender
{
  [window makeKeyAndOrderFront: sender];
}

- (IBAction)compare: (id)sender
{
  [window orderOut: self];

  // NB The controller will be released when its window is closed
  [[DiffWindowController alloc]
    initWithFilename: [self leftFileName]
	 andFilename: [self rightFileName]];
}

- (IBAction)chooseFile: (id)sender
{
  int result;
  NSOpenPanel *openPanel;
  NSTextField *pathField;
  NSString *path;

  if (sender == leftButton)
    {
      pathField = leftPath;
    }
  else if (sender == rightButton)
    {
      pathField = rightPath;
    }
  else
    {
      return;
    }

  path = [pathField stringValue];
  if ([path length] != 0)
    {
      path = [path stringByStandardizingPath];
      path = [path stringByDeletingLastPathComponent];
    }
  else
    {
      path = nil; // this gives us the default path of the open panel
    }

  openPanel = [NSOpenPanel openPanel];
  [openPanel setAllowsMultipleSelection: NO];
  result = [openPanel runModalForDirectory: path file: nil types: nil];
  
  if (result == NSOKButton)
    {
      [pathField setStringValue: [[openPanel filenames] objectAtIndex: 0]];
      [[NSNotificationCenter defaultCenter]
	postNotificationName: NSControlTextDidChangeNotification
		      object: pathField];
    }
}

- (void)controlTextDidChange: (NSNotification *)notification
{
  BOOL ok;
  NSTextField *pathField;
  NSString *fileName;

  pathField = [notification object];
  fileName = [[pathField stringValue] stringByStandardizingPath];

  if (pathField == leftPath)
    {
      [leftIcon setFileName: fileName];
    }
  else if (pathField == rightPath)
    {
      [rightIcon setFileName: fileName];
    }

  ok = [self validateUserInterfaceItem: [compareButton cell]];
  [compareButton setEnabled: ok];
}

- (void)fileIconFileNameDidChange: (NSNotification *)notification
{
  BOOL ok;
  NSString *fileName;
  FileIconView *iconView;

  iconView = [notification object];
  fileName = [iconView fileName];

  if (iconView == leftIcon)
    {
      [leftPath setStringValue: fileName];
    }
  else if (iconView == rightIcon)
    {
      [rightPath setStringValue: fileName];
    }

  ok = [self validateUserInterfaceItem: [compareButton cell]];
  [compareButton setEnabled: ok];
}

- (BOOL)validateUserInterfaceItem: (id<NSValidatedUserInterfaceItem>)item
{
  // validate -compareFiles: action iff both paths are files
  if (sel_isEqual([item action], @selector(compareFiles:)))
    {
      BOOL isDir;
      NSString *left, *right;
      NSFileManager *fm = [NSFileManager defaultManager];

      left = [[leftPath stringValue] stringByStandardizingPath];
      right = [[rightPath stringValue] stringByStandardizingPath];
      return ([fm fileExistsAtPath: left isDirectory: &isDir] && !isDir &&
	      [fm fileExistsAtPath: right isDirectory: &isDir] && !isDir);
    }

  // validate every other item by default
  return YES;
}

@end
