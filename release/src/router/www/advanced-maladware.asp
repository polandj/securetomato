<title>Malware/Adware Blocking</title>
<content>
<script type="text/javascript">
//	<% nvram("at_update,tomatoanon_answer,malad_enable,malad_dflt,malad_xtra,malad_wtl,malad_bkl"); %>
    var tabs = [['config', 'Config'],['sources', 'Sources'],['lists', 'Lists'],['status', 'Status']];
    function tabSelect(name) {
        tgHideIcons();
        cookie.set('advanced_maladware_tab', name);
        tabHigh(name);

        for (var i = 0; i < tabs.length; ++i) {
            var on = (name == tabs[i][0]);
            elem.display(tabs[i][0] + '-tab', on);
        }
    }

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

    function earlyInit(){
        tabSelect(cookie.get('advanced_maladware_tab') || 'config');
        dflt.setup();
        xtra.setup();
        wtl.setup();
        bkl.setup();
        fetchElement('blocked_domain_count', 'tail -n1 /var/lib/adblock/blocklist | cut -d" " -f2');
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
        html += ' <div class="box" data-box="">';
        html += '  <div class="heading">Basic Configuration</div>';
        html += '  <div class="section content">';
        html += createFormFields([
                { title: 'Enable', name: 'f_malad_enable', type: 'checkbox', value: nvram.malad_enable == '1' }
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

        // Status tab
        html += '<div id="status-tab">';
        html += ' <div class="box" data-box="">';
        html += '  <div class="heading">Status</div>';
        html += '  <div class="section content">';
        html += '   <table>'
        html += '     <tr><td>Blocked Domains</td><td id="blocked_domain_count">...</td></tr>';
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
