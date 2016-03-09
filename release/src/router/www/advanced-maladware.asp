<title>Malware/Adware Blocking</title>
<content>
<script type="text/javascript">
//	<% nvram("at_update,tomatoanon_answer,malad_enable,malad_dflt,malad_xtra,malad_wtl,malad_bkl"); %>
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
   
    function earlyInit(){
        f = E('_fom').elements;
        b = !E('_f_malad_enable').checked;
        for (i = 0; i < f.length; ++i) {
            if (typeof(f[i]) == 'undefined' || (typeof(f[i].name) == 'undefined')) { continue; } /* IE Bugfix */
            if ((f[i].name.substr(0, 1) != '_') && (f[i].type != 'button' && f[i].type != 'fieldset') && (f[i].name.indexOf('enable') == -1) &&
                (f[i].name.indexOf('ne_v') == -1)) f[i].disabled = b;
        }
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
<input type="hidden" name="malad_enable">
<input type="hidden" name="malad_dflt">
<input type="hidden" name="malad_xtra">
<input type="hidden" name="malad_wtl">
<input type="hidden" name="malad_bkl">

<div class="box" data-box="qos-basic-set">
    <div class="heading">Basic Malware/Adware Settings</div>
    <div class="content advanced-maladware"></div>
    <script type="text/javascript">
        $('.advanced-maladware').forms([
        { title: 'Enable', name: 'f_malad_enable', type: 'checkbox', value: nvram.malad_enable == '1' }
    ]);
    </script>
</div>

<div class="box" data-box=""> 
<div class="heading">Default Sources</div>
<div class="section content">
<table class="line-table" id="dflt-grid"></table>
<hr/>
<p>Help</p>
</div>
</div>                  

<div class="box" data-box="">
<div class="heading">Extra Sources</div>
<div class="section content">
<table class="line-table" id="xtra-grid"></table><br />  
<hr/>
<p>Help</p>
</div>
</div>

<div class="box" data-box="">
<div class="heading">Whitelist</div>
<div class="section content">
<table class="line-table" id="wtl-grid"></table>
<hr/>
<p>Help</p>
<p>These are always allowed and will never be blocked (grep -f wl.txt -v domains.txt)</p>
</div>
</div>

<div class="box" data-box="">
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
