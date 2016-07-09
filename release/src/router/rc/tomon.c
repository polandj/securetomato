/*
	Copyright (C) 2016 Jonathan Poland
*/

#include "rc.h"

void start_tomon(void) {
	if( !nvram_match( "tomon_enable", "1" ) ) return;
	xstart("tomon");
}

void stop_tomon(void) {
	killall("tomon", SIGTERM);
}
