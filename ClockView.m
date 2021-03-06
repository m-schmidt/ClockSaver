// ClockView.m
// Screensaver view that shows an analog clock
//
// OS X port Copyright (C) 2006-2018 Michael Schmidt <github@mschmidt.me>.
//
// ClockSaver is derived from the KDE screensaver module KClock.
// KDE's KClock is Copyright (C) 2003 Melchior Franz <mfranz@kde.org>.
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License Version 2 as
// published by the Free Software Foundation.


#import "ClockView.h"


// Keys for UserDefaults
#define csHourColor       @"hourColor"
#define csMinuteColor     @"minuteColor"
#define csSecondColor     @"secondColor"
#define csScaleColor      @"scaleColor"
#define csScaleSize       @"scaleSize"
#define csShowSecondHand  @"showSecondHand"


static ScreenSaverDefaults __strong *sharedDefaults = nil;


@implementation ClockView

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {

    if ((self = [super initWithFrame:frame isPreview:isPreview])) {

        self.animationTimeInterval = 1.0;
        [self registerUserDefaults];
        [self resetConfiguration];
        [self computeBaseTransformForFrame:frame];
    }

    return self;
}


- (void)registerUserDefaults {

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        sharedDefaults = [ScreenSaverDefaults defaultsForModuleWithName:[NSBundle bundleForClass:[self class]].bundleIdentifier];
        [sharedDefaults registerDefaults:
         @{csScaleColor:     [self encodedColor:[NSColor whiteColor]],
           csScaleSize:      @0.90f,
           csHourColor:      [self encodedColor:[NSColor whiteColor]],
           csMinuteColor:    [self encodedColor:[NSColor whiteColor]],
           csSecondColor:    [self encodedColor:[NSColor redColor]],
           csShowSecondHand: @YES}];
    });
}


#pragma mark - Configuration Sheet


- (BOOL)hasConfigureSheet {

    return YES;
}


- (void)resetConfiguration {

    scaleColor  = [self decodedColor:[sharedDefaults valueForKey:csScaleColor]];
    hourColor   = [self decodedColor:[sharedDefaults valueForKey:csHourColor]];
    minuteColor = [self decodedColor:[sharedDefaults valueForKey:csMinuteColor]];
    secondColor = [self decodedColor:[sharedDefaults valueForKey:csSecondColor]];

    scaleSize      = [sharedDefaults doubleForKey:csScaleSize];
    showSecondHand = [sharedDefaults boolForKey:csShowSecondHand];
}


- (void)saveConfiguration {

    [sharedDefaults setValue:[self encodedColor:scaleColor]  forKey:csScaleColor];
    [sharedDefaults setValue:[self encodedColor:hourColor]   forKey:csHourColor];
    [sharedDefaults setValue:[self encodedColor:minuteColor] forKey:csMinuteColor];
    [sharedDefaults setValue:[self encodedColor:secondColor] forKey:csSecondColor];

    [sharedDefaults setDouble:scaleSize forKey:csScaleSize];
    [sharedDefaults setBool:showSecondHand forKey:csShowSecondHand];

    [sharedDefaults synchronize];
}


- (NSWindow *)configureSheet {

    if (self.configSheet == nil) {
       [[NSBundle bundleForClass:[self class]] loadNibNamed:@"configureSheet" owner:self topLevelObjects:nil];
    }
    return self.configSheet;
}


- (IBAction)performOK:(id)sender {

    [NSApp endSheet:self.configureSheet];
    [self saveConfiguration];
    [self computeBaseTransformForFrame:self.frame];
}


- (IBAction)performCancel:(id)sender {

    [NSApp endSheet:self.configureSheet];
    [self resetConfiguration];
}


#pragma mark - Encoding of Colors for UserPreferences


- (id)encodedColor:(NSColor *)color {

    return [NSKeyedArchiver archivedDataWithRootObject:color requiringSecureCoding:YES error:NULL];
}


- (NSColor *)decodedColor:(id)data {

    NSColor *color = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSColor class] fromData:data error:NULL];

    if (color == nil) {
        color = [NSColor whiteColor];
    }
    return color;
}


