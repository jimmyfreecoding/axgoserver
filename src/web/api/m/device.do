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
    case 'user_devices':
        act_user_devices();
        break;
    case 'user_device_info':
        act_user_device_info();
        break;
    case 'user_device_bind':
        act_user_device_bind();
        break;
    case 'user_device_template':
        act_user_device_template();
        break;
    case 'device_template_down':
        act_device_template_down();
        break;
    case 'device_template_data_down':
        act_device_template_data_down();
        break;

    case 'device_rule_list':
        act_device_rule_list();
        break;
    case 'device_rule_modify':
        act_device_rule_modify();
        break;
    case 'device_rule_detail':
        act_device_rule_detail();
        break;
    case 'device_rule_remove':
        act_device_rule_remove();
        break;

    case 'device_app_reload':
        act_device_app_reload();
        break;
    default:
        $data = '{"status":"error","code":"401","msg":"请求无效"}';
        _response($data);
        break;
}

function act_device_app_reload(){

    $CONF = &$GLOBALS['CONF'];

    if(empty($_REQUEST['unionid']) || empty($_REQUEST['macaddr'])){
        $data = '{"status":"error","code":"1","msg":"无效请求"}';
        _response($data);
        exit;
    }

    $users = array();
    core_select_data("select * from axgo_user where unionid = '".$_REQUEST['unionid']."' limit 1", $users);
    if(!isset($users[0])){
        $data = '{"status":"error","code":"1","msg":"无效请求用户"}';
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

    $device_binds = array();
    core_select_data("select * from axgo_device_bind where macaddr = '".$devices[0]['macaddr']."' limit 1", $device_binds);
    if(!isset($device_binds[0])){
        $data = '{"status":"success","code":"0","msg":"ok","data":'.json_encode($devices[0]).'}';
        _response($data);
        exit;
    }

    $spaces = array();
    core_select_data("select * from axgo_space where code = '".$device_binds[0]['spaceCode']."' limit 1", $spaces);

    $space_admins = array();
    core_select_data("select * from axgo_space_admin where userID = '".$users[0]['id']."' and spaceCode = '".$device_binds[0]['spaceCode']."' limit 1", $space_admins);

    if(!isset($spaces[0]) || ($spaces[0]['createUserID'] != $users[0]['id'] && !isset($space_admins[0]))){
        $data = '{"status":"error","code":"1","msg":"无权限操作"}';
        _response($data);
        exit;
    }

    $job = array();
    $job['macaddr'] = $devices[0]['macaddr'];
    $job['commandType'] = "system";
    $job['command'] = array();
    $job['command']['type'] = "app_reload";
    //file_put_contents($CONF['mosquitto_tmpdir']."/".uniqid("MQTT"), json_encode($job), LOCK_EX);
    _request($CONF['url_pre']."/mqtt", "POST", $job);

    $data = '{"status":"success","code":"0","msg":"ok"}';
    _response($data);
    exit;
}

function _device_down_rules($macaddr){

    $CONF = &$GLOBALS['CONF'];

    $face_rules = array();
    core_select_data("select * from axgo_face_rule where macaddr = '".$macaddr."' order by sortIndex DESC", $face_rules);
    foreach ($face_rules as $key => $face_rule) {
        $face_rule_users = array();
        core_select_data("select * from axgo_face_rule_user where ruleID = '".$face_rule['id']."'", $face_rule_users);
        $face_rules[$key]['users'] = array();
        foreach ($face_rule_users as $face_rule_user) {
            if(empty($face_rule_user['personId'])){
                continue;
            }
            array_push($face_rules[$key]['users'], $face_rule_user['personId']);
        }

        $face_rule_times = array();
        core_select_data("select startTime,stopTime from axgo_face_rule_time where ruleID = '".$face_rule['id']."'", $face_rule_times);
        if(isset($face_rule_times[0])){
            $face_rules[$key]['times'] = $face_rule_times;
        }

        unset($face_rules[$key]['id']);
        unset($face_rules[$key]['deviceID']);
        unset($face_rules[$key]['macaddr']);
        unset($face_rules[$key]['name']);
        unset($face_rules[$key]['createtime']);
        unset($face_rules[$key]['sortIndex']);

        if(empty($face_rules[$key]['weekDay'])){
            unset($face_rules[$key]['weekDay']);
        }else{
            $face_rules[$key]['day'] = $face_rules[$key]['weekDay'];
            unset($face_rules[$key]['weekDay']);
        }
    }

    $job = array();
    $job['macaddr'] = $macaddr;
    $job['command'] = array();
    $job['command']['type'] = "face_rule";
    $job['command']['rules'] = $face_rules;
    //file_put_contents($CONF['mosquitto_tmpdir']."/".uniqid("MQTT"), json_encode($job), LOCK_EX);
    _request($CONF['url_pre']."/mqtt", "POST", $job);
    $data = '{"status":"success","code":"0","msg":"ok"}';
    _response($data);
    exit;
}

function act_device_rule_detail(){

    $CONF = &$GLOBALS['CONF'];

    if (empty($_REQUEST['unionid']) ||
        empty($_REQUEST['macaddr']) ||
        empty($_REQUEST['id'])) {
        $data = '{"status":"error","code":"1","msg":"缺少必要参数"}';
        _response($data);
        exit;
    }

    $users = array();
    core_select_data("select * from axgo_user where unionid = '" . $_REQUEST['unionid'] . "' limit 1", $users);
    if (!isset($users[0])) {
        $data = '{"status":"error","code":"1","msg":"无效用户"}';
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

    $spaces = array();
    core_select_data("select * from axgo_space where code = '".$device_binds[0]['spaceCode']."' limit 1", $spaces);

    $space_admins = array();
    core_select_data("select * from axgo_space_admin where userID = '".$users[0]['id']."' and spaceCode = '".$device_binds[0]['spaceCode']."' limit 1", $space_admins);

    if(!isset($spaces[0]) || ($spaces[0]['createUserID'] != $users[0]['id'] && !isset($space_admins[0]))){
        $data = '{"status":"error","code":"1","msg":"无权限操作"}';
        _response($data);
        exit;
    }

    $face_rules = array();
    core_select_data("select * from axgo_face_rule where id = '".$_REQUEST['id']."'", $face_rules);
    if(!isset($face_rules[0]) || $face_rules[0]['macaddr'] != $devices[0]['macaddr']){
        $data = '{"status":"error","code":"1","msg":"无权限操作02"}';
        _response($data);
        exit;
    }

    $face_rules[0]['users'] = array();
    core_select_data("select * from axgo_face_rule_user where ruleID = '".$face_rules[0]['id']."'", $face_rules[0]['users']);
    $file_dir = $CONF['dir_data']."/pub/faceImg";
    foreach ($face_rules[0]['users'] as $key => $face_user) {
        if(file_exists($file_dir."/".$face_user['faceUserID'].".jpg")){
            $face_rules[0]['users'][$key]['faceImagePath'] = "/pub/faceImg/".$face_user['faceUserID'].".jpg";
        }
    }

    $face_rules[0]['times'] = array();
    core_select_data("select * from axgo_face_rule_time where ruleID = '".$face_rules[0]['id']."'", $face_rules[0]['times']);


    $data = '{"status":"success","code":"0","msg":"ok", "data":'.json_encode($face_rules).'}';
    _response($data);
    exit;
}

function act_device_rule_list(){

    $CONF = &$GLOBALS['CONF'];

    if (empty($_REQUEST['unionid']) ||
        empty($_REQUEST['macaddr'])) {
        $data = '{"status":"error","code":"1","msg":"缺少必要参数"}';
        _response($data);
        exit;
    }

    $users = array();
    core_select_data("select * from axgo_user where unionid = '" . $_REQUEST['unionid'] . "' limit 1", $users);
    if (!isset($users[0])) {
        $data = '{"status":"error","code":"1","msg":"无效用户"}';
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

    $spaces = array();
    core_select_data("select * from axgo_space where code = '".$device_binds[0]['spaceCode']."' limit 1", $spaces);

    $space_admins = array();
    core_select_data("select * from axgo_space_admin where userID = '".$users[0]['id']."' and spaceCode = '".$device_binds[0]['spaceCode']."' limit 1", $space_admins);

    if(!isset($spaces[0]) || ($spaces[0]['createUserID'] != $users[0]['id'] && !isset($space_admins[0]))){
        $data = '{"status":"error","code":"1","msg":"无权限操作"}';
        _response($data);
        exit;
    }


    $face_rules = array();
    core_select_data("select * from axgo_face_rule where macaddr = '".$devices[0]['macaddr']."' order by sortIndex DESC", $face_rules);

    $file_dir = $CONF['dir_data']."/pub/faceImg";
    foreach ($face_rules as $key1 => $face_rule) {
        $face_rules[$key1]['users'] = array();
        core_select_data("select * from axgo_face_rule_user where ruleID = '".$face_rules[$key1]['id']."'", $face_rules[$key1]['users']);
        foreach ($face_rules[$key1]['users'] as $key => $face_user) {
            if(file_exists($file_dir."/".$face_user['faceUserID'].".jpg")){
                $face_rules[$key1]['users'][$key]['faceImagePath'] = "/pub/faceImg/".$face_user['faceUserID'].".jpg";
            }
        }
        $face_rules[$key1]['times'] = array();
        core_select_data("select * from axgo_face_rule_time where ruleID = '".$face_rules[$key1]['id']."'", $face_rules[$key1]['times']);
    }

    $data = '{"status":"success","code":"0","msg":"ok", "data":'.json_encode($face_rules).'}';
    _response($data);
    exit;
}

function act_device_rule_remove(){

    if (empty($_REQUEST['unionid']) ||
        empty($_REQUEST['macaddr']) ||
        empty($_REQUEST['id'])) {
        $data = '{"status":"error","code":"1","msg":"缺少必要参数"}';
        _response($data);
        exit;
    }

    $users = array();
    core_select_data("select * from axgo_user where unionid = '" . $_REQUEST['unionid'] . "' limit 1", $users);
    if (!isset($users[0])) {
        $data = '{"status":"error","code":"1","msg":"无效用户"}';
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

    $spaces = array();
    core_select_data("select * from axgo_space where code = '".$device_binds[0]['spaceCode']."' limit 1", $spaces);

    $space_admins = array();
    core_select_data("select * from axgo_space_admin where userID = '".$users[0]['id']."' and spaceCode = '".$device_binds[0]['spaceCode']."' limit 1", $space_admins);

    if(!isset($spaces[0]) || ($spaces[0]['createUserID'] != $users[0]['id'] && !isset($space_admins[0]))){
        $data = '{"status":"error","code":"1","msg":"无权限操作"}';
        _response($data);
        exit;
    }


    $face_rules = array();
    core_select_data("select * from axgo_face_rule where id = '".$_REQUEST['id']."'", $face_rules);
    if(!isset($face_rules[0]) || $face_rules[0]['macaddr'] != $devices[0]['macaddr']){
        $data = '{"status":"error","code":"1","msg":"无权限操作02"}';
        _response($data);
        exit;
    }

    //规则对应用户
    core_query_data("delete from axgo_face_rule_user where ruleID = '".$face_rules[0]['id']."'");
    //规则对应时间段
    core_query_data("delete from axgo_face_rule_time where ruleID = '".$face_rules[0]['id']."'");
    //删除规则
    core_query_data("delete from axgo_face_rule where id = '".$face_rules[0]['id']."'");

    _device_down_rules($devices[0]['macaddr']);

    $data = '{"status":"success","code":"0","msg":"ok"}';
    _response($data);
    exit;
}

function act_device_rule_modify(){

    if (empty($_REQUEST['unionid']) ||
        empty($_REQUEST['macaddr']) ||
        empty($_REQUEST['name']) ||
        empty($_REQUEST['type']) ||
        empty($_REQUEST['startDate']) ||
        empty($_REQUEST['stopDate']) ||
        empty($_REQUEST['users'])) {
        $data = '{"status":"error","code":"1","msg":"缺少必要参数"}';
        _response($data);
        exit;
    }

    $rule_users = json_decode($_REQUEST['users'], true);
    if(!$rule_users || count($rule_users) == 0){
        $data = '{"status":"error","code":"1","msg":"规则中必须包含人脸用户"}';
        _response($data);
        exit;
    }

    $users = array();
    core_select_data("select * from axgo_user where unionid = '" . $_REQUEST['unionid'] . "' limit 1", $users);
    if (!isset($users[0])) {
        $data = '{"status":"error","code":"1","msg":"无效用户"}';
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

    $spaces = array();
    core_select_data("select * from axgo_space where code = '".$device_binds[0]['spaceCode']."' limit 1", $spaces);

    $space_admins = array();
    core_select_data("select * from axgo_space_admin where userID = '".$users[0]['id']."' and spaceCode = '".$device_binds[0]['spaceCode']."' limit 1", $space_admins);

    if(!isset($spaces[0]) || ($spaces[0]['createUserID'] != $users[0]['id'] && !isset($space_admins[0]))){
        $data = '{"status":"error","code":"1","msg":"无权限操作"}';
        _response($data);
        exit;
    }

    $current_time = time();
    $arr = array();
    $arr['deviceID'] = $devices[0]['id'];
    $arr['macaddr'] = $devices[0]['macaddr'];
    $arr['name'] = $_REQUEST['name'];
    $arr['type'] = $_REQUEST['type'];
    $arr['sortIndex'] = $_REQUEST['sortIndex'] ? intval($_REQUEST['sortIndex']) : 0;
    $arr['startDate'] = date("Y-m-d", strtotime($_REQUEST['startDate']));
    $arr['stopDate'] = date("Y-m-d", strtotime($_REQUEST['stopDate']));
    $arr['weekDay'] = $_REQUEST['weekDay'] ? $_REQUEST['weekDay'] : "";
    $arr['createtime'] = $current_time;
    $sql = "insert into axgo_face_rule set ".core_db_fmtlist($arr);
    if(!empty($_REQUEST['id'])){
        unset($arr['createtime']);
        $sql = "update axgo_face_rule set ".core_db_fmtlist($arr)." where id = ".$_REQUEST['id'];
    }
    core_query_data($sql);

    $face_rules = array();
    if(empty($_REQUEST['id'])){
        core_select_data("select * from axgo_face_rule where name = '".$arr['name']."' and macaddr = '".$arr['macaddr']."' and createtime = '".$current_time."' limit 1", $face_rules);
        if(!isset($face_rules[0])){
            $data = '{"status":"error","code":"1","msg":"新增规则失败"}';
            _response($data);
            exit;
        }
        $face_rule_id = $face_rules[0]['id'];
    }else{
        $face_rule_id = $_REQUEST['id'];
    }

    //规则对应用户
    core_query_data("delete from axgo_face_rule_user where ruleID = '".$face_rule_id."'");
    foreach ($rule_users as $rule_user) {
        $arr_rule = array();
        $arr_rule['ruleID'] = $face_rule_id;
        $arr_rule['faceUserID'] = $rule_user['faceUserID'];
        $arr_rule['faceUserName'] = $rule_user['faceUserName'];
        $arr_rule['personId'] = $rule_user['personId'];
        core_query_data("insert into axgo_face_rule_user set ".core_db_fmtlist($arr_rule));
    }

    //规则对应时间段
    core_query_data("delete from axgo_face_rule_time where ruleID = '".$face_rule_id."'");
    $times = json_decode($_REQUEST['times'], true);
    foreach ($times as $time) {
        $arr_time = array();
        $arr_time['ruleID'] = $face_rule_id;
        $arr_time['startTime'] = $time['startTime'];
        $arr_time['stopTime'] = $time['stopTime'];
        core_query_data("insert into axgo_face_rule_time set ".core_db_fmtlist($arr_time));
    }

    _device_down_rules($devices[0]['macaddr']);

    $data = '{"status":"success","code":"0","msg":"ok"}';
    _response($data);
    exit;
}


function act_device_template_data_down(){

    $CONF = &$GLOBALS['CONF'];

    if(empty($_REQUEST['unionid']) ||
        empty($_REQUEST['macaddr']) ||
        //empty($_REQUEST['templateData']) ||
        empty($_REQUEST['templateUid'])){
        $data = '{"status":"error","code":"1","msg":"无效请求用户"}';
        _response($data);
        exit;
    }
    $users = array();
    core_select_data("select * from axgo_user where unionid = '".$_REQUEST['unionid']."' limit 1", $users);
    if(!isset($users[0])){
        $data = '{"status":"error","code":"1","msg":"无效用户"}';
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

    $templates = array();
    core_select_data("select * from axgo_module where uid = '".$_REQUEST['templateUid']."' limit 1", $templates);
    if(!isset($templates[0])){
        $data = '{"status":"error","code":"1","msg":"无效模板01"}';
        _response($data);
        exit;
    }elseif($templates[0]['online'] != "1"){
        $data = '{"status":"error","code":"1","msg":"无效模板02"}';
        _response($data);
        exit;
    }elseif($templates[0]['type'] == "1" && strpos($templates[0]['auth_macaddr'], $_REQUEST['macaddr']) === FALSE){
        $data = '{"status":"error","code":"1","msg":"无效模板03"}';
        _response($data);
        exit;
    }

    //设备权限
    $device_binds = array();
    core_select_data("select * from axgo_device_bind where macaddr = '".$devices[0]['macaddr']."' limit 1", $device_binds);
    if(!isset($device_binds[0])){
        $data = '{"status":"error","code":"1","msg":"无权限操作"}';
        _response($data);
        exit;
    }else{
        $spaces = array();
        core_select_data("select * from axgo_space where code = '".$device_binds[0]['spaceCode']."' limit 1", $spaces);

        $space_admins = array();
        core_select_data("select * from axgo_space_admin where userID = '".$users[0]['id']."'", $space_admins);

        if(!isset($spaces[0]) || ($spaces[0]['createUserID'] != $users[0]['id'] && !isset($space_admins[0]))){
            $data = '{"status":"error","code":"1","msg":"无权限"}';
            _response($data);
            exit;
        }
    }

    //下发模板数据,临时测试代码
    $job = array();
    $job['macaddr'] = $devices[0]['macaddr'];
    $job['command'] = array();
    $job['command']['type'] = "template_data";
    $job['command']['templateUUID'] = $templates[0]['uid'];
    $job['command']['data'] = json_decode('{"roomName":"1楼会议室","roderlist":[{"sTime":"09:00","eTime":"09:30","status":"past","subject":"开发会议","creator":"何铮"},{"sTime":"10:10","eTime":"10:20","status":"doing","subject":"开发会议","creator":"何铮"},{"sTime":"11:00","eTime":"11:30","status":"future","subject":"开发会议","creator":"何铮"}],"descs":[{"text":"VIP会议室"},{"text":"可容纳人数:10人"},{"text":"设备:投影仪 投屏设备"},{"text":"会议室开放范围：全公司"},{"text":"下场会议开始时间：10：00"},{"text":"剩余：23小时33分"}],"config":{}}', true);
    //file_put_contents($CONF['mosquitto_tmpdir']."/".uniqid("MQTT"), json_encode($job), LOCK_EX);
    _request($CONF['url_pre']."/mqtt", "POST", $job);

    $data = '{"status":"success","code":"0","msg":"ok"}';
    _response($data);
    exit;
}

function act_device_template_down(){

    $CONF = &$GLOBALS['CONF'];

    if(empty($_REQUEST['unionid']) || empty($_REQUEST['macaddr']) || empty($_REQUEST['templateUid'])){
        $data = '{"status":"error","code":"1","msg":"无效请求用户"}';
        _response($data);
        exit;
    }
    $users = array();
    core_select_data("select * from axgo_user where unionid = '".$_REQUEST['unionid']."' limit 1", $users);
    if(!isset($users[0])){
        $data = '{"status":"error","code":"1","msg":"无效用户"}';
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

    $templates = array();
    core_select_data("select * from axgo_module where uid = '".$_REQUEST['templateUid']."' limit 1", $templates);
    if(!isset($templates[0])){
        $data = '{"status":"error","code":"1","msg":"无效模板01"}';
        _response($data);
        exit;
    }elseif($templates[0]['online'] != "1"){
        $data = '{"status":"error","code":"1","msg":"无效模板02"}';
        _response($data);
        exit;
    }elseif($templates[0]['type'] == "1" && strpos($templates[0]['auth_macaddr'], $_REQUEST['macaddr']) === FALSE){
        $data = '{"status":"error","code":"1","msg":"无效模板03"}';
        _response($data);
        exit;
    }

    //设备权限
    $device_binds = array();
    core_select_data("select * from axgo_device_bind where macaddr = '".$devices[0]['macaddr']."' limit 1", $device_binds);
    if(!isset($device_binds[0])){
        $data = '{"status":"error","code":"1","msg":"无权限操作"}';
        _response($data);
        exit;
    }else{
        $spaces = array();
        core_select_data("select * from axgo_space where code = '".$device_binds[0]['spaceCode']."' limit 1", $spaces);

        $space_admins = array();
        core_select_data("select * from axgo_space_admin where userID = '".$users[0]['id']."'", $space_admins);

        if(!isset($spaces[0]) || ($spaces[0]['createUserID'] != $users[0]['id'] && !isset($space_admins[0]))){
            $data = '{"status":"error","code":"1","msg":"无权限"}';
            _response($data);
            exit;
        }
    }

    //下发模板
    $job = array();
    $job['macaddr'] = $devices[0]['macaddr'];
    $job['command'] = array();
    $job['command']['type'] = "switch_template";
    $job['command']['templateUUID'] = $templates[0]['uid'];
    $job['command']['templatePkgMD5'] = $templates[0]['pkg_md5'];
    $job['command']['templateDownloadUrl'] = $templates[0]['pkg_url'];
    //file_put_contents($CONF['mosquitto_tmpdir']."/".uniqid("MQTT"), json_encode($job), LOCK_EX);
    _request($CONF['url_pre']."/mqtt", "POST", $job);
    core_query_data("update axgo_device set template = '".$templates[0]['uid']."' where id = '".$devices[0]['id']."'");


    //处理模板数据
    if(!empty($_REQUEST['templateDatas']) && !empty($templates[0]['tmpdata'])){
        $templateDatas = json_decode($_REQUEST['templateDatas'], true);
        $tmpdata = json_decode($templates[0]['tmpdata'], true);

        $device_module_datas = array();
        core_select_data("select * from axgo_device_module_data where macaddr = '".$devices[0]['macaddr']."' and template = '".$templates[0]['uid']."' limit 1", $device_module_datas);

        $arr = array();
        $initData = array();
        if(!isset($device_module_datas[0])){
            _analysis_array_data_structure($tmpdata['data'],$initData);
        }else{
            $initData = json_decode($device_module_datas[0]['templateData'], true);
            if($initData === FALSE || $initData === NULL || count($initData) == 0){
                _analysis_array_data_structure($tmpdata['data'],$initData);
            }
        }
        foreach ($templateDatas as $key => $data) {
            $initData[$key] = $data;
        }
        foreach ($initData as $key => $data) {
            if(substr($key, strpos($key, "_item")) == "_item"){
                unset($initData[$key]);
            }
        }
        $arr['deviceID'] = $devices[0]['id'];
        $arr['macaddr'] = $devices[0]['macaddr'];
        $arr['template'] = $templates[0]['uid'];
        $arr['templateType'] = $templates[0]['templateType'];
        $arr['templateData'] = json_encode($initData, JSON_UNESCAPED_UNICODE);
        $arr['createtime'] = time();

        if(!isset($device_module_datas[0])){
            $sql = "insert into axgo_device_module_data set ".core_db_fmtlist($arr);
        }else{
            $sql = "update axgo_device_module_data set ".core_db_fmtlist($arr)." where id = ".$device_module_datas[0]['id'];
        }
        core_query_data($sql);

        sleep(1);

        //下发模板数据
        $job = array();
        $job['macaddr'] = $devices[0]['macaddr'];
        $job['command'] = array();
        $job['command']['type'] = "template_data";
        $job['command']['templateUUID'] = $templates[0]['uid'];
        $job['command']['data'] = $initData;
        //file_put_contents($CONF['mosquitto_tmpdir']."/".uniqid("MQTT"), json_encode($job), LOCK_EX);
        _request($CONF['url_pre']."/mqtt", "POST", $job);
    }

    $data = '{"status":"success","code":"0","msg":"ok"}';
    _response($data);
    exit;
}

function act_user_device_template(){

    if(empty($_REQUEST['unionid'])){
        $data = '{"status":"error","code":"1","msg":"无效请求用户"}';
        _response($data);
        exit;
    }
    $users = array();
    core_select_data("select * from axgo_user where unionid = '".$_REQUEST['unionid']."' limit 1", $users);
    if(!isset($users[0])){
        $data = '{"status":"error","code":"1","msg":"无效用户"}';
        _response($data);
        exit;
    }
    $normal_templates = array();
    $target_templates = array();
    core_select_data("select * from axgo_module where online = '1' and type = '0' ", $normal_templates);
    if(!empty($_REQUEST['macaddr'])){
        core_select_data("select * from axgo_module where online = '1' and type = '1' and auth_macaddr like '%".$_REQUEST['macaddr']."%' ", $target_templates);
    }
    $templates = array_merge($normal_templates, $target_templates);
    //根据模板数据结构生成对应数据体
    foreach ($templates as $key => $template) {
        if(empty($template['tmpdata'])){
            continue;
        }
        $tmpdata = json_decode($template['tmpdata'], true);
        if(!$tmpdata || !isset($tmpdata['data'])){
            continue;
        }
        $templates[$key]['data_structure'] = $tmpdata['data'];
        $templates[$key]['datas'] = array();
        _analysis_array_data_structure($tmpdata['data'],$templates[$key]['datas']);

        if(!empty($_REQUEST['macaddr'])){
            $device_module_datas = array();
            core_select_data("select * from axgo_device_module_data where macaddr = '".$_REQUEST['macaddr']."' and template = '".$template['uid']."' limit 1", $device_module_datas);
            if(isset($device_module_datas[0]) && !empty($device_module_datas[0]['templateData'])){
                $templateData = json_decode($device_module_datas[0]['templateData'], true);
                foreach ($templateData as $data_key => $data_value) {
                    if(substr($data_key, strpos($data_key, "_item")) == "_item"){
                        continue;
                    }
                    $templates[$key]['datas'][$data_key] = $data_value;
                }
            }
        }
    }

    $data = '{"status":"success","code":"0","msg":"ok", "data":'.json_encode($templates).'}';
    _response($data);
    exit;
}


function _analysis_array_data_structure($array_structure, &$data){
    foreach ($array_structure as $structure) {
        if($structure['type'] == 'text'){  //单一文本数据
            $data[$structure['target']] = $structure['value'];
        }elseif($structure['type'] == 'array'){
            $data[$structure['target']] = array();
            $data[$structure['target']."_item"] = array();
            _analysis_array_data_structure($structure['items'],$data[$structure['target']."_item"]);
        }
    }
    return true;
}

function act_user_device_bind(){

    $CONF = &$GLOBALS['CONF'];

    if(empty($_REQUEST['unionid']) || empty($_REQUEST['macaddr']) || empty($_REQUEST['spaceCode']) || empty($_REQUEST['spaceName'])){
        $data = '{"status":"error","code":"1","msg":"请求参数错误"}';
        _response($data);
        exit;
    }

    $users = array();
    core_select_data("select * from axgo_user where unionid = '".$_REQUEST['unionid']."' limit 1", $users);
    if(!isset($users[0])){
        $data = '{"status":"error","code":"1","msg":"无效请求用户"}';
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

    //当前选择空间是否有权限
    $spaces = array();
    core_select_data("select * from axgo_space where code = '".$_REQUEST['spaceCode']."' limit 1", $spaces);
    $space_admins = array();
    core_select_data("select * from axgo_space_admin where spaceCode = '".$_REQUEST['spaceCode']."' and userID = '".$users[0]['id']."' limit 1", $space_admins);
    if(!isset($spaces[0]) || ($spaces[0]['createUserID'] != $users[0]['id'] && !isset($space_admins[0]))){
        $data = '{"status":"error","code":"1","msg":"无权限操作"}';
        _response($data);
        exit;
    }

    $device_binds = array();
    core_select_data("select * from axgo_device_bind where macaddr = '".$devices[0]['macaddr']."' limit 1", $device_binds);
    //原绑定空间你是否有权限
    if(isset($device_binds[0])){
        $bind_spaces = array();
        core_select_data("select * from axgo_space where code = '".$device_binds[0]['spaceCode']."' limit 1", $bind_spaces);
        $bind_space_admins = array();
        core_select_data("select * from axgo_space_admin where spaceCode = '".$device_binds[0]['spaceCode']."' and userID = '".$users[0]['id']."' limit 1", $bind_space_admins);
        if(!isset($bind_spaces[0]) || ($bind_spaces[0]['createUserID'] != $users[0]['id'] && !isset($bind_space_admins[0]))){
            $data = '{"status":"error","code":"1","msg":"无权限操作"}';
            _response($data);
            exit;
        }
    }

    //更新设备基本信息
    if(!empty($_REQUEST['devicenick'])){
        $arr = array();
        $arr['devicenick'] = $_REQUEST['devicenick'];
        $arr['description'] = isset($_REQUEST['description']) ? $_REQUEST['description'] : '';
        core_query_data("update axgo_device set ".core_db_fmtlist($arr)." where id = ".$devices[0]['id']);
    }

    //更新设备基本信息
    if(isset($_REQUEST['doorPasswd'])){

        if(!empty($_REQUEST['doorPasswd'])){
            $doorPasswd = str_pad(intval($_REQUEST['doorPasswd']), 4, "0" ,STR_PAD_LEFT );
            if(strlen($_REQUEST['doorPasswd']) != 4 || $doorPasswd != $_REQUEST['doorPasswd']){
                $data = '{"status":"error","code":"1","msg":"密码格式错误，必须4位数字"}';
                _response($data);
                exit;
            }
        }else{
            $_REQUEST['doorPasswd'] = "";
        }

        $arr = array();
        $arr['doorPasswd'] = $_REQUEST['doorPasswd'];
        core_query_data("update axgo_device set ".core_db_fmtlist($arr)." where id = ".$devices[0]['id']);

        //下发密码
        $job = array();
        $job['macaddr'] = $devices[0]['macaddr'];
        $job['commandType'] = "system";
        $job['command'] = array();
        $job['command']['type'] = "door_passwd";
        $job['command']['passwd'] = $_REQUEST['doorPasswd'];
        //file_put_contents($CONF['mosquitto_tmpdir']."/".uniqid("MQTT"), json_encode($job), LOCK_EX);
        _request($CONF['url_pre']."/mqtt", "POST", $job);
    }

    //重复提交，空间未变动
    if(isset($device_binds[0]) && $device_binds[0]['spaceCode'] == $_REQUEST['spaceCode']){
        $data = '{"status":"success","code":"0","msg":"ok1"}';
        _response($data);
        exit;
    }

    //检测当前设备是否是人脸终端  绑定到对应空间得人员库上  如果更换了空间需要先解绑原有的库再绑定到新人员库
    if(!empty($devices[0]['faceCode'])){
        //解绑旧空间
        if(isset($bind_spaces[0])){
            $axgo_face_groups = array();
            core_select_data("select * from axgo_face_group where spaceCode = '".$bind_spaces[0]['code']."' limit 1", $axgo_face_groups);
            if(isset($axgo_face_groups[0]) && !empty($axgo_face_groups[0]['personSetId'])){
                $bool = arcface_unbind_devices_groups($devices[0]['faceCode'], $axgo_face_groups[0]['personSetId'], $msg);
//                if(!$bool){
//                    $msg = "人员库解绑原始空间失败 ".$msg;
//                    $data = '{"status":"error","code":"1","msg":"'.$msg.'"}';
//                    _response($data);
//                    exit;
//                }
            }
        }

        //绑定新空间
        $axgo_face_groups = array();
        core_select_data("select * from axgo_face_group where spaceCode = '".$spaces[0]['code']."' limit 1", $axgo_face_groups);
        if(isset($axgo_face_groups[0]) && !empty($axgo_face_groups[0]['personSetId'])){
            $bool = arcface_device_bind_groups($devices[0]['faceCode'], $axgo_face_groups[0]['personSetId'], $msg);
//            if(!$bool){
//                $msg = "人员库绑定空间失败 ".$msg;
//                $data = '{"status":"error","code":"1","msg":"'.$msg.'"}';
//                _response($data);
//                exit;
//            }
        }
    }

    $arr = array();
    $arr['deviceID'] = $devices[0]['id'];
    $arr['macaddr'] = $devices[0]['macaddr'];
    $arr['spaceCode'] = $_REQUEST['spaceCode'];
    $arr['spaceName'] = $_REQUEST['spaceName'];
    $arr['type'] = $_REQUEST['type'] ? $_REQUEST['type'] : "";
    $arr['typeName'] = $_REQUEST['typeName'] ? $_REQUEST['typeName'] : "";
    $arr['bindtime'] = time();
    $sql = "insert into axgo_device_bind set ".core_db_fmtlist($arr);
    if(isset($device_binds[0])){
        $sql = "update axgo_device_bind set ".core_db_fmtlist($arr)." where id = ".$device_binds[0]['id'];
    }
    core_query_data($sql);

    $data = '{"status":"success","code":"0","msg":"ok"}';
    _response($data);
    exit;
}


function act_user_device_info(){
    if(empty($_REQUEST['unionid']) || empty($_REQUEST['macaddr'])){
        $data = '{"status":"error","code":"1","msg":"无效请求"}';
        _response($data);
        exit;
    }

    $users = array();
    core_select_data("select * from axgo_user where unionid = '".$_REQUEST['unionid']."' limit 1", $users);
    if(!isset($users[0])){
        $data = '{"status":"error","code":"1","msg":"无效请求用户"}';
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

    $devices[0]['cpuUsedRate'] = intval(floatval($devices[0]['cpuUsed']) * 100);
    $devices[0]['memoryUsedRate'] = intval((floatval($devices[0]['memoryTotal']) - floatval($devices[0]['memoryAvailable'])) / floatval($devices[0]['memoryTotal']) * 100);
    $devices[0]['storageUsedRate'] = intval((floatval($devices[0]['storageTotal']) - floatval($devices[0]['storageAvailable'])) / floatval($devices[0]['storageTotal']) * 100);

    $device_binds = array();
    core_select_data("select * from axgo_device_bind where macaddr = '".$devices[0]['macaddr']."' limit 1", $device_binds);
    if(!isset($device_binds[0])){
        $data = '{"status":"success","code":"0","msg":"ok","data":'.json_encode($devices[0]).'}';
        _response($data);
        exit;
    }

    $spaces = array();
    core_select_data("select * from axgo_space where code = '".$device_binds[0]['spaceCode']."' limit 1", $spaces);

    $space_admins = array();
    core_select_data("select * from axgo_space_admin where userID = '".$users[0]['id']."' and spaceCode = '".$device_binds[0]['spaceCode']."' limit 1", $space_admins);

    if(!isset($spaces[0]) || ($spaces[0]['createUserID'] != $users[0]['id'] && !isset($space_admins[0]))){
        $data = '{"status":"error","code":"1","msg":"无权限操作"}';
        _response($data);
        exit;
    }

    $devices[0]['bindSpaceCode'] = $device_binds[0]['spaceCode'];
    $devices[0]['bindSpaceName'] = $device_binds[0]['spaceName'];
    $devices[0]['bindType'] = $device_binds[0]['type'];
    $devices[0]['bindTypeName'] = $device_binds[0]['typeName'];

    //当前使用模板
    if(!empty($devices[0]['template'])){
        $modules = array();
        core_select_data("select * from axgo_module where uid = '".$devices[0]['template']."' limit 1", $modules);
        if(isset($modules[0])){
            $devices[0]['templateName'] = $modules[0]['name'];
            if(!empty($modules[0]['coverImage'])){
                $devices[0]['templateCoverImage'] = $modules[0]['coverImage'];
            }
        }
    }

    $data = '{"status":"success","code":"0","msg":"ok","data":'.json_encode($devices[0]).'}';
    _response($data);
    exit;
}

/**
 * unionid  spaceCode
 */
function act_user_devices(){

    if(empty($_REQUEST['unionid']) || empty($_REQUEST['spaceCode'])){
        $data = '{"status":"error","code":"1","msg":"无效请求用户"}';
        _response($data);
        exit;
    }
    $users = array();
    core_select_data("select * from axgo_user where unionid = '".$_REQUEST['unionid']."' limit 1", $users);
    if(!isset($users[0])){
        $data = '{"status":"error","code":"1","msg":"无效用户"}';
        _response($data);
        exit;
    }

    $devices = array();

    //当前选择空间是否有权限
    $spaces = array();
    core_select_data("select * from axgo_space where code = '".$_REQUEST['spaceCode']."' limit 1", $spaces);
    $space_admins = array();
    core_select_data("select * from axgo_space_admin where spaceCode = '".$_REQUEST['spaceCode']."' and userID = '".$users[0]['id']."' limit 1", $space_admins);
    if(!isset($spaces[0]) || ($spaces[0]['createUserID'] != $users[0]['id'] && !isset($space_admins[0]))){
        $data = '{"status":"success","code":"0","msg":"ok", "data":'.json_encode($devices).'}';
        _response($data);
        exit;
    }

    $device_binds = array();
    $device_binds_obj = array();
    core_select_data("select * from axgo_device_bind where spaceCode = '".$spaces[0]['code']."'", $device_binds);
    $deviceMacs = "";
    foreach ($device_binds as $device_bind) {
        $deviceMacs .= $deviceMacs == "" ? "'".$device_bind['macaddr']."'" : ",'".$device_bind['macaddr']."'";
        $device_binds_obj[$device_bind['macaddr']] = $device_bind;
    }
    if(empty($deviceMacs)){
        $data = '{"status":"success","code":"0","msg":"ok", "data":'.json_encode($devices).'}';
        _response($data);
        exit;
    }

    core_select_data("select * from axgo_device where macaddr in (".$deviceMacs.")", $devices);
    foreach ($devices as $key => $device) {
        if(!isset($device_binds_obj[$device['macaddr']])){
            continue;
        }
        $devices[$key]['bindType'] = $device_binds_obj[$device['macaddr']]['type'];
        $devices[$key]['bindTypeName'] = $device_binds_obj[$device['macaddr']]['typeName'];

        //模板封面图
        if(!empty($device['template'])){
            $templates = array();
            core_select_data("select * from axgo_module where uid = '".$device['template']."' limit 1", $templates);
            if(isset($templates[0]) && !empty($templates[0]['coverImage'])){
                $devices[$key]['templateCoverImage'] = $templates[0]['coverImage'];
            }
        }
    }

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

function httpRequest($url, $method, $params) {
    $header = array("Content-Type: application/json; charset=utf-8");
    $ch = curl_init();
    if ($method == "POST") {
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($params));
    } elseif (is_array($params) && 0 < count($params)) {
        curl_setopt($ch, CURLOPT_URL, $url . "?" . http_build_query($params));
    } else {
        curl_setopt($ch, CURLOPT_URL, $url);
    }
    curl_setopt($ch, CURLOPT_HEADER, false);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_FORBID_REUSE, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, $header);
   $data = curl_exec($ch);
   curl_close($ch);
   return $data;
}
?>