/*
 * AppController.h
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

#ifndef __APPCONTROLLER_H
#define __APPCONTROLLER_H

#include <AppKit/AppKit.h>

@interface AppController : NSObject
{
  NSString *cvsExecPath;
  
  IBOutlet NSPanel *prefPanel;
  IBOutlet NSTextField *cvsPathField;
}

- (IBAction) compareFiles: (id)sender;
- (IBAction) compareFileToCVS: (id)sender;

- (IBAction)showPrefPanel: (id)sender;
- (IBAction)prefApply: (id)sender;
- (IBAction)prefCancel: (id)sender;
- (IBAction)prefChooseCvsExec: (id)sender;

@end

#endif

