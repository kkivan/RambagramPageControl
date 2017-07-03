// Copyright (c) 2017 RAMBLER&Co
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "RambagramFlowLayout.h"

@implementation RambagramFlowLayout

- (CGFloat)step {
    return self.itemSize.width + self.minimumLineSpacing;
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray<UICollectionViewLayoutAttributes *> *layoutAttributes = [super layoutAttributesForElementsInRect:rect];
    if (self.ignoreScale) {
        return layoutAttributes;
    }

    NSMutableArray *transformedAttributesArray = [NSMutableArray array];
    
    for (UICollectionViewLayoutAttributes *attributes in layoutAttributes) {
        UICollectionViewLayoutAttributes *transformedAttributes = [self transformedAttributes:attributes];
        [transformedAttributesArray addObject:transformedAttributes];
    }

    return transformedAttributesArray;
}

- (CGSize)collectionViewContentSize {
    CGFloat offset = 2 * [self step];
    
    NSUInteger numberOfItems = [self.collectionView numberOfItemsInSection:0];
    CGFloat contentWidth = offset + numberOfItems * [self step] + offset;
    CGFloat contentHeight = self.itemSize.height;
    return CGSizeMake(contentWidth,
                      contentHeight);
}

- (UICollectionViewLayoutAttributes *)transformedAttributes:(UICollectionViewLayoutAttributes *)attributes {
    
    attributes = [attributes copy];
    
    CGFloat offset = 2 * [self step] + self.itemSize.width / 2;
    CGFloat contentOffset = self.collectionView.contentOffset.x;
    CGFloat normalizedCenter = attributes.center.x - contentOffset;
    
    CGFloat scale = 1;
    CGFloat shift = offset + 2.0 * [self step];

    if (normalizedCenter < offset) {
        // increasing
        scale = normalizedCenter / offset;
    } else if (normalizedCenter < shift) {
        // plateu
        scale = 1.0;
    } else {
        // decreasing
        CGFloat diff = normalizedCenter - shift;
        scale = fabs(1 - diff / offset);
    }
    
    scale = MAX(scale, 0.35);

    scale = MIN(scale * 1.2, 1.0);

    attributes.transform3D = CATransform3DScale(CATransform3DIdentity,
                                                scale,
                                                scale,
                                                1);
    return attributes;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset
                                 withScrollingVelocity:(CGPoint)velocity {
    
    CGFloat proposedContentOffsetCenterX = proposedContentOffset.x + self.collectionView.bounds.size.width * 0.5f;
    
    CGRect proposedRect = self.collectionView.bounds;
    
    NSArray *layoutAttributes = [self layoutAttributesForElementsInRect:proposedRect];
    
    UICollectionViewLayoutAttributes* itemToScroll;
    for (UICollectionViewLayoutAttributes* attributes in layoutAttributes) {
        if(!itemToScroll) {
            itemToScroll = attributes;
            continue;
        }
        BOOL isCloserToCenter = fabs(attributes.center.x - proposedContentOffsetCenterX) < fabs(itemToScroll.center.x - proposedContentOffsetCenterX);
        if (isCloserToCenter) {
            itemToScroll = attributes;
        }
    }

    CGPoint targetContentOffset = CGPointMake(itemToScroll.center.x - self.collectionView.bounds.size.width * 0.5f,
                                              proposedContentOffset.y);

    targetContentOffset.x = floor(targetContentOffset.x);
    targetContentOffset.y = floor(targetContentOffset.y);
    return targetContentOffset;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}

@end
