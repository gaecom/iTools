
#import "TabListRowView.h"

@implementation TabListRowView

- (void)drawSelectionInRect:(NSRect)dirtyRect {
    NSColor *primaryColor = [[NSColor alternateSelectedControlColor] colorWithAlphaComponent:0.5];
    NSColor *secondarySelectedControlColor = [[NSColor secondarySelectedControlColor] colorWithAlphaComponent:0.5];
    
    // Implement our own custom alpha drawing
    switch (self.selectionHighlightStyle) {
        case NSTableViewSelectionHighlightStyleRegular: {
            if (self.selected) {
                if (self.emphasized) {
                    [primaryColor set];
                } else {
                    [secondarySelectedControlColor set];
                }
                NSRect bounds = self.bounds;
                const NSRect *rects = NULL;
                NSInteger count = 0;
                [self getRectsBeingDrawn:&rects count:&count];
                for (NSInteger i = 0; i < count; i++) {
                    NSRect rect = NSIntersectionRect(bounds, rects[i]);
                    NSRectFillUsingOperation(rect, NSCompositeSourceOver);
                }
            }
            break;
        }
        default: {
            // Do super's drawing
            [super drawSelectionInRect:dirtyRect];
            break;
        }
    }
}

- (void)drawSeparatorInRect:(NSRect)dirtyRect {
    // Draw the grid
    NSRect sepRect = self.bounds;
    sepRect.origin.y = NSMaxY(sepRect) - 1;
    sepRect.size.height = 1;
    sepRect = NSIntersectionRect(sepRect, dirtyRect);
    if (!NSIsEmptyRect(sepRect)) {
        [[NSColor lightGrayColor] set];
        NSRectFill(sepRect);
    }
}

@end
