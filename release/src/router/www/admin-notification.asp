<title>Notification</title>
<content>
<script type="text/javascript">
//	<% nvram("at_update,tomatoanon_answer,tomon_enable,smtp_to,smtp_from,smtp_srvr,smtp_port,smtp_usr,smtp_pwd,smtp_tssls"); %>
    var tabs = [['config', 'Configuration'], ['email', 'Email'],['events', 'Events']];
    function tabSelect(name) {
        tgHideIcons();
        cookie.set('admin_notification_tab', name);
        tabHigh(name);

        for (var i = 0; i < tabs.length; ++i) {
            var on = (name == tabs[i][0]);
            elem.display(tabs[i][0] + '-tab', on);
        }
    }
    function verifyFields(quiet) {
        var ok = 1;
        if (!v_email('_f_smtp_to', quiet || !ok)) ok = 0;
        if (!v_email('_f_smtp_from', quiet || !ok)) ok = 0;
        if (!v_ip('_f_smtp_srvr', quiet || !ok) || !v_domain('_f_smtp_srvr', quiet || !ok)) ok = 0;
        if (!v_port('_f_smtp_port', quiet || !ok)) ok = 0; 
        return ok;
    }

    function sendTestEmail(id) {
        if ((msg = E(id)) != null) {
            msg.innerHTML = 'Sending...';
            msg.style.visibility = 'visible';
        }
        cmd = new XmlHttp();
        cmd.onCompleted = function(text, xml) {
            if (text.match(/@ok:(.+)/)) 
                E(id).innerHTML = escapeHTML(RegExp.$1);
            else if (text.match(/@error:(.+)/))
                E(id).innerHTML = escapeHTML(RegExp.$1);
            else
                E(id).innerHTML = "Something unexpected happened: " + escapeHTML(text);
            setTimeout(
                function() {
                    msg.style.visibility = 'hidden';
                }, 3300
            );
        }
        cmd.onError = function(x) {
            cmdresult = 'ERROR: ' + x;
            E(id).innerHTML = escapeHTML(cmdresult);
        }
        var to = E('_f_smtp_to').value;
        var from = E('_f_smtp_from').value;
        var srvr = E('_f_smtp_srvr').value;
        var port = E('_f_smtp_port').value;
        var usr = E('_f_smtp_usr').value;
        var pwd = E('_f_smtp_pwd').value;
        var sec = E('_f_smtp_tssls').value;

        args = [];
        if (to && to.length > 0) {
            args.push('to=' + to);
        }
        if (from && from.length > 0) {
            args.push('from=' + from);
        }
        if (srvr && srvr.length > 0) {
            args.push('srvr=' + srvr);
        }
        if (port && port.length > 0) {
            args.push('port=' + port);
        }
        if (usr && usr.length > 0) {
            args.push('usr=' + usr);
        }
        if (pwd && pwd.length > 0) {
            args.push('pwd=' + pwd);
        }
        if (sec) {
            args.push('tssls=1');
        }
        args.push('body=Congratulations, it worked!\n\nThis is a test email notification from the Admin->Notification page of Secure Tomato.');
        args.push('subject=Secure Tomato Test Email');
        cmd.post('smtp.cgi', args.join('&'));
    }

    function save() {
        var fom, r;
    
        fom = E('_fom');
    
        fom.tomon_enable.value = E('_f_tomon_enable').checked ? 1 : 0;
        fom.smtp_to.value = E('_f_smtp_to').value;
        fom.smtp_from.value = E('_f_smtp_from').value;
        fom.smtp_srvr.value = E('_f_smtp_srvr').value;
        fom.smtp_port.value = E('_f_smtp_port').value;
        fom.smtp_usr.value = E('_f_smtp_usr').value;
        fom.smtp_pwd.value = E('_f_smtp_pwd').value;
        fom.smtp_tssls.value = E('_f_smtp_tssls').value;
        fom.smtp_tssls.value = E('_f_smtp_tssls').checked ? 1 : 0;

        form.submit('_fom', 1);
    }
  
    function earlyInit(){
        tabSelect(cookie.get('admin_notification_tab') || 'config');
        init();
    }
    function init() {
    }
