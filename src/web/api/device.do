<?php
require(dirname(__FILE__)."/../../lib/core.pms");

$params = json_decode(file_get_contents("php://input"), true);
if($params){
    $_REQUEST += $params;
}

switch ($_REQUEST['act']) {
	case 'device_status_update':
		act_device_status_update();
		break;
	default:
		$data = '{"status":"error","code":"401","msg":"No Actions"}';
		_response($data);
		break;
}
exit;

function act_device_status_update(){

    if(empty($_REQUEST['macaddr'])){
        $data = '{"status":"error","code":"1","msg":"无效请求设备"}';
        _response($data);
        exit;
    }

    $devices = array();
    core_select_data("select * from axgo_device where macaddr = '".$_REQUEST['macaddr']."' limit 1", $devices);
    if(!isset($devices[0])){
        $data = '{"status":"error","code":"1","msg":"无效设备"}';
        _response($data);
        exit;
    }

    core_query_data("update axgo_device set status = '1', statusUpdateTime = '".time()."' where id = '".$devices[0]['id']."'");

	$data = '{"status":"success","code":"0","msg":"OK"}';
	_response($data);
	exit;
}

function _response($data){
	if (isset($_REQUEST['callback'])) {
		$data = $_REQUEST['callback'].'('.$data.')';
	}
	echo $data;
}
?>