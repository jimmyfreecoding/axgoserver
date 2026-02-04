<?php
require(dirname(__FILE__)."/../../../lib/core.pms");
require(dirname(__FILE__)."/../../../lib/arcface.pms");

$params = json_decode(file_get_contents("php://input"), true);
if($params){
    $_REQUEST += $params;
}

if(empty($_REQUEST['act'])){
    $data = '{"status":"error","code":"401","msg":"无效请求"}';
    _response($data);
    exit;
}

switch ($_REQUEST['act']) {

    case 'device_list':
        act_device_list();
        break;
    case 'device_rule_list':
        act_device_rule_list();
        break;
    case 'device_rule_detail':
        act_device_rule_detail();
        break;

    case 'device_logs':
        act_device_logs();
        break;

    default:
        $data = '{"status":"error","code":"401","msg":"请求无效"}';
        _response($data);
        break;
}

function act_device_logs(){
    if(empty($_REQUEST['macaddr'])){
        $data = '{"status":"error","code":"1","msg":"无效请求"}';
        _response($data);
        exit;
    }

    $axgo_devices = array();
    core_select_data("select * from axgo_device where macaddr = '".$_REQUEST['macaddr']."' limit 1", $axgo_devices);
    if(!isset($axgo_devices[0]) || empty($axgo_devices[0]['faceCode'])){
        $data = '{"status":"error","code":"1","msg":"无效设备"}';
        _response($data);
        exit;
    }

    $pageIndex = 1;
    $pageNum = 20;
    if(!empty($_REQUEST['pageIndex'])){
        $pageIndex = intval($_REQUEST['pageIndex']);
    }
    if(!empty($_REQUEST['pageNum'])){
        $pageNum = intval($_REQUEST['pageNum']);
    }

    $msg = "";
    $result = arcface_device_log($axgo_devices[0]['faceCode'], $pageIndex, $pageNum, $msg);
    if(!$result){
        $data = '{"status":"error","code":"1","msg":"获取日志失败【'.$msg.'】"}';
        _response($data);
        exit;
    }

    $data = '{"status":"success","code":"0","data":'.json_encode($result).'}';
    _response($data);
    exit;
}

function act_device_rule_detail(){

    if(empty($_REQUEST['ruleID'])){
        $data = '{"status":"error","code":"1","msg":"无效请求"}';
        _response($data);
        exit;
    }

    $rules = array();
    core_select_data("select * from axgo_face_rule where id = '".$_REQUEST['ruleID']."'", $rules);
    if(!isset($rules[0])){
        $data = '{"status":"error","code":"1","msg":"无效规则"}';
        _response($data);
        exit;
    }
    $rules[0]['users'] = array();
    core_select_data("select * from axgo_face_rule_user where ruleID = '".$rules[0]['id']."'", $rules[0]['users']);

    $rules[0]['times'] = array();
    core_select_data("select * from axgo_face_rule_time where ruleID = '".$rules[0]['id']."'", $rules[0]['times']);

    $data = '{"status":"success","code":"0","msg":"ok", "data":'.json_encode($rules[0]).'}';
    _response($data);
    exit;
}

function act_device_rule_list(){

    if(empty($_REQUEST['macaddr'])){
        $data = '{"status":"error","code":"1","msg":"无效请求"}';
        _response($data);
        exit;
    }

    $rules = array();
    core_select_data("select * from axgo_face_rule where macaddr = '".$_REQUEST['macaddr']."'", $rules);

    $data = '{"status":"success","code":"0","msg":"ok", "data":'.json_encode($rules).'}';
    _response($data);
    exit;
}

function act_device_list(){

    if(empty($_REQUEST['spaceCode'])){
        $data = '{"status":"error","code":"1","msg":"无效请求"}';
        _response($data);
        exit;
    }

    $devices = array();
    core_select_data("select macaddr, devicenick from axgo_device where macaddr in (select macaddr from axgo_device_bind where spaceCode = '".$_REQUEST['spaceCode']."')", $devices);

    $data = '{"status":"success","code":"0","msg":"ok", "data":'.json_encode($devices).'}';
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