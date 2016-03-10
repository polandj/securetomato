/*
	Copyright (C) 2016 Jonathan Poland
*/

#include "rc.h"

void start_adblock(void) {
	xstart("/bin/adblock.sh", "cron");
}

void stop_adblock(void) {
	xstart("/bin/adblock.sh", "stop");
}

void start_adblock_wanup(void) {
	if ( nvram_match("malad_enable", "1") )
		start_adblock();
}
