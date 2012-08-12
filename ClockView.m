// ClockView.m -- screensaver view that shows an analog clock
// Mac OS X port Copyright (C) 2006 Michael Schmidt <mschmidt.github@gmail.com>.
//
// ClockSaver is derived from the KDE screensaver module KClock.
// KDE's KClock is Copyright (C) 2003 Melchior Franz <mfranz@kde.org>.
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License Version 2 as
// published by the Free Software Foundation.


#import "ClockView.h"


// Extract a color object from the defaults
#define COLOR(N)  ((NSColor*)[NSUnarchiver unarchiveObjectWithData: [sharedDefaults objectForKey:(N)]])


// Key constants
#define csHourColor       @"hourColor"
#define csMinuteColor     @"minuteColor"
#define csSecondColor     @"secondColor"
#define csScaleColor      @"scaleColor"
#define csShadowColor     @"shadowColor"
#define csBackgroundColor @"backgroundColor"
#define csScaleSize       @"scaleSize"
#define csShowSecondHand  @"showSecondHand"



static ScreenSaverDefaults __strong *sharedDefaults = nil;



@interface ClockView (DrawingPrimitives)

- (void)computeBaseTransformForFrame:(NSRect)frame;

- (void)drawRadialAtAngle:(CGFloat)alpha r0:(CGFloat)r0 r1:(CGFloat)r1 width:(CGFloat)width;
- (void)drawDiscWithRadius:(CGFloat)radius;
- (void)drawHandAtAngle:(CGFloat)angle length:(CGFloat)length width:(CGFloat)width color:(NSColor*)color disc:(BOOL)disc;
- (void)drawScale;

@end



@implementation ClockView



+ (void)initialize
{
    static dispatch_once_t pred;

    dispatch_once (&pred, ^{

        sharedDefaults = [ScreenSaverDefaults defaultsForModuleWithName: [[NSBundle bundleForClass: [self class]] bundleIdentifier]];

        [sharedDefaults registerDefaults:
                @{csHourColor:       [NSArchiver archivedDataWithRootObject: [NSColor whiteColor]],
                  csMinuteColor:     [NSArchiver archivedDataWithRootObject: [NSColor whiteColor]],
                  csSecondColor:     [NSArchiver archivedDataWithRootObject: [NSColor redColor]],
                  csScaleColor:      [NSArchiver archivedDataWithRootObject: [NSColor whiteColor]],
                  csShadowColor:     [NSArchiver archivedDataWithRootObject: [NSColor grayColor]],
                  csBackgroundColor: [NSArchiver archivedDataWithRootObject: [NSColor blackColor]],
                  csScaleSize:       @0.90f,
                  csShowSecondHand:  @YES}];
    });
}



- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    if ((self = [super initWithFrame:frame isPreview:isPreview]))
    {
        defaults       = [[NSMutableDictionary alloc] init];
        baseTransform  = nil;

        [self setAnimationTimeInterval: 1.0];
        [self computeBaseTransformForFrame: frame];
    }

    return self;
}



- (BOOL)hasConfigureSheet
{
    return YES;
}



- (NSWindow*)configureSheet
{
    if (configureSheet == nil)
        [NSBundle loadNibNamed:@"configure" owner:self];

    for (id key in @[csHourColor,
                     csMinuteColor,
                     csSecondColor,
                     csScaleColor,
                     csShadowColor,
                     csBackgroundColor,
                     csScaleSize,
                     csShowSecondHand])
        [defaults setValue: [sharedDefaults valueForKey:key] forKey:key];

    return configureSheet;
}



- (IBAction)performOK:(id)sender
{
    [NSApp endSheet: configureSheet];

    for (id key in [defaults allKeys])
        [sharedDefaults setValue:[defaults valueForKey:key] forKey:key];

    [sharedDefaults synchronize];

    [self computeBaseTransformForFrame: [self frame]];
}



- (IBAction)performCancel:(id)sender
{
    [NSApp endSheet: configureSheet];
}



#pragma mark -
#pragma mark Drawing Routines



