/*
 * FileIconView.m
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

#import "FileIconView.h"

@implementation FileIconView

- (void)dealloc
{
  RELEASE(fileName);
  [super dealloc];
}

- (void)awakeFromNib
{
  NSArray *types = [NSArray arrayWithObject: NSFilenamesPboardType];
  [self registerForDraggedTypes: types];
}

- (NSString *)fileName
{
  return fileName;
}

- (void)setFileName: (NSString *)aFileName
{
  ASSIGNCOPY(fileName, aFileName);
  if ([[NSFileManager defaultManager] fileExistsAtPath: fileName])
    {
      [self setImage: [[NSWorkspace sharedWorkspace] iconForFile: fileName]];
    }
  else
    {
      [self setImage: nil];
    }
}

// Drag source methods
- (void)mouseDown: (NSEvent *)theEvent
{
  if ([self image] != nil)
    {
      [self dragFile: [self fileName]
	    fromRect: [self bounds]
	   slideBack: YES
	       event: theEvent];
    }
}

// Drag destination methods
- (NSDragOperation)draggingEntered: (id <NSDraggingInfo>)sender
{
  NSPasteboard *pboard = [sender draggingPasteboard];
  NSArray *types = [pboard types];

  if ([types containsObject: NSFilenamesPboardType])
    {
      if ([[pboard propertyListForType: NSFilenamesPboardType] count] == 1)
	{
	  return [sender draggingSourceOperationMask];
	}
    }
  else if ([types containsObject: NSURLPboardType])
    {
      if ([[NSURL URLFromPasteboard: pboard] isFileURL])
	{
	  return [sender draggingSourceOperationMask];
	}
    }

  return NSDragOperationNone;
}

- (BOOL)prepareForDragOperation: (id <NSDraggingInfo>)sender
{
  return YES;
}

- (BOOL)performDragOperation: (id <NSDraggingInfo>)sender
{
  NSString *name;
  NSPasteboard *pboard = [sender draggingPasteboard];
  NSArray *types = [pboard types];

  if ([types containsObject: NSFilenamesPboardType])
    {
      // If we get here we know that the pasteboard contains exactly one file
      // (cf. -draggingEntered: above)
      NSArray *files = [pboard propertyListForType: NSFilenamesPboardType];
      name = [files objectAtIndex: 0];
    }
  else if ([types containsObject: NSURLPboardType])
    {
      // If we get here we know that the pasteboard contains a file URL
      name = [[NSURL URLFromPasteboard: pboard] path];
    }
  else
    {
      // We shouldn't ever get here
      NSLog(@"Unexpected pasteboard contents");
      name = nil;
    }

  [self setFileName:name];
  [[NSNotificationCenter defaultCenter]
    postNotificationName: FileIconViewFileNameDidChangeNotification
		  object: self];
  return YES;
}

@end

NSString *FileIconViewFileNameDidChangeNotification =
  @"FileIconViewFileNameDidChangeNotification";
