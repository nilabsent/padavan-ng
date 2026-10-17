<!DOCTYPE html>
<html>
<head>
<title><#Web_Title#> - <#Services_Menu_4#></title>
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
	init_itoggle('stubby_enable', change_stubby_enabled);
});

</script>
<script>

<% login_state_hook(); %>

function initial(){
	show_banner(1);
	show_menu(5,7,4);
	show_footer();
	load_body();

	if (found_app_stubby()) {
		showhide_div('tbl_dot', 1);
		loadJSONToSelect('/dot.json', 'stubby_resolver_list');
		change_stubby_enabled();
	}
}

function applyRule(){
	if(validForm()){
		showLoading();

		document.form.action_mode.value = " Apply ";
		document.form.current_page.value = "/Advanced_Services_DoT.asp";
		document.form.next_page.value = "";

		document.form.submit();
	}
}

function validForm(){
	if (!document.form.stubby_enable[0].checked)
		return true;

	if (Resolvers_List.length == 0) {
		alert("<#Service_Stubby_Alert_Empty#>");
		$j(stubby_server).focus();
		return false;
	}

	if(!validate_range(document.form.stubby_listen_port, 1024, 65535)) {
		$j(stubby_listen_port).focus();
		return false;
	}

	return true;
}

function done_validating(action){
	refreshpage();
}

function change_stubby_enabled(){
	var v = document.form.stubby_enable[0].checked;
	showhide_div('stubby_show', v);

	var srv0, srv1, srv2, srv3, ip0, ip1, ip2, ip3;
	srv0 = normalize('<% nvram_get_x("", "stubby_server0"); %>');
	ip0 = normalize('<% nvram_get_x("", "stubby_server_ip0"); %>');
	srv1 = normalize('<% nvram_get_x("", "stubby_server1"); %>');
	ip1 = normalize('<% nvram_get_x("", "stubby_server_ip1"); %>');
	srv2 = normalize('<% nvram_get_x("", "stubby_server2"); %>');
	ip2 = normalize('<% nvram_get_x("", "stubby_server_ip2"); %>');
	srv3 = normalize('<% nvram_get_x("", "stubby_server3"); %>');
	ip3 = normalize('<% nvram_get_x("", "stubby_server_ip3"); %>');

	Resolvers_List = [];
	if (srv0 && ip0) Resolvers_List.push({host: srv0, ip: ip0});
	if (srv1 && ip1) Resolvers_List.push({host: srv1, ip: ip1});
	if (srv2 && ip2) Resolvers_List.push({host: srv2, ip: ip2});
	if (srv3 && ip3) Resolvers_List.push({host: srv3, ip: ip3});

	stubby_update_list();
}

function on_stubby_select_change(selectObject){
	if ( !$j(selectObject).val() ) return false;

	$j(stubby_server_ip).val($j('option:selected', selectObject).attr("data-dns"));
	$j(stubby_server).val($j(selectObject).val()).focus();
}

function resolver_add(){
	if ( $j(stubby_server).val() && $j(stubby_server_ip).val() ) {
		if(!Resolvers_List.find(i => normalize(i.host) === normalize($j(stubby_server).val()))) {
			Resolvers_List.push({host: normalize($j(stubby_server).val()), ip: normalize($j(stubby_server_ip).val())})
		}
	}

	stubby_update_list();
	$j(stubby_server_ip).val('');
	$j(stubby_server).val('');
}

function resolver_del(index){
	if (Resolvers_List.length > 0) {
		Resolvers_List.splice(index, 1);
	}
	stubby_update_list();
}

