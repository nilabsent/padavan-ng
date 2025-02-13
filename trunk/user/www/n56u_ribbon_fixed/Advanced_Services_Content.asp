<!DOCTYPE html>
<html>
<head>
<title><#Web_Title#> - <#menu5_6_5#></title>
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

$j(document).ready(function() {
	init_itoggle('telnetd');
	init_itoggle('sshd_enable_gp');
	init_itoggle('wins_enable', change_wins_enabled);
	init_itoggle('lltd_enable');
	init_itoggle('adsc_enable');
	init_itoggle('crond_enable', change_crond_enabled);
	init_itoggle('watchdog_cpu');
	init_itoggle('doh_enable', change_doh_enabled);
	init_itoggle('stubby_enable', change_stubby_enabled);
	init_itoggle('zapret_enable', change_zapret_enabled);
	init_itoggle('tor_enable', change_tor_enabled);
	init_itoggle('privoxy_enable', change_privoxy_enabled);
	init_itoggle('dnscrypt_enable', change_dnscrypt_enabled);
});

</script>
<script>

<% login_state_hook(); %>
<% openssl_util_hook(); %>

function initial(){
	show_banner(1);
	show_menu(5,7,2);
	show_footer();
	load_body();

	if(!found_app_sshd()){
		showhide_div('row_sshd', 0);
		textarea_sshd_enabled(0);
	}else
		sshd_auth_change();

	if(found_app_nmbd()){
		showhide_div('tbl_wins', 1);
		change_wins_enabled();
	}

	if(!support_http_ssl()) {
		document.form.http_proto.value = "0";
		showhide_div('row_http_proto', 0);
		showhide_div('row_https_lport', 0);
		showhide_div('row_https_clist', 0);
		textarea_https_enabled(0);
	}else{
		if (openssl_util_found() && login_safe()) {
			if(!support_openssl_ec()) {
				var o = document.form.https_gen_rb;
				o.remove(3);
				o.remove(3);
				o.remove(3);
			}
			showhide_div('row_https_gen', 1);
		}
		http_proto_change();
	}
	change_crond_enabled();
	
	if(found_app_tor() || found_app_privoxy() || found_app_dnscrypt() || found_app_zapret() || found_app_doh() || found_app_stubby()){
		showhide_div('tbl_anon', 1);
	}

	$j('#doh_server_list1 option').clone().appendTo('#doh_server_list2');
	$j('#doh_server_list1 option').clone().appendTo('#doh_server_list3');

// fix for firefox
	$j('#doh_server_list1').prop('selectedIndex', -1)
	$j('#doh_server_list2').prop('selectedIndex', -1)
	$j('#doh_server_list3').prop('selectedIndex', -1)

	if(!found_app_doh()){
		showhide_div('row_doh', 0);
		showhide_div('row_doh_conf1', 0);
		showhide_div('row_doh_conf2', 0);
		showhide_div('row_doh_conf3', 0);
	}else{
		change_doh_enabled();
	}

	$j('#stubby_server_list1 option').clone().appendTo('#stubby_server_list2');
	$j('#stubby_server_list1 option').clone().appendTo('#stubby_server_list3');

// fix for firefox
	$j('#stubby_server_list1').prop('selectedIndex', -1)
	$j('#stubby_server_list2').prop('selectedIndex', -1)
	$j('#stubby_server_list3').prop('selectedIndex', -1)

	if(!found_app_stubby()){
		showhide_div('row_stubby', 0);
		showhide_div('row_stubby_conf1', 0);
		showhide_div('row_stubby_conf2', 0);
		showhide_div('row_stubby_conf3', 0);
	}else{
		change_stubby_enabled();
	}

	if(!found_app_zapret()){
		showhide_div('row_zapret', 0);
		showhide_div('row_zapret_strategy', 0);
		showhide_div('row_zapret_config', 0);
		showhide_div('row_zapret_auto', 0);
		showhide_div('row_zapret_user', 0);
		showhide_div('row_zapret_exclude', 0);
	}else{
		change_zapret_enabled();
	}

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
		
	if(!found_app_dnscrypt()){
		showhide_div('row_dnscrypt', 0);
		showhide_div('row_dnscrypt_resolver', 0);
		showhide_div('row_dnscrypt_ipaddr', 0);
		showhide_div('row_dnscrypt_port', 0);
		showhide_div('row_dnscrypt_force_dns', 0);
		showhide_div('row_dnscrypt_options', 0);
	}else
		change_dnscrypt_enabled();
}

function applyRule(){
	if(validForm()){
		showLoading();
		
		document.form.action_mode.value = " Apply ";
		document.form.current_page.value = "/Advanced_Services_Content.asp";
		document.form.next_page.value = "";
		
		document.form.submit();
	}

	if(!found_app_doh()){
		showhide_div('row_doh', 0);
		showhide_div('row_doh_conf1', 0);
		showhide_div('row_doh_conf2', 0);
		showhide_div('row_doh_conf3', 0);
	}

	if(!found_app_stubby()){
		showhide_div('row_stubby', 0);
		showhide_div('row_stubby_conf1', 0);
		showhide_div('row_stubby_conf2', 0);
		showhide_div('row_stubby_conf3', 0);
	}

	if(!found_app_zapret()){
		showhide_div('row_zapret', 0);
		showhide_div('row_zapret_strategy', 0);
		showhide_div('row_zapret_config', 0);
		showhide_div('row_zapret_auto', 0);
		showhide_div('row_zapret_user', 0);
		showhide_div('row_zapret_exclude', 0);
	}

	if(!found_app_tor()){
		showhide_div('row_tor', 0);
		showhide_div('row_tor_conf', 0);
	}

	if(!found_app_privoxy()){
		showhide_div('row_privoxy', 0);
		showhide_div('row_privoxy_conf', 0);
		showhide_div('row_privoxy_action', 0);
		showhide_div('row_privoxy_filter', 0);
		showhide_div('row_privoxy_trust', 0);
	}

	if(!found_app_dnscrypt()){
		showhide_div('row_dnscrypt', 0);
		showhide_div('row_dnscrypt_resolver', 0);
		showhide_div('row_dnscrypt_ipaddr', 0);
		showhide_div('row_dnscrypt_port', 0);
		showhide_div('row_dnscrypt_force_dns', 0);
		showhide_div('row_dnscrypt_options', 0);
	}

}

function validForm(){
	if(!validate_range(document.form.http_lanport, 80, 65535))
		return false;

	if (support_http_ssl()){
		var mode = document.form.http_proto.value;
		if (mode == "0" || mode == "2"){
			if(!validate_range(document.form.http_lanport, 80, 65535))
				return false;
		}
		if (mode == "1" || mode == "2"){
			if(!validate_range(document.form.https_lport, 81, 65535))
				return false;
		}
		if (mode == "2"){
			if (document.form.http_lanport.value == document.form.https_lport.value){
				alert("HTTP and HTTPS ports is equal!");
				document.form.https_lport.focus();
				document.form.https_lport.select();
				return false;
			}
		}
	}else{
		if(!validate_range(document.form.http_lanport, 80, 65535))
			return false;
	}

	return true;
}

