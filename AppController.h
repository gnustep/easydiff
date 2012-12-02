/*
 * AppController.h
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

@class DiffFileChooser;

@interface AppController : NSObject
{
  NSMutableDictionary *vcExecPaths;

  IBOutlet DiffFileChooser *diffFileChooser;
  
  IBOutlet NSPanel *prefPanel;
  IBOutlet NSPopUpButton *vcPopUp;
  IBOutlet NSTextField *vcPathField;
}

- (IBAction)compareFileToVC: (id)sender;

- (IBAction)showPrefPanel: (id)sender;
- (IBAction)prefApply: (id)sender;
- (IBAction)prefCancel: (id)sender;
- (IBAction)prefChooseVC: (id)sender;
- (IBAction)prefChooseVCExec: (id)sender;

@end

