/*
   sqlite> select * from notifications;
   1|2016-04-28 18:14:57|2016-04-29 02:44:22|2016-04-28 18:14:59|Web Username|The web is using the default username, please change it|N
   2|2016-04-28 18:14:59|2016-04-29 02:44:22|2016-04-28 18:15:00|Web Root|Root login is enabled, please disable it|N
   3|2016-04-28 18:15:00|2016-04-29 02:44:22|2016-04-28 18:15:01|SSH Remote|SSH remote management is enabled|N
   4|2016-04-28 18:15:01|2016-04-29 02:44:22|2016-04-28 18:15:02|SSH Password|SSH allows password login, disable this and use keys|N
   5|2016-04-28 18:15:02|2016-04-29 02:44:22|2016-04-28 19:29:25|Web Insecure Remote|Remote management is enabled via HTTP.  Change this!|N
   6|2016-04-28 19:26:01|2016-04-29 02:38:13|2016-04-28 19:26:03|New DHCP lease to unknown device: f8:cf:c5:1e:22:63|New DHCP lease, 172.28.28.243, to unknown host with MAC f8:cf:c5:1e:22:63[android-c58abbd80fb72664]
   |N

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
#include <bcmnvram.h>
#include <sqlite3.h>
#include <curl/curl.h>

#define SYSLOG_REGEX "<[0-9]+>([a-zA-Z]+[ ]+[0-9]+[ ]+[0-9:]+)[ ]+([^[]+)[][0-9]+[: ]+(.+)"
#define DNSMASQ_DHCP_REGEX "DHCPACK.+ ([0-9.]+) ([0-9a-fA-F:]+) ?(.*)"

#define NOTIFICATIONS_CREATE_SQL "CREATE TABLE IF NOT EXISTS notifications( "\
	"id INTEGER PRIMARY KEY, "\
	"tstamp_first TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL, "\
	"tstamp_last TIMESTAMP CURRENT_TIMESTAMP NOT NULL, "\
	"tstamp_email_last_sent TIMESTAMP, "\
	"plug UNIQUE NOT NULL, "\
	"content NOT NULL, "\
	"status TEXT CHECK (status IN ('N', 'R', 'I')) NOT NULL DEFAULT 'N'"\
	")"
#define NOTIFICATIONS_INSERT_SQL "INSERT OR REPLACE INTO notifications "\
	"(id, tstamp_first, tstamp_last, tstamp_email_last_sent, plug, content, status) "\
	"SELECT old.id, old.tstamp_first, CURRENT_TIMESTAMP, old.tstamp_email_last_sent, "\
	"new.plug, new.content, old.status FROM (SELECT ? AS plug, ? AS content) AS new "\
	"LEFT JOIN (SELECT * FROM notifications WHERE plug=?) AS old ON new.plug = old.plug"
#define NOTIFICATIONS_SELECT_SQL "SELECT strftime('%s','now') - strftime('%s', tstamp_email_last_sent) FROM notifications WHERE plug=?"
#define NOTIFICATIONS_UPDATE_SQL "UPDATE notifications SET tstamp_email_last_sent=CURRENT_TIMESTAMP WHERE plug=?"

sqlite3 *db;

sqlite3_stmt *notifications_insert_stmt;
sqlite3_stmt *notifications_select_stmt;
sqlite3_stmt *notifications_update_stmt;

regex_t syslog_re;
regex_t dnsmasq_dhcp_re;

struct smtp_payload {
        char buf[2048];
        size_t offset;
};

static size_t smtp_payload_send(void *ptr, size_t size, size_t nmemb, void *userp)
{
        struct smtp_payload *payload = (struct smtp_payload *)userp;
        const char *data;

        if((size == 0) || (nmemb == 0) || ((size*nmemb) < 1)) {
                return 0;
        }
        data = &payload->buf[payload->offset];
        if (data) {
                size_t len = strlen(data) < (size*nmemb) ? strlen(data) : (size * nmemb);
                memcpy(ptr, data, len);
                payload->offset += len;
                return len;
        }
        return 0;
}

int
send_email(char *subject, char *body)
{
        char *to, *from;
        char *srvr, *port, *usr, *pwd, *tssls;
        char urlbuf[512], errBuf[CURL_ERROR_SIZE];
        struct smtp_payload payload;
        CURL *curl;
        CURLcode res = CURLE_OK;
        struct curl_slist *recipients = NULL;
	int retval = 0;

        to = nvram_get("smtp_to");
        from = nvram_get("smtp_from");
        srvr = nvram_get("smtp_srvr");
        port = nvram_get("smtp_port");
        usr = nvram_get("smtp_usr");
        pwd = nvram_get("smtp_pwd");
        tssls = nvram_get("smtp_tssls");

        curl = curl_easy_init();
        if (!curl) {
                printf("@error: Unable to initialize curl");
                return 0;
        }
        if (usr) {
                curl_easy_setopt(curl, CURLOPT_USERNAME, usr);
        }
        if (pwd) {
                curl_easy_setopt(curl, CURLOPT_PASSWORD, pwd);
        }
        if (srvr && port) {
                snprintf(urlbuf, sizeof(urlbuf), "smtp%s://%s:%s", tssls ? "s": "", srvr, port);
                curl_easy_setopt(curl, CURLOPT_URL, urlbuf);
        } else {
                printf("@error: No server and/or port specified");
                goto CURL_CLEANUP;
        }
        if (tssls) {
                curl_easy_setopt(curl, CURLOPT_USE_SSL, (long)CURLUSESSL_ALL);
        }
        if (from) {
                curl_easy_setopt(curl, CURLOPT_MAIL_FROM, from);
        }
        if (to) {
                recipients = curl_slist_append(recipients, to);
                curl_easy_setopt(curl, CURLOPT_MAIL_RCPT, recipients);
        } else {
                printf("@error: No recipients specified");
                goto CURL_CLEANUP;
        }
        curl_easy_setopt(curl, CURLOPT_ERRORBUFFER, errBuf);

        snprintf(payload.buf, sizeof(payload.buf), "To: %s\r\nFrom: %s\r\nSubject: %s\r\n\r\n%s", to, from, subject, body);
        payload.offset = 0;
        curl_easy_setopt(curl, CURLOPT_READFUNCTION, smtp_payload_send);
        curl_easy_setopt(curl, CURLOPT_READDATA, &payload);
        curl_easy_setopt(curl, CURLOPT_UPLOAD, 1L);

        res = curl_easy_perform(curl);
        if(res != CURLE_OK) {
                printf("@error: %s[%d-%s]", errBuf, res, curl_easy_strerror(res));
        } else {
                printf("@ok: Message Sent");
		retval = 1;
        }

CURL_CLEANUP:
        curl_slist_free_all(recipients);
        curl_easy_cleanup(curl);

	return retval;
}

void
raise(char *plug, char *content) {
	int since_last_email = -1;
	/* Insert or update */
	sqlite3_reset(notifications_insert_stmt);
	if (sqlite3_bind_text(notifications_insert_stmt, 1, plug, -1, NULL) != SQLITE_OK) {
		printf("Error binding plug: %s\n", sqlite3_errmsg(db));
	}
	if (sqlite3_bind_text(notifications_insert_stmt, 2, content, -1, NULL) != SQLITE_OK) {
		printf("Error binding content: %s\n", sqlite3_errmsg(db));
	}
	if (sqlite3_bind_text(notifications_insert_stmt, 3, plug, -1, NULL) != SQLITE_OK) {
		printf("Error binding plug: %s\n", sqlite3_errmsg(db));
	}
	if (sqlite3_step(notifications_insert_stmt) != SQLITE_DONE) {
		printf("INsert failed\n");
	}
	/* Pull out last emailed time */
	sqlite3_reset(notifications_select_stmt);
	if (sqlite3_bind_text(notifications_select_stmt, 1, plug, -1, NULL) != SQLITE_OK) {
		printf("Error binding plug: %s\n", sqlite3_errmsg(db));
	}
	while (sqlite3_step(notifications_select_stmt) == SQLITE_ROW) {
		const char *v = sqlite3_column_text(notifications_select_stmt, 0);
		if (v) {
			since_last_email = atoi(v);
		}
	}
	if (since_last_email == -1 && send_email(plug, content)) {
		/* Update last emailed time */
		sqlite3_reset(notifications_update_stmt);
		if (sqlite3_bind_text(notifications_update_stmt, 1, plug, -1, NULL) != SQLITE_OK) {
			printf("Error binding plug: %s\n", sqlite3_errmsg(db));
		}
		if (sqlite3_step(notifications_update_stmt) != SQLITE_DONE) {
			printf("Update failed\n");
		}
	}
	printf("%s -- %s [emailed %ds ago]\n", plug, content, since_last_email);
}

