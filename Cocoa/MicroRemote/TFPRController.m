//
//  TFPRController.m
//  MicroRemote
//
//  Created by Tomas Franzén on Fri 2015-08-07.
//  Copyright (c) 2015 Tomas Franzén. All rights reserved.
//

#import "TFPRController.h"
#import "ORSSerialPort.h"

@interface TFPRController () <ORSSerialPortDelegate>
@property ORSSerialPort *serialPort;
@property NSMutableData *incomingData;

@property int8_t activeButton;
@property int8_t lastState;

@property NSAppleScript *checkStageScript;
@property NSAppleScript *raiseScript;
@property NSAppleScript *retractScript;
@property NSAppleScript *extrudeScript;
@property NSAppleScript *stopScript;
@end


typedef NS_ENUM(NSUInteger, TFPOperationStage) {
	TFPOperationStageIdle = 'idle',
	TFPOperationStagePreparation = 'prep',
	TFPOperationStageRunning = 'rung',
	TFPOperationStageEnding = 'endg',
};


@implementation TFPRController


- (void)run {
	self.serialPort = [ORSSerialPort serialPortWithPath:@"/dev/tty.usbmodem1421"];
	self.serialPort.delegate = self;
	[self.serialPort open];
	
	self.incomingData = [NSMutableData new];
	
	NSString *checkStageString =
	@"tell app \"MicroPrint\" \n"
	"the current operation stage of printer 1 \n"
	"end tell";
	self.checkStageScript = [[NSAppleScript alloc] initWithSource:checkStageString];
	
	NSString *startRaiseString =
	@"tell app \"MicroPrint\" \n"
	"tell printer 1 to raise print head \n"
	"end tell";
	self.raiseScript = [[NSAppleScript alloc] initWithSource:startRaiseString];
	
	NSString *startRetractString =
	@"tell app \"MicroPrint\" \n"
	"tell printer 1 to retract filament \n"
	"end tell";
	self.retractScript = [[NSAppleScript alloc] initWithSource:startRetractString];
	
	NSString *startExtrudeString =
	@"tell app \"MicroPrint\" \n"
	"tell printer 1 to extrude filament \n"
	"end tell";
	self.extrudeScript = [[NSAppleScript alloc] initWithSource:startExtrudeString];
	
	NSString *stopString =
	@"tell app \"MicroPrint\" \n"
	"tell printer 1 to stop operation \n"
	"end tell";
	self.stopScript = [[NSAppleScript alloc] initWithSource:stopString];
	
	[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(refreshState:) userInfo:nil repeats:YES];
}


- (void)setMode:(uint8_t)mode forLEDAtIndex:(uint8_t)index {
	if(self.lastState != mode) {
		NSString *string = [NSString stringWithFormat:@"l%hhu%hhu",index,mode];
		[self.serialPort sendData:[string dataUsingEncoding:NSUTF8StringEncoding]];
		self.lastState = mode;
	}
}


- (void)serialPortWasOpened:(ORSSerialPort * __nonnull)serialPort {
	[self setMode:0 forLEDAtIndex:0];
}


- (void)serialPort:(ORSSerialPort * __nonnull)serialPort didReceiveData:(NSData * __nonnull)data {
	[self.incomingData appendData:data];
	while(self.incomingData.length >= 2) {
		NSData *packet = [self.incomingData subdataWithRange:NSMakeRange(0, 2)];
		[self.incomingData replaceBytesInRange:NSMakeRange(0, 2) withBytes:NULL length:0];
		
		uint8_t command = ((uint8_t*)(packet.bytes))[0];
		uint8_t value = ((uint8_t*)(packet.bytes))[1];
		
		if(command == 'b') {
			[self buttonWasPressed:value-'0'];
		}
	}
}


- (TFPOperationStage)currentStage {
	NSAppleEventDescriptor *descriptor = [self.checkStageScript executeAndReturnError:NULL];
	return descriptor.enumCodeValue;
}


- (void)startOperationForButtonIndex:(uint8_t)index {
	switch(index) {
		case 0:
			[self.retractScript executeAndReturnError:NULL];
			break;
		case 1:
			[self.extrudeScript executeAndReturnError:NULL];
			break;
		case 2:
			[self.raiseScript executeAndReturnError:NULL];
			break;
	}
	self.activeButton = index;
}


- (void)stopOperationForButtonIndex:(uint8_t)index {
	[self.stopScript executeAndReturnError:NULL];
}


- (void)refreshState:(NSTimer*)timer {
	if(self.activeButton < 0) {
		return;
	}
	
	TFPOperationStage stage = [self currentStage];
	switch(stage) {
		case TFPOperationStageIdle:
			[self setMode:0 forLEDAtIndex:self.activeButton];
			self.activeButton = -1;
			self.lastState = -1;
			break;
			
		case TFPOperationStagePreparation:
			[self setMode:2 forLEDAtIndex:self.activeButton];
			break;
			
		case TFPOperationStageRunning:
			[self setMode:1 forLEDAtIndex:self.activeButton];
			break;
			
		case TFPOperationStageEnding:
			[self setMode:2 forLEDAtIndex:self.activeButton];
			break;
	}
}


- (void)buttonWasPressed:(uint8_t)index {
	switch([self currentStage]) {
		case TFPOperationStageIdle:
			[self startOperationForButtonIndex:index];
			break;
		case TFPOperationStagePreparation:
		case TFPOperationStageRunning:
			[self stopOperationForButtonIndex:index];
			break;
			
		case TFPOperationStageEnding:
			break;
	}
	[self refreshState:nil];
	//NSString *stage = CFBridgingRelease(UTCreateStringForOSType([self currentStage]));
	//NSLog(@"%@",stage);
}


- (void)serialPortWasRemovedFromSystem:(ORSSerialPort * __nonnull)serialPort {
	
}


@end
