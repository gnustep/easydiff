/*
 * DiffWrapper.h
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

#ifndef __DIFFWRAPPER_H
#define __DIFFWRAPPER_H

#include <Foundation/Foundation.h>

@interface DiffWrapper : NSObject
{
  NSString *filename1;
  NSString *filename2;
  NSMutableArray *rightChanges;
  NSMutableArray *leftChanges;
  NSString *leftString;
  NSString *rightString;
  NSMutableArray *leftLineRangesArray;
  NSMutableArray *rightLineRangesArray;
}

- (id) initWithFilename: (NSString *) file1
	    andFilename: (NSString *) file2;

- (void) compare;

- (void) alternateCompare;

- (NSArray *) leftChanges;
- (NSArray *) rightChanges;

- (NSString *) leftString;
- (NSString *) rightString;

- (NSArray *) leftLineRanges;
- (NSArray *) rightLineRanges;
@end

#endif

