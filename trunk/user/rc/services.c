/*
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston,
 * MA 02111-1307 USA
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <unistd.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/sysinfo.h>

#include "rc.h"

void
stop_syslogd(void)
{
	char* svcs[] = { "syslogd", NULL };
	kill_services(svcs, 3, 1);
}

void
stop_klogd(void)
{
	char* svcs[] = { "klogd", NULL };
	kill_services(svcs, 3, 1);
}

int
start_syslogd(void)
{
	char *log_ipaddr, log_rot[8], host_dst[32];
	char *syslogd_argv[] = {
		"/sbin/syslogd",
		log_rot,			/* max size before rotation */
		"-b0",				/* purge on rotate */
		"-S",				/* smaller output */
		"-D",				/* drop duplicates */
		"-O", "/tmp/syslog.log",	/* syslog file */
		NULL,				/* -L */
		NULL, NULL,			/* -R host:port */
		NULL
	};

	snprintf(log_rot, sizeof(log_rot), "-s%d", LOG_ROTATE_SIZE_MAX);

	log_ipaddr = nvram_safe_get("log_ipaddr");
	if (is_valid_ipv4(log_ipaddr)) {
		int log_port = nvram_safe_get_int("log_port", 514, 1, 65535);
		snprintf(host_dst, sizeof(host_dst), "%s:%d", log_ipaddr, log_port);
		syslogd_argv[7] = "-L";		/* local & remote */
		syslogd_argv[8] = "-R";
		syslogd_argv[9] = host_dst;
	}

	setenv_tz();

	return _eval(syslogd_argv, NULL, 0, NULL);
}

int
start_klogd(void)
{
	return eval("/sbin/klogd");
}

void
stop_infosvr(void)
{
	char* svcs[] = { "infosvr", NULL };
	kill_services(svcs, 3, 1);
}

int
start_infosvr(void)
{
	if (nvram_invmatch("adsc_enable", "1"))
		return 1;

	return eval("/usr/sbin/infosvr", IFNAME_BR);
}

void
restart_infosvr(void)
{
	stop_infosvr();
	start_infosvr();
}

void
stop_crond(void)
{
	char* svcs[] = { "crond", NULL };
	kill_services(svcs, 3, 1);
}

int
start_crond(void)
{
	char *crond_argv[] = {
		"/usr/sbin/crond",
		NULL,			/* -d8 */
		NULL
	};

	if (nvram_invmatch("crond_enable", "1"))
		return 1;

	if (nvram_match("crond_log", "0"))
		crond_argv[1] = "-d8";

	setenv_tz();

	return _eval(crond_argv, NULL, 0, NULL);
}

void
restart_crond(void)
{
	stop_crond();
	start_crond();
}

int
start_networkmap(int first_call)
{
	if (first_call && pids("networkmap"))
		return 0;

	return eval("/usr/sbin/networkmap", (first_call) ? "-w" : "");
}

void
stop_networkmap(void)
{
	char* svcs[] = { "networkmap", NULL };
	kill_services(svcs, 3, 1);
}

void
restart_networkmap(void)
{
	if (pids("networkmap"))
		doSystem("killall %s %s", "-SIGUSR1", "networkmap");
	else
		start_networkmap(0);
}

void
stop_telnetd(void)
{
	char* svcs[] = { "telnetd", NULL };
	kill_services(svcs, 3, 1);
}

void
run_telnetd(void)
{
	stop_telnetd();

	eval("telnetd");
}

void
start_telnetd(void)
{
	if (nvram_match("telnetd", "1"))
		eval("telnetd");
}

#if defined(APP_SSHD)
int
is_sshd_run(void)
{
	if (check_if_file_exist("/usr/bin/dropbearmulti"))
	{
		if (pids("dropbear"))
			return 1;
	}
	else if (check_if_file_exist("/usr/sbin/sshd"))
	{
		if (pids("sshd"))
			return 1;
	}
	
	return 0;
}

void
stop_sshd(void)
{
	eval("/usr/bin/sshd.sh", "stop");
}

void
start_sshd(void)
{
	int sshd_mode = nvram_get_int("sshd_enable");

	if (sshd_mode == 2)
		eval("/usr/bin/sshd.sh", "start", "-s");
	else if (sshd_mode == 1)
		eval("/usr/bin/sshd.sh", "start");
}

void
restart_sshd(void)
{
	int is_run_before = is_sshd_run();
	int is_run_after;

	stop_sshd();
	start_sshd();

	is_run_after = is_sshd_run();

	if ((is_run_after != is_run_before) && nvram_match("sshd_wopen", "1") && nvram_match("fw_enable_x", "1"))
		restart_firewall();
}
#endif

#if defined(SUPPORT_ZRAM)
int
get_zram_disksize(void)
{
	int result = 0;
	struct sysinfo info;
	int mode = nvram_get_int("zram_enable");
	if (mode > 0 && mode < 3 && sysinfo(&info) == 0) {
		result = (int)(info.totalram >> (3 - mode));
	}
	return result;
}

void
stop_zram(void)
{
	if (is_module_loaded("zram")) {
		doSystem("swapoff /dev/zram0");
		module_smart_unload("zram", 1);
	}
}

