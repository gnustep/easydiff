/*
 * DiffView.h
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
#import "DiffView.h"
#import "DiffTextView.h"
#import "DiffMiddleView.h"
#import "DiffScroller.h"

@interface DiffView: NSView
{
  NSScrollView *leftView;
  NSScrollView *rightView;
  DiffTextView *leftTextView;
  DiffTextView *rightTextView;
  DiffMiddleView *middleView;

  float mergeFileHeight;
  NSMutableArray *leftScrollingPoint;
  NSMutableArray *rightScrollingPoint;
  NSMutableArray *mergedScrollingPoint;
  DiffScroller *scroller;
  float *lSP;
  float *rSP;
  float *mSP;

  BOOL _scrolling;
}

- (void) tile;


- (void) setLeftString: (NSString *) aString;
- (void) setRightString: (NSString *) aString;


- (void) setLeftChanges: (NSArray *) leftArray
	andRightChanges: (NSArray *) rightArray;

- (void) setLeftLineRanges: (NSArray *) leftLineRanges
	andRightLineRanges: (NSArray *) rightLineRanges;

- (float) mergeFileHeight;

- (void) computeScrollerSize;
- (void) doScroll: (id) sender;

- (DiffTextView *) leftTextView;
- (DiffTextView *) rightTextView;

- (DiffMiddleView *) middleView;
@end