function stubby_update_list(){
	var code = `<table width="100%" style="table-layout: fixed; margin: 0; border: 1px solid #E3E3E3">`;
	var srv, ip;

	for (i=0; i<4; i++){
		srv = '';
		ip = '';
		if (Resolvers_List[i]){
			srv = Resolvers_List[i].host;
			ip = Resolvers_List[i].ip;

			code += `<tr ${(i % 2 === 0 ? 'style="background-color: #EEEEEE"' : '')}>`;
			code += `<td style="width: 49%; word-break: break-all">${srv}</td>`;
			code += `<td style="word-break: break-all">${ip}</td>`;
			code += `<td style="width: 28px; padding-left: 0px"><div title="<#CTL_del#>" class="icon icon-remove" onclick="resolver_del(${i})" style="cursor:pointer; margin-left: 10px"></div></td>`;
			code += `</tr>`;
		}
		code += `<input type="hidden" name="stubby_server${i}" value="${srv}">`;
		code += `<input type="hidden" name="stubby_server_ip${i}" value="${ip}">`;
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

async function loadJSONToSelect(fileName, select) {
	try {
		const response = await fetch(fileName);
		let dataJson = await response.json();

		dataJson.sort((a, b) => a.name.toLowerCase().localeCompare(b.name.toLowerCase()));
		dataJson.forEach(obj => {
			const option = document.createElement('option');
			option.value = obj.url;
			option.textContent = obj.name;
			option.dataset.dns = obj.dns;
			$(select).appendChild(option);
		});
	} catch (error) {
		console.error('Error:', error);
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
    <input type="hidden" name="current_page" value="Advanced_Services_DoT.asp">
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
                            <h2 class="box_head round_top"><#menu5_6_5#> - <#Services_Menu_4#></h2>
                            <div class="round_bottom">
                                <div class="row-fluid">
                                    <div id="tabMenu" class="submenuBlock"></div>
                                    <div class="alert alert-info" style="margin: 10px;"><#Service_DoT_Info#></div>

                                    <table width="100%" cellpadding="4" cellspacing="0" class="table" id="tbl_dot">
                                        <tr>
                                            <th width="50%" style="border-top: 0 none"><a class="help_tooltip" href="javascript:void(0);" onmouseover="openTooltip(this, 25, 4);"><#Service_Stubby_Enable#></a></th>
                                            <td style="border-top: 0 none">
                                                <div class="main_itoggle">
                                                    <div id="stubby_enable_on_of">
                                                        <input type="checkbox" id="stubby_enable_fake" <% nvram_match_x("", "stubby_enable", "1", "value=1 checked"); %><% nvram_match_x("", "stubby_enable", "0", "value=0"); %>>
                                                    </div>
                                                </div>
                                                <div style="position: absolute; margin-left: -10000px;">
                                                    <input type="radio" name="stubby_enable" id="stubby_enable_1" class="input" value="1" <% nvram_match_x("", "stubby_enable", "1", "checked"); %>/><#checkbox_Yes#>
                                                    <input type="radio" name="stubby_enable" id="stubby_enable_0" class="input" value="0" <% nvram_match_x("", "stubby_enable", "0", "checked"); %>/><#checkbox_No#>
                                                </div>
                                            </td>
                                        </tr>

                                        <tbody id="stubby_show" style="border: none">
                                        <tr>
                                            <th width="50%"><a class="help_tooltip" href="javascript:void(0);" onmouseover="openTooltip(this, 25, 5);"><#Service_Stubby_Mode#>:</a></th>
                                            <td>
                                                <select name="stubby_mode" class="input">
                                                    <option value="0" <% nvram_match_x("", "stubby_mode", "0","selected"); %>><#Service_Stubby_Mode_Menu0#></option>
                                                    <option value="1" <% nvram_match_x("", "stubby_mode", "1","selected"); %>><#Service_Stubby_Mode_Menu1#> (*)</option>
                                                    <option value="2" <% nvram_match_x("", "stubby_mode", "2","selected"); %>><#Service_Stubby_Mode_Menu2#></option>
                                                    <option value="3" <% nvram_match_x("", "stubby_mode", "3","selected"); %>><#Service_Stubby_Mode_Menu3#></option>
                                                </select>
                                            </td>
                                        </tr>
                                        <tr>
                                            <th><#Service_Stubby_RoundRobin#>:</th>
                                            <td>
                                                <select name="stubby_round_robin" class="input">
                                                    <option value="0" <% nvram_match_x("", "stubby_round_robin", "0","selected"); %>><#btn_Disable#></option>
                                                    <option value="1" <% nvram_match_x("", "stubby_round_robin", "1","selected"); %>><#btn_Enable#> (*)</option>
                                                </select>
                                            </td>
                                        </tr>
                                        <tr>
                                            <th><#Adm_Svc_dnscrypt_ipaddr#></th>
                                            <td>
                                                <select name="stubby_listen_mode" class="input">
                                                    <option value="0" <% nvram_match_x("", "stubby_listen_mode", "0","selected"); %>>127.0.0.1 (*)</option>
                                                    <option value="1" <% nvram_match_x("", "stubby_listen_mode", "1","selected"); %>><% nvram_get_x("", "lan_ipaddr_t"); %></option>
                                                    <option value="2" <% nvram_match_x("", "stubby_listen_mode", "2","selected"); %>><#Adm_Svc_dnscrypt_all#></option>
                                                </select>
                                            </td>
                                        </tr>
                                        <tr>
                                            <th style="padding-bottom: 18px"><#Adm_Svc_dnscrypt_port#></th>
                                            <td style="padding-bottom: 18px">
                                                <input type="text" maxlength="5" size="15" name="stubby_listen_port" class="input" value="<% nvram_get_x("", "stubby_listen_port"); %>" onkeypress="return is_ipaddrport(this,event);"/>
                                                &nbsp;<span style="color:#888;">[ 1024..65535 ]</span>
                                            </td>
                                        </tr>

                                        <tr>
                                            <th colspan="2" style="background-color: #E3E3E3;"><#Service_Stubby_Resolvers_Header#></th>
                                        </tr>
                                        <tr>
                                            <th><#LANHostConfig_ManualIP_itemname#>:</th>
                                            <td>
                                                <input style="width: 275px" type="text" maxlength="60" class="input" size="10" id="stubby_server_ip"/>
                                            </td>
                                        </tr>
                                        <tr>
                                            <th><#Adm_Svc_dnscrypt_resolver#></th>
                                            <td>
                                                <span class="input-prepend">
                                                    <input style="border-radius: 3px 0 0 3px; width: 252px" type="text" maxlength="128" class="input" size="15" id="stubby_server"/>&#8203;
                                                    <select title="<#Service_Stubby_Resolvers_Header#>" class="input" id="stubby_resolver_list" style="margin-left: -1px; max-width: 24px; outline:0" onchange="on_stubby_select_change(this)" onclick="this.selectedIndex=-1;"></select>
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