#pragma mark - Drawing Routines


// Basic transformation matrix for drawing operations
- (void)computeBaseTransformForFrame:(NSRect)frame {

    baseTransform = [NSAffineTransform transform];

    // Move square of clock area to center of screen
    CGFloat minSize = min (frame.size.width, frame.size.height) * scaleSize;
    [baseTransform translateXBy:(frame.size.width  - minSize) / 2.0
                            yBy:(frame.size.height - minSize) / 2.0];

    // Scale to width/height of 2000
    [baseTransform scaleXBy:minSize / 2000.0
                        yBy:minSize / 2000.0];

    // Origin is in center of screen
    [baseTransform translateXBy:1000.0
                            yBy:1000.0];
}


- (void)animateOneFrame {

    [self setNeedsDisplay:YES];
}


- (void)drawRect:(NSRect)rect {

    // Get current time
    NSCalendarUnit components = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents *now = [[NSCalendar currentCalendar] components:components fromDate:[NSDate date]];

    // Blank screen
    [[NSColor blackColor] set];
    NSRectFill (rect);

    // Draw clock face
    [self drawScaleWithColor:scaleColor];

    [self drawHandAtAngle:([now hour] % 12) * 30.0 + [now minute] * 0.5
                   length:600.0
                    width:55.0
                    color:hourColor
                     disc:NO];

    [self drawHandAtAngle:[now minute] * 6.0 + [now second] * 0.1
                   length:900.0
                    width:40.0
                    color:minuteColor
                     disc:YES];

    if (showSecondHand)
        [self drawHandAtAngle:[now second] * 6.0
                       length:900.0
                        width:30.0
                        color:secondColor
                         disc:YES];
}


// Draws a radial line segment (clock hands and scale)
- (void)drawRadialAtAngle:(CGFloat)alpha r0:(CGFloat)r0 r1:(CGFloat)r1 width:(CGFloat)width {

    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    [context saveGraphicsState];

    // Rotate screen
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform appendTransform:baseTransform];
    [transform rotateByDegrees:90 - alpha];
    [transform concat];

    // Draw line segment
    NSBezierPath *path = [NSBezierPath bezierPath];
    path.lineWidth = width;
    [path moveToPoint:NSMakePoint (r0, 0.0)];
    [path lineToPoint:NSMakePoint (r1, 0.0)];
    [path stroke];

    [context restoreGraphicsState];
}


// Draws a circle located at the origin (part of minuts and second hand)
- (void)drawDiscWithRadius:(CGFloat)radius {

    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    [context saveGraphicsState];

    // Move to center of screen
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform appendTransform:baseTransform];
    [transform concat];

    // Draw a circle
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path appendBezierPathWithArcWithCenter:NSZeroPoint radius:radius startAngle:0.0 endAngle:360.0];
    [path fill];

    [context restoreGraphicsState];
}


// Draws a clock hand with certain attributes
- (void)drawHandAtAngle:(CGFloat)angle
                 length:(CGFloat)length
                  width:(CGFloat)width
                  color:(NSColor *)color
                   disc:(BOOL)disc {

    CGFloat shadowWidth = 1.0;

    // Draw shadow for hand
    [[NSColor grayColor] set];

    if (disc) {
        [self drawDiscWithRadius:width * 1.3 + shadowWidth];
    }

    [self drawRadialAtAngle:angle r0:0.75 * width r1:length + shadowWidth width:width  + shadowWidth];

    // Draw hand itself
    [color set];

    if (disc) {
        [self drawDiscWithRadius:width * 1.3];
    }

    [self drawRadialAtAngle:angle r0:0.75 * width r1:length width:width];
}


// Draws the clock scale
- (void)drawScaleWithColor:(NSColor *)color {

    [color set];

    // For each minute...
    for (int angle = 0; angle < 360; angle += 6) {
        if (angle % 30) {
            [self drawRadialAtAngle:angle r0:920.0 r1:980.0 width:15.0];
        }
        else {
            [self drawRadialAtAngle:angle r0:825.0 r1:980.0 width:40.0];
        }
    }
}

@end
