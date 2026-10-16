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
let IPSet_List = [];
const normalize = str => str.trim().replace(/\s+/g, '');
const normalize_name = str => str.trim().replace(/[^a-zA-Z0-9_.:-]+/g, '');

$j(document).ready(function() {
	init_itoggle('ipset_enable', change_ipset_enabled);
});

</script>
<script>

<% login_state_hook(); %>

function initial(){
	show_banner(1);
	show_menu(5,7,7);
	show_footer();
	load_body();

	const parsedData = JSON.parse(document.form['ipsetes.ipset.json'].value);
	if (Array.isArray(parsedData))
		IPSet_List = parsedData;

	if (found_support_ipset()) {
		change_ipset_enabled();
	}
}

function applyRule(){
	if(validForm()){
		showLoading();

		document.form.action_mode.value = " Apply ";
		document.form.current_page.value = "/Advanced_Services_IPSet.asp";
		document.form.next_page.value = "";

		document.form.submit();
	}
}

function validForm(){
	document.form['ipsetes.ipset.json'].value = JSON.stringify(IPSet_List, null, 2);
	return true;
}

function done_validating(action){
	refreshpage();
}

function change_ipset_enabled(){
	var v = document.form.ipset_enable[0].checked;
	showhide_div('row_ipset', v);

	ipset_list_update();
}

function ipset_add() {
	if (!$j(ipset_name).val()) {
		$j(ipset_name).focus();
		return;
	}

	if (!$j(ipset_url).val()) {
		$j(ipset_url).focus();
		return;
	}

	if ( $j(ipset_name).val() && $j(ipset_url).val() ) {
		if(!IPSet_List.find( i => normalize_name(i.name).toLowerCase() === normalize_name($j(ipset_name).val()).toLowerCase() )) {
			IPSet_List.push({name: normalize_name($j(ipset_name).val()), url: normalize($j(ipset_url).val())})
		}
	}

	ipset_list_update();

	$j(ipset_name).val('');
	$j(ipset_url).val('');

	$j(ipset_name).focus();
}

function ipset_del(index){
	if (IPSet_List.length > 0) {
		IPSet_List.splice(index, 1);
	}

	ipset_list_update();
}

function ipset_list_update() {
	var code = `<table width="100%" style="margin: 0; border: 1px solid #E3E3E3">`;

	IPSet_List.forEach((item, index, array) => {
			code += `<tr ${(index % 2 === 0 ? 'style="background-color: #EEEEEE"' : '')}>`;
			code += `<td>${item.name}</td>`;

			if (item.url.startsWith("http://")
			    || item.url.startsWith("https://")
			    || item.url.startsWith("ftp://"))
				code += `<td class="compact-link"><a href="${item.url}" title="${item.url}" target="_blank">${item.url}</a></td>`;
			else
				code += `<td class="compact-link" title="${item.url}">${item.url}</td>`;

			code += `<td style="min-width: 28px; padding-left: 0px"><div title="<#CTL_del#>" class="icon icon-remove" onclick="ipset_del(${index})" style="cursor:pointer; margin-left: 10px"></div></td>`;
			code += `</tr>`;
	});

	if (IPSet_List.length == 0)
		code += `<tr><td colspan="3" class="alert" style="text-align: center; padding: 0; border-color: transparent"><div class="alert alert-info" style="margin: 0"><#Service_IPSet_Help#></div></td></tr>`;

	code += `</table>`;
	$("IPSet_List_Block").innerHTML = code;
}

function updateTooltip(input) {
	if (input.scrollWidth > input.clientWidth) {
		input.title = input.value;
	} else {
		input.removeAttribute('title');
	}
}

function ipsetImport() {
	const fileInput = document.getElementById('fileInput');
	const file = fileInput.files[0];

	if (!file) {
		alert('Select file');
		return;
	}
	if (file.size > 32768) {
		alert("File is too big");
		return;
	}

	const reader = new FileReader();
	reader.onload = function(e) {
		try {
			const parsedData = JSON.parse(e.target.result);
			if (Array.isArray(parsedData))
				IPSet_List = parsedData;

			ipset_list_update();
		} catch (error) {
			alert("The JSON file is corrupted. Check the console log for details.");
			console.log(error);
		}
	};

	reader.readAsText(file);
}

function ipsetExport(){
	const blob = new Blob([document.form['ipsetes.ipset.json'].value], { type: 'application/octet-stream' });
	const url = URL.createObjectURL(blob);

	const a = document.createElement('a');
	a.href = url;
	a.download = 'padavan_ipset.json';

	document.body.appendChild(a);
	a.click();

	document.body.removeChild(a);
	URL.revokeObjectURL(url);
}

function ipsetUpdateNow(){
	$("ipset_btn_update").disabled = 1;
	sendSystemCmd('restart_ipset');
	setTimeout('$("ipset_btn_update").disabled = 0;', 2000);
}

