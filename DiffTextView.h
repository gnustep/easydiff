/*
 * DiffTextView.h
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


#ifndef _DIFFTEXTVIEW_H_
#define _DIFFTEXTVIEW_H_

#include <AppKit/AppKit.h>

@interface DiffTextView : NSTextView
{
@public
  NSMutableArray *colors;
  NSArray *changes;
  NSMutableArray *lineRangesArray;
  NSMutableArray *blockCharacterRangesArray;
  NSRect *blockRectsArray;
  float *separationPosition;
  float *separationDiff;
  int blockRectsArraySize;
  int blockRectsArrayFirstFree;
  int lastLine;
  int firstCharOfLastLine;
}

- (void) setChanges: (NSArray *)anArray;

//- (void) computeAllLineRanges;
- (void) computeLineRangesFromUpTo: (int) number;
- (NSRange) lineRangesForRect: (NSRect) aRect;

- (void) setLineRanges: (NSArray *) lineRanges;

- (NSArray *)lineRangesArray;

- (void) setColor: (NSColor *) aColor
  forChangeNumber: (int) number;
@end

#endif // _DIFFTEXTVIEW_H_

