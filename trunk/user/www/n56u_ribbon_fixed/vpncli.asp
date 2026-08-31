<!DOCTYPE html>
<html>
<head>
<title><#Web_Title#> - <#menu6#></title>
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
	init_itoggle('vpnc_enable', change_vpnc_enabled);

	$j("#tab_vpnc_cfg, #tab_vpnc_ssl").click(function(){
		var newHash = $j(this).attr('href').toLowerCase();
		showTab(newHash);
		return false;
	});
});

</script>
<script>

<% login_state_hook(); %>
<% openvpn_cli_cert_hook(); %>

lan_ipaddr_x = '<% nvram_get_x("", "lan_ipaddr"); %>';
lan_netmask_x = '<% nvram_get_x("", "lan_netmask"); %>';
fw_enable_x = '<% nvram_get_x("", "fw_enable_x"); %>';
vpnc_state_last = '<% nvram_get_x("", "vpnc_state_t"); %>';
ip6_service = '<% nvram_get_x("", "ip6_service"); %>';
vpnc_type = '<% nvram_get_x("", "vpnc_type"); %>';

function initial(){
	show_banner(0);
	show_menu(4, -1, 0);
	show_footer();

	if (!found_app_ovpn())
		document.form.vpnc_type.remove(2);
	else
	if (!support_ipv6() || ip6_service == ''){
		var o = document.form.vpnc_ov_prot;
		for (var i = 0; i < 4; i++) {
			o.remove(2);
		}
	}

	if (!found_app_wg()) {
		$j("#vpnc_type option[value='3']").remove();
	} else {
		if (found_app_awg())
			$j("#vpnc_type option[value='3']").html('AmneziaWG');
	}

	if (fw_enable_x == "0"){
		var o1 = document.form.vpnc_sfw;
		o1.remove(0);
		o1.remove(0);
	}

	change_vpnc_enabled();

	showTab(getHash());

	load_body();
}

function update_vpnc_status(vpnc_state){
	this.vpnc_state_last = vpnc_state;
	if (vpnc_type == 3) {
		showhide_div('col_vpnc_wg_state', (vpnc_state != 0 && document.form.vpnc_enable[0].checked) ? 1 : 0);
		if (vpnc_state == 2) {
			$("col_vpnc_wg_state").innerHTML = '<#Connecting#>';
			$('col_vpnc_wg_state').setAttribute('class', 'label label-warning');
		} else
		if (vpnc_state == 1) {
			$("col_vpnc_wg_state").innerHTML = '<#Connected#>';
			$('col_vpnc_wg_state').setAttribute('class', 'label label-success');
		}
	} else {
		showhide_div('col_vpnc_state', (vpnc_state != 0 && document.form.vpnc_enable[0].checked) ? 1 : 0);
	}
}

function applyRule(){
	if(validForm()){
		showLoading();

		document.form.action_mode.value = " Apply ";
		document.form.current_page.value = "/vpncli.asp";
		document.form.next_page.value = "";

		document.form.submit();
	}
}

function valid_rlan_subnet(oa, om){
	var ip4ra = parse_ipv4_addr(oa.value);
	var ip4rm = parse_ipv4_addr(om.value);
	if (ip4ra == null){
		alert(oa.value + " <#JS_validip#>");
		oa.focus();
		oa.select();
		return false;
	}
	if (ip4rm == null || isMask(om.value) <= 0){
		alert(om.value + " <#JS_validmask#>");
		om.focus();
		om.select();
		return false;
	}

	for (i=0;i<4;i++)
		ip4ra[i] = ip4ra[i] & ip4rm[i];
	var r_str = ip4ra[0] + '.' + ip4ra[1] + '.' + ip4ra[2] + '.' + ip4ra[3];

	if (matchSubnet2(oa.value, om.value, lan_ipaddr_x, lan_netmask_x)) {
		alert("Please set remote subnet not equal LAN subnet (" + r_str + ")!");
		oa.focus();
		oa.select();
		return false;
	}

	oa.value = r_str;

	return true;
}

function validForm(){
	if (!document.form.vpnc_enable[0].checked)
		return true;

	var mode = document.form.vpnc_type.value;

	if((mode != "3") && document.form.vpnc_peer.value.length < 4){
		alert("Remote host is invalid!");
		document.form.vpnc_peer.focus();
		return false;
	}

	if(!validate_string(document.form.vpnc_peer))
		return false;

	if (mode == "3") {
		if (document.form.vpnc_wg_if_addr.value==""){
			alert("<#JS_fieldblank#>");
			document.form.vpnc_wg_if_addr.focus();
			document.form.vpnc_wg_if_addr.select();
			return false;
		}

		if (document.form.vpnc_wg_if_private.value==""){
			alert("<#JS_fieldblank#>");
			document.form.vpnc_wg_if_private.focus();
			document.form.vpnc_wg_if_private.select();
			return false;
		}

		if (document.form.vpnc_wg_peer_public.value==""){
			alert("<#JS_fieldblank#>");
			document.form.vpnc_wg_peer_public.focus();
			document.form.vpnc_wg_peer_public.select();
			return false;
		}

		if (document.form.vpnc_wg_peer_endpoint.value==""){
			alert("<#JS_fieldblank#>");
			document.form.vpnc_wg_peer_endpoint.focus();
			document.form.vpnc_wg_peer_endpoint.select();
			return false;
		}

		if (document.form.vpnc_wg_peer_allowedips.value==""){
			alert("<#JS_fieldblank#>");
			document.form.vpnc_wg_peer_allowedips.focus();
			document.form.vpnc_wg_peer_allowedips.select();
			return false;
		}

		if(!validate_range(document.form.vpnc_wg_mtu, 1000, 1420)) {
			return false;
		}

		if(!validate_range(document.form.vpnc_wg_peer_port, 1, 65535))
			return false;

		if (found_app_awg()) {
			if(!validate_range(document.form.vpnc_awg_jc, 0, 128)) {
				$("spoiler_vpnc_amnezia_junk").style.display = "";
				return false;
			}

			if(!validate_range(document.form.vpnc_awg_jmin, 0, 1024)) {
				$("spoiler_vpnc_amnezia_junk").style.display = "";
				return false;
			}

			if(!validate_range(document.form.vpnc_awg_jmax, parseInt(document.form.vpnc_awg_jmin.value), 1024)) {
				$("spoiler_vpnc_amnezia_junk").style.display = "";
				return false;
			}
		}
	}
	else if (mode == "2") {
		if(!validate_range(document.form.vpnc_ov_port, 1, 65535))
			return false;
	}
	else {
		if(!validate_range(document.form.vpnc_mtu, 1000, 1460))
			return false;
		if(!validate_range(document.form.vpnc_mru, 1000, 1460))
			return false;

		if (document.form.vpnc_rnet.value.length > 0)
			return valid_rlan_subnet(document.form.vpnc_rnet, document.form.vpnc_rmsk);
	}

	return true;
}

function done_validating(action){
}

function textarea_ovpn_enabled(v){
	inputCtrl(document.form['ovpncli.client.conf'], v);
	inputCtrl(document.form['ovpncli.ca.crt'], v);
	inputCtrl(document.form['ovpncli.client.crt'], v);
	inputCtrl(document.form['ovpncli.client.key'], v);
	inputCtrl(document.form['ovpncli.ta.key'], v);
}

function change_vpnc_enabled() {
	var v = document.form.vpnc_enable[0].checked;

	showhide_div('tbl_vpnc_config', v);
	showhide_div('tbl_vpnc_server', v);

	if (!v){
		showhide_div('tab_vpnc_ssl', 0);
		showhide_div('tbl_vpnc_route', 0);
		textarea_ovpn_enabled(0);
		showhide_div('tbl_vpnc_access_control', v);
		showhide_div('tbl_vpnc_amnezia', v);
	}else{
		change_vpnc_type();
	}
}

function change_vpnc_type() {
	var mode = document.form.vpnc_type.value;
	var is_ov = (mode == "2") ? 1 : 0;
	var is_wg = (mode == "3") ? 1 : 0;

	showhide_div('row_vpnc_auth', !is_ov && !is_wg);
	showhide_div('row_vpnc_mppe', !is_ov && !is_wg);
	showhide_div('row_vpnc_pppd', !is_ov && !is_wg);
	showhide_div('row_vpnc_mtu', !is_ov && !is_wg);
	showhide_div('row_vpnc_mru', !is_ov && !is_wg);
	showhide_div('tbl_vpnc_route', !is_ov && !is_wg);

	showhide_div('row_vpnc_ov_import', is_ov);
	showhide_div('row_vpnc_ov_port', is_ov);
	showhide_div('row_vpnc_ov_prot', is_ov);
	showhide_div('row_vpnc_ov_auth', is_ov);
	showhide_div('row_vpnc_ov_mdig', is_ov);
	showhide_div('row_vpnc_ov_ciph', is_ov);
	showhide_div('row_vpnc_ov_ncp_clist', is_ov);
	showhide_div('row_vpnc_ov_compress', is_ov);
	showhide_div('row_vpnc_ov_atls', is_ov);
	showhide_div('row_vpnc_ov_mode', is_ov);
	showhide_div('row_vpnc_ov_conf', is_ov);
	showhide_div('tab_vpnc_ssl', is_ov);
	showhide_div('certs_hint', (is_ov && !openvpn_cli_cert_found()) ? 1 : 0);

	textarea_ovpn_enabled(is_ov);

	showhide_div('row_vpnc_wg', is_wg);
	showhide_div('vpnc_peer_row', !is_wg);
	showhide_div('tbl_vpnc_access_control', is_wg);
	showhide_div('tbl_vpnc_amnezia', found_app_awg() && is_wg);
	showhide_div('row_vpnc_ipset', found_support_ipset());
	showhide_div('row_dipset', found_support_ipset());

	showhide_div('row_vpnc_server_script', !is_wg);
	showhide_div('row_vpnc_post_script', is_wg);

	$("vpnc_use_dns").innerHTML = "<#VPNC_PDNS#>";
	if (is_wg) {
		$("vpnc_use_dns").innerHTML = "<#VPNC_WG_UseDNS#>";
		vpnc_access_control();
	}

	if (is_ov) {
		change_vpnc_ov_auth();
		change_vpnc_ov_atls();
		change_vpnc_ov_mode();
	}
	else {
		showhide_div('row_vpnc_ov_cnat', 0);

		showhide_div('row_vpnc_user', !is_wg);
		showhide_div('row_vpnc_pass', !is_wg);
	}

	update_vpnc_status(vpnc_state_last);
}