function done_validating(action){
	refreshpage();
}

function textarea_https_enabled(v){
	inputCtrl(document.form['httpssl.ca.crt'], v);
	inputCtrl(document.form['httpssl.dh1024.pem'], v);
	inputCtrl(document.form['httpssl.server.crt'], v);
	inputCtrl(document.form['httpssl.server.key'], v);
}

function textarea_sshd_enabled(v){
	inputCtrl(document.form['scripts.authorized_keys'], v);
}

function change_doh_enabled(){
	var v = document.form.doh_enable[0].checked;
	showhide_div('row_doh_conf1', v);
	showhide_div('row_doh_conf2', v);
	showhide_div('row_doh_conf3', v);
}

function on_doh_select_change(selectObject, i){
	if ( !$j(selectObject).val() ) return false;
	$j('input[name=' + "doh_server_ip" + i +']').val("1.1.1.1,8.8.8.8,9.9.9.9,208.67.222.222,77.88.8.8");
	$j('input[name=' + "doh_server" + i +']').val($j(selectObject).val()).focus();
}

function doh_clean(i){
	$j('input[name=' + "doh_server_ip" + i +']').val("");
	$j('input[name=' + "doh_server" + i +']').val("").focus();
}

function change_stubby_enabled(){
	var v = document.form.stubby_enable[0].checked;
	showhide_div('row_stubby_conf1', v);
	showhide_div('row_stubby_conf2', v);
	showhide_div('row_stubby_conf3', v);
}

function on_stubby_select_change(selectObject, i){
	if ( !$j(selectObject).val() ) return false;
	$j('input[name=' + "stubby_server_ip" + i +']').val( $j('option:selected', selectObject).attr("valueip") );
	$j('input[name=' + "stubby_server" + i +']').val($j(selectObject).val()).focus();
}

function stubby_clean(i){
	$j('input[name=' + "stubby_server_ip" + i +']').val("");
	$j('input[name=' + "stubby_server" + i +']').val("").focus();
}

