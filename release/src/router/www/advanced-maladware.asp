<title>Malware/Adware Blocking</title>
<content>
<script type="text/javascript">
//	<% nvram("at_update,tomatoanon_answer,malad_enable,malad_dflt,malad_xtra,malad_wtl,malad_bkl"); %>
    /* Default Sources */
    var dflt = new TomatoGrid();
    dflt.setup = function() {
        var dsbld = nvram['malad_dflt'];
        var sources = [
            [1, 'Adaway', 'http://adaway.org/hosts.txt', 1],
            [1, 'YoYo', 'http://pgl.yoyo.org/adservers/serverlist.php?hostformat=dnsmasq&showintro=0&mimetype=plaintext', 3],
            [1, 'WinHelp', 'http://winhelp2002.mvps.org/hosts.txt', 1],
            [1, 'SomeOne', 'http://someonewhocares.org/hosts/hosts', 1],
            [1, 'MalDml', 'http://www.malwaredomainlist.com/hostslist/hosts.txt', 1],
            [1, 'GJTech', 'http://adblock.gjtech.net/?format=unix-hosts', 1],
            [1, 'HostFile', 'http://hosts-file.net/ad_servers.txt', 1],
            [1, 'MalDom', 'http://mirror1.malwaredomains.com/files/justdomains', 2]
        ];
        this.init('dflt-grid', 'sort', 10, [
            {type: 'checkbox'},
            {type: 'text', attrib: 'disabled'},
            {type: 'text', attrib: 'disabled'},
            {type: 'select', attrib: 'disabled', options: [[1, 'Host'],[2, 'Domain'],[3, 'DNSMASQ']], class : 'input-small'}
        ]);
        this.canDelete = false;
        this.headerSet(['On', 'Name', 'URL', 'Format']);
        for (i = 0; i < sources.length; ++i) {
            var item = sources[i];
            is_checked = dsbld.indexOf(item[1]) == -1 ? 1 : 0;
            this.insertData(-1, [is_checked, item[1], item[2], item[3]]);
        }
        this.sort(1);
    }
    dflt.dataToView = function(data) {
        return [(data[0] != 0) ? '<i class="icon-check icon-green"></i>' : '<i class="icon-cancel icon-red"></i>', 
            data[1],
            data[2],
            ['Host', 'Domain', 'DNSMASQ'][data[3] - 1]];
    }
    dflt.dataToFieldValues = function (data) {
        return [(data[0] != 0) ? 'checked' : '',
            data[1],
            data[2],
            data[3]];
    }
    dflt.fieldValuesToData = function(row) {
        var f = fields.getAll(row);
        return [f[0].checked ? 1 : 0,
            f[1].value,
            f[2].value,
            f[3].value];
    }
    
    /* Optional Additional Sources */
    var xtra = new TomatoGrid();
    xtra.verifyFields = function(row, quiet) {
        var f;
        f = fields.getAll(row);

        return v_domain(f[1], quiet, false) && v_url(f[2], quiet);
    }
    xtra.resetNewEditor = function() {
        var f, c, n;

        f = fields.getAll(this.newEditor);
        ferror.clearAll(f);

        f[0].checked = 1;
        f[1].value = '';
        f[2].value = '';
        f[3].selectedIndex = 0;
    }
    xtra.dataToView = function(data) {
        return [(data[0] != 0) ? '<i class="icon-check icon-green"></i>' : '<i class="icon-cancel icon-red"></i>', 
            data[1],
            data[2],
            ['Host', 'Domain', 'DNSMASQ'][data[3] - 1]];
    }
    xtra.dataToFieldValues = function (data) {
        return [(data[0] != 0) ? 'checked' : '',
            data[1],
            data[2],
            data[3]];
    }
    xtra.fieldValuesToData = function(row) {
        var f = fields.getAll(row);
        return [f[0].checked ? 1 : 0,
            f[1].value,
            f[2].value,
            f[3].value];
    }
    xtra.setup = function() {
        var i, j, m, s, t, n;
        var sources = [];

        this.init('xtra-grid', 'sort', 5, [
            { type: 'checkbox'},
            { type: 'text', maxlen: 10},
            { type: 'text', maxlen: 100},
            { type: 'select', options: [[1, 'Host'],[2, 'Domain'],[3, 'DNSMASQ']], class : 'input-small' }
        ]);
        this.headerSet(['On', 'Name', 'URL', 'Format']);

        var s = nvram.malad_xtra.split('>');
        for (var i = 0; i < s.length; ++i) {
            var t = s[i].split('<');
            this.insertData(-1, t)
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
            this.insertData(-1, [s[i]]);
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
            this.insertData(-1, [s[i]]);
        }
        this.sort(0);
        this.showNewEditor();
        this.resetNewEditor();
    }

    function save() {
        var fom, r;
    
        if (dflt.isEditing() || xtra.isEditing() || wtl.isEditing() || bkl.isEditing()) return;

        fom = E('_fom');

        var dflts = dflt.getAllData();
        r = [];
        for (i = 0; i < dflts.length; ++i) {
            var item = dflts[i];
            if (item[0] == 0) {
                r.push(item[1]);
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
    
    function earlyInit(){
        dflt.setup();
        xtra.setup();
        wtl.setup();
        bkl.setup();
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
<input type="hidden" name="_nvset" value="1">
<input type="hidden" name="_commit" value="1">
<input type="hidden" name="malad_dflt">
<input type="hidden" name="malad_xtra">
<input type="hidden" name="malad_wtl">
<input type="hidden" name="malad_bkl">

<div class="box" data-box="routing-static"> 
<div class="heading">Default Sources</div>
<div class="section content">
<table class="line-table" id="dflt-grid"></table>
<hr/>
<p>Help</p>
</div>
</div>                  

<div class="box">
<div class="heading">Additional Sources</div>
<div class="content">
<table class="line-table" id="xtra-grid"></table><br />  
<hr/>
<p>Help</p>
</div>
</div>

<div class="box" data-box="routing-static">
<div class="heading">Whitelist</div>
<div class="section content">
<table class="line-table" id="wtl-grid"></table>
<hr/>
<p>Help</p>
<p>These are always allowed and will never be blocked (grep -f wl.txt -v domains.txt)</p>
</div>
</div>

<div class="box" data-box="routing-static">
<div class="heading">Blacklist</div>
<div class="section content">
<table class="line-table" id="bkl-grid"></table>
<hr/>
<p>Help</p>
<p>These will always be blocked (append to end)</p>
</div>
</div>

<button type="button" value="Save" id="save-button" onclick="save()" class="btn btn-primary">Save <i class="icon-check"></i></button>
<button type="button" value="Cancel" id="cancel-button" onclick="javascript:reloadPage();" class="btn">Cancel <i class="icon-cancel"></i></button>
<span id="footer-msg" class="alert alert-warning" style="visibility: hidden;"></span>
</form>
<script type="text/javascript">earlyInit();</script>
</content>
