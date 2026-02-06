<?php
$params = json_decode(file_get_contents("php://input"), true);
if($params){
    $_REQUEST += $params;
}

switch ($_REQUEST['act']) {
	case 'mqtt_config':
		act_mqtt_config();
		break;
	default:
		$data = '{"status":"error","code":"401","msg":"No Actions"}';
		_response($data);
		break;
}
exit;

function act_mqtt_config(){

    $config = array();
    $config['host'] = 'tcp://49.51.243.227:31504';
    $config['userName'] = 'geeqee';
    $config['passWord'] = 'fafd99wehfh9efhsk3';

	$data = '{"status":"success","code":"0","msg":"OK", "data": '.json_encode($config).'}';
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