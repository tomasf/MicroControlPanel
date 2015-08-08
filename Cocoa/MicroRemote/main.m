//
//  main.m
//  MicroRemote
//
//  Created by Tomas Franzén on Fri 2015-08-07.
//  Copyright (c) 2015 Tomas Franzén. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ORSSerialPort.h"
#import "TFPRController.h"


int main(int argc, const char * argv[]) {
	@autoreleasepool {
		TFPRController *controller = [TFPRController new];
		[controller run];
		for(;;) [[NSRunLoop currentRunLoop] run];
		
	}
    return 0;
}