void
start_zram(void)
{
	int disksize = get_zram_disksize();
	if (disksize) {
		module_smart_load("zram", "num_devices=1");
		sleep(1);
		fput_int("/sys/block/zram0/disksize", disksize);
		doSystem("mkswap /dev/zram0");
		doSystem("swapon -p 32767 -d /dev/zram0");
	}
}

void
restart_zram(void)
{
	stop_zram();
	start_zram();
}
#endif

#if defined(APP_ZAPRET)
int is_zapret_run(void){
	if (check_if_file_exist("/usr/bin/nfqws"))
	{
		if (pids("zapret"))
			return 1;
	}
	return 0;
}

void stop_zapret(void){
	eval("/usr/bin/zapret.sh", "stop");
}

void start_zapret(void){
	int zapret_mode = nvram_get_int("zapret_enable");
	if (zapret_mode == 1)
		eval("/usr/bin/zapret.sh", "start");
}

void restart_zapret(void){
	stop_zapret();
	start_zapret();
}

void reload_zapret(void){
	int zapret_mode = nvram_get_int("zapret_enable");
	if (zapret_mode == 1)
		eval("/usr/bin/zapret.sh", "reload");
}
#endif

#if defined(APP_TOR)
int
is_tor_run(void)
{
	if (check_if_file_exist("/usr/sbin/tor"))
	{
		if (pids("tor"))
			return 1;
	}
	return 0;
}

void
stop_tor(void)
{
	eval("/usr/bin/tor.sh", "stop");
}

void
start_tor(void)
{
	int tor_mode = nvram_get_int("tor_enable");

	if (tor_mode == 1)
		eval("/usr/bin/tor.sh", "start");
}

void
restart_tor(void)
{
	stop_tor();
	start_tor();
}
#endif
#if defined(APP_PRIVOXY)
int
is_privoxy_run(void)
{
	if (check_if_file_exist("/usr/sbin/privoxy"))
	{
		if (pids("privoxy"))
			return 1;
	}
	return 0;
}

void
stop_privoxy(void)
{
	eval("/usr/bin/privoxy.sh", "stop");
}

void
start_privoxy(void)
{
	int privoxy_mode = nvram_get_int("privoxy_enable");

	if (privoxy_mode == 1)
		eval("/usr/bin/privoxy.sh", "start");
}

void
restart_privoxy(void)
{
	stop_privoxy();
	start_privoxy();
}
#endif
#if defined(APP_DNSCRYPT)
int
is_dnscrypt_run(void)
{
	if (check_if_file_exist("/usr/sbin/dnscrypt-proxy"))
	{
		if (pids("dnscrypt-proxy"))
			return 1;
	}
	return 0;
}

void
stop_dnscrypt(void)
{
	eval("/usr/bin/dnscrypt-proxy.sh", "stop");
}

void
start_dnscrypt(void)
{
	if (nvram_get_int("dnscrypt_enable") == 1)
		eval("/usr/bin/dnscrypt-proxy.sh", "start");
}

void
restart_dnscrypt(void)
{
	int is_run_before = is_dnscrypt_run();
	int is_run_after;

	stop_dnscrypt();
	start_dnscrypt();

	is_run_after = is_dnscrypt_run();

	/* add-remove iptables rules for DNS forwarding when switching-on-off DNSCrypt-Proxy control in WebUI */
	if ((is_run_after != is_run_before) && nvram_match("dnscrypt_force_dns", "1"))
		restart_firewall();

	/* add-remove needed dnsmasq params when dnscrypt-proxy is enabled-disabled */
	restart_dhcpd();
}
#endif

void
start_httpd(int restart_fw)
{
	int http_proto, argv_index, http_port, restart_fw_need;
	char http_port_s[8];
#if defined (SUPPORT_HTTPS)
	char https_port_s[8];
#endif
	char *httpd_argv[] = {
		"/usr/sbin/httpd",
		NULL, NULL,
		NULL, NULL,
		NULL,
	};

	argv_index = 1;
	http_port = 0;
	restart_fw_need = 0;

#if defined (SUPPORT_HTTPS)
	http_proto = nvram_get_int("http_proto");
#else
	http_proto = 0;
#endif
	if (http_proto == 0 || http_proto == 2) {

		http_port = nvram_get_int("http_lanport");
		if (http_port < 80 || http_port > 65535) {
			http_port = 80;
			nvram_set_int("http_lanport", http_port);
		}
		
		sprintf(http_port_s, "%d", http_port);
		
		httpd_argv[argv_index++] = "-p";
		httpd_argv[argv_index++] = http_port_s;
		
		restart_fw_need |= nvram_get_int("misc_http_x");
	}

#if defined (SUPPORT_HTTPS)
	if (http_proto == 1 || http_proto == 2) {
		int https_port = nvram_get_int("https_lport");
		if (https_port < 81 || https_port > 65535 || https_port == http_port) {
			https_port = 443;
			nvram_set_int("https_lport", https_port);
		}
		
		sprintf(https_port_s, "%d", https_port);
		
		httpd_argv[argv_index++] = "-s";
		httpd_argv[argv_index++] = https_port_s;
		
		restart_fw_need |= nvram_get_int("https_wopen");
	}
#endif

	_eval(httpd_argv, NULL, 0, NULL);

	nvram_set_int_temp("httpd_started", 1);

	if (restart_fw && restart_fw_need && nvram_match("fw_enable_x", "1"))
		restart_firewall();
}

