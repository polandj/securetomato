<!DOCTYPE HTML PUBLIC '-//W3C//DTD HTML 4.0//EN'>
<!--
	Tomato GUI
	Copyright (C) 2006-2010 Jonathan Zarate
	http://www.polarcloud.com/tomato/

	For use with Tomato Firmware only.
	No part of this file may be used without permission.
-->
<html>
<head>
<meta http-equiv='content-type' content='text/html;charset=utf-8'>
<meta name='robots' content='noindex,nofollow'>
<title>[<% ident(); %>] <% translate("Bandwidth"); %>: <% translate("Client Monitor"); %></title>
<link rel='stylesheet' type='text/css' href='tomato.css'>
<% css(); %>
<script type='text/javascript' src='tomato.js'></script>

<!-- / / / -->

<style type='text/css'>
#txt {
	width: 550px;
	white-space: nowrap;
}
#bwm-controls {
	text-align: right;
	margin-right: 5px;
	margin-top: 5px;
	float: right;
	visibility: hidden;
}
ul.tabs a,
#tabs a {
	width: 140px;
	height: 12px;
	font-size: 9px;
}
</style>

<script type='text/javascript' src='debug.js'></script>

<script type='text/javascript' src='wireless.jsx?_http_id=<% nv(http_id); %>'></script>
<script type='text/javascript' src='bwm-common.js'></script>

<script type='text/javascript'>
//	<% nvram("wan_ifname,lan_ifname,wl_ifname,wan_proto,wan_iface,web_svg,rstats_colors,bwm_client"); %>

var cprefix = 'bwcm_r';
var updateInt = 2;
var updateDiv = updateInt;
var updateMaxL = 300;
var updateReTotal = 1;
var prev = [];
var debugTime = 0;
var avgMode = 0;
var wdog = null;
var wdogWarn = null;

var ref = new TomatoRefresh('update.cgi', 'exec=climon', updateInt);

ref.stop = function() {
	this.timer.start(1000);
}

ref.refresh = function(text) {
	var c, i, h, n, j, k, l;

	watchdogReset();

	++updating;
	try {
		climon = null;
		eval(text);

		n = (new Date()).getTime();
		if (this.timeExpect) {
			if (debugTime) E('dtime').innerHTML = (this.timeExpect - n) + ' ' + ((this.timeExpect + 1000*updateInt) - n);
			this.timeExpect += 1000*updateInt;
			this.refreshTime = MAX(this.timeExpect - n, 500);
		}
		else {
			this.timeExpect = n + 1000*updateInt;
		}

		for (i in climon) {
			c = climon[i];
			if ((p = prev[i]) != null) {
				h = speed_history[i];

				h.rx.splice(0, 1);
				h.rx.push((c.rx < p.rx) ? (c.rx + (0xFFFFFFFF - p.rx)) : (c.rx - p.rx));

				h.tx.splice(0, 1);
				h.tx.push((c.tx < p.tx) ? (c.tx + (0xFFFFFFFF - p.tx)) : (c.tx - p.tx));
			}
			else if (!speed_history[i]) {
				speed_history[i] = {};
				h = speed_history[i];
				h.rx = [];
				h.tx = [];
				for (j = 300; j > 0; --j) {
					h.rx.push(0);
					h.tx.push(0);
				}
				h.count = 0;
			}
			prev[i] = c;
		}
		loadData();
	}
	catch (ex) {
	}
	--updating;
}

function watchdog() {
	watchdogReset();
	ref.stop();
	wdogWarn.style.display = '';
}

function watchdogReset() {
	if (wdog) clearTimeout(wdog)
	wdog = setTimeout(watchdog, 5000*updateInt);
	wdogWarn.style.display = 'none';
}

function init() {
	if (nvram.bwm_client.length > 0) {
		E('sesdiv').style.display = '';

		populateCache();

		speed_history = [];

		initCommon(2, 1, 1);

		wdogWarn = E('warnwd');
		watchdogReset();

		ref.start();
	}
}
</script>

</head>
<body onload='init()'>
<form>
<table id='container' cellspacing=0>
<tr><td colspan=2 id='header'>
	<div class='title'>Tomato</div>
	<div class='version'><% translate("Version"); %> <% version(); %></div>
</td></tr>
<tr id='body'><td id='navi'><script type='text/javascript'>navi()</script></td>
<td id='content'>
<div id='ident'><% ident(); %></div>

