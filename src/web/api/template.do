<?php
require(dirname(__FILE__)."/../../lib/c_config.pms");
require(dirname(__FILE__)."/../../lib/c_common.pms");

$params = json_decode(file_get_contents("php://input"), true);
if($params){
    $_REQUEST += $params;
}

switch ($_REQUEST['act']) {
	case 'all_template':
		act_all_template();
		break;
	default:
		$data = '{"status":"error","code":"401","msg":"No Actions"}';
		_response($data);
		break;
}
exit;

function act_all_template(){

    $CONF = &$GLOBALS['CONF'];

    if(empty($_REQUEST['mac'])){
        $data = '{"status":"error","code":"1","msg":"无效请求设备"}';
        _response($data);
        exit;
    }

    $templates = array();

    $dbcon = common_get_connect($CONF['mysql_server_addr'],$CONF['mysql_username'],$CONF['mysql_password']);
    common_change_database($CONF['mysql_dbname'], $dbcon);

    $result = mysql_query("select * from axgo_module where online = '1'", $dbcon);
    while ($row = mysql_fetch_array($result,MYSQL_ASSOC)) {
        if($row['type'] == '1' && strpos($row['auth_macaddr'], $_REQUEST['mac']) == -1){
            continue;
        }
        array_push($templates, $row);
    }
    mysql_free_result($result);
    common_close_connect($dbcon);

	$data = '{"status":"success","code":"0","msg":"OK", "data": '.json_encode($templates).'}';
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