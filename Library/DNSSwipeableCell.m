//
//  DNSSwipeableCell.m
//  DNSSwipeableCell
//
//  Created by Ellen Shapiro on 12/29/13.
//  Copyright (c) 2013 Designated Nerd Software. All rights reserved.
//

#import "DNSSwipeableCell.h"

@interface DNSSwipeableCell() <UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSMutableArray *buttons;
@property (nonatomic, assign) CGPoint panStartPoint;
@property (nonatomic, assign) CGFloat startingRightLayoutConstraintConstant;
@property (nonatomic, strong) NSLayoutConstraint *contentViewRightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *contentViewLeftConstraint;

@end

@implementation DNSSwipeableCell

#pragma mark - Initialization
- (void)commonInit
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    //Setup button array
    self.buttons = [NSMutableArray array];
    
    //setup content view
    self.myContentView = [[UIView alloc] init];
    self.myContentView.userInteractionEnabled = YES;
    self.myContentView.clipsToBounds = YES;
    
    self.myContentView.backgroundColor = [UIColor whiteColor];
    self.myContentView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.contentView addSubview:self.myContentView];
    
    //Setup pan gesture recognizer
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panThisCell:)];
    panRecognizer.delegate = self;
    [self.myContentView addGestureRecognizer:panRecognizer];
    
    [self layoutIfNeeded];
}

- (id)init
{
    if (self = [super init]) {
        [self commonInit];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self commonInit];
    }
    
    return self;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self commonInit];
    }
    
    return self;
}

#pragma mark - Cell Lifecycle

