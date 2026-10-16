<!DOCTYPE html>
<html>
<head>
<title><#Web_Title#> - <#Services_Menu_5#></title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Expires" content="-1">

<link rel="shortcut icon" href="images/favicon.ico">
<link rel="icon" href="images/favicon.png">
<link rel="stylesheet" type="text/css" href="/bootstrap/css/bootstrap.min.css">
<link rel="stylesheet" type="text/css" href="/bootstrap/css/main.css">
<link rel="stylesheet" type="text/css" href="/bootstrap/css/engage.itoggle.css">
<link rel="stylesheet" type="text/css" href="/jquery.multiSelectDropdown.css">

<script type="text/javascript" src="/jquery.js"></script>
<script type="text/javascript" src="/jquery.multiSelectDropdown.js"></script>
<script type="text/javascript" src="/bootstrap/js/bootstrap.min.js"></script>
<script type="text/javascript" src="/bootstrap/js/engage.itoggle.min.js"></script>
<script type="text/javascript" src="/state.js"></script>
<script type="text/javascript" src="/general.js"></script>
<script type="text/javascript" src="/itoggle.js"></script>
<script type="text/javascript" src="/popup.js"></script>
<script type="text/javascript" src="/help.js"></script>
<script>
var $j = jQuery.noConflict();
var ipmonitor = [<% get_static_client(); %>];

$j(document).ready(function() {
	init_itoggle('zapret_enable', change_zapret_enabled);
});

</script>
<script>

<% login_state_hook(); %>
<% net_iface_list(); %>

function initial(){
	show_banner(1);
	show_menu(5,7,5);
	show_footer();
	load_body();

	if (found_app_zapret()) {
		showhide_div('tbl_zapret', 1);
		change_zapret_enabled();
	}
}

function applyRule(){
	if(validForm()){
		showLoading();

		document.form.action_mode.value = " Apply ";
		document.form.current_page.value = "/Advanced_Services_Zapret.asp";
		document.form.next_page.value = "";

		document.form.submit();
	}
}

function validForm(){
	return true;
}

function done_validating(action){
	refreshpage();
}

function textarea_zapret_enabled(v){
	for (const i of ["", 0, 1, 2, 3, 4, 5, 6, 7, 8, 9]) {
		inputCtrl(document.form['zapretc.strategy' + i], v);
	}
	zapret_strategy_change(document.form.zapret_strategy, v);
	inputCtrl(document.form['zapretc.user.list'], v);
	inputCtrl(document.form['zapretc.auto.list'], v);
	inputCtrl(document.form['zapretc.exclude.list'], v);
	inputCtrl(document.form['zapretc.post_script.sh'], v);
}

function change_zapret_enabled(){
	var v = document.form.zapret_enable[0].checked;
	showhide_div('row_zapret_service', v);

	textarea_zapret_enabled(v);

	let allowed_list, items_list, allowed, items;

	allowed_list = "<% nvram_get_x("", "zapret_iface"); %>";
	items_list = net_iface_list();

	allowed = allowed_list.replace(/\s+/g, '').split(',')
		.filter(Boolean)
		.map(item => item);
	items = items_list.replace(/\s+/g, '').split(',')
		.filter(Boolean)
		.filter(item => !allowed.includes(item))
		.map(text => ({text, checked: false}))

	const data_iface = [
		...allowed.map(text => ({text, checked: true})),
		...items
	];

	$j('#zapret_iface_list').multiSelectDropdown({
		items: data_iface,
		placeholder: "<#APChnAuto#>",
		width: '320px',
		allowDelete: false,
		allowAdd: false,
		addSuggestionText: '<#CTL_add#>',
		removeSpaces: true,
		allowedItems: '^[a-zA-Z0-9-_.:]+$',
		allowedAlert: '<#JS_field_noletter#>',
		onChange: function(selected){
			document.form.zapret_iface.value = selected.join(',');
		}
	});

	allowed_list = "<% nvram_get_x("", "zapret_clients_allowed"); %>";
	items_list = "<% nvram_get_x("", "zapret_clients"); %>";

	allowed = allowed_list.replace(/\s+/g, '').split(',')
		.filter(Boolean)
		.map(item => item);
	items = items_list.replace(/\s+/g, '').split(',')
		.filter(Boolean)
		.filter(ip => !allowed.includes(ip))
		.map(item => item);

	const data_clients = [
		...allowed.map(item => ( {text: item, checked: true } )),
		...items.map(item => ( {text: item, checked: false } )),
		...ipmonitor
			.filter(ip => ip[0])
			.filter(ip => !allowed.includes(ip[0]))
			.filter(ip => !items.includes(ip[0]))
			.map(item => ( {text: item[0], title: item[2] ?? '*', checked: false } )),
	];

	$j('#zapret_clients_list').multiSelectDropdown({
		items: data_clients,
		placeholder: "<#ZapretWORestrictions#>",
		width: '320px',
		allowDelete: true,
		allowAdd: true,
		addSuggestionText: '<#CTL_add#>',
		removeSpaces: true,
		allowedItems: '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(?:\/([0-9]|[1-2][0-9]|3[0-2]))?$',
		allowedAlert: '<#LANHostConfig_x_DDNS_alarm_9#>',
		onChange: function(selected){
			document.form.zapret_clients_allowed.value = selected.join(',');
			document.form.zapret_clients.value = this.multiSelectDropdown('getAllItems')
				.filter(item => !item.title)
				.map(item => item.text)
				.join(',');
		}
	});
}

