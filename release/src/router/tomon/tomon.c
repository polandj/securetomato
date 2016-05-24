/*
   CREATE TABLE notifications (id INTEGER PRIMARY KEY, tstamp_first TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL, tstamp_last TIMESTAMP CURRENT_TIMESTAMP NOT NULL, tstamp_email_last_sent TIMESTAMP, plug UNIQUE NOT NULL, content NOT NULL, status TEXT CHECK (status IN ('N', 'R', 'I')) NOT NULL DEFAULT 'N');
   
   sqlite> select * from notifications;
   1|2016-04-28 18:14:57|2016-04-29 02:44:22|2016-04-28 18:14:59|Web Username|The web is using the default username, please change it|N
   2|2016-04-28 18:14:59|2016-04-29 02:44:22|2016-04-28 18:15:00|Web Root|Root login is enabled, please disable it|N
   3|2016-04-28 18:15:00|2016-04-29 02:44:22|2016-04-28 18:15:01|SSH Remote|SSH remote management is enabled|N
   4|2016-04-28 18:15:01|2016-04-29 02:44:22|2016-04-28 18:15:02|SSH Password|SSH allows password login, disable this and use keys|N
   5|2016-04-28 18:15:02|2016-04-29 02:44:22|2016-04-28 19:29:25|Web Insecure Remote|Remote management is enabled via HTTP.  Change this!|N
   6|2016-04-28 19:26:01|2016-04-29 02:38:13|2016-04-28 19:26:03|New DHCP lease to unknown device: f8:cf:c5:1e:22:63|New DHCP lease, 172.28.28.243, to unknown host with MAC f8:cf:c5:1e:22:63[android-c58abbd80fb72664]
   |N

   '<[0-9]+>([a-zA-Z]+[ ]+[0-9]+[ ]+[0-9:]+)[ ]+([^[]+)[][0-9]+[: ]+(.+)

   DHCPACK.+ ([0-9.]+) ([0-9a-fA-F:]+) ?(.*)

   CREATE TABLE IF NOT EXISTS notifications (id INTEGER PRIMARY KEY, tstamp_first TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL, tstamp_last TIMESTAMP CURRENT_TIMESTAMP NOT NULL, tstamp_email_last_sent TIMESTAMP, plug UNIQUE NOT NULL, content NOT NULL, status TEXT CHECK (status IN ('N', 'R', 'I')) NOT NULL DEFAULT 'N')

   insert or replace into notifications (id, tstamp_first, tstamp_last, tstamp_email_last_sent, plug, content, status) select old.id, old.tstamp_first, CURRENT_TIMESTAMP, old.tstamp_email_last_sent, new.plug, new.content, old.status FROM (select ? as plug, ? as content) AS new left join (select * from notifications where plug=?) as old on new.plug = old.plug

   SELECT tstamp_email_last_sent FROM notifications WHERE plug=?
   UPDATE notifications SET tstamp_email_last_sent=CURRENT_TIMESTAMP WHERE plug=?
*/
#include <event.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <regex.h>

#define SYSLOG_REGEX "<[0-9]+>([a-zA-Z]+[ ]+[0-9]+[ ]+[0-9:]+)[ ]+([^[]+)[][0-9]+[: ]+(.+)"

regex_t syslog_re;

void timer_cb(evutil_socket_t fd, short what, void *arg)
{
	// Periodic Checks
	printf("TIMER\n");
}

void recv_cb(evutil_socket_t fd, short what, void *arg)
{
	// Receive syslog
	unsigned int unFromAddrLen;
	int nByte = 0;
	char aReqBuffer[512];
	struct sockaddr_in stFromAddr;

	unFromAddrLen = sizeof(stFromAddr);

	if ((nByte = recvfrom(fd, aReqBuffer, sizeof(aReqBuffer)-1, 0,
					(struct sockaddr *)&stFromAddr, &unFromAddrLen)) == -1)
	{
		printf("error occured while receivingn");
	}

	aReqBuffer[nByte] = '\0';
	regmatch_t m[4];
	if (!regexec(&syslog_re, aReqBuffer, 4, m, 0)) {
		printf("Matched -> %.*s - %.*s - %.*s\n", m[1].rm_eo-m[1].rm_so, &aReqBuffer[m[1].rm_so],
				                          m[2].rm_eo-m[2].rm_so, &aReqBuffer[m[2].rm_so],
							  m[3].rm_eo-m[3].rm_so, &aReqBuffer[m[3].rm_so]);
	} else {
		printf("NO MATCH: '%.*s'\n",nByte, aReqBuffer);
	}

}

int main(int argc, char **argv)
{
	struct event_base *base ;
	struct event timer_ev;

	struct event recv_ev;
	int udpsock_fd;
	struct sockaddr_in stAddr;

	if (regcomp(&syslog_re, SYSLOG_REGEX, REG_EXTENDED|REG_NEWLINE)) {
		printf("ERROR - unable to compile syslog regex\n");
		exit(-1);
	}

	base = event_init();

	if ((udpsock_fd = socket(AF_INET, SOCK_DGRAM, 0)) == -1)
	{
		printf("ERROR - unable to create socket:n");
		exit(-1);
	}

	//Start : Set flags in non-blocking mode
	int nReqFlags = fcntl(udpsock_fd, F_GETFL, 0);
	if (nReqFlags< 0)
	{
		printf("ERROR - cannot set socket options");
	}

	if (fcntl(udpsock_fd, F_SETFL, nReqFlags | O_NONBLOCK) < 0)
	{
		printf("ERROR - cannot set socket options");
	}
	// End: Set flags in non-blocking mode
	memset(&stAddr, 0, sizeof(struct sockaddr_in));
	//stAddr.sin_addr.s_addr = inet_addr("192.168.64.1555552");
	stAddr.sin_addr.s_addr = INADDR_ANY; //listening on local ip
	stAddr.sin_port = htons(514);
	stAddr.sin_family = AF_INET;


	int nOptVal = 1;
	if (setsockopt(udpsock_fd, SOL_SOCKET, SO_REUSEADDR,
				(const void *)&nOptVal, sizeof(nOptVal)))
	{
		printf("ERROR - socketOptions: Error at Setsockopt");

	}

	if (bind(udpsock_fd, (struct sockaddr *)&stAddr, sizeof(stAddr)) != 0)
	{
		printf("Error: Unable to bind the default IP n");
		exit(-1);
	}

	event_set(&recv_ev, udpsock_fd, EV_READ | EV_PERSIST, recv_cb, NULL);
	event_add(&recv_ev, NULL);

	struct timeval stTv;
	stTv.tv_sec = 15;
	stTv.tv_usec = 0;
	event_set(&timer_ev, -1, EV_TIMEOUT | EV_PERSIST , timer_cb, NULL);
	event_add(&timer_ev, &stTv);

	event_base_dispatch(base);
	return 0;
}
