// ClockView.h
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


#import <ScreenSaver/ScreenSaver.h>


@interface ClockView : ScreenSaverView
{
    NSAffineTransform *baseTransform;

    NSColor *scaleColor;
    NSColor *hourColor;
    NSColor *minuteColor;
    NSColor *secondColor;

    CGFloat scaleSize;
    BOOL showSecondHand;
}

@property (strong, nonatomic) IBOutlet NSWindow *configSheet;

- (IBAction)performOK:(id)sender;
- (IBAction)performCancel:(id)sender;

@end
