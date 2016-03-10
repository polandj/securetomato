<!DOCTYPE html>
<html lang="en">
	<head>
		<meta charset="utf-8">
		<meta name="viewport" content="width=960">
		<meta http-equiv="content-type" content="text/html;charset=utf-8">
		<meta name="robots" content="noindex,nofollow">
		<title>[<% ident(); %>]: Basic</title>

		<!-- Stylesheets -->
		<link href="css/reset.css" rel="stylesheet">
		<link href="css/style.css" rel="stylesheet">
		<% css(); %>

		<!-- Load Favicon (icon) -->
		<link rel="shortcut icon" href="/favicon.ico" />

		<!-- One time load JAVASCRIPT -->
		<script type="text/javascript" src="js/jquery.min.js"></script>
		<script type="text/javascript" src="tomato.js"></script>
		<script type="text/javascript" src="js/advancedtomato.js"></script>

		<!-- Variables which we keep through whole GUI, also determine Tomato version here -->
		<script type="text/javascript">

			var routerName = '[<% ident(); %>] ';
			//<% nvram("web_nav,at_update,at_navi,tomatoanon_answer"); %>
			//<% anonupdate(); %>

			// Fix for system data display
			var refTimer, wl_ifaces = {}, ajaxLoadingState = false, gui_version = "<% version(0); %>";
			$(document).ready(function() {

				// Attempt match
				match_regex = gui_version.match(/^1\.28\.0000.*?([0-9]{1,3}\.[0-9]{1}\-[0-9]{3}).* ([a-z0-9\-]+)$/i);
				
				// Check matches
				if ( match_regex == null || match_regex[1] == null ) { 

					gui_version = 'More Info' 

				} else { 

					gui_version = 'v' + match_regex[1] + ' ' + match_regex[2]; 

				}

				// Write version & initiate GUI functions & binds
				$('#gui-version').html('<i class="icon-info-alt"></i> <span class="nav-collapse-hide">' + gui_version + '</span>');
				AdvancedTomato();

			});
			
		</script>
	</head>
	<body>
		<div id="wrapper">

			<div class="top-header">

				<a href="/">
					<div class="logo">
						<img src="img/securetomato-logo.svg" width="32px" height="32px"/>
						<h1 class="nav-collapse-hide">Secure<span>Tomato</span></h1>
						<h2 class="currentpage nav-collapse-hide">...</h2>
					</div>
				</a>

				<div class="left-container">
					<a data-toggle="tooltip" title="Toggle Collapsed Navigation" href="#" class="toggle-nav"><i class="icon-align-left"></i></a>
				</div>

				<div class="pull-right links">
					<ul>
						<li><a title="Tools" href="#tools-ping.asp">Tools <i class="icon-tools"></i></a></li>
						<li><a title="Bandwidth" href="#bwm-realtime.asp">Bandwidth <i class="icon-graphs"></i></a></li>
						<li><a title="IP Traffic" href="#bwm-ipt-realtime.asp">IP Traffic <i class="icon-globe"></i></a></li>
						<li><a title="System" id="system-ui" href="#system">System <i class="icon-system"></i></a></li>
					</ul>
					<div class="system-ui">

						<div class="datasystem align center"></div>

						<div class="router-control">
							<a href="#" class="btn btn-primary" onclick="reboot();">Reboot <i class="icon-reboot"></i></a>
							<a href="#" class="btn btn-danger" onclick="shutdown();">Shutdown <i class="icon-power"></i></a>
							<a href="#" onclick="logout();" class="btn">Logout <i class="icon-logout"></i></a>
						</div>
					</div>
				</div>
			</div>

			<div class="navigation">
				<ul>
					<li class="nav-footer" id="gui-version" style="cursor: pointer;" onclick="loadPage('#about.asp');"></li>
				</ul>
			</div>


			<div class="container">
				<div class="ajaxwrap"></div>
				<div class="clearfix"></div>
			</div>

		</div>
	</body>
</html>