function restoreZapret(){
	if(!confirm('<#ZapretRestoreConfirm#>'))
		return false;

	var v, cmd;

	v = "<% nvram_get_x("", "zapret_enable"); %>";
	cmd = 'cd /etc/storage/zapret;rm -f ./strategy ./strategy[0-9];';
	cmd += 'zapret.sh ' + (v == 1 ? 'restart' : '') + ';';
	cmd += 'mtd_storage.sh save';

	sendSystemCmd(cmd, true);
}

function restoreZapretDomain(){
	if(!confirm('<#ZapretRestoreDomainConfirm#>'))
		return false;

	var v, cmd;

	v = "<% nvram_get_x("", "zapret_enable"); %>";
	cmd = 'cd /etc/storage/zapret;rm -f user.list auto.list exclude.list;';
	cmd += 'zapret.sh ' + (v == 1 ? 'restart' : '') + ';';
	cmd += 'mtd_storage.sh save';

	sendSystemCmd(cmd, true);
}

function zapret_strategy_change(o, v) {
	for (const i of ["", 0, 1, 2, 3, 4, 5, 6, 7, 8, 9]) {
		showhide_div('zapretc.strategy' + i, 0);
	}
	if (v == 1) showhide_div('zapretc.strategy' + o.value, 1);
}

</script>
<style>
    .caption-bold {
        font-weight: bold;
    }
    .strategy {
        resize: vertical;
        text-wrap: nowrap;
        font-family: 'Courier New', Courier, mono;
        font-size: 12px;
    }
    .nav-tabs > li > a {
        padding-right: 8px;
        padding-left: 8px;
    }
</style>
</head>

<body onload="initial();" onunLoad="return unload_body();">