void
stop_httpd(void)
{
	nvram_set_int_temp("httpd_started", 0);
	char* svcs[] = { "httpd", NULL };
	kill_services(svcs, 3, 1);
}

void
restart_httpd(void)
{
	stop_httpd();
	start_httpd(1);
}

void
stop_rstats(void)
{
	char* svcs[] = { "rstats", NULL };
	kill_services(svcs, 3, 1);
}

int
start_rstats(void)
{
	if (nvram_invmatch("rstats_enable", "1"))
		return 1;

	return eval("/sbin/rstats");
}

void
restart_rstats(void)
{
	stop_rstats();
	start_rstats();
}

int
start_lltd(void)
{
	if (nvram_invmatch("lltd_enable", "1"))
		return 1;

	return eval("/bin/lld2d", IFNAME_BR);
}

void
stop_lltd(void)
{
	char* svcs[] = { "lld2d", NULL };
	kill_services(svcs, 2, 1);
}

void
restart_lltd(void)
{
	stop_lltd();
	start_lltd();
}

int
start_logger(int showinfo)
{
	start_syslogd();

	if (showinfo)
	{
		// wait for logger daemon started
		usleep(300000);
		
#if 0
#if defined (VENDOR_ASUS)
		logmessage(LOGNAME, "bootloader version: %s", nvram_safe_get("blver"));
#endif
#endif
		logmessage(LOGNAME, "firmware version: %s", nvram_safe_get("firmver_sub"));
	}

	start_klogd();

	return 0;
}

void
stop_logger(void)
{
	char* svcs[] = { "klogd", "syslogd", NULL };
	kill_services(svcs, 3, 1);
}

void
start_watchdog_cpu(void)
{
	if (nvram_get_int("watchdog_cpu") != 0)
		module_smart_load("rt_timer_wdg", NULL);
}

void
restart_watchdog_cpu(void)
{
	if (nvram_get_int("watchdog_cpu") == 0)
		module_smart_unload("rt_timer_wdg", 0);
	else
		module_smart_load("rt_timer_wdg", NULL);
}

int
start_services_once(int is_ap_mode)
{
#if defined(SUPPORT_ZRAM)
	start_zram();
#endif
	start_8021x_wl();
	start_8021x_rt();
	start_httpd(0);
	start_telnetd();
#if defined(APP_SSHD)
	start_sshd();
#endif
#if defined(APP_ZAPRET)
	start_zapret();
#endif
#if defined(APP_TOR)
	start_tor();
#endif
#if defined(APP_PRIVOXY)
	start_privoxy();
#endif
#if defined(APP_DNSCRYPT)
	start_dnscrypt();
#endif
	start_vpn_server();
	start_watchdog();
	start_infosvr();

	if (!is_ap_mode) {
		if (!is_upnp_run())
			start_upnp();
		
		if (!nvram_match("lan_stp", "0")) {
			br_set_stp(IFNAME_BR, 1);
			br_set_fd(IFNAME_BR, 15);
		}
	} else {
		start_udpxy(IFNAME_BR);
#if defined(APP_XUPNPD)
		start_xupnpd(IFNAME_BR);
#endif
	}

	start_lltd();
	start_watchdog_cpu();
	start_crond();
	start_networkmap(1);
	start_rstats();

	return 0;
}

void
stop_services(int stopall)
{
	if (stopall) {
		stop_telnetd();
#if defined (APP_SSHD)
		stop_sshd();
#endif
		stop_httpd();
		stop_vpn_server();
	}
#if defined (USE_USB_SUPPORT)
	stop_p910nd();
#if defined (SRV_LPRD)
	stop_lpd();
#endif
#if defined (SRV_U2EC)
	stop_u2ec();
#endif
#endif
#if defined(APP_ZAPRET)
	stop_zapret();
#endif
#if defined(APP_TOR)
	stop_tor();
#endif
#if defined(APP_PRIVOXY)
	stop_privoxy();
#endif
#if defined(APP_DNSCRYPT)
	stop_dnscrypt();
#endif
	stop_networkmap();
	stop_lltd();
	stop_detect_internet();
	stop_rstats();
	stop_infosvr();
	stop_crond();
	stop_igmpproxy(NULL);
#if defined(SUPPORT_ZRAM)
	stop_zram();
#endif
}

void
stop_services_lan_wan(void)
{
	stop_dns_dhcpd();
	stop_upnp();
	stop_detect_link();
#if defined (APP_SMBD) || defined (APP_NMBD)
	stop_nmbd();
#endif
}

void
stop_misc(void)
{
	char* svcs[] = {
		"ntpd",
		"detect_wan",
		"watchdog",
		NULL
	};

	kill_services(svcs, 3, 1);
}
