<!DOCTYPE html>
<html>
<head>
<title><#Web_Title#> - <#Services_Menu_6#></title>
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

$j(document).ready(function() {
	init_itoggle('tor_enable', change_tor_enabled);
	init_itoggle('privoxy_enable', change_privoxy_enabled);
});

</script>
<script>

<% login_state_hook(); %>

var ipmonitor = [<% get_static_client(); %>];
let IPSetList = [<% get_ipset_list_hook(); %>];

function initial(){
	show_banner(1);
	show_menu(5,7,6);
	show_footer();
	load_body();

	if (found_app_tor() || found_app_privoxy())
		showhide_div('tbl_anon', 1);
	else
		showhide_div('tbl_anon', 0);

	if(!found_app_tor()){
		showhide_div('row_tor', 0);
		showhide_div('row_tor_conf', 0);
	}else
		change_tor_enabled();
		
	if(!found_app_privoxy()){
		showhide_div('row_privoxy', 0);
		showhide_div('row_privoxy_conf', 0);
		showhide_div('row_privoxy_action', 0);
		showhide_div('row_privoxy_filter', 0);
		showhide_div('row_privoxy_trust', 0);
	}else
		change_privoxy_enabled();
}

function applyRule(){
	if(validForm()){
		showLoading();

		document.form.action_mode.value = " Apply ";
		document.form.current_page.value = "/Advanced_Services_Proxy.asp";
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

function textarea_tor_enabled(v){
	inputCtrl(document.form['torconf.torrc'], v);
}

function textarea_privoxy_enabled(v){
	inputCtrl(document.form['privoxy.config'], v);
	inputCtrl(document.form['privoxy.user.action'], v);
	inputCtrl(document.form['privoxy.user.filter'], v);
	inputCtrl(document.form['privoxy.user.trust'], v);
}

function change_tor_enabled(){
	var v = document.form.tor_enable[0].checked;
	showhide_div('row_tor_conf', v);
	showhide_div('row_dipset', found_support_ipset());
	showhide_div('row_tor_ipset', found_support_ipset());
	tor_proxy_change()
	if (!login_safe())
		v = 0;
	textarea_tor_enabled(v);

	let allowed_list, items_list, allowed, items;

	allowed_list = "<% nvram_get_x("", "tor_clients_allowed"); %>";
	items_list = "<% nvram_get_x("", "tor_clients"); %>";

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

	$j('#tor_clients_list').multiSelectDropdown({
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
			document.form.tor_clients_allowed.value = selected.join(',');
			document.form.tor_clients.value = this.multiSelectDropdown('getAllItems')
				.filter(item => !item.title)
				.map(item => item.text)
				.join(',');
		}
	});

	if (!found_support_ipset())
		return;

	const excludeNames = new Set([
		"nozapret",
		"nozapret6",
		"vpn.remote", "vpn.exclude", "vpn.clients",
		"tor.remote", "tor.exclude", "tor.clients"
	]);

	allowed_list = "<% nvram_get_x("", "tor_ipset_allowed"); %>";
	allowed = allowed_list.replace(/\s+/g, '').split(',')
		.filter(Boolean)
		.map(item => ({text: item, checked: true }));

	const map = new Map(
		allowed.map(item => [item.text, {...item, title: ""}])
	);

	for (const item of IPSetList) {
		if (excludeNames.has(item.name)) {
			continue;
		}

		// russian word declension...
		const title = item.entries
			? `${item.entries} ${declOfNum(item.entries, ['<#Entries1#>', '<#Entries2#>', '<#Entries#>'])}`
			: "";

		if (map.has(item.name)) {
			map.get(item.name).title = title;
		} else {
			map.set(item.name, {text: item.name, title, checked: false });
		}
	}

	const result = [...map.values()].sort((a, b) => {
		if (a.checked !== b.checked) {
			return a.checked ? -1 : 1;
		}

		const aUpper = a.text[0] === a.text[0].toUpperCase();
		const bUpper = b.text[0] === b.text[0].toUpperCase();

		if (aUpper !== bUpper) {
			return aUpper ? -1 : 1;
		}

		return a.text.localeCompare(b.text);
	});

	$j('#tor_ipset').multiSelectDropdown({
		items: result,
		placeholder: "<#Select_menu_default#>",
		width: '320px',
		allowDelete: false,
		allowAdd: true,
		addSuggestionText: '<#CTL_add#>',
		removeSpaces: true,
		allowedItems: '^[a-zA-Z0-9-_.]+$',
		allowedAlert: '<#JS_field_noletter#>',
		onChange: function(selected){
			document.form.tor_ipset_allowed.value = selected.join(',');
		}
	});
}

function tor_proxy_change(){
	var proto = document.form.tor_proxy_mode.value;
	var v1 = (proto == "1") ? 1 : 0;
	var v2 = (proto == "2") ? 1 : 0;

	showhide_div('tor_clients', v1 || v2);
	showhide_div('tor_remote', v1);

        if (found_support_ipset()) {
		showhide_div('row_tor_ipset', v1);
		showhide_div('row_dipset', v1);
	}
}

function change_privoxy_enabled(){
	var v = document.form.privoxy_enable[0].checked;
	showhide_div('row_privoxy_conf', v);
	showhide_div('row_privoxy_action', v);
	showhide_div('row_privoxy_filter', v);
	showhide_div('row_privoxy_trust', v);
	if (!login_safe())
		v = 0;
	textarea_privoxy_enabled(v);
}

</script>
<style>
    .caption-bold {
        font-weight: bold;
    }
    .nav-tabs > li > a {
        padding-right: 8px;
        padding-left: 8px;
    }
    #tor_ipset .msd-title {
        font-size: 13px;
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
                            <h2 class="box_head round_top"><#menu5_6_5#> - <#Services_Menu_6#></h2>
                            <div class="round_bottom">
                                <div class="row-fluid">
                                    <div id="tabMenu" class="submenuBlock"></div>
                                    <div class="alert alert-info" style="margin: 10px;"><#Service_Proxy_Info#></div>

                                    <table width="100%" cellpadding="4" cellspacing="0" class="table" id="tbl_anon">
                                        <tr>
                                            <th colspan="2" style="background-color: #E3E3E3;"><#Adm_System_anon#></th>
                                        </tr>

                                        <tr id="row_tor">
                                            <th width="50%"><#Adm_Svc_tor#></th>
                                            <td>
                                                <div class="main_itoggle">
                                                    <div id="tor_enable_on_of">
                                                        <input type="checkbox" id="tor_enable_fake" <% nvram_match_x("", "tor_enable", "1", "value=1 checked"); %><% nvram_match_x("", "tor_enable", "0", "value=0"); %>>
                                                    </div>
                                                </div>
                                                <div style="position: absolute; margin-left: -10000px;">
                                                    <input type="radio" name="tor_enable" id="tor_enable_1" class="input" value="1" <% nvram_match_x("", "tor_enable", "1", "checked"); %>/><#checkbox_Yes#>
                                                    <input type="radio" name="tor_enable" id="tor_enable_0" class="input" value="0" <% nvram_match_x("", "tor_enable", "0", "checked"); %>/><#checkbox_No#>
                                                </div>
                                            </td>
                                        </tr>

                                        <tr id="row_tor_conf">
                                            <td colspan="2" style="padding: 0; border: 0;">
                                                <table height="100%" width="100%" cellpadding="0" cellspacing="0" class="table" style="border: 0px; margin: 0px;">
                                                    <tr>
                                                        <th width="50%"><#Adm_Svc_TorTransparent#>:</th>
                                                        <td>
                                                            <select name="tor_proxy_mode" class="input" onchange="tor_proxy_change();" style="width: 320px;">
                                                                <option value="0" <% nvram_match_x("", "tor_proxy_mode", "0","selected"); %>><#CTL_Disabled#></option>
                                                                <option value="1" <% nvram_match_x("", "tor_proxy_mode", "1","selected"); %>><#Adm_Svc_TorSelRemote#></option>
                                                                <option value="2" <% nvram_match_x("", "tor_proxy_mode", "2","selected"); %>><#Adm_Svc_TorAllRemote#></option>
                                                            </select>
                                                        </td>
                                                    </tr>
                                                    <tr id="tor_clients">
                                                        <th width="50%"><#Adm_Svc_TorListUsers#>:</th>
                                                        <td>
                                                            <span id="tor_clients_list"></span>
                                                            <input type="hidden" name="tor_clients" value="<% nvram_get_x("", "tor_clients"); %>">
                                                            <input type="hidden" name="tor_clients_allowed" value="<% nvram_get_x("", "tor_clients_allowed"); %>">
                                                        </td>
                                                    </tr>
                                                    <tr id="row_tor_ipset">
                                                        <th width="50%"><#Adm_Svc_TorListIpset#>:</th>
                                                        <td>
                                                            <span id="tor_ipset"></span>
                                                            <input type="hidden" name="tor_ipset_allowed" value="<% nvram_get_x("", "tor_ipset_allowed"); %>">
                                                        </td>
                                                    </tr>
                                                    <tr id="tor_remote">
                                                        <td colspan="2">
                                                            <a href="javascript:spoiler_toggle('spoiler_tor_remote')"><span><#Adm_Svc_TorListRemote#>:</span> <i style="scale: 75%;" class="icon-chevron-down"></i></a>
                                                            <div id="spoiler_tor_remote" style="display:none; padding-top: 8px;">
                                                                <textarea rows="16" wrap="off" spellcheck="false" maxlength="16384" class="span12" name="torconf.remote_network.list" style="font-family:'Courier New'; font-size:12px; resize:vertical;"><% nvram_dump("torconf.remote_network.list",""); %></textarea>
                                                            </div>
                                                        </td>
                                                    </tr>
                                                    <tr id="row_dipset">
                                                        <td colspan="2">
                                                            <a href="javascript:spoiler_toggle('spoiler_dipset')"><span><#CustomConf#> "dnsmasq.ipset"</span> <i style="scale: 75%;" class="icon-chevron-down"></i></a>
                                                            <div id="spoiler_dipset" style="display:none;">
                                                                <textarea rows="16" wrap="off" spellcheck="false" maxlength="16384" class="span12" name="dnsmasq.dnsmasq.ipset" style="resize: vertical; font-family:'Courier New'; font-size:12px;"><% nvram_dump("dnsmasq.dnsmasq.ipset",""); %></textarea>
                                                            </div>
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td colspan="2">
                                                            <a href="javascript:spoiler_toggle('spoiler_tor_conf')"><span><#CustomConf#> "torrc"</span> <i style="scale: 75%;" class="icon-chevron-down"></i></a>
                                                            <div id="spoiler_tor_conf" style="display:none; padding-top: 8px;">
                                                                <textarea rows="16" wrap="off" spellcheck="false" maxlength="4096" class="span12" name="torconf.torrc" style="font-family:'Courier New'; font-size:12px; resize:vertical;"><% nvram_dump("torconf.torrc",""); %></textarea>
                                                            </div>
                                                        </td>
                                                    </tr>
                                                </table>
                                            </td>
                                        </tr>

                                        <tr id="row_privoxy">
                                            <th width="50%"><#Adm_Svc_privoxy#></th>
                                            <td>
                                                <div class="main_itoggle">
                                                    <div id="privoxy_enable_on_of">
                                                        <input type="checkbox" id="privoxy_enable_fake" <% nvram_match_x("", "privoxy_enable", "1", "value=1 checked"); %><% nvram_match_x("", "privoxy_enable", "0", "value=0"); %>>
                                                    </div>
                                                </div>
                                                <div style="position: absolute; margin-left: -10000px;">
                                                    <input type="radio" name="privoxy_enable" id="privoxy_enable_1" class="input" value="1" <% nvram_match_x("", "privoxy_enable", "1", "checked"); %>/><#checkbox_Yes#>
                                                    <input type="radio" name="privoxy_enable" id="privoxy_enable_0" class="input" value="0" <% nvram_match_x("", "privoxy_enable", "0", "checked"); %>/><#checkbox_No#>
                                                </div>
                                            </td>
                                        </tr>
                                        <tr id="row_privoxy_conf" style="display:none">
                                            <td colspan="2">
                                                <a href="javascript:spoiler_toggle('spoiler_privoxy_conf')"><span><#CustomConf#> "config"</span></a>
                                                <div id="spoiler_privoxy_conf" style="display:none;">
                                                    <textarea rows="16" wrap="off" spellcheck="false" maxlength="8192" class="span12" name="privoxy.config" style="font-family:'Courier New'; font-size:12px; resize:vertical;"><% nvram_dump("privoxy.config",""); %></textarea>
                                                </div>
                                            </td>
                                        </tr>
                                        <tr id="row_privoxy_action" style="display:none">
                                            <td colspan="2">
                                                <a href="javascript:spoiler_toggle('spoiler_privoxy_action')"><span><#CustomConf#> "user.action"</span></a>
                                                <div id="spoiler_privoxy_action" style="display:none;">
                                                    <textarea rows="16" wrap="off" spellcheck="false" maxlength="8192" class="span12" name="privoxy.user.action" style="font-family:'Courier New'; font-size:12px; resize:vertical;"><% nvram_dump("privoxy.user.action",""); %></textarea>
                                                </div>
                                            </td>
                                        </tr>
                                        <tr id="row_privoxy_filter" style="display:none">
                                            <td colspan="2">
                                                <a href="javascript:spoiler_toggle('spoiler_privoxy_filter')"><span><#CustomConf#> "user.filter"</span></a>
                                                <div id="spoiler_privoxy_filter" style="display:none;">
                                                    <textarea rows="16" wrap="off" spellcheck="false" maxlength="8192" class="span12" name="privoxy.user.filter" style="font-family:'Courier New'; font-size:12px; resize:vertical;"><% nvram_dump("privoxy.user.filter",""); %></textarea>
                                                </div>
                                            </td>
                                        </tr>
                                        <tr id="row_privoxy_trust" style="display:none">
                                            <td colspan="2">
                                                <a href="javascript:spoiler_toggle('spoiler_privoxy_trust')"><span><#CustomConf#> "user.trust"</span></a>
                                                <div id="spoiler_privoxy_trust" style="display:none;">
                                                    <textarea rows="16" wrap="off" spellcheck="false" maxlength="8192" class="span12" name="privoxy.user.trust" style="font-family:'Courier New'; font-size:12px; resize:vertical;"><% nvram_dump("privoxy.user.trust",""); %></textarea>
                                                </div>
                                            </td>
                                        </tr>
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
