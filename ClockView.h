// ClockView.h -- screensaver view that shows an analog clock
// Mac OS X port Copyright (C) 2006 Michael Schmidt <no.more.spam@gmx.net>.
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
    IBOutlet NSWindow   *configureSheet;

    NSMutableDictionary *defaults;
    NSAffineTransform   *baseTransform;
}

- (IBAction)performOK:(id)sender;
- (IBAction)performCancel:(id)sender;

@end