<!-- / / / -->
<script type='text/javascript'>
if (nvram.bwm_client.length < 1) {
	W('<i><a href="basic-static.asp"><% translate("You need to configure"); %></a> <% translate("which LAN clients/devices should be monitored before coming back to this page"); %>.</i>');
}
</script>
<div id='sesdiv' style='display:none'>

<div id='rstats'>
	<div id='tab-area'></div>

	<script type='text/javascript'>
	if (nvram.web_svg != '0') {
		// without a div, Opera 9 moves svgdoc several pixels outside of <embed> (?)
		W("<div style='border-top:1px solid #f0f0f0;border-bottom:1px solid #f0f0f0;visibility:hidden;padding:0;margin:0' id='graph'><embed src='bwm-graph.svg?<% version(); %>' style='width:760px;height:300px;margin:0;padding:0' type='image/svg+xml' pluginspage='http://www.adobe.com/svg/viewer/install/'></embed></div>");
	}
	</script>

	<div id='bwm-controls'>
		<small>(<script type='text/javascript'>W(5*updateInt);</script> <% translate("minute window"); %>, <script type='text/javascript'>W(updateInt);</script> <% translate("second interval"); %>)</small><br>
		<br>
		<% translate("Avg"); %>:&nbsp;
			<a href='javascript:switchAvg(1)' id='avg1'><% translate("Off"); %></a>,
			<a href='javascript:switchAvg(2)' id='avg2'>2x</a>,
			<a href='javascript:switchAvg(4)' id='avg4'>4x</a>,
			<a href='javascript:switchAvg(6)' id='avg6'>6x</a>,
			<a href='javascript:switchAvg(8)' id='avg8'>8x</a><br>
		<% translate("Max"); %>:&nbsp;
			<a href='javascript:switchScale(0)' id='scale0'><% translate("Uniform"); %></a>,
			<a href='javascript:switchScale(1)' id='scale1'><% translate("Per Client"); %></a><br>
		<% translate("Display"); %>:&nbsp;
			<a href='javascript:switchDraw(0)' id='draw0'><% translate("Solid"); %></a>,
			<a href='javascript:switchDraw(1)' id='draw1'><% translate("Line"); %></a><br>
		<% translate("Color"); %>:&nbsp; <a href='javascript:switchColor()' id='drawcolor'>-</a><br>
		<small><a href='javascript:switchColor(1)' id='drawrev'>[<% translate("reverse"); %>]</a></small><br>

		<br><br>
		&nbsp; &raquo; <a href="basic-static.asp"><% translate("Configure"); %></a>
	</div>

	<br><br>
	<table border=0 cellspacing=2 id='txt'>
	<tr>
		<td width='8%' align='right' valign='top'><b style='border-bottom:blue 1px solid' id='rx-name'>RX</b></td>
			<td width='15%' align='right' valign='top'><span id='rx-current'></span></td>
		<td width='8%' align='right' valign='top'><b><% translate("Avg"); %></b></td>
			<td width='15%' align='right' valign='top' id='rx-avg'></td>
		<td width='8%' align='right' valign='top'><b><% translate("Peak"); %></b></td>
			<td width='15%' align='right' valign='top' id='rx-max'></td>
		<td width='8%' align='right' valign='top'><b><% translate("Total"); %></b></td>
			<td width='14%' align='right' valign='top' id='rx-total'></td>
		<td>&nbsp;</td>
	</tr>
	<tr>
		<td width='8%' align='right' valign='top'><b style='border-bottom:blue 1px solid' id='tx-name'>TX</b></td>
			<td width='15%' align='right' valign='top'><span id='tx-current'></span></td>
		<td width='8%' align='right' valign='top'><b><% translate("Avg"); %></b></td>
			<td width='15%' align='right' valign='top' id='tx-avg'></td>
		<td width='8%' align='right' valign='top'><b><% translate("Peak"); %></b></td>
			<td width='15%' align='right' valign='top' id='tx-max'></td>
		<td width='8%' align='right' valign='top'><b><% translate("Total"); %></b></td>
			<td width='14%' align='right' valign='top' id='tx-total'></td>
		<td>&nbsp;</td>
	</tr>
	</table>
</div>
<br>
<br>

<!-- / / / -->

</td></tr>
<tr><td id='footer' colspan=2>
	<span id='warnwd' style='display:none'><% translate("Warning: 10 second timeout, restarting"); %>...&nbsp;</span>
	<span id='dtime'></span>
	<img src='spin.gif' id='refresh-spinner' onclick='javascript:debugTime=1'>

</div>
</td></tr>
</table>
</form>
</body>
</html>