// Basic transformation matrix for drawing operations
- (void)computeBaseTransformForFrame:(NSRect)frame
{
    baseTransform = [NSAffineTransform transform];

    // Move square of clock area to center of screen
    CGFloat minSize = min (frame.size.width, frame.size.height);

    minSize *= [sharedDefaults floatForKey:csScaleSize];

    [baseTransform translateXBy: (frame.size.width  - minSize) / 2.0
                            yBy: (frame.size.height - minSize) / 2.0];

    // Scale to width/height of 2000
    [baseTransform scaleXBy: minSize / 2000.0
                        yBy: minSize / 2000.0];

    // Origin is in center of screen
    [baseTransform translateXBy: 1000.0
                            yBy: 1000.0];
}


- (void)animateOneFrame
{
    NSCalendarDate *now = [NSCalendarDate calendarDate];

    // Blank screen
    [COLOR(csBackgroundColor) set];
    NSRectFill ([self bounds]);

    // Draw clock
    [self drawScale];

    [self drawHandAtAngle: ([now hourOfDay] % 12) * 30.0 + [now minuteOfHour] * 0.5
                   length: 600.0
                    width: 55.0
                    color: COLOR(csHourColor)
                     disc: NO];

    [self drawHandAtAngle: [now minuteOfHour] * 6.0 + [now secondOfMinute] * 0.1
                   length: 900.0
                    width: 40.0
                    color: COLOR(csMinuteColor)
                     disc: YES];

    if ([sharedDefaults boolForKey:csShowSecondHand])
        [self drawHandAtAngle: [now secondOfMinute] * 6.0
                       length: 900.0
                        width: 30.0
                        color: COLOR(csSecondColor)
                         disc: YES];
}



// Draws a radial line segment (clock hands and scale)
- (void)drawRadialAtAngle:(CGFloat)alpha r0:(CGFloat)r0 r1:(CGFloat)r1 width:(CGFloat)width
{
    // Transform screen coordinates
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform appendTransform:baseTransform];
    [transform rotateByDegrees: 90-alpha];

    // Draw a line
    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    NSBezierPath *path         = [NSBezierPath bezierPath];

    [context saveGraphicsState];
    [transform concat];

    [path setLineWidth: width];
    [path moveToPoint: NSMakePoint (r0, 0.0)];
    [path lineToPoint: NSMakePoint (r1, 0.0)];
    [path stroke];

    [context restoreGraphicsState];
}



// Draws a circle located at the origin (part of minuts and second hand)
- (void)drawDiscWithRadius:(CGFloat)radius
{
    // Transform screen coordinates
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform appendTransform:baseTransform];

    // Draw a circle
    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    NSBezierPath *path         = [NSBezierPath bezierPath];

    [context saveGraphicsState];
    [transform concat];

    [path appendBezierPathWithArcWithCenter: NSZeroPoint
                                     radius: radius
                                 startAngle: 0.0
                                   endAngle: 360.0];
    [path fill];

    [context restoreGraphicsState];
}



// Draws a clock hand with certain attributes
- (void)drawHandAtAngle: (CGFloat)angle
                 length: (CGFloat)length
                  width: (CGFloat)width
                  color: (NSColor*)color
                   disc: (BOOL)disc
{
    CGFloat shadowWidth = 1.0;

    // Draw shadow for hand
    [COLOR(csShadowColor) set];

    if (disc)
        [self drawDiscWithRadius: width * 1.3 + shadowWidth];

    [self drawRadialAtAngle: angle
                         r0: 0.75 * width
                         r1: length + shadowWidth
                      width: width  + shadowWidth];

    // Draw hand itself
    [color set];

    if (disc)
        [self drawDiscWithRadius: width * 1.3];

    [self drawRadialAtAngle: angle
                         r0: 0.75 * width
                         r1: length
                      width: width];
}



// Draws the clock scale
- (void)drawScale
{
    [COLOR(csScaleColor) set];
    int angle;

    // For each minute...
    for (angle = 0; angle < 360; angle += 6)
    {
        if (angle % 30)
            [self drawRadialAtAngle: angle
                                 r0: 920.0
                                 r1: 980.0
                              width: 15.0];
        else
            [self drawRadialAtAngle: angle
                                 r0: 825.0
                                 r1: 980.0
                              width: 40.0];
    }
}

@end