- (void)updateConstraints
{
    [super updateConstraints];
    if (!self.contentViewLeftConstraint) {
        //Pin content view to left and right of screen, grab left and right constraints.
        NSDictionary *views = @{ @"myContentView" : self.myContentView };
        
        NSArray *verticalConstraints = [NSLayoutConstraint
                                        constraintsWithVisualFormat:@"V:|[myContentView]|"
                                        options:0
                                        metrics:nil
                                        views:views];
        [self.contentView addConstraints:verticalConstraints];
        
        NSArray *horizontalConstraints = [NSLayoutConstraint
                                          constraintsWithVisualFormat:@"H:|[myContentView]|"
                                          options:0
                                          metrics:0
                                          views:views];
        self.contentViewLeftConstraint = horizontalConstraints[0];
        self.contentViewRightConstraint = horizontalConstraints[1];
        
        [self.contentView addConstraints:horizontalConstraints];
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [self resetConstraintContstantsToZero:NO notifyDelegateDidClose:NO];
    
    //Reset buttons
    [self removeButtonSubviews];
}

#pragma mark - Button Config

- (void)configureButtons
{
    CGFloat previousMinX = CGRectGetWidth(self.frame);
    NSInteger buttons = [self.dataSource numberOfButtonsInSwipeableCell:self];
    for (NSInteger i = 0; i < buttons; i++) {
        UIButton *button = [self buttonForIndex:i previousButtonMinX:previousMinX];
        [self.buttons addObject:button];
        previousMinX -= CGRectGetWidth(button.frame);
        [self.contentView addSubview:button];
    }
    
    [self.contentView bringSubviewToFront:self.myContentView];
}

- (void)configureButtonsIfNeeded
{
    if (self.buttons.count == 0) {
        [self configureButtons];
    }
}

- (void)removeButtonSubviews
{
    for (UIButton *button in self.buttons) {
        [button removeFromSuperview];
    }
    
    [self.buttons removeAllObjects];
}

- (UIButton *)buttonForIndex:(NSInteger)index previousButtonMinX:(CGFloat)previousMinX
{
    UIButton *button = nil;
    
    /* The datasource implements buttonForIndex. Let's use custom buttom */
    if ([self.dataSource respondsToSelector:@selector(swipeableCell:buttonForIndex:)]) {
        
        button = [self.dataSource swipeableCell:self buttonForIndex:index];
        
        /* Lets generate the button */
    } else {
        
        button = [UIButton buttonWithType:UIButtonTypeCustom];
        
        if ([self.dataSource respondsToSelector:@selector(swipeableCell:titleForButtonAtIndex:)]) {
            //use given title
            [button setTitle:[self.dataSource swipeableCell:self titleForButtonAtIndex:index] forState:UIControlStateNormal];
        } else {
            //Default to empty title
            [button setTitle:@"" forState:UIControlStateNormal];
        }
        
        if ([self.dataSource respondsToSelector:@selector(swipeableCell:imageForButtonAtIndex:)]) {
            //Use the image, if it exists
            UIImage *iconImage = [self.dataSource swipeableCell:self imageForButtonAtIndex:index];
            if (iconImage) {
                [button setImage:[iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
            }
        }
        
        if ([self.dataSource respondsToSelector:@selector(swipeableCell:tintColorForButtonAtIndex:)]) {
            //Use the given tint color.
            button.tintColor = [self.dataSource swipeableCell:self tintColorForButtonAtIndex:index];
        } else {
            //Default to white
            button.tintColor = [UIColor whiteColor];
        }
        
        //Add 8pt of padding on the left and right.
        [button setContentEdgeInsets:UIEdgeInsetsMake(0, 8, 0, 8)];
        
        if ([self.dataSource respondsToSelector:@selector(swipeableCell:fontForButtonAtIndex:)]) {
            //Set font if provided.
            button.titleLabel.font = [self.dataSource swipeableCell:self fontForButtonAtIndex:index];
        }
        
        //Size the button to fit the contents
        [button sizeToFit];
        
        CGFloat appleRecommendedMinimumTouchPointWidth = 44.0f;
        if (button.frame.size.width < appleRecommendedMinimumTouchPointWidth) {
            CGRect frame = button.frame;
            frame.size.width = appleRecommendedMinimumTouchPointWidth;
            button.frame = frame;
        }
        
        if ([self.dataSource respondsToSelector:@selector(swipeableCell:backgroundColorForButtonAtIndex:)]) {
            //Set background color from data source
            button.backgroundColor = [self.dataSource swipeableCell:self  backgroundColorForButtonAtIndex:index];
        } else {
            //Use default colors
            if (index == 0) {
                button.backgroundColor = [UIColor redColor];
            } else {
                button.backgroundColor = [UIColor lightGrayColor];
            }
        }
    }
    
    //Update the origin and size to make sure that everything is the size it needs to be
    CGFloat xOrigin = previousMinX - CGRectGetWidth(button.frame);
    button.frame = CGRectMake(xOrigin, 0, CGRectGetWidth(button.frame), CGRectGetHeight(self.contentView.frame));
    
    //Add tap target
    [button addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    if (xOrigin < 40) {
        NSLog(@"***ATTENTION!*** Button at index %@ is going to leave less than 40 points of space! That's going to be hard to close.", @(index));
    }
    
    return button;
}

- (IBAction)buttonClicked:(id)sender
{
    if ([sender isKindOfClass:[UIButton class] ]) {
        NSInteger index = [self.buttons indexOfObject:sender];
        if (index != NSNotFound) {
            NSLog(@"Clicked button at index %@", @(index));
            [self.delegate swipeableCell:self didSelectButtonAtIndex:index];
        } else {
            NSAssert(NO, @"Index not in the list of buttons!");
        }
    } else {
        NSLog(@"NOT A BUTTON!");
    }
}

#pragma mark - Measurement convenience methods

- (CGFloat)halfOfFirstButtonWidth
{
    UIButton *firstButton = [self.buttons firstObject];
    return (CGRectGetWidth(firstButton.frame) / 2);
}

- (CGFloat)halfOfLastButtonXPosition
{
    UIButton *lastButton = [self.buttons lastObject];
    CGFloat halfOfLastButton = CGRectGetWidth(lastButton.frame) / 2;
    return [self buttonTotalWidth] - halfOfLastButton;
}

- (CGFloat)buttonTotalWidth
{
    //Add all the widths together
    CGFloat buttonWidth = 0;
    for (UIButton *button in self.buttons) {
        buttonWidth += CGRectGetWidth(button.frame);
    }
    
    return buttonWidth;
}

#pragma mark - Constraint animation

#pragma mark Public
- (void)openCell:(BOOL)animated
{
    [self configureButtonsIfNeeded];
    [self setConstraintsToShowAllButtons:animated notifyDelegateDidOpen:NO];
}

- (void)closeCell:(BOOL)animated
{
    [self configureButtonsIfNeeded];
    [self resetConstraintContstantsToZero:animated notifyDelegateDidClose:NO];
}

#pragma mark Private

- (void)setConstraintsToShowAllButtons:(BOOL)animated notifyDelegateDidOpen:(BOOL)notifyDelegate
{
    if (notifyDelegate) {
        [self.delegate swipeableCellDidOpen:self];
    }
    
    CGFloat buttonTotalWidth = [self buttonTotalWidth];
    if (self.startingRightLayoutConstraintConstant == buttonTotalWidth &&
        self.contentViewRightConstraint.constant == buttonTotalWidth) {
        //Already all the way open, no bounce necessary
        return;
    }
    
    self.contentViewLeftConstraint.constant = -buttonTotalWidth;
    self.contentViewRightConstraint.constant = buttonTotalWidth;
    
    [self updateConstraintsIfNeeded:animated completion:^(BOOL finished) {
        self.startingRightLayoutConstraintConstant = self.contentViewRightConstraint.constant;
    }];
}

- (void)resetConstraintContstantsToZero:(BOOL)animated notifyDelegateDidClose:(BOOL)notifyDelegate
{
    if (notifyDelegate) {
        [self.delegate swipeableCellDidClose:self];
    }
    if (self.startingRightLayoutConstraintConstant == 0 &&
        self.contentViewRightConstraint.constant == 0) {
        
        if (self.selectionStyle != UITableViewCellSelectionStyleNone) {
            //Remove the button subviews so they don't show through if the user selects this cell
            [self removeButtonSubviews];
        }
        
        //Already all the way closed, no bounce necessary
        return;
    }
    
    self.contentViewRightConstraint.constant = 0;
    self.contentViewLeftConstraint.constant = 0;
    [self updateConstraintsIfNeeded:animated completion:^(BOOL finished) {
        self.startingRightLayoutConstraintConstant = self.contentViewRightConstraint.constant;
        if (self.selectionStyle != UITableViewCellSelectionStyleNone) {
            //Remove the button subviews so they don't show through if the user selects this cell
            [self removeButtonSubviews];
        }
    }];
}

- (void)updateConstraintsIfNeeded:(BOOL)animated completion:(void (^)(BOOL finished))completion;
{
    float duration = 0;
    if (animated) {
        duration = 0.4;
    }
    
    [UIView animateWithDuration:duration
                          delay:0
         usingSpringWithDamping:0.6
          initialSpringVelocity:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         [self layoutIfNeeded];
                     } completion:completion];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        UIPanGestureRecognizer *panGesture = (UIPanGestureRecognizer*)gestureRecognizer;
        CGPoint velocity = [panGesture velocityInView:self.myContentView];
        if (velocity.x > 0) {
            return YES;
        } else if (fabsf(velocity.x) > fabsf(velocity.y)) {
            return NO;
        }
    }
    
    return YES;
}

#pragma mark - Gesture Recognizer target

- (void)panThisCell:(UIPanGestureRecognizer *)recognizer
{
    CGPoint currentPoint = [recognizer translationInView:self.myContentView];

    //Check what direction the swipe is moving by checking the translation
    BOOL movingHorizontally = fabsf(self.panStartPoint.y) < fabsf(self.panStartPoint.x);
    
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            self.panStartPoint = currentPoint;
            self.startingRightLayoutConstraintConstant = self.contentViewRightConstraint.constant;
            break;
        case UIGestureRecognizerStateChanged: {
            if(movingHorizontally) {
                if (!self.selected) {
                    [self configureButtonsIfNeeded];
                }
                
                // Started by moving horizontally
                CGFloat deltaX = currentPoint.x - self.panStartPoint.x;
                BOOL panningLeft = NO;
                if (currentPoint.x < self.panStartPoint.x) {
                    panningLeft = YES;
                }
                
                CGFloat adjustment = self.startingRightLayoutConstraintConstant - deltaX;
                if (!panningLeft) {
                    CGFloat constant = MAX(adjustment, 0);
                    if (constant == 0) {
                        [self resetConstraintContstantsToZero:YES notifyDelegateDidClose:NO];
                    } else {
                        self.contentViewRightConstraint.constant = constant;
                    }
                } else {
                    CGFloat constant = MIN(adjustment, [self buttonTotalWidth]);
                    if (constant == [self buttonTotalWidth]) {
                        [self setConstraintsToShowAllButtons:YES notifyDelegateDidOpen:NO];
                    } else {
                        self.contentViewRightConstraint.constant = constant;
                    }
                }
                
                self.contentViewLeftConstraint.constant = -self.contentViewRightConstraint.constant;
            }
        }
            break;
        case UIGestureRecognizerStateEnded:
            if(movingHorizontally) {
                if (self.startingRightLayoutConstraintConstant == 0) {
                    //We were opening
                    CGFloat halfWidth = [self halfOfFirstButtonWidth];
                    if (halfWidth != 0 && //Handle case where cell is already offscreen.
                        self.contentViewRightConstraint.constant >= halfWidth) {
                        //Open all the way
                        [self setConstraintsToShowAllButtons:YES notifyDelegateDidOpen:YES];
                    } else {
                        //Re-close
                        [self resetConstraintContstantsToZero:YES notifyDelegateDidClose:YES];
                    }
                } else {
                //We were closing
                    if (self.contentViewRightConstraint.constant >= [self halfOfLastButtonXPosition]) {
                        //Re-open all the way
                        [self setConstraintsToShowAllButtons:YES notifyDelegateDidOpen:YES];
                    } else {
                        //Close
                        [self resetConstraintContstantsToZero:YES notifyDelegateDidClose:YES];
                    }
                }
            }
            break;
        case UIGestureRecognizerStateCancelled:
            if(movingHorizontally) {
                // Started by moving horizontally
                if (self.startingRightLayoutConstraintConstant == 0) {
                    //We were closed - reset everything to 0
                    [self resetConstraintContstantsToZero:YES notifyDelegateDidClose:YES];
                } else {
                    //We were open - reset to the open state
                    [self setConstraintsToShowAllButtons:YES notifyDelegateDidOpen:YES];
                }
            }
            break;
            
        default:
            break;
    }
}

@end