function change_vpnc_ov_auth() {
	var v = (document.form.vpnc_ov_auth.value == "1") ? 1 : 0;

	showhide_div('row_vpnc_user', v);
	showhide_div('row_vpnc_pass', v);
	showhide_div('row_client_key', !v);
	showhide_div('row_client_crt', !v);
}

function change_vpnc_ov_atls() {
	var v = (document.form.vpnc_ov_atls.value != "0") ? 1 : 0;

	showhide_div('row_ta_key', v);
	inputCtrl(document.form['ovpncli.ta.key'], v);
}

function change_vpnc_ov_mode() {
	showhide_div('row_vpnc_ov_cnat', (document.form.vpnc_ov_mode.value == "1") ? 0 : 1);
}

function ov_conf_import() {
	const fileInput = document.getElementById('ov_fileInput');
	const file = fileInput.files[0];

	if (!file) {
		alert('Select file');
		return;
	}
	if (file.size > 65536) {
	alert("File is too big");
		return;
	}

	const reader = new FileReader();
	reader.onload = function(e) {
		const content = e.target.result;
		const lines = content.split(/\r?\n/);

		let settings = {};
		let certBlocks = {};
		let currentBlock = null;
		let blockContent = [];
		let remoteSet = false;

		document.querySelector('[name="vpnc_peer"]').value = '';
		document.querySelector('[name="vpnc_ov_port"]').value = '1194';
		document.querySelector('[name="vpnc_ov_prot"]').value = 0;
		document.querySelector('[name="vpnc_ov_mode"]').value = 1;
		document.querySelector('[name="vpnc_ov_auth"]').value = 0;
		document.querySelector('[name="vpnc_user"]').value = '';
		document.querySelector('[name="vpnc_pass"]').value = '';
		document.querySelector('[name="vpnc_ov_mdig"]').value = 1;
		document.querySelector('[name="vpnc_ov_ciph"]').value = 3;
		document.querySelector('[name="vpnc_ov_ncp_clist"]').value = '';
		document.querySelector('[name="vpnc_ov_compress"]').value = 0;
		document.querySelector('[name="vpnc_ov_atls"]').value = 0;
		document.querySelector('[name="ovpncli.ca.crt"]').value = '';
		document.querySelector('[name="ovpncli.client.crt"]').value = '';
		document.querySelector('[name="ovpncli.client.key"]').value = '';
		document.querySelector('[name="ovpncli.ta.key"]').value = '';

		lines.forEach(line => {
			let trimmed = line.trim();

			if (/^<\w+>/.test(trimmed)) {
				currentBlock = trimmed.replace(/[<>]/g, '').toLowerCase();
				blockContent = [];
				return;
			}
			if (/^<\/\w+>/.test(trimmed)) {
				certBlocks[currentBlock] = blockContent.join("\n");
				currentBlock = null;
				return;
			}
			if (currentBlock) {
				blockContent.push(line);
				return;
			}

			if (!trimmed || trimmed.startsWith('#') || trimmed.startsWith(';')) return;

			const parts = trimmed.split(/\s+/);
			const key = parts[0].toLowerCase();
			const value = parts.slice(1).join(' ');

			if (key === 'remote') {
				if (!remoteSet) {
					settings[key] = value;
					remoteSet = true;
				}
				return;
			}

			settings[key] = value;
		});

		if (settings['remote']) {
			const parts = settings['remote'].split(/\s+/);
			const host = parts[0] || '';
			const port = parts[1] || '';
			let protoHint = parts[2] ? parts[2].toLowerCase() : (settings['proto'] || 'udp').toLowerCase();

			document.querySelector('[name="vpnc_peer"]').value = host;
			if (port) document.querySelector('[name="vpnc_ov_port"]').value = port;

			// IPv6?
			let isIPv6 = /\[.*\]/.test(host) || (host.includes(':') && !host.match(/^\d+\.\d+\.\d+\.\d+$/));

			let protValue;
			switch (protoHint) {
				case 'udp4': protValue = 0; break;
				case 'tcp4': protValue = 1; break;
				case 'udp6': protValue = 2; break;
				case 'tcp6': protValue = 3; break;
				case 'tcp':  protValue = isIPv6 ? 3 : 1; break;
				case 'udp':  protValue = isIPv6 ? 2 : 0; break;
				default:     protValue = isIPv6 ? 2 : 0; break; // udp on default
			}

			document.querySelector('[name="vpnc_ov_prot"]').value = protValue;
		}

		// dev
		if (settings['dev']) {
			let dev = settings['dev'].toLowerCase();
			document.querySelector('[name="vpnc_ov_mode"]').value = (dev === 'tap') ? 0 : 1;
		}

		// auth
		if (settings['auth']) {
			const authMap = {
				'md5': 0, 'sha1': 1, 'sha224': 2,
				'sha256': 3, 'sha384': 4, 'sha512': 5
			};
			let val = settings['auth'].toLowerCase();
			if (authMap.hasOwnProperty(val))
				document.querySelector('[name="vpnc_ov_mdig"]').value = authMap[val];
		}

		// cipher
		if (settings['cipher']) {
			const cipherMap = {
				'none': 0, 'des-cbc': 1, 'des-ede-cbc': 2, 'bf-cbc': 3,
				'aes-128-cbc': 4, 'aes-192-cbc': 5, 'des-ede3-cbc': 6,
				'desx-cbc': 7, 'aes-256-cbc': 8, 'camellia-128-cbc': 9,
				'camellia-192-cbc': 10, 'camellia-256-cbc': 11,
				'aes-128-gcm': 12, 'aes-192-gcm': 13, 'aes-256-gcm': 14,
				'chacha20-poly1305': 15
			};
			let val = settings['cipher'].toLowerCase();
			if (cipherMap.hasOwnProperty(val))
				document.querySelector('[name="vpnc_ov_ciph"]').value = cipherMap[val];
		}

		// data-ciphers
		if (settings['data-ciphers']) {
			document.querySelector('[name="vpnc_ov_ncp_clist"]').value = settings['data-ciphers'];
		} else if (settings['cipher']) {
			document.querySelector('[name="vpnc_ov_ncp_clist"]').value = settings['cipher'];
		}

		// compression
		if (settings['comp-lzo']) {
			document.querySelector('[name="vpnc_ov_compress"]').value =
				settings['comp-lzo'] === 'no' ? 1 : 2;
			}
		if (settings['lz4-v2']) {
			document.querySelector('[name="vpnc_ov_compress"]').value = 4;
		}
		if (settings['compress']) {
			if (settings['compress'].includes('lz4-v2'))
				document.querySelector('[name="vpnc_ov_compress"]').value = 4;
			else if (settings['compress'].includes('lz4'))
				document.querySelector('[name="vpnc_ov_compress"]').value = 3;
		}

		// auth-user-pass
		if (settings['auth-user-pass'] != undefined) {
			document.querySelector('[name="vpnc_ov_auth"]').value = 1;
		}

		// TLS-Auth / TLS-Crypt
		if (certBlocks['ta']) document.querySelector('[name="vpnc_ov_atls"]').value = 1;
		if (certBlocks['tc']) document.querySelector('[name="vpnc_ov_atls"]').value = 2;
		if (certBlocks['ctc2']) document.querySelector('[name="vpnc_ov_atls"]').value = 3;

		if (certBlocks['ca']) document.querySelector('[name="ovpncli.ca.crt"]').value = certBlocks['ca'];
		if (certBlocks['cert']) document.querySelector('[name="ovpncli.client.crt"]').value = certBlocks['cert'];
		if (certBlocks['key']) document.querySelector('[name="ovpncli.client.key"]').value = certBlocks['key'];
		if (certBlocks['ta']) document.querySelector('[name="ovpncli.ta.key"]').value = certBlocks['ta'];

		if (certBlocks['tc']) document.querySelector('[name="ovpncli.ta.key"]').value = certBlocks['tc'];
		if (certBlocks['ctc2']) document.querySelector('[name="ovpncli.ta.key"]').value = certBlocks['ctc2'];

		change_vpnc_ov_auth();
		change_vpnc_ov_atls();
		change_vpnc_ov_mode();
	};
	reader.readAsText(file);
}