</script>

<form id="_fom" method="post" action="tomato.cgi">
<input type="hidden" name="_nextpage" value="/#admin-notification.asp">
<input type="hidden" name="_service" value="tomon">

<div id="admin-notification">
    <script type="text/javascript">
        var html = '<ul id="tabs" class="nav nav-tabs">';
        for (j = 0; j < tabs.length; j++) {
            html += '<li><a href="javascript:tabSelect(\''+tabs[j][0]+'\')" id="'+tabs[j][0]+'">'+tabs[j][1]+'</a></li>';
        }
        html += '</ul>';
        html += '<div class="content">';

        // Config Tab
        html += '<div id="config-tab">';
        html += '<input type="hidden" name="tomon_enable">';
        html += ' <div class="box" data-box="">';
        html += '  <div class="heading">Basic Configuration</div>';
        html += '  <div class="section content">';
        html += createFormFields([
                { title: 'Enable', name: 'f_tomon_enable', type: 'checkbox', value: nvram.tomon_enable == '1' }
            ]);
        html += '  </div>';
        html += ' </div>';
        html += '</div>';

        // Email Tab
        html += '<div id="email-tab">';
        html += '<input type="hidden" name="smtp_to">';
        html += '<input type="hidden" name="smtp_from">';
        html += '<input type="hidden" name="smtp_srvr">';
        html += '<input type="hidden" name="smtp_port">';
        html += '<input type="hidden" name="smtp_usr">';
        html += '<input type="hidden" name="smtp_pwd">';
        html += '<input type="hidden" name="smtp_tssls">';
        html += ' <div class="box" data-box="">';
        html += '  <div class="heading">Basic Configuration</div>';
        html += '  <div class="section content">';
        html += createFormFields([
                { title: 'To', name: 'f_smtp_to', type: 'text', size:34, maxlen:64, value: nvram.smtp_to },
                { title: 'From', name: 'f_smtp_from', type: 'text', size:34, maxlen:64, value: nvram.smtp_from },
                { title: 'SMTP Server', name: 'f_smtp_srvr', type: 'text', size:34, maxlen:64, value: nvram.smtp_srvr },
                { title: 'SMTP Port', name: 'f_smtp_port', type: 'text', size:8, maxlen:5, value: nvram.smtp_port },
                { title: 'SMTP Username', name: 'f_smtp_usr', type: 'text', size: 32, maxlen:32, value: nvram.smtp_usr },
                { title: 'SMTP Password', name: 'f_smtp_pwd', type: 'password', size:32, maxlen:32, value: nvram.smtp_pwd },
                { title: 'Use SSL/TLS', name: 'f_smtp_tssls', type: 'checkbox', value: nvram.smtp_tssls },
            ]);
        html += '<button type="button" value "Test" id="test-button" onclick="sendTestEmail(\'test-result\')" class="btn">Send test email <i class="icon-upload"></i></button>';
        html += '  <span id="test-result" class="alert alert-warning" style="visibility: hidden;"></span>';
        html += '  </div>';
        html += ' </div>';
        html += '</div>';

        // Events tab
        html += '<div id="events-tab">';
        html += ' <div class="box" data-box="">';
        html += '  <div class="heading">Events</div>';
        html += '  <div class="section content">';
        html += '  </div>';
        html += ' </div>';                
        html += '</div>';

        // End of tabs
        html += '</div>';
        $('#admin-notification').html(html);
    </script>
</div>

<button type="button" value="Save" id="save-button" onclick="save()" class="btn btn-primary">Save <i class="icon-check"></i></button>
<button type="button" value="Cancel" id="cancel-button" onclick="javascript:reloadPage();" class="btn">Cancel <i class="icon-cancel"></i></button>
<span id="footer-msg" class="alert alert-warning" style="visibility: hidden;"></span>
</form>
<script type="text/javascript">earlyInit();</script>
</content>