function checkEnter(e){
	e = e || event;
	return (e.keyCode || event.which || event.charCode || 0) === 13;
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
    code {
        color: inherit;
        white-space: nowrap;
    }
    .compact-link {
        width: 100%;
        max-width: 500px;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
        vertical-align: middle;
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
    <input type="hidden" name="current_page" value="Advanced_Services_Misc.asp">
    <input type="hidden" name="next_page" value="">
    <input type="hidden" name="next_host" value="">
    <input type="hidden" name="sid_list" value="LANHostConfig;General;Storage;">
    <input type="hidden" name="group_id" value="">
    <input type="hidden" name="action_mode" value="">
    <input type="hidden" name="action_script" value="">
    <textarea style="display: none" maxlength="32768" name="ipsetes.ipset.json"><% nvram_dump("ipsetes.ipset.json",""); %></textarea>

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
                            <h2 class="box_head round_top"><#menu5_6_5#> - <#Services_Menu_7#></h2>
                            <div class="round_bottom">
                                <div class="row-fluid">
                                    <div id="tabMenu" class="submenuBlock"></div>
                                    <div class="alert alert-info" style="margin: 10px;"><#Service_IPSet_Info#></div>

                                    <table width="100%" cellpadding="4" cellspacing="0" class="table">
                                        <tr>
                                            <th width="50%" style="border-top: 0 none"><#Service_IPSet_Enable#></a></th>
                                            <td style="border-top: 0 none">
                                                <div class="main_itoggle">
                                                    <div id="ipset_enable_on_of">
                                                        <input type="checkbox" id="ipset_enable_fake" <% nvram_match_x("", "ipset_enable", "1", "value=1 checked"); %><% nvram_match_x("", "ipset_enable", "0", "value=0"); %>>
                                                    </div>
                                                </div>
                                                <div style="position: absolute; margin-left: -10000px;">
                                                    <input type="radio" name="ipset_enable" id="ipset_enable_1" class="input" value="1" <% nvram_match_x("", "ipset_enable", "1", "checked"); %>/><#checkbox_Yes#>
                                                    <input type="radio" name="ipset_enable" id="ipset_enable_0" class="input" value="0" <% nvram_match_x("", "ipset_enable", "0", "checked"); %>/><#checkbox_No#>
                                                </div>
                                            </td>
                                        </tr>

                                        <tbody id="row_ipset" style="border: none">
                                        <tr>
                                            <th width="50%" style="padding-bottom: 12px;"><#Service_IPSet_Restore#>:</th>
                                            <td>
                                                <input style="display: none" type="file" accept=".json" id="fileInput" onChange="ipsetImport();" onclick="this.value=''">
                                                <label for="fileInput" class="btn btn-info" style="width: 197px;"><#ChooseFile#></label>
                                            </td>
                                        </tr>
                                        <tr>
                                            <th style="padding-bottom: 12px"><#Service_IPSet_Save#>:</th>
                                            <td>
                                                <input type="button" onclick="ipsetExport();" value="<#CTL_onlysave#>" class="btn btn-success" style="width: 219px; outline: 0">
                                            </td>
                                        </tr>
                                        <tr>
                                            <th style="padding-bottom: 18px"><#Service_IPSet_AutoUpdate#>:</th>
                                            <td style="padding-bottom: 18px">
                                                <select name="ipset_period" class="input">
                                                    <option value="6"   <% nvram_match_x("","ipset_period",  "6","selected"); %>>6 <#period_hours#></option>
                                                    <option value="12"  <% nvram_match_x("","ipset_period", "12","selected"); %>>12 <#period_hours#></option>
                                                    <option value="24"  <% nvram_match_x("","ipset_period", "24","selected"); %>>1 <#period_day#> (*)</option>
                                                    <option value="48"  <% nvram_match_x("","ipset_period", "48","selected"); %>>2 <#period_days#></option>
                                                    <option value="72"  <% nvram_match_x("","ipset_period", "72","selected"); %>>3 <#period_days#></option>
                                                    <option value="168" <% nvram_match_x("","ipset_period","168","selected"); %>>1 <#period_week#></option>
                                                    <option value="336" <% nvram_match_x("","ipset_period","336","selected"); %>>2 <#period_weeks#></option>
                                                    <option value="0"   <% nvram_match_x("","ipset_period",  "0","selected"); %>><#btn_Disable#></option>
                                                </select>
                                                &nbsp;<input id="ipset_btn_update" type="button" class="btn btn-info" style="max-width: 94px; outline:0" onclick="ipsetUpdateNow();" value="<#CTL_refresh#>"/>
                                            </td>
                                        </tr>
                                        <tr>
                                            <th colspan="2" style="background-color: #E3E3E3;"><#Service_IPSet_List#></th>
                                        </tr>
                                        <tr>
                                            <th width="50%"><#Service_IPSet_Name#>:</a></th>
                                            <td>
                                                <input onkeypress="if (checkEnter(event)) ipset_add();" style="width: 275px" type="text" maxlength="32" id="ipset_name" class="input" oninput="updateTooltip(this)" onmouseenter="updateTooltip(this)"/>
                                            </td>
                                        </tr>
                                        <tr>
                                            <th width="50%"><#Service_IPSet_URL#>:</a></th>
                                            <td>
                                                <input onkeypress="if (checkEnter(event)) ipset_add();" style="width: 275px" type="text" maxlength="4096" id="ipset_url" class="input" oninput="updateTooltip(this)" onmouseenter="updateTooltip(this)"/>
                                                <button type="button" class="btn" style="outline:0" id="ipset_button_add" title="<#CTL_add#>" onclick="ipset_add();"><i class="icon icon-plus"></i></button>
                                            </td>
                                        </tr>
                                        <tr>
                                            <td colspan="2" style="padding-top: 8px; padding-bottom: 18px; border: none">
                                                <div id="IPSet_List_Block"></div>
                                            </td>
                                        </tr>

                                        <tr>
                                            <th colspan="2" style="background-color: #E3E3E3;"><#UserScripts#></th>
                                        </tr>
                                        <tr>
                                            <td colspan="2">
                                                <a href="javascript:spoiler_toggle('ipset.post_script')"><span><#Service_IPSet_Script#>:</span> <i style="scale: 75%;" class="icon-chevron-down"></i></a>
                                                <div id="ipset.post_script" style="display:none;  padding-top: 4px;">
                                                    <textarea rows="20" spellcheck="false" maxlength="16384" class="span12 strategy" name="ipsetes.ipset_post_script.sh"><% nvram_dump("ipsetes.ipset_post_script.sh",""); %></textarea>
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
