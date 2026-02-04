<?php
require(dirname(__FILE__)."/../../lib/core.pms");
require(dirname(__FILE__)."/../../lib/arcface.pms");

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

    case 'books_check':
        act_books_check();
        break;

    default:
        $data = '{"status":"error","code":"401","msg":"请求无效"}';
        _response($data);
        break;
}

/**
 * 将预定信息转换为扩展规则下发到设备上
 * 根据与会人姓名匹配人脸库
 * $books = [{"timeStart":"","timeStop":"","members":"张三,李四"}]
 */
function act_books_check(){

    $CONF = &$GLOBALS['CONF'];

    if (empty($_REQUEST['macaddr']) || !isset($_REQUEST['books'])) {
        $data = '{"status":"error","code":"1","msg":"缺少必要参数"}';
        _response($data);
        exit;
    }

    $devices = array();
    core_select_data("select * from axgo_device where macaddr = '" . $_REQUEST['macaddr'] . "' limit 1", $devices);
    if (!isset($devices[0])) {
        $data = '{"status":"error","code":"1","msg":"无效设备"}';
        _response($data);
        exit;
    }

    $device_binds = array();
    core_select_data("select * from axgo_device_bind where macaddr = '".$devices[0]['macaddr']."' limit 1", $device_binds);
    if(!isset($device_binds[0])){
        $data = '{"status":"error","code":"1","msg":"无权限操作01"}';
        _response($data);
        exit;
    }

    $axgo_face_groups = array();
    core_select_data("select * from axgo_face_group where spaceCode = '".$device_binds[0]['spaceCode']."' limit 1", $axgo_face_groups);
    if(!isset($axgo_face_groups[0])){
        $data = '{"status":"error","code":"1","msg":"无对应设备人脸库"}';
        _response($data);
        exit;
    }

    $face_group_users = array();
    $face_group_users_obj = array();
    core_select_data("select * from axgo_face_group_user where personSetId = '".$axgo_face_groups[0]['personSetId']."'", $face_group_users);
    foreach ($face_group_users as $face_group_user) {
        $face_group_users_obj[$face_group_user['personId']] = true;
    }

    $face_rules = array();

    //$books = json_decode($_REQUEST['books'], true);
    $books = $_REQUEST['books'];
    foreach($books as $book){
        $members = explode(",", $book['members']);
        $member_arr = array();
        foreach ($members as $member) {
            $face_users = array();
            core_select_data("select * from axgo_face_user where name like '%".$member."%'", $face_users);
            foreach ($face_users as $face_user) {
                if(!isset($face_group_users_obj[$face_user['personId']])){
                    continue;
                }
                array_push($member_arr, $face_user['personId']);
            }
        }
        if(count($member_arr) == 0){
            continue;
        }

        $book_rule = array();
        $book_rule['type'] = "date_part";
        $book_rule['startDate'] = date("Y-m-d", $book['timeStart']);
        $book_rule['stopDate'] = date("Y-m-d", $book['timeStart']);
        $book_rule['users'] = $member_arr;
        $book_rule['times'] = array();
        array_push($book_rule['times'], array(
            "startTime" => date("H:i", $book['timeStart']),
            "stopTime" => date("H:i", $book['timeStop']),
        ));
        array_push($face_rules, $book_rule);
    }


    $job = array();
    $job['macaddr'] = $devices[0]['macaddr'];
    $job['command'] = array();
    $job['command']['type'] = "face_rule_extend";
    $job['command']['rules'] = $face_rules;
    file_put_contents($CONF['mosquitto_tmpdir']."/".uniqid("MQTT"), json_encode($job), LOCK_EX);

    $data = '{"status":"success","code":"0","msg":"ok"}';
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