var arrHashes = ["cfg", "ssl"];

function showTab(curHash){
	var obj = $('tab_vpnc_'+curHash.slice(1));
	if (obj == null || obj.style.display == 'none')
		curHash = '#cfg';
	for(var i = 0; i < arrHashes.length; i++){
		if(curHash == ('#'+arrHashes[i])){
			$j('#tab_vpnc_'+arrHashes[i]).parents('li').addClass('active');
			$j('#wnd_vpnc_'+arrHashes[i]).show();
		}else{
			$j('#wnd_vpnc_'+arrHashes[i]).hide();
			$j('#tab_vpnc_'+arrHashes[i]).parents('li').removeClass('active');
		}
	}
	window.location.hash = curHash;
}

function getHash(){
	var curHash = window.location.hash.toLowerCase();
	for(var i = 0; i < arrHashes.length; i++){
		if(curHash == ('#'+arrHashes[i]))
			return curHash;
	}
	return ('#'+arrHashes[0]);
}

function wg_pubkey(){
	if (!login_safe())
		return false;

	if (document.form.vpnc_wg_if_private.value.length != 44) {
		document.form.vpnc_wg_if_public.value = "";
		return;
	}

	$j.post('/apply.cgi',
	{
		'action_mode': ' wg_action ',
		'action': 'pubkey',
		'privkey': document.form.vpnc_wg_if_private.value
	},
	function(response){
		document.form.vpnc_wg_if_public.value = response;
	});
}

function wg_genkey(){
	if (!login_safe())
		return false;

	$j.post('/apply.cgi',
	{
		'action_mode': ' wg_action ',
		'action': 'genkey'
	},
	function(response){
		document.form.vpnc_wg_if_private.value = response;

		$j.post('/apply.cgi',
		{
			'action_mode': ' wg_action ',
			'action': 'pubkey',
			'privkey': document.form.vpnc_wg_if_private.value
		},
		function(response){
			document.form.vpnc_wg_if_public.value = response;
		});
	});
	document.form.vpnc_wg_if_private.focus();
}

function wg_genpsk(){
	if (!login_safe())
		return false;

	$j.post('/apply.cgi',
	{
		'action_mode': ' wg_action ',
		'action': 'genpsk'
	},
	function(response){
		document.form.vpnc_wg_if_preshared.value = response;
	});
	document.form.vpnc_wg_if_preshared.focus();
}

function wg_genhpk(){
	if (!login_safe())
		return false;

	$j.post('/apply.cgi',
	{
		'action_mode': ' wg_action ',
		'action': 'genkey'
	},
	function(response){
		document.form.vpnc_awg_headerprotectionkey.value = response;
	});
	document.form.vpnc_awg_headerprotectionkey.focus();
}

async function loadJSON(fileName) {
	const response = await fetch(fileName);
	return await response.json();
}

function wg_conf_import() {
	const fileInput = document.getElementById('wg_fileInput');
	const file = fileInput.files[0];

	if (!file) {
		alert('Select file');
		return;
	}

	if( fileInput.files[0].size > 8192) {
		alert("File is too big");
		return;
	}

	const reader = new FileReader();

	reader.onload = function(e) {
		const content = e.target.result;
		var settings = {};

		const lines = content.split('\n');
		lines.forEach(line => {
			line = line.trim();
			if (!line || line.startsWith('#')) return;

			const separatorIndex = line.indexOf('=');
			if (separatorIndex > 0) {
				const key = line.substring(0, separatorIndex).trim().toLowerCase();
				const value = line.substring(separatorIndex + 1).trim();
				settings[key] = value;
			}
		});

		document.form.vpnc_wg_if_addr.value = "";
		document.form.vpnc_wg_if_private.value = "";
		document.form.vpnc_wg_if_preshared.value = "";
		document.form.vpnc_wg_mtu.value = "1280";
		document.form.vpnc_wg_peer_public.value = "";
		document.form.vpnc_wg_peer_endpoint.value = "";
		document.form.vpnc_wg_peer_port.value = "51820";
		document.form.vpnc_wg_peer_keepalive.value = "25";
		document.form.vpnc_wg_peer_allowedips.value = "0.0.0.0/0, ::/0";
		document.form.vpnc_wg_if_dns.value = "";

		if (settings.address) document.form.vpnc_wg_if_addr.value = settings.address;
		if (settings.privatekey) document.form.vpnc_wg_if_private.value = settings.privatekey;
		if (settings.presharedkey) document.form.vpnc_wg_if_preshared.value = settings.presharedkey;
		wg_pubkey();
		if (settings.mtu) document.form.vpnc_wg_mtu.value = settings.mtu;
		if (settings.publickey) document.form.vpnc_wg_peer_public.value = settings.publickey;
		if (settings.endpoint) {
			const separatorIndex = settings.endpoint.lastIndexOf(':');
			if (separatorIndex > 0) {
				document.form.vpnc_wg_peer_endpoint.value = settings.endpoint.substring(0, separatorIndex);
				document.form.vpnc_wg_peer_port.value = settings.endpoint.substring(separatorIndex + 1);
			} else
				document.form.vpnc_wg_peer_endpoint.value = settings.endpoint;
		}
		if (settings.persistentkeepalive) document.form.vpnc_wg_peer_keepalive.value = settings.persistentkeepalive;
		if (settings.allowedips) document.form.vpnc_wg_peer_allowedips.value = settings.allowedips;
		if (settings.dns) document.form.vpnc_wg_if_dns.value = settings.dns;

		if (found_app_awg()) {
			loadJSON('amneziawg.json')
				.then(data => {
					const fields = ['jc', 'jmin', 'jmax', 'i1', 'i2', 'i3', 'i4', 'i5', 'h1', 'h2', 'h3', 'h4', 's1', 's2', 's3', 's4', 'contentpaddingaddition', 'rekeyaftertime', 'rekeytimeout', 'rejectaftertime', 'keepalivetimeout', 'maxhandshakeattempts', 'headerprotectionkey'];
					fields.forEach(field => {
						document.form[`vpnc_awg_${field}`].value = settings[field] || data[0][field] || '';
					});
				});
		}
	};
	reader.readAsText(file);
}

function vpnc_access_control() {
	// ===== clients list =====
	let allowed_list, added_list, allowed, added

	const ipmonitor = [<% get_static_client(); %>];

	allowed_list = "<% nvram_get_x("", "vpnc_clients_allowed"); %>";
	added_list = "<% nvram_get_x("", "vpnc_clients"); %>";

	allowed = allowed_list.replace(/\s+/g, '').split(',')
		.filter(Boolean)
		.map(ip => ip);
	added = added_list.replace(/\s+/g, '').split(',')
		.filter(Boolean)
		.filter(ip => !allowed.includes(ip))
		.map(ip => ip);

	const clients = [
		...allowed.map(ip => ( {text: ip, checked: true } )),
		...added.map(ip => ( {text: ip, checked: false } )),
		...ipmonitor
			.filter(ip => ip[0])
			.filter(ip => !allowed.includes(ip[0]))
			.filter(ip => !added.includes(ip[0]))
			.map(item => ( {text: item[0], title: item[2] ?? '*', checked: false } )),
	];

	$j('#vpnc_clients').multiSelectDropdown({
		items: clients,
		placeholder: "<#ZapretWORestrictions#>",
		width: '320px',
		allowDelete: true,
		allowAdd: true,
		addSuggestionText: '<#CTL_add#>',
		removeSpaces: true,
		allowedItems: '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(?:\/([0-9]|[1-2][0-9]|3[0-2]))?$',
		allowedAlert: '<#LANHostConfig_x_DDNS_alarm_9#>',
		onChange: function(selected){
			document.form.vpnc_clients_allowed.value = selected.join(',');
			document.form.vpnc_clients.value = this.multiSelectDropdown('getAllItems')
				.filter(item => !item.title)
				.map(item => item.text)
				.join(',');
		}
	});

	// ===== ipset lists =====
	if (!found_support_ipset())
		return;

	allowed_list = "<% nvram_get_x("", "vpnc_ipset_allowed"); %>";
	added_list = "<% nvram_get_x("", "vpnc_ipset"); %>";

	allowed = allowed_list.replace(/\s+/g, '').split(',')
		.filter(Boolean)
		.map(item => item);
	added = added_list.replace(/\s+/g, '').split(',')
		.filter(Boolean)
		.filter(item => !allowed.includes(item))
		.map(item => ( {text: item, checked: false } ));

	const ipset = [
		...allowed.map(item => ({text: item, checked: true })),
		...added
	];

	$j('#vpnc_ipset').multiSelectDropdown({
		items: ipset,
		placeholder: "<#Select_menu_default#>",
		width: '320px',
		allowDelete: true,
		allowAdd: true,
		addSuggestionText: '<#CTL_add#>',
		removeSpaces: true,
		allowedItems: '^[a-zA-Z0-9-_.]+$',
		allowedAlert: '<#JS_field_noletter#>',
		onChange: function(selected){
			document.form.vpnc_ipset_allowed.value = selected.join(',');
			document.form.vpnc_ipset.value = this.multiSelectDropdown('getAllItems')
				.map(item => item.text)
				.join(',');
		}
	});
}