<div class="wrapper">
    <div class="container-fluid" style="padding-right: 0px">
        <div class="row-fluid">
            <div class="span3"><center><div id="logo"></div></center></div>
            <div class="span9" >
                <div id="TopBanner"></div>
            </div>
        </div>
    </div>

    <div id="Loading" class="popup_bg"></div>

    <iframe name="hidden_frame" id="hidden_frame" src="" width="0" height="0" frameborder="0"></iframe>
    <form method="post" name="form" id="ruleForm" action="/start_apply.htm" target="hidden_frame">
    <input type="hidden" name="current_page" value="Advanced_Services_Content.asp">
    <input type="hidden" name="next_page" value="">
    <input type="hidden" name="next_host" value="">
    <input type="hidden" name="sid_list" value="LANHostConfig;General;Storage;">
    <input type="hidden" name="group_id" value="">
    <input type="hidden" name="action_mode" value="">
    <input type="hidden" name="action_script" value="">

    <div class="container-fluid">
        <div class="row-fluid">
            <div class="span3">
                <!--Sidebar content-->
                <!--=====Beginning of Main Menu=====-->
                <div class="well sidebar-nav side_nav" style="padding: 0px;">
                    <ul id="mainMenu" class="clearfix"></ul>
                    <ul class="clearfix">
                        <li>
                            <div id="subMenu" class="accordion"></div>
                        </li>
                    </ul>
                </div>
            </div>

            <div class="span9">
                <!--Body content-->
                <div class="row-fluid">
                    <div class="span12">
                        <div class="box well grad_colour_dark_blue">
                            <h2 class="box_head round_top"><#menu5_6_5#> - <#Services_Menu_5#></h2>
                            <div class="round_bottom">
                                <div class="row-fluid">
                                    <div id="tabMenu" class="submenuBlock"></div>
                                    <div class="alert alert-info" style="margin: 10px;"><#Adm_Svc_Zapret_Info#></div>

                                    <table width="100%" cellpadding="4" cellspacing="0" class="table" id="tbl_zapret">
                                        <tr>
                                            <th width="50%" style="border-top: 0 none"><a class="help_tooltip" href="javascript:void(0);" onmouseover="openTooltip(this, 25, 2);"><#Adm_Svc_Zapret_Enable#></a></th>
                                            <td style="border-top: 0 none">
                                                <div class="main_itoggle">
                                                    <div id="zapret_enable_on_of">
                                                        <input type="checkbox" id="zapret_enable_fake" <% nvram_match_x("", "zapret_enable", "1", "value=1 checked"); %><% nvram_match_x("", "zapret_enable", "0", "value=0"); %>>
                                                    </div>
                                                </div>
                                                <div style="position: absolute; margin-left: -10000px;">
                                                    <input type="radio" name="zapret_enable" id="zapret_enable_1" class="input" value="1" <% nvram_match_x("", "zapret_enable", "1", "checked"); %>/><#checkbox_Yes#>
                                                    <input type="radio" name="zapret_enable" id="zapret_enable_0" class="input" value="0" <% nvram_match_x("", "zapret_enable", "0", "checked"); %>/><#checkbox_No#>
                                                </div>
                                            </td>
                                        </tr>

                                        <tbody id="row_zapret_service" style="border: none">
                                        <tr>
                                            <th><#PPPConnection_x_WANType_statusname#>:</th>
                                            <td>
                                                <span id="zapret_iface_list"></span>
                                                <input type="hidden" name="zapret_iface" value="<% nvram_get_x("", "zapret_iface"); %>">
                                            </td>
                                        </tr>
                                            <th><#ZapretAllowedClients#>:</th>
                                            <td>
                                                <span id="zapret_clients_list"></span>
                                                <input type="hidden" name="zapret_clients" value="<% nvram_get_x("", "zapret_clients"); %>">
                                                <input type="hidden" name="zapret_clients_allowed" value="<% nvram_get_x("", "zapret_clients_allowed"); %>">
                                            </td>
                                        </tr>
                                        <tr>
                                            <th><#ZapretLog#>:</th>
                                            <td>
                                                <select name="zapret_log" class="input">
                                                    <option value="0" <% nvram_match_x("", "zapret_log", "0","selected"); %>><#CTL_Disabled#></option>
                                                    <option value="1" <% nvram_match_x("", "zapret_log", "1","selected"); %>><#CTL_Enabled#></option>
                                                </select>
                                            </td>
                                        </tr>
                                        <tr>
                                        <tr>
                                            <th width="50%" style="border-bottom: 0 none;"><a href="javascript:spoiler_toggle('zapret.strategy')"><#ZapretStrategy#>: <i style="scale: 75%;" class="icon-chevron-down"></i></a></th>
                                            <td style="border-bottom: 0 none;">
                                                <select name="zapret_strategy" class="input" onchange="zapret_strategy_change(this, 1);">
                                                    <option value="" <% nvram_match_x("", "zapret_strategy", "","selected"); %>><#ZapretDefaultProfile#></option>
                                                    <option value="0" <% nvram_match_x("", "zapret_strategy", "0","selected"); %>><#ZapretStrategyProfile#> #0</option>
                                                    <option value="1" <% nvram_match_x("", "zapret_strategy", "1","selected"); %>><#ZapretStrategyProfile#> #1</option>
                                                    <option value="2" <% nvram_match_x("", "zapret_strategy", "2","selected"); %>><#ZapretStrategyProfile#> #2</option>
                                                    <option value="3" <% nvram_match_x("", "zapret_strategy", "3","selected"); %>><#ZapretStrategyProfile#> #3</option>
                                                    <option value="4" <% nvram_match_x("", "zapret_strategy", "4","selected"); %>><#ZapretStrategyProfile#> #4</option>
                                                    <option value="5" <% nvram_match_x("", "zapret_strategy", "5","selected"); %>><#ZapretStrategyProfile#> #5</option>
                                                    <option value="6" <% nvram_match_x("", "zapret_strategy", "6","selected"); %>><#ZapretStrategyProfile#> #6</option>
                                                    <option value="7" <% nvram_match_x("", "zapret_strategy", "7","selected"); %>><#ZapretStrategyProfile#> #7</option>
                                                    <option value="8" <% nvram_match_x("", "zapret_strategy", "8","selected"); %>><#ZapretStrategyProfile#> #8</option>
                                                    <option value="9" <% nvram_match_x("", "zapret_strategy", "9","selected"); %>><#ZapretStrategyProfile#> #9</option>
                                                </select>
                                                &nbsp;<input type="button" class="btn btn-info" style="outline:0" onclick="restoreZapret();" value="<#CTL_restore#>"/>
                                            </td>
                                            <tr>
                                                <td id="zapret.strategy" colspan="2" style="padding-top: 0px; border-top: 0 none; display:none">
                                                    <div>
                                                        <textarea rows="20" spellcheck="false" maxlength="4096" class="span12 strategy" id="zapretc.strategy" name="zapretc.strategy"><% nvram_dump("zapretc.strategy",""); %></textarea>
                                                        <textarea rows="20" spellcheck="false" maxlength="4096" class="span12 strategy" id="zapretc.strategy0" name="zapretc.strategy0"><% nvram_dump("zapretc.strategy0",""); %></textarea>
                                                        <textarea rows="20" spellcheck="false" maxlength="4096" class="span12 strategy" id="zapretc.strategy1" name="zapretc.strategy1"><% nvram_dump("zapretc.strategy1",""); %></textarea>
                                                        <textarea rows="20" spellcheck="false" maxlength="4096" class="span12 strategy" id="zapretc.strategy2" name="zapretc.strategy2"><% nvram_dump("zapretc.strategy2",""); %></textarea>
                                                        <textarea rows="20" spellcheck="false" maxlength="4096" class="span12 strategy" id="zapretc.strategy3" name="zapretc.strategy3"><% nvram_dump("zapretc.strategy3",""); %></textarea>
                                                        <textarea rows="20" spellcheck="false" maxlength="4096" class="span12 strategy" id="zapretc.strategy4" name="zapretc.strategy4"><% nvram_dump("zapretc.strategy4",""); %></textarea>
                                                        <textarea rows="20" spellcheck="false" maxlength="4096" class="span12 strategy" id="zapretc.strategy5" name="zapretc.strategy5"><% nvram_dump("zapretc.strategy5",""); %></textarea>
                                                        <textarea rows="20" spellcheck="false" maxlength="4096" class="span12 strategy" id="zapretc.strategy6" name="zapretc.strategy6"><% nvram_dump("zapretc.strategy6",""); %></textarea>
                                                        <textarea rows="20" spellcheck="false" maxlength="4096" class="span12 strategy" id="zapretc.strategy7" name="zapretc.strategy7"><% nvram_dump("zapretc.strategy7",""); %></textarea>
                                                        <textarea rows="20" spellcheck="false" maxlength="4096" class="span12 strategy" id="zapretc.strategy8" name="zapretc.strategy8"><% nvram_dump("zapretc.strategy8",""); %></textarea>
                                                        <textarea rows="20" spellcheck="false" maxlength="4096" class="span12 strategy" id="zapretc.strategy9" name="zapretc.strategy9"><% nvram_dump("zapretc.strategy9",""); %></textarea>
                                                    </div>
                                                </td>
                                            </tr>
                                        </tr>
                                        <tr>
                                            <td colspan="2">
                                                <a href="javascript:spoiler_toggle('domain.list')"><span><#ZapretDomainLists#>:</span> <i style="scale: 75%;" class="icon-chevron-down"></i></a>
                                                <table id="domain.list" height="100%" width="100%" cellpadding="0" cellspacing="0" class="table" style="border: 0px; margin: 0px; margin-bottom: 8px; display:none">
                                                    <tr>
                                                        <td style="border:0px; padding-bottom: 4px;">
                                                            <#ZapretCustomList#>:
                                                        </td>
                                                        <td style="border:0px; padding-bottom: 4px; padding-left: 11px;">
                                                            <#ZapretAutomaticList#>:
                                                        </td>
                                                        <td style="border:0px; padding-bottom: 4px; padding-left: 13px; position: relative">
                                                            <input type="button" class="btn btn-info" style="max-width: 94px; outline:0; position: absolute; top: -18px; left: 124px" onclick="restoreZapretDomain();" value="<#CTL_restore#>"/>
                                                            <#ZapretExclusionList#>:
                                                        </td>
                                                    </tr>
                                                    <tr height="100%">
                                                        <td style="border:0px; width: 33%; padding: 0px; padding-right: 5px; vertical-align: top;">
                                                            <textarea rows="20" spellcheck="false" maxlength="65536" class="span12 strategy" name="zapretc.user.list" style="height: 100%; margin-bottom: 0px"><% nvram_dump("zapretc.user.list",""); %></textarea>
                                                        </td>
                                                        <td style="border:0px; width: 33%; padding: 0px; padding-left: 3px; padding-right: 3px; vertical-align: top;">
                                                            <textarea rows="20" spellcheck="false" maxlength="16384" class="span12 strategy" name="zapretc.auto.list" style="height: 100%; margin-bottom: 0px"><% nvram_dump("zapretc.auto.list",""); %></textarea>
                                                        </td>
                                                        <td style="border:0px; width: 33%; padding: 0px; padding-left: 5px; vertical-align: top;">
                                                            <textarea rows="20" spellcheck="false" maxlength="65536" class="span12 strategy" name="zapretc.exclude.list" style="height: 100%; margin-bottom: 0px"><% nvram_dump("zapretc.exclude.list",""); %></textarea>
                                                        </td>
                                                    </tr>
                                                </table>
                                            </td>
                                        </tr>
                                        <tr>
                                            <td colspan="2">
                                                <a href="javascript:spoiler_toggle('ipset.list')"><span><#ZapretIpsetLists#>:</span> <i style="scale: 75%;" class="icon-chevron-down"></i></a>
                                                <table id="ipset.list" height="100%" width="100%" cellpadding="0" cellspacing="0" class="table" style="border: 0px; margin: 0px; margin-bottom: 8px; display:none">
                                                    <tr>
                                                        <td style="border:0px; padding-bottom: 4px;">
                                                            <#ZapretIpsetCustomList#>:
                                                        </td>
                                                        <td style="border:0px; padding-bottom: 4px; padding-left: 13px; position: relative">
                                                            <#ZapretIpsetExclusionList#>:
                                                        </td>
                                                    </tr>
                                                    <tr height="100%">
                                                        <td style="border:0px; width: 50%; padding: 0px; padding-right: 5px; vertical-align: top;">
                                                            <textarea rows="20" spellcheck="false" maxlength="65536" class="span12 strategy" name="zapretc.ipset.list" style="height: 100%; margin-bottom: 0px"><% nvram_dump("zapretc.ipset.list",""); %></textarea>
                                                        </td>
                                                        <td style="border:0px; padding: 0px; padding-left: 5px; vertical-align: top;">
                                                            <textarea rows="20" spellcheck="false" maxlength="65536" class="span12 strategy" name="zapretc.ipset-exclude.list" style="height: 100%; margin-bottom: 0px"><% nvram_dump("zapretc.ipset-exclude.list",""); %></textarea>
                                                        </td>
                                                    </tr>
                                                </table>
                                            </td>
                                        </tr>
                                        <tr>
                                            <td colspan="2">
                                                <a href="javascript:spoiler_toggle('zapret.post_script')"><span><#ZapretPostScript#>:</span> <i style="scale: 75%;" class="icon-chevron-down"></i></a>
                                                <div id="zapret.post_script" style="display:none;  padding-top: 8px;">
                                                    <textarea rows="20" spellcheck="false" maxlength="16384" class="span12 strategy" name="zapretc.post_script.sh"><% nvram_dump("zapretc.post_script.sh",""); %></textarea>
                                                </div>
                                            </td>
                                        </tr>
                                        </tbody>
                                    </table>

                                    <table class="table">
                                        <tr>
                                            <td style="border: 0 none;">
                                                <center><input class="btn btn-primary" style="width: 219px" onclick="applyRule();" type="button" value="<#CTL_apply#>" /></center>
                                            </td>
                                        </tr>
                                    </table>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    </form>

    <div id="footer"></div>
</div>
</body>
</html>
