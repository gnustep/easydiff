/*
 * DiffMiddleView.h
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

#import <AppKit/AppKit.h>
#import "DiffTextView.h"

@interface DiffMiddleView : NSView
{
  DiffTextView *leftView;
  DiffTextView *rightView;
  NSArray *leftChanges;
  NSArray *rightChanges;
  NSMutableArray *matrixArray;
}

- (DiffTextView *)leftView;
- (void) setLeftView: (DiffTextView *)aView;

- (DiffTextView *)rightView;
- (void) setRightView: (DiffTextView *)aView;

/*
- (void) setLeftChanges: (NSArray *) anArray;
- (void) setRightChanges: (NSArray *) anArray;
*/

- (void) setLeftChanges: (NSArray *) leftArray
	andRightChanges: (NSArray *) rightArray;

- (void) tile;

- (NSArray*) matrixArray;
@end