void 
timer_cb(evutil_socket_t fd, short what, void *arg) {
	// Periodic Checks
	printf("TIMER\n");
}

void
dnsmasq_dhcp_check(char *datetime, char *msg) {
	regmatch_t m[4];

	const char *statics=nvram_get("dhcpd_static") ?: "";
	if (!regexec(&dnsmasq_dhcp_re, msg, 4, m, 0)) {
		char ip[20], mac[20], hostname[1000];
		snprintf(ip, sizeof(ip), "%.*s", m[1].rm_eo-m[1].rm_so, &msg[m[1].rm_so]);
		snprintf(mac, sizeof(mac), "%.*s", m[2].rm_eo-m[2].rm_so, &msg[m[2].rm_so]);
		snprintf(hostname, sizeof(hostname), "%.*s", m[3].rm_eo-m[3].rm_so, &msg[m[3].rm_so]);
		printf("New Lease: %s to %s (%s)\n", ip, mac, hostname);
		if (strcasestr(mac, statics)) {
			char plug[100], content[500];
			snprintf(plug, sizeof(plug), "New DHCP lease to unknown device: %s", mac);
			snprintf(content, sizeof(content), 
			    "New DHCP lease, %s, to unknown host with MAC %s[%s]", ip, mac, hostname);
			raise(plug, content);
		}
	}
}