</script>

<style>
    .caption-bold {
        font-weight: bold;
    }
</style>

</head>

<body onload="initial();" onunload="unload_body();">
<script>
    if(get_ap_mode()){
        alert("<#page_not_support_mode_hint#>");
        location.href = "/as.asp";
    }
</script>

<div class="wrapper">
    <div class="container-fluid" style="padding-right: 0px">
        <div class="row-fluid">
            <div class="span3"><center><div id="logo"></div></center></div>
            <div class="span9" >
                <div id="TopBanner"></div>
            </div>
        </div>
    </div>

    <br>

    <div id="Loading" class="popup_bg"></div>

    <iframe name="hidden_frame" id="hidden_frame" src="" width="0" height="0" frameborder="0" style="position: absolute;"></iframe>

    <form method="post" name="form" id="ruleForm" action="/start_apply.htm" target="hidden_frame">
    <input type="hidden" name="current_page" value="vpncli.asp">
    <input type="hidden" name="next_page" value="">
    <input type="hidden" name="next_host" value="">
    <input type="hidden" name="sid_list" value="LANHostConfig;">
    <input type="hidden" name="group_id" value="">
    <input type="hidden" name="action_mode" value="">
    <input type="hidden" name="action_script" value="">
    <input type="hidden" name="flag" value="">

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
                <div class="box well grad_colour_dark_blue">
                    <div id="tabMenu"></div>
                    <h2 class="box_head round_top"><#menu6#></h2>

                    <div class="round_bottom">

                        <div>
                            <ul class="nav nav-tabs" style="margin-bottom: 10px;">
                                <li class="active">
                                    <a id="tab_vpnc_cfg" href="#cfg"><#Settings#></a>
                                </li>
                                <li>
                                    <a id="tab_vpnc_ssl" href="#ssl" style="display:none"><#OVPN_Cert#></a>
                                </li>
                            </ul>
                        </div>

                        <div id="wnd_vpnc_cfg">
                            <div class="alert alert-info" style="margin: 10px;"><#VPNC_Info#></div>
                            <table class="table">
                                <tr>
                                    <th width="50%" style="padding-bottom: 0px; border-top: 0 none;"><#VPNC_Enable#></th>
                                    <td style="padding-bottom: 0px; border-top: 0 none;">
                                        <div class="main_itoggle">
                                            <div id="vpnc_enable_on_of">
                                                <input type="checkbox" id="vpnc_enable_fake" <% nvram_match_x("", "vpnc_enable", "1", "value=1 checked"); %><% nvram_match_x("", "vpnc_enable", "0", "value=0"); %>>
                                            </div>
                                        </div>
                                            <div style="position: absolute; margin-left: -10000px;">
                                            <input type="radio" name="vpnc_enable" id="vpnc_enable_1" class="input" value="1" onclick="change_vpnc_enabled();" <% nvram_match_x("", "vpnc_enable", "1", "checked"); %>><#checkbox_Yes#>
                                            <input type="radio" name="vpnc_enable" id="vpnc_enable_0" class="input" value="0" onclick="change_vpnc_enabled();" <% nvram_match_x("", "vpnc_enable", "0", "checked"); %>><#checkbox_No#>
                                        </div>
                                    </td>
                                </tr>
                            </table>
                            <table class="table" id="tbl_vpnc_config" style="display:none">
                                <tr>
                                    <th colspan="2" style="background-color: #E3E3E3;"><#VPNC_Base#></th>
                                </tr>
                                <tr>
                                    <th width="50%"><#VPNC_Type#></th>
                                    <td>
                                        <select name="vpnc_type" id="vpnc_type" class="input" onchange="change_vpnc_type();">
                                            <option value="0" <% nvram_match_x("", "vpnc_type", "0","selected"); %>>PPTP</option>
                                            <option value="1" <% nvram_match_x("", "vpnc_type", "1","selected"); %>>L2TP (w/o IPSec)</option>
                                            <option value="2" <% nvram_match_x("", "vpnc_type", "2","selected"); %>>OpenVPN</option>
                                            <option value="3" <% nvram_match_x("", "vpnc_type", "3","selected"); %>>Wireguard</option>
                                        </select>
                                        <span id="certs_hint" style="display:none" class="label label-warning"><#OVPN_Hint#></span>
                                    </td>
                                </tr>
                                <tr id="row_vpnc_ov_import" style="display:none">
                                    <th width="50%" style="padding-bottom: 12px;"><#VPNC_WG_ImportConf#>:</th>
                                    <td>
                                        <input style="width: 320px" type="file" id="ov_fileInput" accept=".txt,.conf,.ovpn" name="vpnc_ov_import" onChange="ov_conf_import();" onclick="this.value=''">
                                    </td>
                                </tr>
                                <tr id="vpnc_peer_row">
                                    <th><#VPNC_Peer#></th>
                                    <td>
                                        <input type="text" name="vpnc_peer" class="input" maxlength="256" size="32" value="<% nvram_get_x("", "vpnc_peer"); %>" onKeyPress="return is_string(this,event);"/>
                                        &nbsp;<span id="col_vpnc_state" style="display:none" class="label label-success"><#Connected#></span>
                                    </td>
                                </tr>
                                <tr id="row_vpnc_ov_port" style="display:none">
                                    <th><#OVPN_Port#></th>
                                    <td>
                                        <input type="text" maxlength="5" size="5" name="vpnc_ov_port" class="input" value="<% nvram_get_x("", "vpnc_ov_port"); %>" onkeypress="return is_number(this,event);">
                                        &nbsp;<span style="color:#888;">[ 1194 ]</span>
                                    </td>
                                </tr>
                                <tr id="row_vpnc_wg" style="display:none">
                                    <td colspan="2" style="padding: 0px; padding: 0px; border: 0 none;">

                                        <table width="100%" style="margin-bottom: 10px;">
                                            <tr>
                                                <th width="50%" style="padding-bottom: 12px;"><#VPNC_WG_ImportConf#>:</th>
                                                <td>
                                                    <input style="width: 320px" type="file" id="wg_fileInput" accept=".txt,.conf" name="vpnc_wg_import" onChange="wg_conf_import();" onclick="this.value=''">
                                                </td>
                                            </tr>
                                            <tr>
                                                <th><#VPNC_Peer#></th>
                                                <td>
                                                    <input type="text" name="vpnc_wg_peer_endpoint" class="input" maxlength="256" size="32" value="<% nvram_get_x("", "vpnc_wg_peer_endpoint"); %>" onKeyPress="return is_string(this,event);"/>
                                                    &nbsp;<span id="col_vpnc_wg_state" style="display:none" class="label label-success"><#Connected#></span>
                                                </td>
                                            </tr>
                                            <tr>
                                                <th><#OVPN_Port#></th>
                                                <td>
                                                    <input type="text" maxlength="5" size="5" name="vpnc_wg_peer_port" class="input" value="<% nvram_get_x("", "vpnc_wg_peer_port"); %>" onkeypress="return is_number(this,event);">
                                                    &nbsp;<span style="color:#888;">[ 51820 ]</span>
                                                </td>
                                            </tr>
                                            <tr>
                                                <th width="50%"><#WG_Peer_Public_key#>:</th>
                                                <td>
                                                    <input type="text" name="vpnc_wg_peer_public" class="input" maxlength="44" size="32" value="<% nvram_get_x("", "vpnc_wg_peer_public"); %>" onKeyPress="return is_string(this,event);"/>
                                                </td>
                                            </tr>
                                            <tr>
                                                <th><#VPNC_WG_KeepAlive#>:</th>
                                                <td>
                                                    <input type="text" name="vpnc_wg_peer_keepalive" class="input" maxlength="5" size="32" value="<% nvram_get_x("", "vpnc_wg_peer_keepalive"); %>" onKeyPress="return is_number(this,event);"/>
                                                    &nbsp;<span style="color:#888;">[ 0..65535 ]</span>
                                                </td>
                                            </tr>
                                            <tr>
                                                <th><#VPNC_WG_AllowedIPS#>:</th>
                                                <td>
                                                    <input type="text" name="vpnc_wg_peer_allowedips" class="input" maxlength="256" size="32" value="<% nvram_get_x("", "vpnc_wg_peer_allowedips"); %>" onKeyPress="return is_string(this,event);"/>
                                                    &nbsp;<span style="color:#888;">[ 0.0.0.0/0 ]</span>
                                                </td>
                                            </tr>
                                        </table>
                                        <table width="100%" style="margin-bottom: -8px;">
                                            <tr>
                                                <th colspan="2" style="background-color: #E3E3E3;"><#t2IF#></th>
                                            </tr>
                                            <tr>
                                                <th width="50%"><#VPNC_WG_Addresses#>:</th>
                                                <td>
                                                    <input type="text" name="vpnc_wg_if_addr" class="input" maxlength="256" size="32" value="<% nvram_get_x("", "vpnc_wg_if_addr"); %>" onKeyPress="return is_string(this,event);"/>
                                                </td>
                                            </tr>
                                            <tr>
                                                <th><#WG_Private_key#>:</th>
                                                <td>
                                                    <input style="-webkit-text-security: disc;" onfocus="vpnc_wg_if_private.style='-webkit-text-security: unset;'" onblur="vpnc_wg_if_private.style='-webkit-text-security: disc;'; wg_pubkey();" type="text" name="vpnc_wg_if_private" class="input" maxlength="44" size="32" value="<% nvram_get_x("", "vpnc_wg_if_private"); %>" onKeyPress="return is_string(this,event);"/>
                                                    <input type="button" class="btn btn-mini" style="outline:0" onclick="wg_genkey();" value="<#CTL_refresh#>"/>
                                                </td>
                                            </tr>
                                            <tr>
                                                <th><#WG_Public_key#>:</th>
                                                <td>
                                                    <input readonly type="text" name="vpnc_wg_if_public" class="input" maxlength="44" size="32" value="<% nvram_get_x("", "vpnc_wg_if_public"); %>" onKeyPress="return is_string(this,event);"/>
                                                    <input type="button" class="btn btn-mini" style="outline:0" onclick="document.form.vpnc_wg_if_public.select(); document.execCommand('copy');" value="<#CTL_copy#>"/>
                                                </td>
                                            </tr>
                                            <tr>
                                                <th><#WG_Preshared_key#>:</th>
                                                <td>
                                                    <input style="-webkit-text-security: disc;" onfocus="vpnc_wg_if_preshared.style='-webkit-text-security: unset;'" onblur="vpnc_wg_if_preshared.style='-webkit-text-security: disc;';" type="text" name="vpnc_wg_if_preshared" class="input" maxlength="44" size="32" value="<% nvram_get_x("", "vpnc_wg_if_preshared"); %>" onKeyPress="return is_string(this,event);"/>
                                                    <input type="button" class="btn btn-mini" style="outline:0" onclick="wg_genpsk();" value="<#CTL_refresh#>"/>
                                                </td>
                                            </tr>
                                            <tr>
                                                <th><#PPPConnection_x_PPPoEMTU_itemname#></th>
                                                <td>
                                                    <input type="text" name="vpnc_wg_mtu" class="input" maxlength="5" size="32" value="<% nvram_get_x("", "vpnc_wg_mtu"); %>" onKeyPress="return is_number(this,event);"/>
                                                    &nbsp;<span style="color:#888;">[ 1000..1420 ]</span>
                                                </td>
                                            </tr>
                                            <tr>
                                                <th><#PPPConnection_x_WANDNSServer_itemname#></th>
                                                <td>
                                                    <input type="text" name="vpnc_wg_if_dns" class="input" maxlength="256" size="32" value="<% nvram_get_x("", "vpnc_wg_if_dns"); %>" onKeyPress="return is_string(this,event);"/>
                                                </td>
                                            </tr>
                                        </table>
                                    </td>
                                </tr>

                                <tr id="row_vpnc_ov_prot" style="display:none">
                                    <th><#OVPN_Prot#></th>
                                    <td>
                                        <select name="vpnc_ov_prot" class="input">
                                            <option value="0" <% nvram_match_x("", "vpnc_ov_prot", "0","selected"); %>>UDP over IPv4 (*)</option>
                                            <option value="1" <% nvram_match_x("", "vpnc_ov_prot", "1","selected"); %>>TCP over IPv4</option>
                                            <option value="2" <% nvram_match_x("", "vpnc_ov_prot", "2","selected"); %>>UDP over IPv6</option>
                                            <option value="3" <% nvram_match_x("", "vpnc_ov_prot", "3","selected"); %>>TCP over IPv6</option>
                                            <option value="4" <% nvram_match_x("", "vpnc_ov_prot", "4","selected"); %>>UDP both</option>
                                            <option value="5" <% nvram_match_x("", "vpnc_ov_prot", "5","selected"); %>>TCP both</option>
                                        </select>
                                    </td>
                                </tr>
                                <tr id="row_vpnc_ov_mode" style="display:none">
                                    <th><#OVPN_Mode#></th>
                                    <td>
                                        <select name="vpnc_ov_mode" class="input" onchange="change_vpnc_ov_mode();">
                                            <option value="0" <% nvram_match_x("", "vpnc_ov_mode", "0","selected"); %>>L2 - TAP (Ethernet)</option>
                                            <option value="1" <% nvram_match_x("", "vpnc_ov_mode", "1","selected"); %>>L3 - TUN (IP)</option>
                                        </select>
                                    </td>
                                </tr>
                                <tr id="row_vpnc_ov_auth" style="display:none">
                                    <th><#OVPN_Auth#></th>
                                    <td>
                                        <select name="vpnc_ov_auth" class="input" onchange="change_vpnc_ov_auth();">
                                            <option value="0" <% nvram_match_x("", "vpnc_ov_auth", "0","selected"); %>>TLS: client.crt/client.key</option>
                                            <option value="1" <% nvram_match_x("", "vpnc_ov_auth", "1","selected"); %>>TLS: username/password</option>
                                        </select>
                                    </td>
                                </tr>
                                <tr id="row_vpnc_user">
                                    <th><#ISP_Authentication_user#></th>
                                    <td>
                                       <input type="text" maxlength="64" class="input" size="32" name="vpnc_user" value="<% nvram_get_x("", "vpnc_user"); %>" onkeypress="return is_string(this,event);"/>
                                    </td>
                                </tr>
                                <tr id="row_vpnc_pass">
                                    <th><#ISP_Authentication_pass#></th>
                                    <td>
                                        <div class="input-append">
                                            <input type="password" maxlength="64" class="input" size="32" name="vpnc_pass" id="vpnc_pass" style="width: 175px;" value="<% nvram_get_x("", "vpnc_pass"); %>"/>
                                            <button style="margin-left: -5px;" class="btn" type="button" onclick="passwordShowHide('vpnc_pass')"><i class="icon-eye-close"></i></button>
                                        </div>
                                    </td>
                                </tr>
                                <tr id="row_vpnc_auth">
                                    <th><#VPNS_Auth#></th>
                                    <td>
                                        <select name="vpnc_auth" class="input">
                                            <option value="0" <% nvram_match_x("", "vpnc_auth", "0","selected"); %>>Auto</option>
                                            <option value="1" <% nvram_match_x("", "vpnc_auth", "1","selected"); %>>MS-CHAPv2</option>
                                            <option value="2" <% nvram_match_x("", "vpnc_auth", "2","selected"); %>>CHAP</option>
                                            <option value="3" <% nvram_match_x("", "vpnc_auth", "3","selected"); %>>PAP</option>
                                        </select>
                                    </td>
                                </tr>
                                <tr id="row_vpnc_mppe">
                                    <th><#VPNS_Ciph#></th>
                                    <td>
                                        <select name="vpnc_mppe" class="input">
                                            <option value="0" <% nvram_match_x("", "vpnc_mppe", "0","selected"); %>>Auto</option>
                                            <option value="1" <% nvram_match_x("", "vpnc_mppe", "1","selected"); %>>MPPE-128</option>
                                            <option value="2" <% nvram_match_x("", "vpnc_mppe", "2","selected"); %>>MPPE-40</option>
                                            <option value="3" <% nvram_match_x("", "vpnc_mppe", "3","selected"); %>>No encryption</option>
                                        </select>
                                    </td>
                                </tr>
                                <tr id="row_vpnc_mtu">
                                    <th>MTU:</th>
                                    <td>
                                        <input type="text" maxlength="4" size="5" name="vpnc_mtu" class="input" value="<% nvram_get_x("", "vpnc_mtu"); %>" onkeypress="return is_number(this,event);"/>
                                        &nbsp;<span style="color:#888;">[1000..1460]</span>
                                    </td>
                                </tr>
                                <tr id="row_vpnc_mru">
                                    <th>MRU:</th>
                                    <td>
                                        <input type="text" maxlength="4" size="5" name="vpnc_mru" class="input" value="<% nvram_get_x("", "vpnc_mru"); %>" onkeypress="return is_number(this,event);"/>
                                        &nbsp;<span style="color:#888;">[1000..1460]</span>
                                    </td>
                                </tr>
                                <tr id="row_vpnc_pppd">
                                    <th style="padding-bottom: 0px;"><#PPPConnection_x_AdditionalOptions_itemname#></th>
                                    <td style="padding-bottom: 0px;">
                                        <input type="text" name="vpnc_pppd" value="<% nvram_get_x("", "vpnc_pppd"); %>" class="input" maxlength="255" size="32" onKeyPress="return is_string(this,event);" />
                                    </td>
                                </tr>
                                <tr id="row_vpnc_ov_mdig" style="display:none">
                                    <th><#VPNS_Auth#></th>
                                    <td>
                                        <select name="vpnc_ov_mdig" class="input">
                                            <option value="0" <% nvram_match_x("", "vpnc_ov_mdig", "0","selected"); %>>[MD5] MD-5, 128 bit</option>
                                            <option value="1" <% nvram_match_x("", "vpnc_ov_mdig", "1","selected"); %>>[SHA1] SHA-1, 160 bit (*)</option>
                                            <option value="2" <% nvram_match_x("", "vpnc_ov_mdig", "2","selected"); %>>[SHA224] SHA-224, 224 bit</option>
                                            <option value="3" <% nvram_match_x("", "vpnc_ov_mdig", "3","selected"); %>>[SHA256] SHA-256, 256 bit</option>
                                            <option value="4" <% nvram_match_x("", "vpnc_ov_mdig", "4","selected"); %>>[SHA384] SHA-384, 384 bit</option>
                                            <option value="5" <% nvram_match_x("", "vpnc_ov_mdig", "5","selected"); %>>[SHA512] SHA-512, 512 bit</option>
                                        </select>
                                    </td>
                                </tr>
                                <tr id="row_vpnc_ov_ciph" style="display:none">
                                    <th><#VPNS_Ciph#></th>
                                    <td>
                                        <select name="vpnc_ov_ciph" class="input">
                                            <option value="0" <% nvram_match_x("", "vpnc_ov_ciph", "0","selected"); %>>[none]</option>
                                            <option value="1" <% nvram_match_x("", "vpnc_ov_ciph", "1","selected"); %>>[DES-CBC] DES, 64 bit</option>
                                            <option value="2" <% nvram_match_x("", "vpnc_ov_ciph", "2","selected"); %>>[DES-EDE-CBC] 3DES, 128 bit</option>
                                            <option value="3" <% nvram_match_x("", "vpnc_ov_ciph", "3","selected"); %>>[BF-CBC] Blowfish, 128 bit (*)</option>
                                            <option value="4" <% nvram_match_x("", "vpnc_ov_ciph", "4","selected"); %>>[AES-128-CBC] AES, 128 bit</option>
                                            <option value="5" <% nvram_match_x("", "vpnc_ov_ciph", "5","selected"); %>>[AES-192-CBC] AES, 192 bit</option>
                                            <option value="6" <% nvram_match_x("", "vpnc_ov_ciph", "6","selected"); %>>[DES-EDE3-CBC] 3DES, 192 bit</option>
                                            <option value="7" <% nvram_match_x("", "vpnc_ov_ciph", "7","selected"); %>>[DESX-CBC] DES-X, 192 bit</option>
                                            <option value="8" <% nvram_match_x("", "vpnc_ov_ciph", "8","selected"); %>>[AES-256-CBC] AES, 256 bit</option>
                                            <option value="9" <% nvram_match_x("", "vpnc_ov_ciph", "9","selected"); %>>[CAMELLIA-128-CBC] CAM, 128 bit</option>
                                            <option value="10" <% nvram_match_x("", "vpnc_ov_ciph", "10","selected"); %>>[CAMELLIA-192-CBC] CAM, 192 bit</option>
                                            <option value="11" <% nvram_match_x("", "vpnc_ov_ciph", "11","selected"); %>>[CAMELLIA-256-CBC] CAM, 256 bit</option>
                                            <option value="12" <% nvram_match_x("", "vpnc_ov_ciph", "12","selected"); %>>[AES-128-GCM] AES-GCM, 128 bit</option>
                                            <option value="13" <% nvram_match_x("", "vpnc_ov_ciph", "13","selected"); %>>[AES-192-GCM] AES-GCM, 192 bit</option>
                                            <option value="14" <% nvram_match_x("", "vpnc_ov_ciph", "14","selected"); %>>[AES-256-GCM] AES-GCM, 256 bit</option>
                                            <option value="15" <% nvram_match_x("", "vpnc_ov_ciph", "15","selected"); %>>[CHACHA20-POLY1305], 256 bit</option>
                                        </select>
                                    </td>
                                </tr>
                                <tr id="row_vpnc_ov_ncp_clist" style="display:none">
                                    <th><#OVPN_NCP_clist#></th>
                                    <td>
                                        <input type="text" maxlength="256" size="15" name="vpnc_ov_ncp_clist" class="input" style="width: 310px;" value="<% nvram_get_x("", "vpnc_ov_ncp_clist"); %>" onkeypress="return is_string(this,event);"/>
                                    </td>
                                </tr>
                                <tr id="row_vpnc_ov_compress" style="display:none">
                                    <th><#OVPN_COMPRESS#></th>
                                    <td>
                                        <select name="vpnc_ov_compress" class="input">
                                            <option value="0" <% nvram_match_x("", "vpnc_ov_compress", "0","selected"); %>><#btn_Disable#> (*)</option>
                                            <option value="1" <% nvram_match_x("", "vpnc_ov_compress", "1","selected"); %>><#OVPN_COMPRESS_Item1#></option>
                                            <option value="2" <% nvram_match_x("", "vpnc_ov_compress", "2","selected"); %>><#OVPN_COMPRESS_Item2#></option>
                                            <option value="3" <% nvram_match_x("", "vpnc_ov_compress", "3","selected"); %>><#OVPN_COMPRESS_Item3#></option>
                                            <option value="4" <% nvram_match_x("", "vpnc_ov_compress", "4","selected"); %>><#OVPN_COMPRESS_Item4#></option>
                                        </select>
                                    </td>
                                </tr>
                                <tr id="row_vpnc_ov_atls" style="display:none">
                                    <th><#OVPN_HMAC#></th>
                                    <td>
                                        <select name="vpnc_ov_atls" class="input" onchange="change_vpnc_ov_atls();">
                                            <option value="0" <% nvram_match_x("", "vpnc_ov_atls", "0","selected"); %>><#checkbox_No#></option>
                                            <option value="1" <% nvram_match_x("", "vpnc_ov_atls", "1","selected"); %>><#OVPN_HMAC_Item1#></option>
                                            <option value="2" <% nvram_match_x("", "vpnc_ov_atls", "2","selected"); %>><#OVPN_HMAC_Item2#></option>
                                            <option value="3" <% nvram_match_x("", "vpnc_ov_atls", "3","selected"); %>><#OVPN_USE_TCV2_ItemC#></option>
                                        </select>
                                    </td>
                                </tr>
                                <tr id="row_vpnc_ov_cnat" style="display:none">
                                    <th><#OVPN_Topo#></th>
                                    <td>
                                        <select name="vpnc_ov_cnat" class="input">
                                            <option value="0" <% nvram_match_x("", "vpnc_ov_cnat", "0","selected"); %>><#OVPN_Topo1#></option>
                                            <option value="1" <% nvram_match_x("", "vpnc_ov_cnat", "1","selected"); %>><#OVPN_Topo2#></option>
                                        </select>
                                    </td>
                                </tr>
                                <tr id="row_vpnc_ov_conf" style="display:none">
                                    <td colspan="2" style="padding-bottom: 0px;">
                                        <a href="javascript:spoiler_toggle('spoiler_vpnc_ov_conf')"><span><#OVPN_User#></span></a>
                                        <div id="spoiler_vpnc_ov_conf" style="display:none;">
                                            <textarea rows="16" wrap="off" spellcheck="false" maxlength="8192" class="span12" name="ovpncli.client.conf" style="resize: vertical; font-family:'Courier New'; font-size:12px;"><% nvram_dump("ovpncli.client.conf",""); %></textarea>
                                        </div>
                                    </td>
                                </tr>
                            </table>

                            <table class="table" id="tbl_vpnc_amnezia" style="display: none">
                                <tr>
                                    <th colspan="2" style="background-color: #E3E3E3;"><#AmneziaWG_Params#></th>
                                </tr>
                                <tr>
                                    <td colspan="2" style="padding-left: 0px; padding-right: 0px">
                                        <a href="javascript:spoiler_toggle('spoiler_vpnc_amnezia_junk')"><span style="padding-left: 8px"><#AmneziaWG_JunkPackets#>:</span> <i style="scale: 75%;" class="icon-chevron-down"></i></a>
                                        <table width="100%" id="spoiler_vpnc_amnezia_junk" style="display: none; border: 0px">
                                            <tr>
                                                <th style="border: 0px" width="50%">Jc, <#AmneziaWG_Jc#>:</th>
                                                <td style="border: 0px">
                                                    <input name="vpnc_awg_jc" value="<% nvram_get_x("", "vpnc_awg_jc"); %>">
                                                    &nbsp;<span style="color:#888;">[ 0..128 ]</span>
                                                </td>
                                            </tr>
                                            <tr>
                                                <th>Jmin, <#AmneziaWG_Jmin#>:</th>
                                                <td>
                                                    <input name="vpnc_awg_jmin" value="<% nvram_get_x("", "vpnc_awg_jmin"); %>">
                                                    &nbsp;<span style="color:#888;">[ 0..1024 ]</span>
                                                </td>
                                            </tr>
                                            <tr>
                                                <th>Jmax, <#AmneziaWG_Jmax#>:</th>
                                                <td>
                                                    <input name="vpnc_awg_jmax" value="<% nvram_get_x("", "vpnc_awg_jmax"); %>">
                                                    &nbsp;<span style="color:#888;">[ Jmax > Jmin ]</span>
                                                </td>
                                            </tr>
                                        </table>
                                    </td>
                                </tr>
                                <tr>
                                    <td colspan="2" style="padding-left: 0px; padding-right: 0px">
                                        <a href="javascript:spoiler_toggle('spoiler_vpnc_amnezia_headers')"><span style="padding-left: 8px"><#AmneziaWG_HeadersMod#>:</span> <i style="scale: 75%;" class="icon-chevron-down"></i></a>
                                        <table width="100%" id="spoiler_vpnc_amnezia_headers" style="display: none; border: 0px">
                                            <tr>
                                                <th style="border: 0px" width="50%"><a class="help_tooltip" href="javascript:void(0);" onmouseover="openTooltip(this,26,3);">Header protection key</a>:</th>
                                                <td style="border: 0px">
                                                    <input style="-webkit-text-security: disc;" onfocus="vpnc_awg_headerprotectionkey.style='-webkit-text-security: unset;'" onblur="vpnc_awg_headerprotectionkey.style='-webkit-text-security: disc;';" type="text" name="vpnc_awg_headerprotectionkey" class="input" maxlength="44" size="32" value="<% nvram_get_x("", "vpnc_awg_headerprotectionkey"); %>" onKeyPress="return is_string(this,event);"/>
                                                    <input type="button" class="btn btn-mini" style="outline:0" onclick="wg_genhpk();" value="<#CTL_refresh#>"/>
                                                </td>
                                            </tr>
                                            <tr>
                                                <th>Content padding addition:</th>
                                                <td>
                                                    <input name="vpnc_awg_contentpaddingaddition" value="<% nvram_get_x("", "vpnc_awg_contentpaddingaddition"); %>">
                                                    &nbsp;<span style="color:#888;">[ 0..100 ]</span>
                                                </td>
                                            </tr>
                                            <tr>
                                                <th>Init header, H1:</th>
                                                <td>
                                                    <input name="vpnc_awg_h1" value="<% nvram_get_x("", "vpnc_awg_h1"); %>">
                                                </td>
                                            </tr>
                                            <tr>
                                                <th>Response header, H2:</th>
                                                <td>
                                                    <input name="vpnc_awg_h2" value="<% nvram_get_x("", "vpnc_awg_h2"); %>">
                                                </td>
                                            </tr>
                                            <tr>
                                                <th>Cookie header, H3:</th>
                                                <td>
                                                    <input name="vpnc_awg_h3" value="<% nvram_get_x("", "vpnc_awg_h3"); %>">
                                                </td>
                                            </tr>
                                            <tr>
                                                <th>Data header, H4:</th>
                                                <td>
                                                    <input name="vpnc_awg_h4" value="<% nvram_get_x("", "vpnc_awg_h4"); %>">
                                                </td>
                                            </tr>
                                            <tr>
                                                <th>Init random increment, S1:</th>
                                                <td>
                                                    <input name="vpnc_awg_s1" value="<% nvram_get_x("", "vpnc_awg_s1"); %>">
                                                    &nbsp;<span style="color:#888;">[ 0..256 ]</span>
                                                </td>
                                            </tr>
                                            <tr>
                                                <th>Response random increment, S2:</th>
                                                <td>
                                                    <input name="vpnc_awg_s2" value="<% nvram_get_x("", "vpnc_awg_s2"); %>">
                                                    &nbsp;<span style="color:#888;">[ 0..256 ]</span>
                                                </td>
                                            </tr>
                                            <tr>
                                                <th>Cookie random increment, S3:</th>
                                                <td>
                                                    <input name="vpnc_awg_s3" value="<% nvram_get_x("", "vpnc_awg_s3"); %>">
                                                    &nbsp;<span style="color:#888;">[ 0..256 ]</span>
                                                </td>
                                            </tr>
                                            <tr>
                                                <th>Data random increment, S4:</th>
                                                <td>
                                                    <input name="vpnc_awg_s4" value="<% nvram_get_x("", "vpnc_awg_s4"); %>">
                                                    &nbsp;<span style="color:#888;">[ 0..32 ]</span>
                                                </td>
                                            </tr>
                                        </table>
                                    </td>
                                </tr>

                                <tr>
                                    <td colspan="2" style="padding-left: 0px; padding-right: 0px">
                                        <a href="javascript:spoiler_toggle('spoiler_vpnc_amnezia_i1')"><span style="padding-left: 8px"><#AmneziaWG_ObfuscationProto#>:</span> <i style="scale: 75%;" class="icon-chevron-down"></i></a>
                                        <table width="100%" id="spoiler_vpnc_amnezia_i1" style="display: none; border: 0px;">
                                            <tr>
                                                <th style="border: 0px" width="50%"><#AmneziaWG_Obfuscation#> I1:</th>
                                                <td style="border: 0px">
                                                    <input style="width: 310px" type="text" name="vpnc_awg_i1" class="input" maxlength="4096" size="32" value="<% nvram_get_x("", "vpnc_awg_i1"); %>" onKeyPress="return is_string(this,event);"/>
                                                </td>
                                            </tr>
                                            <tr>
                                                <th><#AmneziaWG_Obfuscation#> I2:</th>
                                                <td>
                                                    <input style="width: 310px;" type="text" name="vpnc_awg_i2" class="input" maxlength="512" size="32" value="<% nvram_get_x("", "vpnc_awg_i2"); %>" onKeyPress="return is_string(this,event);"/>
                                                </td>
                                            </tr>
                                            <tr>
                                                <th><#AmneziaWG_Obfuscation#> I3:</th>
                                                <td>
                                                    <input style="width: 310px;" type="text" name="vpnc_awg_i3" class="input" maxlength="512" size="32" value="<% nvram_get_x("", "vpnc_awg_i3"); %>" onKeyPress="return is_string(this,event);"/>
                                                </td>
                                            </tr>
                                            <tr>
                                                <th><#AmneziaWG_Obfuscation#> I4:</th>
                                                <td>
                                                    <input style="width: 310px;" type="text" name="vpnc_awg_i4" class="input" maxlength="512" size="32" value="<% nvram_get_x("", "vpnc_awg_i4"); %>" onKeyPress="return is_string(this,event);"/>
                                                </td>
                                            </tr>
                                            <tr>
                                                <th><#AmneziaWG_Obfuscation#> I5:</th>
                                                <td>
                                                    <input style="width: 310px;" type="text" name="vpnc_awg_i5" class="input" maxlength="512" size="32" value="<% nvram_get_x("", "vpnc_awg_i5"); %>" onKeyPress="return is_string(this,event);"/>
                                                </td>
                                            </tr>
                                        </table>
                                    </td>
                                </tr>

                                <tr>
                                    <td colspan="2" style="padding: 0px; padding-top: 8px">
                                        <a href="javascript:spoiler_toggle('spoiler_vpnc_amnezia_timeouts')"><span style="padding-left: 8px"><#AmneziaWG_Timeouts#>:</span> <i style="scale: 75%;" class="icon-chevron-down"></i></a>
                                        <table width="100%" id="spoiler_vpnc_amnezia_timeouts" style="display: none; border: 0px">

                                            <tr>
                                                <th style="border: 0px" width="50%">Rekey after time, <#Second#>:</th>
                                                <td style="border: 0px">
                                                    <input name="vpnc_awg_rekeyaftertime" value="<% nvram_get_x("", "vpnc_awg_rekeyaftertime"); %>">
                                                    &nbsp;<span style="color:#888;">[ 0..300 ]</span>
                                                </td>
                                            </tr>
                                            <tr>
                                                <th width="50%">Rekey timeout, <#Second#>:</th>
                                                <td>
                                                    <input name="vpnc_awg_rekeytimeout" value="<% nvram_get_x("", "vpnc_awg_rekeytimeout"); %>">
                                                    &nbsp;<span style="color:#888;">[ 0..300 ]</span>
                                                </td>
                                            </tr>
                                            <tr>
                                                <th width="50%">Reject after time, <#Second#>:</th>
                                                <td>
                                                    <input name="vpnc_awg_rejectaftertime" value="<% nvram_get_x("", "vpnc_awg_rejectaftertime"); %>">
                                                    &nbsp;<span style="color:#888;">[ 0..300 ]</span>
                                                </td>
                                            </tr>
                                            <tr>
                                                <th width="50%">Keepalive timeout, <#Second#>:</th>
                                                <td>
                                                    <input name="vpnc_awg_keepalivetimeout" value="<% nvram_get_x("", "vpnc_awg_keepalivetimeout"); %>">
                                                    &nbsp;<span style="color:#888;">[ 0..300 ]</span>
                                                </td>
                                            </tr>
                                            <tr>
                                                <th style="padding-bottom: 0px" width="50%">Max handshake attempts:</th>
                                                <td style="padding-bottom: 0px">
                                                    <input name="vpnc_awg_maxhandshakeattempts" value="<% nvram_get_x("", "vpnc_awg_maxhandshakeattempts"); %>">
                                                    &nbsp;<span style="color:#888;">[ 0..300 ]</span>
                                                </td>
                                            </tr>
                                        </table>
                                    </td>
                                </tr>
                            </table>

                            <table class="table" id="tbl_vpnc_access_control" style="display: none">
                                <tr>
                                    <th colspan="2" style="background-color: #E3E3E3;"><#VPNC_AccessControl#></th>
                                </tr>
                                <tr>
                                    <th width="50%"><#VPNC_ClientsList#>:</th>
                                    <td>
                                        <span id="vpnc_clients"></span>
                                        <input type="hidden" name="vpnc_clients" value="<% nvram_get_x("", "vpnc_clients"); %>">
                                        <input type="hidden" name="vpnc_clients_allowed" value="<% nvram_get_x("", "vpnc_clients_allowed"); %>">
                                    </td>
                                </tr>
                                <tr id="row_vpnc_ipset" style="display: none">
                                    <th width="50%"><#VPNC_IpsetList#>:</th>
                                    <td>
                                        <span id="vpnc_ipset"></span>
                                        <input type="hidden" name="vpnc_ipset" value="<% nvram_get_x("", "vpnc_ipset"); %>">
                                        <input type="hidden" name="vpnc_ipset_allowed" value="<% nvram_get_x("", "vpnc_ipset_allowed"); %>">
                                    </td>
                                </tr>

                                <tr id="row_dipset" style="display: none">
                                    <td colspan="2">
                                        <a href="javascript:spoiler_toggle('spoiler_dipset')"><span><#CustomConf#> "dnsmasq.ipset"</span> <i style="scale: 75%;" class="icon-chevron-down"></i></a>
                                        <div id="spoiler_dipset" style="display:none;">
                                            <textarea rows="16" wrap="off" spellcheck="false" maxlength="32768" class="span12" name="dnsmasq.dnsmasq.ipset" style="resize: vertical; font-family:'Courier New'; font-size:12px;"><% nvram_dump("dnsmasq.dnsmasq.ipset",""); %></textarea>
                                        </div>
                                    </td>
                                </tr>

                                <tr>
                                    <td colspan="2">
                                        <a href="javascript:spoiler_toggle('spoiler_vpnc_remote_network')"><span><#VPNC_RNet_List#>:</span> <i style="scale: 75%;" class="icon-chevron-down"></i></a>
                                        <div id="spoiler_vpnc_remote_network" style="display: none">
                                            <textarea rows="16" wrap="off" spellcheck="false" maxlength="32768" class="span12" name="scripts.vpnc_remote_network.list" style="font-family:'Courier New'; font-size:12px; resize:vertical;"><% nvram_dump("scripts.vpnc_remote_network.list",""); %></textarea>
                                        </div>
                                    </td>
                                </tr>
                                <tr>
                                    <td colspan="2" style="padding-bottom: 0px;">
                                        <a href="javascript:spoiler_toggle('spoiler_vpnc_exclude_network')"><span><#VPNC_ExcludeList#>:</span> <i style="scale: 75%;" class="icon-chevron-down"></i></a>
                                        <div id="spoiler_vpnc_exclude_network" style="display: none">
                                            <textarea rows="16" wrap="off" spellcheck="false" maxlength="32768" class="span12" name="scripts.vpnc_exclude_network.list" style="font-family:'Courier New'; font-size:12px; resize:vertical; margin-bottom: 0px"><% nvram_dump("scripts.vpnc_exclude_network.list",""); %></textarea>
                                        </div>
                                    </td>
                                </tr>
                            </table>

                            <table class="table" id="tbl_vpnc_server">
                                <tr>
                                    <th colspan="2" style="background-color: #E3E3E3;"><#VPNC_VPNS#></th>
                                </tr>
                                <tr>
                                    <th width="50%"><#VPNC_SFW#></th>
                                    <td>
                                        <select name="vpnc_sfw" class="input" style="width: 320px;">
                                            <option value="1" <% nvram_match_x("", "vpnc_sfw", "1","selected"); %>><#VPNC_SFW_Item1#></option>
                                            <option value="3" <% nvram_match_x("", "vpnc_sfw", "3","selected"); %>><#VPNC_SFW_Item3#></option>
                                            <option value="0" <% nvram_match_x("", "vpnc_sfw", "0","selected"); %>><#VPNC_SFW_Item0#></option>
                                            <option value="2" <% nvram_match_x("", "vpnc_sfw", "2","selected"); %>><#VPNC_SFW_Item2#></option>
                                        </select>
                                    </td>
                                </tr>
                                <tr id="vpnc_get_dns">
                                    <th id="vpnc_use_dns"><#VPNC_PDNS#></th>
                                    <td>
                                        <select name="vpnc_pdns" class="input" style="width: 320px;">
                                            <option value="0" <% nvram_match_x("", "vpnc_pdns", "0","selected"); %>><#checkbox_No#></option>
                                            <option value="1" <% nvram_match_x("", "vpnc_pdns", "1","selected"); %>><#VPNC_PDNS_Item1#></option>
                                            <option value="2" <% nvram_match_x("", "vpnc_pdns", "2","selected"); %>><#VPNC_PDNS_Item2#></option>
                                        </select>
                                    </td>
                                </tr>
                                <tr>
                                    <th><#VPNC_DGW#></th>
                                    <td>
                                        <select name="vpnc_dgw" class="input" style="width: 320px;">
                                            <option value="0" <% nvram_match_x("", "vpnc_dgw", "0","selected"); %>><#checkbox_No#></option>
                                            <option value="1" <% nvram_match_x("", "vpnc_dgw", "1","selected"); %>><#checkbox_Yes#></option>
                                        </select>
                                    </td>
                                </tr>
                                <tr id="row_vpnc_server_script" style="display: none">
                                    <td colspan="2">
                                        <a href="javascript:spoiler_toggle('spoiler_script')"><span><#RunPostVPNC#></span> <i style="scale: 75%;" class="icon-chevron-down"></i></a>
                                        <div id="spoiler_script" style="display:none;">
                                            <textarea rows="16" wrap="off" spellcheck="false" maxlength="8192" class="span12" name="scripts.vpnc_server_script.sh" style="font-family:'Courier New'; font-size:12px; resize:vertical;"><% nvram_dump("scripts.vpnc_server_script.sh",""); %></textarea>
                                        </div>
                                    </td>
                                </tr>
                                <tr id="row_vpnc_post_script" style="display: none">
                                    <td colspan="2">
                                        <a href="javascript:spoiler_toggle('spoiler_post_script')"><span><#ZapretPostScript#>:</span> <i style="scale: 75%;" class="icon-chevron-down"></i></a>
                                        <div id="spoiler_post_script" style="display:none;">
                                            <textarea rows="16" wrap="off" spellcheck="false" maxlength="8192" class="span12" name="scripts.vpnc_post_script.sh" style="font-family:'Courier New'; font-size:12px; resize:vertical;"><% nvram_dump("scripts.vpnc_post_script.sh",""); %></textarea>
                                        </div>
                                    </td>
                                </tr>
                            </table>
                            <table class="table" id="tbl_vpnc_route" style="display:none">
                                <tr>
                                    <th colspan="2" style="background-color: #E3E3E3;"><#VPNC_Route#></th>
                                </tr>
                                <tr>
                                    <th width="50%"><#VPNC_RNet#></th>
                                    <td>
                                        <input type="text" maxlength="15" size="14" name="vpnc_rnet" style="width: 145px;" value="<% nvram_get_x("", "vpnc_rnet"); %>" onKeyPress="return is_ipaddr(this,event);" />&nbsp;/
                                        <input type="text" maxlength="15" size="14" name="vpnc_rmsk" style="width: 144px;" value="<% nvram_get_x("", "vpnc_rmsk"); %>" onKeyPress="return is_ipaddr(this,event);" />
                                    </td>
                                </tr>
                            </table>
                            <table class="table">
                                <tr>
                                    <td style="border: 0 none; padding: 0px;"><center><input name="button" type="button" class="btn btn-primary" style="width: 219px" onclick="applyRule();" value="<#CTL_apply#>"/></center></td>
                                </tr>
                            </table>
                        </div>

                        <div id="wnd_vpnc_ssl" style="display:none">
                            <table class="table">
                                <tr>
                                    <td style="padding-bottom: 0px; border-top: 0 none;">
                                        <span class="caption-bold">ca.crt (Root CA Certificate):</span>
                                        <textarea rows="4" wrap="off" spellcheck="false" maxlength="8192" class="span12" name="ovpncli.ca.crt" style="resize: vertical; font-family:'Courier New'; font-size:12px;"><% nvram_dump("ovpncli.ca.crt",""); %></textarea>
                                    </td>
                                </tr>
                                <tr id="row_client_crt">
                                    <td style="padding-bottom: 0px; border-top: 0 none;">
                                        <span class="caption-bold">client.crt (Client Certificate):</span>
                                        <textarea rows="4" wrap="off" spellcheck="false" maxlength="8192" class="span12" name="ovpncli.client.crt" style="resize: vertical; font-family:'Courier New'; font-size:12px;"><% nvram_dump("ovpncli.client.crt",""); %></textarea>
                                    </td>
                                </tr>
                                <tr id="row_client_key">
                                    <td style="padding-bottom: 0px; border-top: 0 none;">
                                        <span class="caption-bold">client.key (Client Private Key) - secret:</span>
                                        <textarea rows="4" wrap="off" spellcheck="false" maxlength="8192" class="span12" name="ovpncli.client.key" style="resize: vertical; font-family:'Courier New'; font-size:12px;"><% nvram_dump("ovpncli.client.key",""); %></textarea>
                                    </td>
                                </tr>
                                <tr id="row_ta_key">
                                    <td style="padding-bottom: 0px; border-top: 0 none;">
                                        <span class="caption-bold">ta.key/tc.key(ctc2.key) (TLS Auth/Crypt(Crypt-v2) Key) - secret:</span>
                                        <textarea rows="4" wrap="off" spellcheck="false" maxlength="8192" class="span12" name="ovpncli.ta.key" style="resize: vertical; font-family:'Courier New'; font-size:12px;"><% nvram_dump("ovpncli.ta.key",""); %></textarea>
                                    </td>
                                </tr>
                            </table>
                            <table class="table">
                                <tr>
                                    <td style="border: 0 none;"><center><input name="button2" type="button" class="btn btn-primary" style="width: 219px" onclick="applyRule();" value="<#CTL_apply#>"/></center></td>
                                </tr>
                            </table>
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
