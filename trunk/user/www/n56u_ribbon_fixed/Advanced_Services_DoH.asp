<!DOCTYPE html>
<html>
<head>
<title><#Web_Title#> - <#Services_Menu_2#></title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Expires" content="-1">

<link rel="shortcut icon" href="images/favicon.ico">
<link rel="icon" href="images/favicon.png">
<link rel="stylesheet" type="text/css" href="/bootstrap/css/bootstrap.min.css">
<link rel="stylesheet" type="text/css" href="/bootstrap/css/main.css">
<link rel="stylesheet" type="text/css" href="/bootstrap/css/engage.itoggle.css">

<script type="text/javascript" src="/jquery.js"></script>
<script type="text/javascript" src="/bootstrap/js/bootstrap.min.js"></script>
<script type="text/javascript" src="/bootstrap/js/engage.itoggle.min.js"></script>
<script type="text/javascript" src="/state.js"></script>
<script type="text/javascript" src="/general.js"></script>
<script type="text/javascript" src="/itoggle.js"></script>
<script type="text/javascript" src="/popup.js"></script>
<script type="text/javascript" src="/help.js"></script>
<script>
var $j = jQuery.noConflict();
let Resolvers_List = [];
const normalize = str => str.trim().toLowerCase().replace(/\s+/g, '');

$j(document).ready(function() {
	init_itoggle('doh_enable', change_doh_enabled);
});

</script>
<script>

<% login_state_hook(); %>

function initial(){
	show_banner(1);
	show_menu(5,7,3);
	show_footer();
	load_body();

	if (found_app_doh()) {
		showhide_div('tbl_doh', 1);
		loadJSONToSelect('/doh.json', 'doh_resolver_list');
		change_doh_enabled();
	}

	if (found_app_quic()) {
		showhide_div('row_doh_quic', 1);
	} else {
		$j(doh_quic).val('0');
	}
}

function applyRule(){
	if(validForm()){
		showLoading();

		document.form.action_mode.value = " Apply ";
		document.form.current_page.value = "/Advanced_Services_DoH.asp";
		document.form.next_page.value = "";

		document.form.submit();
	}
}

function validate_ipv4(ip) {
	const regex = /^(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}$/;
	return regex.test(ip);
}

function validForm(){
	if (!document.form.doh_enable[0].checked)
		return true;

	if(!validate_range(document.form.doh_listen_port, 1024, 65530)) {
		$j(doh_listen_port).focus();
		return false;
	}

	document.form.doh_bootstrap_dns.value = normalize(document.form.doh_bootstrap_dns.value);
	const ok = document.form.doh_bootstrap_dns.value.split(',').every(ip => validate_ipv4(ip.trim()));
	if(!ok) {
		alert("Invalid IPv4 address!");
		$j(doh_bootstrap_dns).focus();
		return false;
	}

	if (Resolvers_List.length == 0) {
		alert("<#Service_Stubby_Alert_Empty#>");
		$j(doh_server).focus();
		return false;
	}

	return true;
}

function done_validating(action){
	refreshpage();
}

function change_doh_enabled(){
	var v = document.form.doh_enable[0].checked;
	showhide_div('doh_show', v);

	var r0, r1, r2, r3
	r0 = normalize('<% nvram_get_x("", "doh_server0"); %>');
	r1 = normalize('<% nvram_get_x("", "doh_server1"); %>');
	r2 = normalize('<% nvram_get_x("", "doh_server2"); %>');
	r3 = normalize('<% nvram_get_x("", "doh_server3"); %>');

	Resolvers_List = [];
	if (r0) Resolvers_List.push({resolver: r0});
	if (r1) Resolvers_List.push({resolver: r1});
	if (r2) Resolvers_List.push({resolver: r2});
	if (r3) Resolvers_List.push({resolver: r3});

	resolver_list_update();
}

function on_doh_select_change(selectObject){
	if ( !$j(selectObject).val() ) return false;

	$j(doh_server).val($j(selectObject).val()).focus();
}

async function loadJSONToSelect(fileName, select) {
	try {
		const response = await fetch(fileName);
		let dataJson = await response.json();

		dataJson.sort((a, b) => a.name.toLowerCase().localeCompare(b.name.toLowerCase()));
		dataJson.forEach(obj => {
			const option = document.createElement('option');
			option.value = obj.url;
			option.textContent = obj.name;
			$(select).appendChild(option);
		});
	} catch (error) {
		console.error('Error:', error);
	}
}