void 
recv_cb(evutil_socket_t fd, short what, void *arg) {
	// Receive syslog
	unsigned int unFromAddrLen;
	int nByte = 0;
	char aReqBuffer[1024];
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
		char datetime[20], daemon[20], msg[1000];
		snprintf(datetime, sizeof(datetime), "%.*s", m[1].rm_eo-m[1].rm_so, &aReqBuffer[m[1].rm_so]);
		snprintf(daemon, sizeof(daemon), "%.*s", m[2].rm_eo-m[2].rm_so, &aReqBuffer[m[2].rm_so]);
		snprintf(msg, sizeof(msg), "%.*s", m[3].rm_eo-m[3].rm_so, &aReqBuffer[m[3].rm_so]);
		printf("Matched -> %s - %s - %s\n", datetime, daemon, msg);
		if (!strcasecmp(daemon, "dnsmasq-dhcp")) {
			dnsmasq_dhcp_check(datetime, msg);
		}
	} else {
		printf("NO MATCH: '%.*s'\n",nByte, aReqBuffer);
	}

}

void
reg_init(void) {
	if (regcomp(&syslog_re, SYSLOG_REGEX, REG_EXTENDED|REG_NEWLINE)) {
		printf("ERROR - unable to compile syslog regex\n");
		exit(-1);
	}

	if (regcomp(&dnsmasq_dhcp_re, DNSMASQ_DHCP_REGEX, REG_EXTENDED|REG_NEWLINE)) {
		printf("ERROR - unable to compile dnsmasq-dhcp regex\n");
		exit(-1);
	}
}

sqlite3 *
db_init(void) {
	if (sqlite3_open("/tmp/tomon.db", &db)) {
		printf("Failed to open database: %s\n", sqlite3_errmsg(db));
		sqlite3_close(db);
		exit(-1);
	}
	char *zErrMsg;
	if (sqlite3_exec(db, NOTIFICATIONS_CREATE_SQL, NULL, 0, &zErrMsg) != SQLITE_OK) {
		printf("Failed to create database: %s\n", zErrMsg);
		sqlite3_close(db);
		exit(-1);
	}
	if (sqlite3_prepare_v2(db, NOTIFICATIONS_INSERT_SQL, -1, &notifications_insert_stmt, NULL) != SQLITE_OK) {
		printf("Failed to prepare INSERT SQL: %s\n", sqlite3_errmsg(db));
		sqlite3_close(db);
		exit(-1);
	}
	if (sqlite3_prepare_v2(db, NOTIFICATIONS_SELECT_SQL, -1, &notifications_select_stmt, NULL) != SQLITE_OK) {
		printf("Failed to prepare SELECT SQL: %s\n", sqlite3_errmsg(db));
		sqlite3_close(db);
		exit(-1);
	}
	if (sqlite3_prepare_v2(db, NOTIFICATIONS_UPDATE_SQL, -1, &notifications_update_stmt, NULL) != SQLITE_OK) {
		printf("Failed to prepare UPDATE SQL: %s\n", sqlite3_errmsg(db));
		sqlite3_close(db);
		exit(-1);
	}
	return db;
}

void
server_init(struct event *ev) {
	int udpsock_fd;
	struct sockaddr_in stAddr;

	if ((udpsock_fd = socket(AF_INET, SOCK_DGRAM, 0)) == -1) {
		printf("ERROR - unable to create socket:n");
		exit(-1);
	}

	int nReqFlags = fcntl(udpsock_fd, F_GETFL, 0);
	if (nReqFlags< 0) {
		printf("ERROR - cannot set socket options");
	}

	if (fcntl(udpsock_fd, F_SETFL, nReqFlags | O_NONBLOCK) < 0) {
		printf("ERROR - cannot set socket options");
	}

	memset(&stAddr, 0, sizeof(struct sockaddr_in));
	stAddr.sin_addr.s_addr = inet_addr("127.0.0.1");
	stAddr.sin_port = htons(514);
	stAddr.sin_family = AF_INET;

	int nOptVal = 1;
	if (setsockopt(udpsock_fd, SOL_SOCKET, SO_REUSEADDR,
	    (const void *)&nOptVal, sizeof(nOptVal))) {
		printf("ERROR - socketOptions: Error at Setsockopt");
	}

	if (bind(udpsock_fd, (struct sockaddr *)&stAddr, sizeof(stAddr)) != 0) {
		printf("Error: Unable to bind the default IP n");
		exit(-1);
	}

	event_set(ev, udpsock_fd, EV_READ | EV_PERSIST, recv_cb, NULL);
	event_add(ev, NULL);
}

void
timer_init(int sec, struct event *ev) {
	struct timeval stTv;
	stTv.tv_sec = sec;
	stTv.tv_usec = 0;
	event_set(ev, -1, EV_TIMEOUT | EV_PERSIST, timer_cb, NULL);
	event_add(ev, &stTv);
}

int 
main(int argc, char **argv) {
	struct event_base *base;
	struct event server_ev, timer_ev;

	reg_init();
	db_init();
	base = event_init();
	server_init(&server_ev);
	timer_init(60, &timer_ev);
	event_base_dispatch(base);
	return 0;
}
