<title>Malware/Adware Blocking</title>
<content>
<script type="text/javascript">
//	<% nvram("at_update,tomatoanon_answer,malad_enable,malad_mode,malad_cron,malad_dflt,malad_xtra,malad_wtl,malad_bkl"); %>
    var pxld = {"uts": "uptime in seconds",
                "req": "number of connection requests",
                "avg": "average request size in bytes",
                "rmx": "maximum request size in bytes",
                "tav": "average request processing time in milliseconds",
                "tmx": "maximum request processing time in milliseconds", 
                "err": "number of connections resulting in processing errors (syslog may have details)", 
                "tmo": "number of connections that timed out while trying to read a request from the client",
                "cls": "number of connections that were closed by the client while reading or replying to the request",
                "nou": "number of requests that failed to include a URL",
                "pth": "number of requests for a path that could not be parsed",
                "nfe": "number of requests for a file with no extension",
                "ufe": "number of requests for an unrecognized/unhandled file extension",
                "gif": "number of requests for GIF images",
                "bad": "number of requests for unrecognized/unhandled HTTP methods",
                "txt": "number of requests for plaintext data formats",
                "jpg": "number of requests for JPEG images",
                "png": "number of requests for PNG images",
                "swf": "number of requests for Adobe Shockwave Flash files",
                "ico": "number of requests for ICO files (usually favicons)",
                "slh": "number of HTTPS requests with a good certifcate (cert exists and used)",
                "slm": "number of HTTPS requests without a certficate (cert missing for ad domain)",
                "sle": "number of HTTPS requests with a bad cert (error in existing cert)",
                "slu": "number of unrecognized HTTPS requests (none of slh/slm/sle)",
                "sta": "number of requests for HTML stats",
                "stt": "number of requests for plaintext stats",
                "204": "number of requests for /generate_204 URLs",
                "rdr": "number of requests resulting in a redirect",
                "pst": "number of requests for HTTP POST method",
                "hed": "number of requests for HTTP HEAD method"}

    var tabs = [['config', 'Config'],['sources', 'Sources'],['lists', 'Lists'],['certs', 'Certificates'], ['status', 'Status']];
    function tabSelect(name) {
        tgHideIcons();
        cookie.set('advanced_maladware_tab', name);
        tabHigh(name);

        for (var i = 0; i < tabs.length; ++i) {
            var on = (name == tabs[i][0]);
            elem.display(tabs[i][0] + '-tab', on);
        }
    }
    function verifyFields() {}

    /* Default Sources */
    var dflt_sources = [
        ['fb1d1107', 'http://adaway.org/hosts.txt'],
        ['da9bd190', 'http://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&mimetype=plaintext'],
        ['c2934517', 'http://winhelp2002.mvps.org/hosts.txt'],
        ['f4af2545', 'http://someonewhocares.org/hosts/hosts'],
        ['3b41114e', 'http://www.malwaredomainlist.com/hostslist/hosts.txt'],
        ['353675ed', 'http://adblock.gjtech.net/?format=unix-hosts'],
        ['88096bb7', 'http://hosts-file.net/ad_servers.txt']
    ];
    var dflt = new TomatoGrid();
    dflt.setup = function() {
        var dsbld = nvram['malad_dflt'];
        this.init('dflt-grid', 'sort', 10, [
            {type: 'checkbox'},
            {type: 'text', attrib: 'disabled'}
        ]);
        this.canDelete = false;
        this.headerSet(['On', 'URL']);
        for (i = 0; i < dflt_sources.length; ++i) {
            var item = dflt_sources[i];
            is_checked = dsbld.indexOf(item[0]) == -1 ? 1 : 0;
            this.insertData(-1, [is_checked, item[1]]);
        }
        this.sort(1);
    }
    dflt.dataToView = function(data) {
        return [(data[0] != 0) ? '<i class="icon-check icon-green"></i>' : '<i class="icon-cancel icon-red"></i>', 
            data[1]];
    }
    dflt.dataToFieldValues = function (data) {
        return [(data[0] != 0) ? 'checked' : '',
            data[1]];
    }
    dflt.fieldValuesToData = function(row) {
        var f = fields.getAll(row);
        return [f[0].checked ? 1 : 0,
            f[1].value];
    }
    
    /* Optional Additional Sources */
    var xtra = new TomatoGrid();
    xtra.verifyFields = function(row, quiet) {
        var f;
        f = fields.getAll(row);

        return v_url(f[1], quiet);
    }
    xtra.resetNewEditor = function() {
        var f, c, n;

        f = fields.getAll(this.newEditor);
        ferror.clearAll(f);

        f[0].checked = 1;
        f[1].value = '';
    }
    xtra.dataToView = function(data) {
        return [(data[0] != 0) ? '<i class="icon-check icon-green"></i>' : '<i class="icon-cancel icon-red"></i>', 
            data[1]];
    }
    xtra.dataToFieldValues = function (data) {
        return [(data[0] != 0) ? 'checked' : '',
            data[1]];
    }
    xtra.fieldValuesToData = function(row) {
        var f = fields.getAll(row);
        return [f[0].checked ? 1 : 0,
            f[1].value];
    }
    xtra.setup = function() {
        var i, j, m, s, t, n;

        this.init('xtra-grid', 'sort', 5, [
            { type: 'checkbox'},
            { type: 'text', maxlen: 100}
        ]);
        this.headerSet(['On', 'URL']);

        var s = nvram.malad_xtra.split('>');
        for (var i = 0; i < s.length; ++i) {
            var t = s[i].split('<');
            if (t.length == 2) {
                this.insertData(-1, t);
            }
        }
        this.sort(1);
        this.showNewEditor();
        this.resetNewEditor();
    }

    /* Whitelist */
    var wtl = new TomatoGrid();
    wtl.verifyFields = function(row, quiet) {
        var f;
        f = fields.getAll(row);
        return v_domain(f[0], quiet);
    }
    wtl.resetNewEditor = function() {
        var f,c,n;
        f = fields.getAll(this.newEditor);
        ferror.clearAll(f);
        f[0].value = '';
    }
    wtl.setup = function() {
        this.init('wtl-grid','sort', 25, [
            {type: 'text', maxlen: 50 }
        ]);
        this.headerSet(['Domain']);
        var s = nvram.malad_wtl.split(' ');
        for (var i = 0; i < s.length; ++i) {
            if (s[i].length > 0) {
                this.insertData(-1, [s[i]]);
            }
        }
        this.sort(0);
        this.showNewEditor();
        this.resetNewEditor();
    }

    /* Blacklist */
    var bkl = new TomatoGrid();
    bkl.verifyFields = function(row, quiet) {
        var f;
        f = fields.getAll(row);
        return v_domain(f[0], quiet);
    }
    bkl.resetNewEditor = function() {
        var f,c,n;
        f = fields.getAll(this.newEditor);
        ferror.clearAll(f);
        f[0].value = '';
    }
    bkl.setup = function() {
        this.init('bkl-grid','sort', 25, [
            {type: 'text', maxlen: 50 }
        ]);
        this.headerSet(['Domain']);
        var s = nvram.malad_bkl.split(' ');
        for (var i = 0; i < s.length; ++i) {
            if (s[i].length > 0) {
                this.insertData(-1, [s[i]]);
            }
        }
        this.sort(0);
        this.showNewEditor();
        this.resetNewEditor();
    }

    function save() {
        var fom, r;
    
        if (dflt.isEditing() || xtra.isEditing() || wtl.isEditing() || bkl.isEditing()) return;

        fom = E('_fom');

        fom.malad_enable.value = E('_f_malad_enable').checked ? 1 : 0;
        if (fom.malad_enable.value == 0) {
            fom._service.value = 'adblock-stop';
        }
        fom.malad_mode.value = E('_f_malad_mode').value;
        fom.malad_cron.value = "55 4 " + E('_f_malad_cron').value + " * *";

        var dflts = dflt.getAllData();
        r = [];
        for (i = 0; i < dflts.length; ++i) {
            var item = dflts[i];
            if (item[0] == 0) {
                // Lookup the abbreviated md5 and save that instead of full URL
                for (j=0; j < dflt_sources.length; ++j) {
                    if (dflt_sources[j][1] == item[1]) {
                        r.push(dflt_sources[j][0]);
                        break;
                    }
                }
            }
        }
        fom.malad_dflt.value = r.join(' ');

        var xtras = xtra.getAllData();
        r = [];
        for (var i = 0; i < xtras.length; ++i) {
            r.push(xtras[i].join('<'));
        }
        fom.malad_xtra.value = r.join('>');

        var wtls = wtl.getAllData();
        r = [];
        for (var i = 0; i < wtls.length; ++i) {
            r.push(wtls[i]);
        }
        fom.malad_wtl.value = r.join(' ');

        var bkls = bkl.getAllData();
        r = [];
        for (var i = 0; i < bkls.length; ++i) {
            r.push(bkls[i]);
        }
        fom.malad_bkl.value = r.join(' ');

        form.submit('_fom', 1);
    }
  
    function updateElement(id, cmdresult) {
        E(id).innerHTML = escapeText(cmdresult).replace('<br>', '').replace('&nbsp;','')
    }

    function escapeText(s) {
        function esc(c) {
            return '&#' + c.charCodeAt(0) + ';';
        }
        return s.replace(/[&"'<>]/g, esc).replace(/\n/g, ' <br>').replace(/ /g, '&nbsp;');
    }
    
    function fetchElement(id, cmdline) {
        cmd = new XmlHttp();
        cmd.onCompleted = function(text, xml) {
            eval(text);
            updateElement(id, cmdresult);
        }
        cmd.onError = function(x) {
            cmdresult = 'ERROR: ' + x;
            updateElement(id, cmdresult);
        }
        cmd.post('shell.cgi', 'action=execute&command=' + escapeCGI(cmdline.replace(/\r/g, '')));
    }

    function fetchStats(id, cmdline) {
        cmd = new XmlHttp();
        cmd.onCompleted = function(text, xml) {
            html = '';
            eval(text);
            stats = cmdresult.split(', ');
            for (j = 0; j < stats.length; j++) {
                parts = stats[j].split(' ');
                if (parseInt(parts[0]) > 0) {
                    html += '<tr><td>'+pxld[parts[1].trim()]+'</td><td>'+parts[0]+'</td></tr>';
                }
            }
            E(id).innerHTML = html;
        }
        cmd.onError = function(x) {
            cmdresult = 'ERROR: ' + x;
            E(id).innerHTML = escapeText(cmdresult).replace('<br>', '').replace('&nbsp;','');
        }
        cmd.post('shell.cgi', 'action=execute&command=' + escapeCGI(cmdline.replace(/\r/g, '')));
    }
    function earlyInit(){
        tabSelect(cookie.get('advanced_maladware_tab') || 'config');
        dflt.setup();
        xtra.setup();
        wtl.setup();
        bkl.setup();
        fetchElement('blocklist_count', 'tail -n1 /etc/adblock/blocklist | cut -d" " -f2');
        fetchElement('blocklist_date', 'head -1 /etc/adblock/blocklist | grep -o "generated .*" | cut -f3- -d" "');
        fetchStats('pixelserv_stats', 'wget -qO- http://adblock.is.loaded/servstats.txt | tail -1');
        init();
    }
    function init() {
        dflt.recolor();
        xtra.recolor();
        wtl.recolor();
        bkl.recolor();
    }
</script>

<form id="_fom" method="post" action="tomato.cgi">
<input type="hidden" name="_nextpage" value="/#advanced-maladware.asp">
<input type="hidden" name="_service" value="adblock-restart">

<div id="advanced-maladware">
    <script type="text/javascript">
        var html = '<ul id="tabs" class="nav nav-tabs">';
        for (j = 0; j < tabs.length; j++) {
            html += '<li><a href="javascript:tabSelect(\''+tabs[j][0]+'\')" id="'+tabs[j][0]+'">'+tabs[j][1]+'</a></li>';
        }
        html += '</ul>';
        html += '<div class="content">';

        // Config Tab
        html += '<div id="config-tab">';
        html += '<input type="hidden" name="malad_enable">';
        html += '<input type="hidden" name="malad_mode">';
        html += '<input type="hidden" name="malad_cron">';
        html += ' <div class="box" data-box="">';
        html += '  <div class="heading">Basic Configuration</div>';
        html += '  <div class="section content">';
        html += createFormFields([
                { title: 'Enable', name: 'f_malad_enable', type: 'checkbox', value: nvram.malad_enable == '1' },
                { title: 'Mode', name: 'f_malad_mode', type: 'select', options: [['', 'Pixelserv'],['1', 'NO Pixelserv']], value: nvram.malad_mode },
                { title: 'Refresh blocklist every', name: 'f_malad_cron', type: 'select', options: [['0','Sun'],['1','Mon'],['2','Tue'],['3','Wed'],['4','Thu'],['5','Fri'],['6', 'Sat']], value: nvram.malad_cron.split(' ')[2]}
            ]);
        html += '  </div>';
        html += ' </div>';
        html += '</div>';

        // Sources tab
        html += '<div id="sources-tab">';
        html += ' <input type="hidden" name="malad_dflt">';
        html += ' <input type="hidden" name="malad_xtra">';
        html += ' <div class="box" data-box="">';
        html += '  <div class="heading">Default Sources</div>';
        html += '  <div class="section content">';
        html += '   <table class="line-table" id="dflt-grid"></table>';
        html += '  </div>';
        html += ' </div>';                
        html += ' <div class="box" data-box="">';
        html += '  <div class="heading">Extra Sources</div>';
        html += '  <div class="section content">';
        html += '   <table class="line-table" id="xtra-grid"></table>';
        html += '  </div>';
        html += ' </div>';
        html += '</div>';


        // Lists tab
        html += '<div id="lists-tab">';
        html += ' <input type="hidden" name="malad_wtl">';
        html += ' <input type="hidden" name="malad_bkl">';
        html += ' <div class="box" data-box="">';
        html += '  <div class="heading">Whitelist</div>';
        html += '  <div class="section content">';
        html += '   <table class="line-table" id="wtl-grid"></table>';
        html += '  </div>';
        html += ' </div>';
        html += ' <div class="box" data-box="">';
        html += '  <div class="heading">Blacklist</div>';
        html += '  <div class="section content">';
        html += '   <table class="line-table" id="bkl-grid"></table>';
        html += '  </div>';
        html += ' </div>';
        html += '</div>';

        // Certificates tab
        html += '<div id="certs-tab">';
        html += ' <input type="hidden" name="malad_cacrt">';
        html += ' <input type="hidden" name="malad_cakey">';
        html += ' <div class="box" data-box="">';
        html += '  <div class="heading">Certificates</div>';
        html += '  <div class="section content">';
        html += createFormFields([
                { title: 'Certificate', name: 'f_malad_cacrt', type: 'textarea', value: '', style: 'width: 100%; height: 80px;'},
                { title: 'Key', name: 'f_malad_cakey', type: 'textarea', value: '', style: 'width: 100%; height: 80px;'}
            ]);
        html += '  </div>';
        html += ' </div>';
        html += '</div>';

        // Status tab
        html += '<div id="status-tab">';
        html += ' <div class="box" data-box="">';
        html += '  <div class="heading">Status</div>';
        html += '  <div class="section content">';
        html += '   <table>';
        html += '     <tr><td>Blocklist Count</td><td id="blocklist_count">...</td></tr>';
        html += '     <tr><td>Last updated</td><td id="blocklist_date">...</td></tr>';
        html += '   </table>';
        html += '  </div>';
        html += ' </div>';
        html += ' <div class="box" data-box="">';
        html += '  <div class="heading">Pixel Serv</div>';
        html += '  <div class="section content">';
        html += '   <table id="pixelserv_stats"></table>';
        html += '  </div>';
        html += ' </div>';
        html += '</div>';

        // End of tabs
        html += '</div>';
        $('#advanced-maladware').html(html);
    </script>
</div>

<button type="button" value="Save" id="save-button" onclick="save()" class="btn btn-primary">Save <i class="icon-check"></i></button>
<button type="button" value="Cancel" id="cancel-button" onclick="javascript:reloadPage();" class="btn">Cancel <i class="icon-cancel"></i></button>
<span id="footer-msg" class="alert alert-warning" style="visibility: hidden;"></span>
</form>
<script type="text/javascript">earlyInit();</script>
</content>