function resolver_add() {
	if ( $j(doh_server).val() ) {
		if(!Resolvers_List.find(i => normalize(i.resolver) === normalize($j(doh_server).val()))) {
			Resolvers_List.push({resolver: normalize($j(doh_server).val())})
		}
	}

	resolver_list_update();
	$j(doh_server).val('');
}

function resolver_del(index){
	if (Resolvers_List.length > 0) {
		Resolvers_List.splice(index, 1);
	}

	resolver_list_update();
}

function resolver_list_update() {
	var code = `<table width="100%" style="table-layout: fixed; margin: 0; border: 1px solid #E3E3E3">`;
	var resolver;
	var port = Number($j(doh_listen_port).val());
	var ip = "127.0.0.1";

	if ($j(doh_listen_mode).val() == 1)
		ip = $j('#doh_listen_mode option:selected').text();
	if ($j(doh_listen_mode).val() == 2)
		ip = "0.0.0.0";

	for (i=0; i<4; i++){
		resolver = '';
		if (Resolvers_List[i]){
			resolver = Resolvers_List[i].resolver;

			code += `<tr ${(i % 2 === 0 ? 'style="background-color: #EEEEEE"' : '')}>`;
			code += `<td style="width: 60%; word-break: break-all">${resolver}</td>`;
			code += `<td style="word-break: break-all">${ip}:${port + i}</td>`;
			code += `<td style="width: 28px; padding-left: 0px"><div title="<#CTL_del#>" class="icon icon-remove" onclick="resolver_del(${i})" style="cursor:pointer; margin-left: 10px"></div></td>`;
			code += `</tr>`;
		}
		code += `<input type="hidden" name="doh_server${i}" value="${resolver}">`;
	}

	if (Resolvers_List.length < 4)
		$j(resolver_button_add).attr("disabled",false);
	else
		$j(resolver_button_add).attr("disabled",true);

	if (Resolvers_List.length == 0)
		code += `<tr><td colspan="3" class="alert" style="text-align: center; padding: 0; border-color: transparent"><div class="alert alert-info" style="margin: 0"><#Service_Stubby_DNSList_Help#></div></td></tr>`;

	code += `</table>`;
	$("Resolver_List_Block").innerHTML = code;
}