function textarea_zapret_enabled(v){
	inputCtrl(document.form['zapretc.strategy'], v);
	inputCtrl(document.form['zapretc.user.list'], v);
	inputCtrl(document.form['zapretc.auto.list'], v);
	inputCtrl(document.form['zapretc.exclude.list'], v);
	inputCtrl(document.form['zapretc.config'], v);
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

function textarea_crond_enabled(v){
	inputCtrl(document.form['crontab.login'], v);
}

function http_proto_change(){
	var proto = document.form.http_proto.value;
	var v1 = (proto == "0" || proto == "2") ? 1 : 0;
	var v2 = (proto == "1" || proto == "2") ? 1 : 0;

	showhide_div('row_http_lport', v1);
	showhide_div('row_https_lport', v2);

	if (!login_safe())
		v2 = 0;

	showhide_div('row_https_clist', v2);
	showhide_div('tbl_https_certs', v2);
	textarea_https_enabled(v2);
}

var id_timeout_btn_gen;
function flashing_btn_gen(is_shown){
	var $btn=$j('#https_gen_bn');
	if (is_shown)
		$btn.val('Please wait...');
	else
		$btn.val('');
	id_timeout_btn_gen = setTimeout("flashing_btn_gen("+!is_shown+")", 250);
}

function reset_btn_gen(is_refresh){
	var $btn=$j('#https_gen_bn');
	$btn.removeClass('alert-error').removeClass('alert-success');
	$btn.val('<#VPNS_GenNew#>');
	if (is_refresh)
		location.href = location.href;
}

function create_server_cert() {
	if(!confirm('<#Adm_System_https_query#>'))
		return false;
	var $btn=$j('#https_gen_bn');
	flashing_btn_gen(1);
	$btn.addClass('alert-error');
	$j.ajax({
		type: "post",
		url: "/apply.cgi",
		data: {
			action_mode: " CreateCertHTTPS ",
			common_name: $('https_gen_cn').value,
			rsa_bits: $('https_gen_rb').value,
			days_valid: $('https_gen_dv').value
		},
		dataType: "json",
		error: function(xhr) {
			clearTimeout(id_timeout_btn_gen);
			$btn.val('Failed!');
			setTimeout("reset_btn_gen(0)", 1500);
		},
		success: function(response) {
			var sys_result = (response != null && typeof response === 'object' && "sys_result" in response)
				? response.sys_result : -1;
			clearTimeout(id_timeout_btn_gen);
			if(sys_result == 0){
				$btn.removeClass('alert-error').addClass('alert-success');
				$btn.val('Success!');
				setTimeout("reset_btn_gen(1)", 1000);
			}else{
				$btn.val('Failed!');
				setTimeout("reset_btn_gen(0)", 1500);
			}
		}
	});
}

function sshd_auth_change(){
	var auth = document.form.sshd_enable.value;
	var v = (auth != "0") ? 1 : 0;
	showhide_div('row_ssh_gp', v);
	showhide_div('row_ssh_keys', v);
	if (!login_safe())
		v = 0;
	textarea_sshd_enabled(v);
}

function change_wins_enabled(){
	var v = document.form.wins_enable[0].checked;
	showhide_div('row_smb_wgrp', v);
	showhide_div('row_smb_lmb', v);
}

function change_zapret_enabled(){
	var v = document.form.zapret_enable[0].checked;
	showhide_div('row_zapret_strategy', v);
	showhide_div('row_zapret_config', v);
	showhide_div('row_zapret_auto', v);
	showhide_div('row_zapret_user', v);
	showhide_div('row_zapret_exclude', v);
	if (!login_safe()) v = 0;
	textarea_zapret_enabled(v);
}

function change_tor_enabled(){
	var v = document.form.tor_enable[0].checked;
	showhide_div('row_tor_conf', v);
	if (!login_safe())
		v = 0;
	textarea_tor_enabled(v);
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

function change_dnscrypt_enabled(){
	var v = document.form.dnscrypt_enable[0].checked;
	showhide_div('row_dnscrypt_resolver', v);
	showhide_div('row_dnscrypt_ipaddr', v);
	showhide_div('row_dnscrypt_port', v);
	showhide_div('row_dnscrypt_force_dns', v);
	showhide_div('row_dnscrypt_options', v);
}

function change_crond_enabled(){
	var v = document.form.crond_enable[0].checked;
	showhide_div('row_crontabs', v);
	if (!login_safe())
		v = 0;
	textarea_crond_enabled(v);
}
</script>
<style>
    .caption-bold {
        font-weight: bold;
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
                            <h2 class="box_head round_top"><#menu5_6#> - <#menu5_6_5#></h2>
                            <div class="round_bottom">
                                <div class="row-fluid">
                                    <div id="tabMenu" class="submenuBlock"></div>
                                    <div class="alert alert-info" style="margin: 10px;"><#Adm_Svc_desc#></div>

                                    <table width="100%" cellpadding="4" cellspacing="0" class="table">
                                        <tr>
                                            <th colspan="2" style="background-color: #E3E3E3;"><#Adm_System_webs#></th>
                                        </tr>
                                        <tr id="row_http_proto">
                                            <th><#Adm_System_http_proto#></th>
                                            <td>
                                                <select name="http_proto" class="input" onchange="http_proto_change();">
                                                    <option value="0" <% nvram_match_x("", "http_proto", "0","selected"); %>>HTTP</option>
                                                    <option value="1" <% nvram_match_x("", "http_proto", "1","selected"); %>>HTTPS</option>
                                                    <option value="2" <% nvram_match_x("", "http_proto", "2","selected"); %>>HTTP & HTTPS</option>
                                                </select>
                                            </td>
                                        </tr>
                                        <tr id="row_http_lport">
                                            <th><#Adm_System_http_lport#></th>
                                            <td>
                                                <input type="text" maxlength="5" size="15" name="http_lanport" class="input" value="<% nvram_get_x("", "http_lanport"); %>" onkeypress="return is_number(this,event);"/>
                                                &nbsp;<span style="color:#888;">[80..65535]</span>
                                            </td>
                                        </tr>
                                        <tr id="row_https_lport" style="display:none">
                                            <th><#Adm_System_https_lport#></th>
                                            <td>
                                                <input type="text" maxlength="5" size="15" name="https_lport" class="input" value="<% nvram_get_x("", "https_lport"); %>" onkeypress="return is_number(this,event);"/>
                                                &nbsp;<span style="color:#888;">[81..65535]</span>
                                            </td>
                                        </tr>
                                        <tr id="row_https_clist" style="display:none">
                                            <th><#Adm_System_https_clist#></th>
                                            <td>
                                                <input type="text" maxlength="256" size="15" name="https_clist" class="input" style="width: 286px;" value="<% nvram_get_x("", "https_clist"); %>" onkeypress="return is_string(this,event);"/>
                                            </td>
                                        </tr>
                                        <tr>
                                            <th width="50%"><#Adm_System_http_access#></th>
                                            <td>
                                                <select name="http_access" class="input">
                                                    <option value="0" <% nvram_match_x("", "http_access", "0","selected"); %>><#checkbox_No#> (*)</option>
                                                    <option value="1" <% nvram_match_x("", "http_access", "1","selected"); %>>Wired clients only</option>
                                                    <option value="2" <% nvram_match_x("", "http_access", "2","selected"); %>>Wired and MainAP clients</option>
                                                </select>
                                            </td>
                                        </tr>
                                    </table>

                                    <table width="100%" cellpadding="4" cellspacing="0" class="table" id="tbl_https_certs" style="display:none">
                                        <tr>
                                            <th colspan="4" style="background-color: #E3E3E3;"><#Adm_System_https_certs#></th>
                                        </tr>
                                        <tr id="row_https_gen" style="display:none">
                                            <td align="right" style="text-align:right;">
                                                <span class="caption-bold">Server CN:</span>
                                                <input id="https_gen_cn" type="text" maxlength="32" size="10" style="width: 105px;" placeholder="my.domain" onKeyPress="return is_string(this,event);"/>
                                            </td>
                                            <td align="left">
                                                <span class="caption-bold">Bits:</span>
                                                <select id="https_gen_rb" class="input" style="width: 108px;">
                                                    <option value="1024">RSA 1024 (*)</option>
                                                    <option value="2048">RSA 2048</option>
                                                    <option value="4096">RSA 4096</option>
                                                    <option value="prime256v1">EC P-256</option>
                                                    <option value="secp384r1">EC P-384</option>
                                                    <option value="secp521r1">EC P-521</option>
                                                </select>
                                            </td>
                                            <td align="left">
                                                <span class="caption-bold">Days valid:</span>
                                                <input id="https_gen_dv" type="text" maxlength="5" size="10" style="width: 35px;" value="365" onKeyPress="return is_number(this,event);"/>
                                            </td>
                                            <td align="left">
                                                <input id="https_gen_bn" type="button" class="btn" style="width: 145px; outline:0" onclick="create_server_cert();" value="<#VPNS_GenNew#>"/>
                                            </td>
                                        </tr>
                                        <tr>
                                            <td colspan="4" style="padding-bottom: 0px;">
                                                <a href="javascript:spoiler_toggle('ca.crt')"><span>Root CA Certificate (optional)</span></a>
                                                <div id="ca.crt" style="display:none;">
                                                    <textarea rows="8" wrap="off" spellcheck="false" maxlength="8192" class="span12" name="httpssl.ca.crt" style="font-family:'Courier New'; font-size:12px;"><% nvram_dump("httpssl.ca.crt",""); %></textarea>
                                                </div>
                                            </td>
                                        </tr>
                                        <tr>
                                            <td colspan="4" style="padding-bottom: 0px; border-top: 0 none;">
                                                <a href="javascript:spoiler_toggle('dh1024.pem')"><span>Diffie-Hellman PEM (optional)</span></a>
                                                <div id="dh1024.pem" style="display:none;">
                                                    <textarea rows="8" wrap="off" spellcheck="false" maxlength="8192" class="span12" name="httpssl.dh1024.pem" style="font-family:'Courier New'; font-size:12px;"><% nvram_dump("httpssl.dh1024.pem",""); %></textarea>
                                                </div>
                                            </td>
                                        </tr>
                                        <tr>
                                            <td colspan="4" style="padding-bottom: 0px; border-top: 0 none;">
                                                <a href="javascript:spoiler_toggle('server.crt')"><span>Server Certificate (required)</span></a>
                                                <div id="server.crt" style="display:none;">
                                                    <textarea rows="8" wrap="off" spellcheck="false" maxlength="8192" class="span12" name="httpssl.server.crt" style="font-family:'Courier New'; font-size:12px;"><% nvram_dump("httpssl.server.crt",""); %></textarea>
                                                </div>
                                            </td>
                                        </tr>
                                        <tr>
                                            <td colspan="4" style="padding-bottom: 0px; border-top: 0 none;">
                                                <a href="javascript:spoiler_toggle('server.key')"><span>Server Private Key (required)</span></a>
                                                <div id="server.key" style="display:none;">
                                                    <textarea rows="8" wrap="off" spellcheck="false" maxlength="8192" class="span12" name="httpssl.server.key" style="font-family:'Courier New'; font-size:12px;"><% nvram_dump("httpssl.server.key",""); %></textarea>
                                                </div>
                                            </td>
                                        </tr>
                                    </table>

                                    <table width="100%" cellpadding="4" cellspacing="0" class="table">
                                        <tr>
                                            <th colspan="2" style="background-color: #E3E3E3;"><#Adm_System_term#></th>
                                        </tr>
                                        <tr>
                                            <th width="50%"><#Adm_System_telnetd#></th>
                                            <td>
                                                <div class="main_itoggle">
                                                    <div id="telnetd_on_of">
                                                        <input type="checkbox" id="telnetd_fake" <% nvram_match_x("", "telnetd", "1", "value=1 checked"); %><% nvram_match_x("", "telnetd", "0", "value=0"); %>>
                                                    </div>
                                                </div>
                                                <div style="position: absolute; margin-left: -10000px;">
                                                    <input type="radio" name="telnetd" id="telnetd_1" class="input" value="1" <% nvram_match_x("", "telnetd", "1", "checked"); %>/><#checkbox_Yes#>
                                                    <input type="radio" name="telnetd" id="telnetd_0" class="input" value="0" <% nvram_match_x("", "telnetd", "0", "checked"); %>/><#checkbox_No#>
                                                </div>
                                            </td>
                                        </tr>
                                        <tr id="row_sshd">
                                            <th><#Adm_System_sshd#></th>
                                            <td>
                                                <select name="sshd_enable" class="input" onchange="sshd_auth_change();">
                                                    <option value="0" <% nvram_match_x("", "sshd_enable", "0","selected"); %>><#checkbox_No#> (*)</option>
                                                    <option value="1" <% nvram_match_x("", "sshd_enable", "1","selected"); %>><#checkbox_Yes#></option>
                                                    <option value="2" <% nvram_match_x("", "sshd_enable", "2","selected"); %>><#checkbox_Yes#> (authorized_keys only)</option>
                                                </select>
                                            </td>
                                        </tr>
                                        <tr id="row_ssh_gp">
                                            <th width="50%"><#Adm_System_sshd_gp#></th>
                                            <td>
                                                <div class="main_itoggle">
                                                    <div id="sshd_enable_gp_on_of">
                                                        <input type="checkbox" id="sshd_enable_gp_fake" <% nvram_match_x("", "sshd_enable_gp", "1", "value=1 checked"); %><% nvram_match_x("", "sshd_enable_gp", "0", "value=0"); %>>
                                                    </div>
                                                </div>
                                                <div style="position: absolute; margin-left: -10000px;">
                                                    <input type="radio" name="sshd_enable_gp" id="sshd_enable_gp_1" class="input" value="1" <% nvram_match_x("", "sshd_enable_gp", "1", "checked"); %>/><#checkbox_Yes#>
                                                    <input type="radio" name="sshd_enable_gp" id="sshd_enable_gp_0" class="input" value="0" <% nvram_match_x("", "sshd_enable_gp", "0", "checked"); %>/><#checkbox_No#>
                                                </div>
                                            </td>
                                        </tr>
                                        <tr id="row_ssh_keys" style="display:none">
                                            <td colspan="2" style="padding-bottom: 0px;">
                                                <a href="javascript:spoiler_toggle('authorized_keys')"><span><#Adm_System_sshd_keys#> (authorized_keys)</span></a>
                                                <div id="authorized_keys" style="display:none;">
                                                    <textarea rows="8" wrap="off" spellcheck="false" maxlength="8192" class="span12" name="scripts.authorized_keys" style="font-family:'Courier New'; font-size:12px;"><% nvram_dump("scripts.authorized_keys",""); %></textarea>
                                                </div>
                                            </td>
                                        </tr>
                                    </table>

                                    <table width="100%" cellpadding="4" cellspacing="0" class="table" id="tbl_wins" style="display:none">
                                        <tr>
                                            <th colspan="2" style="background-color: #E3E3E3;">Windows Internet Name Service (WINS)</th>
                                        </tr>
                                        <tr>
                                            <th width="50%"><#Adm_Svc_wins#></th>
                                            <td>
                                                <div class="main_itoggle">
                                                    <div id="wins_enable_on_of">
                                                        <input type="checkbox" id="wins_enable_fake" <% nvram_match_x("", "wins_enable", "1", "value=1 checked"); %><% nvram_match_x("", "wins_enable", "0", "value=0"); %>>
                                                    </div>
                                                </div>
                                                <div style="position: absolute; margin-left: -10000px;">
                                                    <input type="radio" name="wins_enable" id="wins_enable_1" class="input" value="1" onclick="change_wins_enabled();" <% nvram_match_x("", "wins_enable", "1", "checked"); %>/><#checkbox_Yes#>
                                                    <input type="radio" name="wins_enable" id="wins_enable_0" class="input" value="0" onclick="change_wins_enabled();" <% nvram_match_x("", "wins_enable", "0", "checked"); %>/><#checkbox_No#>
                                                </div>
                                            </td>
                                        </tr>
                                        <tr id="row_smb_wgrp" style="display:none;">
                                            <th>
                                                <a class="help_tooltip" href="javascript:void(0);" onmouseover="openTooltip(this,17, 3);"><#ShareNode_WorkGroup_itemname#></a>
                                            </th>
                                            <td>
                                                <input type="text" name="st_samba_workgroup" class="input" maxlength="32" size="32" value="<% nvram_get_x("", "st_samba_workgroup"); %>"/>
                                            </td>
                                        </tr>
                                        <tr id="row_smb_lmb" style="display:none;">
                                            <th>
                                                <#StorageLMB#>
                                            </th>
                                            <td>
                                                <select name="st_samba_lmb" class="input">
                                                    <option value="0" <% nvram_match_x("", "st_samba_lmb", "0", "selected"); %>><#checkbox_No#></option>
                                                    <option value="1" <% nvram_match_x("", "st_samba_lmb", "1", "selected"); %>>Local Master Browser (*)</option>
                                                    <option value="2" <% nvram_match_x("", "st_samba_lmb", "2", "selected"); %>>Local & Domain Master Browser</option>
                                                </select>
                                            </td>
                                        </tr>
                                    </table>

                                    <table width="100%" cellpadding="4" cellspacing="0" class="table" id="tbl_anon" style="display:none">
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
					<tr id="row_tor_conf" style="display:none">
					    <td colspan="2">
						<a href="javascript:spoiler_toggle('spoiler_tor_conf')"><span><#CustomConf#> "torrc"</span></a>
						    <div id="spoiler_tor_conf" style="display:none;">
							<textarea rows="16" wrap="off" spellcheck="false" maxlength="4096" class="span12" name="torconf.torrc" style="font-family:'Courier New'; font-size:12px;"><% nvram_dump("torconf.torrc",""); %></textarea>
						    </div>
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
							<textarea rows="16" wrap="off" spellcheck="false" maxlength="65536" class="span12" name="privoxy.config" style="font-family:'Courier New'; font-size:12px;"><% nvram_dump("privoxy.config",""); %></textarea>
						    </div>
					    </td>
					</tr>
					<tr id="row_privoxy_action" style="display:none">
					    <td colspan="2">
						<a href="javascript:spoiler_toggle('spoiler_privoxy_action')"><span><#CustomConf#> "user.action"</span></a>
						    <div id="spoiler_privoxy_action" style="display:none;">
							<textarea rows="16" wrap="off" spellcheck="false" maxlength="65536" class="span12" name="privoxy.user.action" style="font-family:'Courier New'; font-size:12px;"><% nvram_dump("privoxy.user.action",""); %></textarea>
						    </div>
					    </td>
					</tr>
					<tr id="row_privoxy_filter" style="display:none">
					    <td colspan="2">
						<a href="javascript:spoiler_toggle('spoiler_privoxy_filter')"><span><#CustomConf#> "user.filter"</span></a>
						    <div id="spoiler_privoxy_filter" style="display:none;">
							<textarea rows="16" wrap="off" spellcheck="false" maxlength="65536" class="span12" name="privoxy.user.filter" style="font-family:'Courier New'; font-size:12px;"><% nvram_dump("privoxy.user.filter",""); %></textarea>
						    </div>
					    </td>
					</tr>
					<tr id="row_privoxy_trust" style="display:none">
					    <td colspan="2">
						<a href="javascript:spoiler_toggle('spoiler_privoxy_trust')"><span><#CustomConf#> "user.trust"</span></a>
						    <div id="spoiler_privoxy_trust" style="display:none;">
							<textarea rows="16" wrap="off" spellcheck="false" maxlength="65536" class="span12" name="privoxy.user.trust" style="font-family:'Courier New'; font-size:12px;"><% nvram_dump("privoxy.user.trust",""); %></textarea>
						    </div>
					    </td>
					</tr>

                                        <tr id="row_dnscrypt">
                                            <th width="50%"><a class="help_tooltip" href="javascript:void(0);" onmouseover="openTooltip(this, 25, 1);"><#Adm_Svc_dnscrypt#></a></th>
                                            <td>
                                                <div class="main_itoggle">
                                                    <div id="dnscrypt_enable_on_of">
                                                        <input type="checkbox" id="dnscrypt_enable_fake" <% nvram_match_x("", "dnscrypt_enable", "1", "value=1 checked"); %><% nvram_match_x("", "dnscrypt_enable", "0", "value=0"); %>>
                                                    </div>
                                                </div>
                                                <div style="position: absolute; margin-left: -10000px;">
                                                    <input type="radio" name="dnscrypt_enable" id="dnscrypt_enable_1" class="input" value="1" <% nvram_match_x("", "dnscrypt_enable", "1", "checked"); %>/><#checkbox_Yes#>
                                                    <input type="radio" name="dnscrypt_enable" id="dnscrypt_enable_0" class="input" value="0" <% nvram_match_x("", "dnscrypt_enable", "0", "checked"); %>/><#checkbox_No#>
                                                </div>
                                            </td>
                                        </tr>
					<tr id="row_dnscrypt_resolver" style="display:none">
                                            <th><#Adm_Svc_dnscrypt_resolver#></th>
                                            <td>
                                                <input type="text" maxlength="64" size="15" name="dnscrypt_resolver" class="input" value="<% nvram_get_x("", "dnscrypt_resolver"); %>" onkeypress="return is_string(this,event);"/>
                                                &nbsp;<a href="dnscrypt-resolvers.csv" target="_blank"><span><#Adm_Svc_dnscrypt_list#></span></a>
                                            </td>
					</tr>
					<tr id="row_dnscrypt_ipaddr" style="display:none">
                                            <th><#Adm_Svc_dnscrypt_ipaddr#></th>
                                            <td>
						<select name="dnscrypt_ipaddr" class="input">
						    <option value="127.0.0.1" <% nvram_match_x("", "dnscrypt_ipaddr", "127.0.0.1","selected"); %>>127.0.0.1 (*)</option>
						    <option id="localip" value="<% nvram_get_x("", "lan_ipaddr"); %>"><% nvram_get_x("", "lan_ipaddr"); %></option>
						    <option value="0.0.0.0" <% nvram_match_x("", "dnscrypt_ipaddr", "0.0.0.0","selected"); %>><#Adm_Svc_dnscrypt_all#></option>
							<script type="text/javascript">
							    if("<% nvram_get_x("", "lan_ipaddr"); %>"=="<% nvram_get_x("", "dnscrypt_ipaddr"); %>")
							    lip=document.getElementById("localip").selected="selected";
							</script>
						</select>
                                            </td>
					</tr>
					<tr id="row_dnscrypt_port" style="display:none">
					    <th><#Adm_Svc_dnscrypt_port#></th>
                                            <td>
                                                <input type="text" maxlength="5" size="15" name="dnscrypt_port" class="input" value="<% nvram_get_x("", "dnscrypt_port"); %>" onkeypress="return is_ipaddrport(this,event);"/>
                                                &nbsp;<span style="color:#888;">[53..65535]</span>
                                            </td>
					</tr>
                                        <tr id="row_dnscrypt_force_dns" style="display:none;">
                                            <th width="50%"><a class="help_tooltip" href="javascript:void(0);" onmouseover="openTooltip(this, 25, 2);"><#Adm_Svc_dnscrypt_force_dns#></a></th>
                                            <td>
                                                <select name="dnscrypt_force_dns" class="input">
                                                    <option value="0" <% nvram_match_x("", "dnscrypt_force_dns", "0", "selected"); %>><#checkbox_No#> (*)</option>
                                                    <option value="1" <% nvram_match_x("", "dnscrypt_force_dns", "1", "selected"); %>><#checkbox_Yes#></option>
                                                </select>
                                            </td>
                                        </tr>
					<tr id="row_dnscrypt_options" style="display:none">
                                            <th width="50%"><a class="help_tooltip" href="javascript:void(0);" onmouseover="openTooltip(this, 25, 3);"><#Adm_Svc_dnscrypt_options#></a></th>
                                            <td>
                                                <input type="text" maxlength="128" size="15" name="dnscrypt_options" class="input" value="<% nvram_get_x("", "dnscrypt_options"); %>" onkeypress="return is_string(this,event);"/>
                                            </td>
					</tr>


                                        <tr id="row_doh">
                                            <th width="50%"><a class="help_tooltip" href="javascript:void(0);" onmouseover="openTooltip(this, 25, 5);"><#Adm_Svc_doh#></a></th>
                                            <td>
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
                                        <tr id="row_doh_conf1" style="display:none">
                                            <td colspan="2" align="left" style="text-align:left;">
                                                <span class="caption-bold">1:</span>
                                                <input type="text" maxlength="60" class="input" size="10" style="margin-left: 4px; width: 308px;" name="doh_server1" value="<% nvram_get_x("", "doh_server1"); %>" onkeypress="return is_string(this,event);"/>
                                                <input type="text" maxlength="60" class="input" size="10" style="width: 190px;" name="doh_server_ip1" value="<% nvram_get_x("", "doh_server_ip1"); %>" onkeypress="return is_string(this,event);"/>&#8203;
                                                <select class="input" id="doh_server_list1" style="padding-left: 0px; border-left: 0; max-width:20px;" onchange="on_doh_select_change(this, 1)" onclick="this.selectedIndex=-1;">
                                                    <option value="https://0ms.dev/dns-query">0ms DNS</option>
                                                    <option value="https://dns.adguard-dns.com/dns-query">Adguard: ads and trackers</option>
                                                    <option value="https://family.adguard-dns.com/dns-query">Adguard: family filter</option>
                                                    <option value="https://unfiltered.adguard-dns.com/dns-query">Adguard: unfiltered</option>
                                                    <option value="https://blitz.ahadns.com/1:1">AhaDNS: ads, malware, privacy</option>
                                                    <option value="https://blitz.ahadns.com/1:27">AhaDNS: no-Google</option>
                                                    <option value="https://blitz.ahadns.com/1:4">AhaDNS: privacy</option>
                                                    <option value="https://blitz.ahadns.com/1:5">AhaDNS: privacy strict</option>
                                                    <option value="https://dns.alidns.com/dns-query">Ali DNS</option>
                                                    <option value="https://dns.bebasid.com/dns-query">BebasDNS</option>
                                                    <option value="https://antivirus.bebasid.com/dns-query">BebasDNS: antivirus</option>
                                                    <option value="https://internetsehat.bebasid.com/dns-query">BebasDNS: family</option>
                                                    <option value="https://dns.bebasid.com/unfiltered">BebasDNS: unfiltered</option>
                                                    <option value="https://doh.opendns.com/dns-query">Cisco OpenDNS</option>
                                                    <option value="https://doh.familyshield.opendns.com/dns-query">Cisco OpenDNS: family</option>
                                                    <option value="https://doh.sandbox.opendns.com/dns-query">Cisco OpenDNS: unfiltered</option>
                                                    <option value="https://doh.cleanbrowsing.org/doh/adult-filter">CleanBrowsing: adult</option>
                                                    <option value="https://doh.cleanbrowsing.org/doh/family-filter">CleanBrowsing: family</option>
                                                    <option value="https://doh.cleanbrowsing.org/doh/security-filter">CleanBrowsing: security</option>
                                                    <option value="https://dns.cloudflare.com/dns-query">Cloudflare</option>
                                                    <option value="https://family.cloudflare-dns.com/dns-query">Cloudflare: family</option>
                                                    <option value="https://security.cloudflare-dns.com/dns-query">Cloudflare: security</option>
                                                    <option value="https://dns.comss.one/dns-query">Comss.one DNS</option>
                                                    <option value="https://freedns.controld.com/p2">ControlD: ads and trackers</option>
                                                    <option value="https://freedns.controld.com/family">ControlD: family filter</option>
                                                    <option value="https://freedns.controld.com/p1">ControlD: malware</option>
                                                    <option value="https://freedns.controld.com/p0">ControlD: unfiltered</option>
                                                    <option value="https://dns.decloudus.com/dns-query">DeCloudUs DNS</option>
                                                    <option value="https://dns.pub/dns-query">DNSPod Public DNS+</option>
                                                    <option value="https://doh.dns.sb/dns-query">DNS.SB</option>
                                                    <option value="https://dns.google/dns-query">Google</option>
                                                    <option value="https://dns.nextdns.io">NextDNS</option>
                                                    <option value="https://ada.openbld.net/dns-query">OpenBLD.net DNS</option>
                                                    <option value="https://dns.quad9.net/dns-query">Quad9</option>
                                                    <option value="https://family.rabbitdns.org/dns-query">Rabbit DNS: family</option>
                                                    <option value="https://security.rabbitdns.org/dns-query">Rabbit DNS: security</option>
                                                    <option value="https://dns.rabbitdns.org/dns-query">Rabbit DNS: unfiltered</option>
                                                    <option value="https://wikimedia-dns.org/dns-query">Wikimedia DNS</option>
                                                    <option value="https://common.dot.dns.yandex.net/dns-query">Yandex</option>
                                                    <option value="https://family.dot.dns.yandex.net/dns-query">Yandex: family</option>
                                                    <option value="https://safe.dot.dns.yandex.net/dns-query">Yandex: security</option>
                                                </select>
                                                <div class="icon icon-remove" onclick="doh_clean(1)" style="margin-top:2px; margin-left:10px; cursor:pointer;"></div>
                                            </td>
                                        </tr>
                                        <tr id="row_doh_conf2" style="display:none">
                                            <td colspan="2" align="left" style="text-align:left;">
                                                <span class="caption-bold">2:</span>
                                                <input type="text" maxlength="60" class="input" size="10" style="margin-left: 4px; width: 308px;" name="doh_server2" value="<% nvram_get_x("", "doh_server2"); %>" onkeypress="return is_string(this,event);"/>
                                                <input type="text" maxlength="60" class="input" size="10" style="width: 190px;" name="doh_server_ip2" value="<% nvram_get_x("", "doh_server_ip2"); %>" onkeypress="return is_string(this,event);"/>&#8203;
                                                <select class="input" id="doh_server_list2" style="padding-left: 0px; border-left: 0; max-width:20px;" onchange="on_doh_select_change(this, 2)" onfocus="this.selectedIndex=-1;"></select>
                                                <div class="icon icon-remove" onclick="doh_clean(2)" style="margin-top:2px; margin-left:10px; cursor:pointer;"></div>
                                            </td>
                                        </tr>
                                        <tr id="row_doh_conf3" style="display:none">
                                            <td colspan="2" align="left" style="text-align:left;">
                                                <span class="caption-bold">3:</span>
                                                <input type="text" maxlength="60" class="input" size="10" style="margin-left: 4px; width: 308px;" name="doh_server3" value="<% nvram_get_x("", "doh_server3"); %>" onkeypress="return is_string(this,event);"/>
                                                <input type="text" maxlength="60" class="input" size="10" style="width: 190px;" name="doh_server_ip3" value="<% nvram_get_x("", "doh_server_ip3"); %>" onkeypress="return is_string(this,event);"/>&#8203;
                                                <select class="input" id="doh_server_list3" style="padding-left: 0px; border-left: 0; max-width:20px;" onchange="on_doh_select_change(this, 3)" onfocus="this.selectedIndex=-1;"></select>
                                                <div class="icon icon-remove" onclick="doh_clean(3)" style="margin-top:2px; margin-left:10px; cursor:pointer;"></div>
                                            </td>
                                        </tr>

                                        <tr id="row_stubby">
                                            <th width="50%"><a class="help_tooltip" href="javascript:void(0);" onmouseover="openTooltip(this, 25, 6);"><#Adm_Svc_stubby#></a></th>
                                            <td>
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
                                        <tr id="row_stubby_conf1" style="display:none">
                                            <td colspan="2" align="left" style="text-align:left;">
                                                <span class="caption-bold">1:</span>
                                                <input type="text" maxlength="60" class="input" size="10" style="margin-left: 4px; width: 308px;" name="stubby_server1" value="<% nvram_get_x("", "stubby_server1"); %>" onkeypress="return is_string(this,event);"/>
                                                <input type="text" maxlength="60" class="input" size="10" style="width: 190px;" name="stubby_server_ip1" value="<% nvram_get_x("", "stubby_server_ip1"); %>" onkeypress="return is_string(this,event);"/>&#8203;
                                                <select class="input" id="stubby_server_list1" style="padding-left: 0px; border-left: 0; max-width:20px;" onchange="on_stubby_select_change(this, 1)" onfocus="this.selectedIndex=-1;">
                                                    <option value="dns.adguard-dns.com" valueip="94.140.14.14">AdGuard:ads and trackers</option>
                                                    <option value="family.adguard-dns.com" valueip="94.140.14.15">AdGuard: family</option>
                                                    <option value="unfiltered.adguard-dns.com" valueip="94.140.14.140">AdGuard: unfiltered</option>
                                                    <option value="dns.google" valueip="8.8.8.8">Google</option>
                                                    <option value="one.one.one.one" valueip="1.1.1.1">Cloudflare</option>
                                                    <option value="security.cloudflare-dns.com" valueip="1.1.1.2">Cloudflare: security</option>
                                                    <option value="family.cloudflare-dns.com" valueip="1.1.1.3">Cloudflare: family</option>
                                                    <option value="common.dot.dns.yandex.net" valueip="77.88.8.8">Yandex</option>
                                                    <option value="dns.quad9.net" valueip="9.9.9.9">Quad9</option>
                                                    <option value="dns.alidns.com" valueip="223.5.5.5">Ali DNS</option>
                                                    <option value="dns.opendns.com" valueip="208.67.222.222">Cisco OpenDNS</option>
                                                    <option value="familyshield.opendns.com" valueip="208.67.222.123">Cisco OpenDNS: family</option>
                                                    <option value="sandbox.opendns.com" valueip="208.67.222.2">Cisco OpenDNS: sandbox</option>
                                                    <option value="family-filter-dns.cleanbrowsing.org" valueip="185.228.168.168">CleanBrowsing: family</option>
                                                    <option value="adult-filter-dns.cleanbrowsing.org" valueip="185.228.168.10">CleanBrowsing: adult</option>
                                                    <option value="security-filter-dns.cleanbrowsing.org" valueip="185.228.168.9">CleanBrowsing: security</option>
                                                    <option value="p0.freedns.controld.com" valueip="76.76.2.0">ControlD: unfiltered</option>
                                                    <option value="p1.freedns.controld.com" valueip="76.76.2.1">ControlD: malware</option>
                                                    <option value="p2.freedns.controld.com" valueip="76.76.2.2">ControlD: + ads and trackers</option>
                                                    <option value="p3.freedns.controld.com" valueip="76.76.2.3">ControlD: + social networks</option>
                                                    <option value="family.freedns.controld.com" valueip="76.76.2.4">ControlD: + adult content</option>
                                                    <option value="dns.de.futuredns.eu.org" valueip="162.55.52.228">FutureDNS</option>
                                                </select>
                                                <div class="icon icon-remove" onclick="stubby_clean(1)" style="margin-top:2px; margin-left:10px; cursor:pointer;"></div>
                                            </td>
                                        </tr>
                                        <tr id="row_stubby_conf2" style="display:none">
                                            <td colspan="2" align="left" style="text-align:left;">
                                                <span class="caption-bold">2:</span>
                                                <input type="text" maxlength="60" class="input" size="10" style="margin-left: 4px; width: 308px;" name="stubby_server2" value="<% nvram_get_x("", "stubby_server2"); %>" onkeypress="return is_string(this,event);"/>
                                                <input type="text" maxlength="60" class="input" size="10" style="width: 190px;" name="stubby_server_ip2" value="<% nvram_get_x("", "stubby_server_ip2"); %>" onkeypress="return is_string(this,event);"/>&#8203;
                                                <select class="input" id="stubby_server_list2" style="padding-left: 0px; border-left: 0; max-width:20px;" onchange="on_stubby_select_change(this, 2)" onfocus="this.selectedIndex=-1;"></select>
                                                <div class="icon icon-remove" onclick="stubby_clean(2)" style="margin-top:2px; margin-left:10px; cursor:pointer;"></div>
                                            </td>
                                        </tr>
                                        <tr id="row_stubby_conf3" style="display:none">
                                            <td colspan="2" align="left" style="text-align:left;">
                                                <span class="caption-bold">3:</span>
                                                <input type="text" maxlength="60" class="input" size="10" style="margin-left: 4px; width: 308px;" name="stubby_server3" value="<% nvram_get_x("", "stubby_server3"); %>" onkeypress="return is_string(this,event);"/>
                                                <input type="text" maxlength="60" class="input" size="10" style="width: 190px;" name="stubby_server_ip3" value="<% nvram_get_x("", "stubby_server_ip3"); %>" onkeypress="return is_string(this,event);"/>&#8203;
                                                <select class="input" id="stubby_server_list3" style="padding-left: 0px; border-left: 0; max-width:20px;" onchange="on_stubby_select_change(this, 3)" onfocus="this.selectedIndex=-1;"></select>
                                                <div class="icon icon-remove" onclick="stubby_clean(3)" style="margin-top:2px; margin-left:10px; cursor:pointer;"></div>
                                            </td>
                                        </tr>

                                        <tr id="row_zapret">
                                            <th width="50%"><a class="help_tooltip" href="javascript:void(0);" onmouseover="openTooltip(this, 25, 4);"><#Adm_Svc_zapret#></a></th>
                                            <td>
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
                                        <tr id="row_zapret_strategy" style="display:none">
                                            <td colspan="2">
                                                <a href="javascript:spoiler_toggle('zapret.strategy')"><span><#ZapretStrategy#> "strategy"</span></a>
                                                <div id="zapret.strategy" style="display:none;">
                                                    <textarea rows="16" wrap="off" spellcheck="false" maxlength="8192" class="span12" name="zapretc.strategy" style="resize:none; font-family:'Courier New'; font-size:12px;"><% nvram_dump("zapretc.strategy",""); %></textarea>
                                                </div>
                                            </td>
                                        </tr>
                                        <tr id="row_zapret_user" style="display:none">
                                            <td colspan="2">
                                                <a href="javascript:spoiler_toggle('user.list')"><span><#ZapretUserList#> "user.list"</span></a>
                                                <div id="user.list" style="display:none;">
                                                    <textarea rows="16" wrap="off" spellcheck="false" maxlength="8192" class="span12" name="zapretc.user.list" style="resize:none; font-family:'Courier New'; font-size:12px;"><% nvram_dump("zapretc.user.list",""); %></textarea>
                                                </div>
                                            </td>
                                        </tr>
                                        <tr id="row_zapret_auto" style="display:none">
                                            <td colspan="2">
                                                <a href="javascript:spoiler_toggle('auto.list')"><span><#ZapretAutoList#> "auto.list"</span></a>
                                                <div id="auto.list" style="display:none;">
                                                    <textarea rows="16" wrap="off" spellcheck="false" maxlength="8192" class="span12" name="zapretc.auto.list" style="resize:none; font-family:'Courier New'; font-size:12px;"><% nvram_dump("zapretc.auto.list",""); %></textarea>
                                                </div>
                                            </td>
                                        </tr>
                                        <tr id="row_zapret_exclude" style="display:none">
                                            <td colspan="2">
                                                <a href="javascript:spoiler_toggle('exclude.list')"><span><#ZapretExcludeList#> "exclude.list"</span></a>
                                                <div id="exclude.list" style="display:none;">
                                                    <textarea rows="16" wrap="off" spellcheck="false" maxlength="8192" class="span12" name="zapretc.exclude.list" style="resize:none; font-family:'Courier New'; font-size:12px;"><% nvram_dump("zapretc.exclude.list",""); %></textarea>
                                                </div>
                                            </td>
                                        </tr>
                                        <tr id="row_zapret_config" style="display:none">
                                            <td colspan="2">
                                                <a href="javascript:spoiler_toggle('zapret.config')"><span><#CustomConf#> "config"</span></a>
                                                <div id="zapret.config" style="display:none;">
                                                    <textarea rows="16" wrap="off" spellcheck="false" maxlength="8192" class="span12" name="zapretc.config" style="resize:none; font-family:'Courier New'; font-size:12px;"><% nvram_dump("zapretc.config",""); %></textarea>
                                                </div>
                                            </td>
                                        </tr>

                                    </table>

                                    <table width="100%" cellpadding="4" cellspacing="0" class="table">
                                        <tr>
                                            <th colspan="2" style="background-color: #E3E3E3;"><#Adm_System_misc#></th>
                                        </tr>
                                        <tr>
                                            <th><#Adm_Svc_lltd#></th>
                                            <td>
                                                <div class="main_itoggle">
                                                    <div id="lltd_enable_on_of">
                                                        <input type="checkbox" id="lltd_enable_fake" <% nvram_match_x("", "lltd_enable", "1", "value=1 checked"); %><% nvram_match_x("", "lltd_enable", "0", "value=0"); %>>
                                                    </div>
                                                </div>
                                                <div style="position: absolute; margin-left: -10000px;">
                                                    <input type="radio" name="lltd_enable" id="lltd_enable_1" class="input" value="1" <% nvram_match_x("", "lltd_enable", "1", "checked"); %>/><#checkbox_Yes#>
                                                    <input type="radio" name="lltd_enable" id="lltd_enable_0" class="input" value="0" <% nvram_match_x("", "lltd_enable", "0", "checked"); %>/><#checkbox_No#>
                                                </div>
                                            </td>
                                        </tr>
                                        <tr>
                                            <th><#Adm_Svc_adsc#></th>
                                            <td>
                                                <div class="main_itoggle">
                                                    <div id="adsc_enable_on_of">
                                                        <input type="checkbox" id="adsc_enable_fake" <% nvram_match_x("", "adsc_enable", "1", "value=1 checked"); %><% nvram_match_x("", "adsc_enable", "0", "value=0"); %>>
                                                    </div>
                                                </div>
                                                <div style="position: absolute; margin-left: -10000px;">
                                                    <input type="radio" name="adsc_enable" id="adsc_enable_1" class="input" value="1" <% nvram_match_x("", "adsc_enable", "1", "checked"); %>/><#checkbox_Yes#>
                                                    <input type="radio" name="adsc_enable" id="adsc_enable_0" class="input" value="0" <% nvram_match_x("", "adsc_enable", "0", "checked"); %>/><#checkbox_No#>
                                                </div>
                                            </td>
                                        </tr>
                                        <tr>
                                            <th><#Adm_Svc_crond#></th>
                                            <td>
                                                <div class="main_itoggle">
                                                    <div id="crond_enable_on_of">
                                                        <input type="checkbox" id="crond_enable_fake" <% nvram_match_x("", "crond_enable", "1", "value=1 checked"); %><% nvram_match_x("", "crond_enable", "0", "value=0"); %>>
                                                    </div>
                                                </div>
                                                <div style="position: absolute; margin-left: -10000px;">
                                                    <input type="radio" name="crond_enable" id="crond_enable_1" class="input" value="1" <% nvram_match_x("", "crond_enable", "1", "checked"); %>/><#checkbox_Yes#>
                                                    <input type="radio" name="crond_enable" id="crond_enable_0" class="input" value="0" <% nvram_match_x("", "crond_enable", "0", "checked"); %>/><#checkbox_No#>
                                                </div>
                                            </td>
                                        </tr>
                                        <tr id="row_crontabs" style="display:none">
                                            <td colspan="2">
                                                <a href="javascript:spoiler_toggle('crond_crontabs')"><span><#Adm_Svc_crontabs#></span></a>
                                                <div id="crond_crontabs" style="display:none;">
                                                    <textarea rows="8" wrap="off" spellcheck="false" maxlength="8192" class="span12" name="crontab.login" style="font-family:'Courier New'; font-size:12px;"><% nvram_dump("crontab.login",""); %></textarea>
                                                </div>
                                            </td>
                                        </tr>
                                        <tr>
                                            <th width="50%"><a class="help_tooltip" href="javascript:void(0);" onmouseover="openTooltip(this,23,1);"><#TweaksWdg#></a></th>
                                            <td>
                                                <div class="main_itoggle">
                                                    <div id="watchdog_cpu_on_of">
                                                        <input type="checkbox" id="watchdog_cpu_fake" <% nvram_match_x("", "watchdog_cpu", "1", "value=1 checked"); %><% nvram_match_x("", "watchdog_cpu", "0", "value=0"); %>>
                                                    </div>
                                                </div>
                                                <div style="position: absolute; margin-left: -10000px;">
                                                    <input type="radio" name="watchdog_cpu" id="watchdog_cpu_1" class="input" value="1" <% nvram_match_x("", "watchdog_cpu", "1", "checked"); %>/><#checkbox_Yes#>
                                                    <input type="radio" name="watchdog_cpu" id="watchdog_cpu_0" class="input" value="0" <% nvram_match_x("", "watchdog_cpu", "0", "checked"); %>/><#checkbox_No#>
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