function updateTooltip(input) {
	if (input.scrollWidth > input.clientWidth) {
		input.title = input.value;
	} else {
		input.removeAttribute('title');
	}
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
    <input type="hidden" name="current_page" value="Advanced_Services_DoH.asp">
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
                            <h2 class="box_head round_top"><#menu5_6_5#> - <#Services_Menu_3#></h2>
                            <div class="round_bottom">
                                <div class="row-fluid">
                                    <div id="tabMenu" class="submenuBlock"></div>
                                    <div class="alert alert-info" style="margin: 10px;"><#Service_DoH_Info#></div>

                                    <table width="100%" cellpadding="4" cellspacing="0" class="table" id="tbl_doh">
                                        <tr>
                                            <th width="50%" style="border-top: 0 none"><a class="help_tooltip" href="javascript:void(0);" onmouseover="openTooltip(this, 25, 3);"><#Adm_Svc_doh#></a></th>
                                            <td style="border-top: 0 none">
                                                <div class="main_itoggle">
                                                    <div id="doh_enable_on_of">
                                                        <input type="checkbox" id="doh_enable_fake" <% nvram_match_x("", "doh_enable", "1", "value=1 checked"); %><% nvram_match_x("", "doh_enable", "0", "value=0"); %>>
                                                    </div>
                                                </div>
                                                <div style="position: absolute; margin-left: -10000px;">
                                                    <input type="radio" name="doh_enable" id="doh_enable_1" class="input" value="1" <% nvram_match_x("", "doh_enable", "1", "checked"); %>/><#checkbox_Yes#>
                                                    <input type="radio" name="doh_enable" id="doh_enable_0" class="input" value="0" <% nvram_match_x("", "doh_enable", "0", "checked"); %>/><#checkbox_No#>
                                                </div>
                                            </td>
                                        </tr>

                                        <tbody id="doh_show" style="border: none">
                                        <tr>
                                            <th width="50%"><a class="help_tooltip" href="javascript:void(0);" onmouseover="openTooltip(this, 25, 6);"><#Service_Stubby_Mode#>:</a></th>
                                            <td>
                                                <select name="doh_mode" class="input">
                                                    <option value="0" <% nvram_match_x("", "doh_mode", "0","selected"); %>><#Service_DNSCrypt_Mode_Menu0#></option>
                                                    <option value="1" <% nvram_match_x("", "doh_mode", "1","selected"); %>><#Service_DNSCrypt_Mode_Menu1#> (*)</option>
                                                </select>
                                            </td>
                                        </tr>
                                        <tr>
                                            <th><#Adm_Svc_dnscrypt_ipaddr#></th>
                                            <td>
                                                <select name="doh_listen_mode" id="doh_listen_mode" class="input" onchange="resolver_list_update()">
                                                    <option value="0" <% nvram_match_x("", "doh_listen_mode", "0","selected"); %>>127.0.0.1 (*)</option>
                                                    <option value="1" <% nvram_match_x("", "doh_listen_mode", "1","selected"); %>><% nvram_get_x("", "lan_ipaddr_t"); %></option>
                                                    <option value="2" <% nvram_match_x("", "doh_listen_mode", "2","selected"); %>><#Adm_Svc_dnscrypt_all#></option>
                                                </select>
                                            </td>
                                        </tr>
                                        <tr>
                                            <th><#Adm_Svc_dnscrypt_port#></th>
                                            <td>
                                                <input type="text" maxlength="5" size="15" id="doh_listen_port" name="doh_listen_port" class="input" value="<% nvram_get_x("", "doh_listen_port"); %>" onchange="resolver_list_update()" onkeypress="return is_ipaddrport(this,event);"/>
                                                &nbsp;<span style="color:#888;">[1024..65530]</span>
                                            </td>
                                        </tr>
                                        <tr id="row_doh_quic" style="display:none">
                                            <th><#Service_DoH_Quic#>:</th>
                                            <td>
                                                <select name="doh_quic" id="doh_quic" class="input">
                                                    <option value="0" <% nvram_match_x("", "doh_quic", "0","selected"); %>><#CTL_Disabled#></option>
                                                    <option value="1" <% nvram_match_x("", "doh_quic", "1","selected"); %>><#CTL_Enabled#></option>
                                                </select>
                                            </td>
                                        </tr>
                                        <tr>
                                            <th style="padding-bottom: 18px"><#Service_DoH_BootstrapDNS#>:</th>
                                            <td style="padding-bottom: 18px">
                                                <input type="text" maxlength="128" id="doh_bootstrap_dns" name="doh_bootstrap_dns" class="input" value="<% nvram_get_x("", "doh_bootstrap_dns"); %>" oninput="updateTooltip(this)" onmouseenter="updateTooltip(this)"/>
                                            </td>
                                        </tr>
                                        <tr>
                                            <th colspan="2" style="background-color: #E3E3E3;"><#Service_Stubby_Resolvers_Header#></th>
                                        </tr>
                                        <tr>
                                            <th><#Adm_Svc_dnscrypt_resolver#></th>
                                            <td>
                                                <span class="input-prepend">
                                                    <input style="border-radius: 3px 0 0 3px; width: 252px" type="text" maxlength="128" class="input" size="15" id="doh_server" oninput="updateTooltip(this)" onmouseenter="updateTooltip(this)"/>&#8203;
                                                    <select title="<#Service_Stubby_Resolvers_Header#>" class="input" id="doh_resolver_list" style="margin-left: -1px; max-width: 24px; outline:0" onchange="on_doh_select_change(this)" onclick="this.selectedIndex=-1;"></select>
                                                </span>
                                                <button type="button" class="btn" style="outline:0" id="resolver_button_add" title="<#CTL_add#>" onclick="resolver_add();"><i class="icon icon-plus"></i></button>
                                            </td>
                                        </tr>
                                        <tr>
                                            <td colspan="2" style="padding-top: 8px; padding-bottom: 18px; border: none">
                                                <div id="Resolver_List_Block"></div>
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
