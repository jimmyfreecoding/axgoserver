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

    case 'face_user_modify':
        act_face_user_modify();
        break;
    case 'face_user_remove':
        act_face_user_remove();
        break;
    case 'device_rule_modify':
        act_device_rule_modify();
        break;

    default:
        $data = '{"status":"error","code":"401","msg":"请求无效"}';
        _response($data);
        break;
}

function act_device_rule_modify(){

    if(empty($_REQUEST['macaddr']) || !isset($_REQUEST['rules'])){
        $data = '{"status":"error","code":"1","msg":"无效请求"}';
        _response($data);
        exit;
    }

    $return = array();

    $axgo_devices = array();
    core_select_data("select * from axgo_device where macaddr = '".$_REQUEST['macaddr']."' limit 1", $axgo_devices);
    if(!isset($axgo_devices[0])){
        $data = '{"status":"error","code":"1","msg":"无效设备"}';
        _response($data);
        exit;
    }

    $axgo_face_rules = array();
    $axgo_face_rules_obj = array();
    core_select_data("select * from axgo_face_rule where macaddr = '".$_REQUEST['macaddr']."'", $axgo_face_rules);
    foreach ($axgo_face_rules as $axgo_face_rule) {
        $axgo_face_rules_obj[$axgo_face_rule['id']] = true;
    }

    $rules = json_decode($_REQUEST['rules'], true);
    foreach($rules as $rule){
        $current_time = time();
        $arr = array();
        $arr['deviceID'] = $axgo_devices[0]['id'];
        $arr['macaddr'] = $axgo_devices[0]['macaddr'];
        $arr['name'] = $rule['name'];
        $arr['type'] = $rule['type'];
        $arr['startDate'] = $rule['startDate'];
        $arr['stopDate'] = $rule['stopDate'];
        $arr['createtime'] = $current_time;
        $sql = "insert into axgo_face_rule set ".core_db_fmtlist($arr);

        $ruleID = "";
        $flag = false;
        if(!empty($rule['axgoRuleID']) && isset($axgo_face_rules_obj[$rule['axgoRuleID']])){
            unset($arr['createtime']);
            $sql = "update axgo_face_rule set ".core_db_fmtlist($arr)." where id = '".$rule['axgoRuleID']."'";
            unset($axgo_face_rules_obj[$rule['axgoRuleID']]);
            $flag = true;
            $ruleID = $rule['axgoRuleID'];
        }
        core_query_data($sql);

        //新增，获取id，将返回给ax
        if(!$flag){
            $new_axgo_face_rules = array();
            core_select_data("select * from axgo_face_rule where macaddr = '".$_REQUEST['macaddr']."' and name = '".$arr['name']."' and createtime = '".$current_time."' limit 1", $new_axgo_face_rules);
            if(isset($new_axgo_face_rules[0])){
                $ruleID = $new_axgo_face_rules[0]['id'];
            }
        }
        if(empty($ruleID)){
            continue;
        }

        if(!empty($rule['axRuleID'])){
            $return[$rule['axRuleID']] = $ruleID;
        }

        //设置规则时间段
        core_query_data("delete from axgo_face_rule_time where ruleID = '".$ruleID."'");
        $arr = array();
        $arr['ruleID'] = $ruleID;
        $arr['startTime'] = $rule['startTime'];
        $arr['stopTime'] = $rule['stopTime'];
        core_query_data("insert into axgo_face_rule_time set ".core_db_fmtlist($arr));


        //设置规则用户
        $axgo_face_rule_users = array();
        $axgo_face_rule_users_obi = array();
        core_select_data("select * from axgo_face_rule_user where ruleID = '".$ruleID."'", $axgo_face_rule_users);
        foreach($axgo_face_rule_users as $axgo_face_rule_user){
            $axgo_face_rule_users_obi[$axgo_face_rule_user['personId']] = true;
        }
        foreach($rule['users'] as $userID){
            $axgo_face_users = array();
            core_select_data("select * from axgo_face_user where id = '".$userID."'", $axgo_face_users);
            if(!isset($axgo_face_users[0])){
                continue;
            }
            if(isset($axgo_face_rule_users_obi[$axgo_face_users[0]['personId']])){
                unset($axgo_face_rule_users_obi[$axgo_face_users[0]['personId']]);
                continue;
            }
            $arr = array();
            $arr['ruleID'] = $ruleID;
            $arr['faceUserID'] = $axgo_face_users[0]['id'];
            $arr['faceUserName'] = $axgo_face_users[0]['name'];
            $arr['personId'] = $axgo_face_users[0]['personId'];
            core_query_data("insert into axgo_face_rule_user set ".core_db_fmtlist($arr));
        }
        //删除不在规则里面历史用户
        foreach($axgo_face_rule_users_obi as $personId => $value){
            core_query_data("delete from axgo_face_rule_user where ruleID = '".$ruleID."' and personId = '".$personId."'");
        }
    }

    //删除非ax指定的规则
    foreach($axgo_face_rules_obj as $ruleID => $value){
        core_query_data("delete from axgo_face_rule_time where ruleID = '".$ruleID."'");
        core_query_data("delete from axgo_face_rule_user where ruleID = '".$ruleID."'");
        core_query_data("delete from axgo_face_rule where id = '".$ruleID."'");
    }

    _device_down_rules($axgo_devices[0]['macaddr']);

    $data = '{"status":"success","code":"0","msg":"ok", "data":'.json_encode($return).'}';
    _response($data);
    exit;
}

function act_face_user_remove(){

    $CONF = &$GLOBALS['CONF'];

    if(empty($_REQUEST['faceUserID']) || empty($_REQUEST['spaceCode'])){
        $data = '{"status":"error","code":"1","msg":"无效请求"}';
        _response($data);
        exit;
    }

    $spaces = array();
    core_select_data("select * from axgo_space where code = '".$_REQUEST['spaceCode']."' limit 1", $spaces);
    if(!isset($spaces[0])){
        $data = '{"status":"error","code":"1","msg":"无效空间"}';
        _response($data);
        exit;
    }

    $face_groups = array();
    core_select_data("select * from axgo_face_group where spaceCode = '".$_REQUEST['spaceCode']."' limit 1", $face_groups);
    if(!isset($face_groups[0])){
        $data = '{"status":"error","code":"1","msg":"无效人脸库"}';
        _response($data);
        exit;
    }

    $face_users = array();
    core_select_data("select * from axgo_face_user where id = '".$_REQUEST['faceUserID']."'", $face_users);
    if(!isset($face_users[0])){
        $data = '{"status":"error","code":"1","msg":"无效人员"}';
        _response($data);
        exit;
    }

    $face_group_users = array();
    $face_group_users_obj = array();
    core_select_data("select * from axgo_face_group_user where personId = '".$face_users[0]['personId']."'", $face_group_users);
    foreach ($face_group_users as $face_group_user) {
        if(empty($face_group_user['personSetId'])){
            continue;
        }
        $face_group_users_obj[$face_group_user['personSetId']] = $face_group_user;
    }
    if(!isset($face_group_users_obj[$face_groups[0]['personSetId']])){
        $data = '{"status":"error","code":"1","msg":"无效对应人脸库"}';
        _response($data);
        exit;
    }
    unset($face_group_users_obj[$face_groups[0]['personSetId']]);

    //检测是否删除用户还是解绑当前空间
    $face_group_users = array();
    if(!empty($face_users[0]['personId'])) {
        core_select_data("select * from axgo_face_group_user where personId = '" . $face_users[0]['personId'] . "'", $face_group_users);
    }
    if(count($face_group_users_obj) <= 0){
        if(!empty($face_users[0]['personId'])){
            $bool = arcface_delete_person($face_users[0]['personId'], $msg);
//            if(!$bool){
//                $data = '{"status":"error","code":"1","msg":"删除人员失败 '.$msg.'"}';
//                _response($data);
//                exit;
//            }
        }
        //删除解绑关系
        core_query_data("delete from axgo_face_group_user where personSetId = '".$face_groups[0]['personSetId']."' and personId = '".$face_users[0]['personId']."'");
        //删除用户
        core_query_data("delete from axgo_face_user where id = '".$face_users[0]['id']."'");
        //删除用户人脸头像
        @unlink($CONF['dir_data']."/pub/faceImg/".$face_users[0]['id'].".jpg");
    }else{
        if(!empty($face_users[0]['personId'])){
            $bool = arcface_user_unto_group($face_users[0]['personId'], $face_groups[0]['personSetId'], $msg);
//            if(!$bool){
//                $data = '{"status":"error","code":"1","msg":"解绑人员失败 '.$msg.'"}';
//                _response($data);
//                exit;
//            }
        }
        //删除解绑关系
        core_query_data("delete from axgo_face_group_user where personSetId = '".$face_groups[0]['personSetId']."' and personId = '".$face_users[0]['personId']."'");
    }

    //同步平板信息
    foreach($face_group_users as $face_group_user){
        $face_groups = array();
        core_select_data("select * from axgo_face_group where personSetId = '".$face_group_user['personSetId']."' limit 1", $face_groups);
        if(isset($face_groups[0])){
            _face_space_device_update_user($face_groups[0]['spaceCode'],$msg);
        }
    }

    $data = '{"status":"success","code":"0","msg":"ok"}';
    _response($data);
    exit;
}

function act_face_user_modify(){

    $CONF = &$GLOBALS['CONF'];

    if(empty($_REQUEST['name']) || empty($_REQUEST['spaceCode'])){
        $data = '{"status":"error","code":"1","msg":"无效请求"}';
        _response($data);
        exit;
    }

    $spaces = array();
    core_select_data("select * from axgo_space where code = '".$_REQUEST['spaceCode']."' limit 1", $spaces);
    if(!isset($spaces[0])){
        $data = '{"status":"error","code":"1","msg":"无效空间"}';
        _response($data);
        exit;
    }

    $face_groups = array();
    core_select_data("select * from axgo_face_group where spaceCode = '".$spaces[0]['code']."' limit 1", $face_groups);
    if(!isset($face_groups[0])){
        $data = '{"status":"error","code":"1","msg":"空间无对应人员库"}';
        _response($data);
        exit;
    }

    $current_time = time();
    $arr = array();
    $arr['name'] = $_REQUEST['name'];
    $arr['createtime'] = $current_time;
    $sql = "insert into axgo_face_user set ".core_db_fmtlist($arr);
    if(!empty($_REQUEST['faceUserID'])){
        unset($arr['createtime']);
        $sql = "update axgo_face_user set ".core_db_fmtlist($arr)." where id = '".$_REQUEST['faceUserID']."'";
    }
    core_query_data($sql);

    //check用户是否本地写入成功
    $face_users = array();
    if(!empty($_REQUEST['faceUserID'])) {
        core_select_data("select * from axgo_face_user where id = '" . $_REQUEST['faceUserID'] . "'", $face_users);
    }else{
        core_select_data("select * from axgo_face_user where name = '".$_REQUEST['name']."' and createtime = '".$current_time."' limit 1", $face_users);
    }

    if(!isset($face_users[0]) || $face_users[0]['name'] != $_REQUEST['name']){
        $data = '{"status":"error","code":"1","msg":"新增或修改人员失败"}';
        _response($data);
        exit;
    }

    //是否同时带有人脸头像上来
    $file_dir = $CONF['dir_data']."/pub/faceImg";
    if(!is_dir($file_dir)){
        @mkdir($file_dir, 0777, true);
    }
    $file_name = $face_users[0]['id'].".jpg";
    $o_face_image_md5 = "";
    if(file_exists($file_dir."/".$file_name)){
        $o_face_image_md5 = md5_file($file_dir."/".$file_name);
    }
    if(isset($_FILES['faceImage']) && file_exists($_FILES['faceImage']['tmp_name'])){
        if(!move_uploaded_file($_FILES['faceImage']['tmp_name'], $file_dir."/".$file_name)){
            $data = '{"status":"error","code":"1","msg":"人员头像上传失败"}';
            _response($data);
            exit;
        }
        if(!file_exists($file_dir."/".$file_name)){
            $data = '{"status":"error","code":"1","msg":"人员头像上传失败2"}';
            _response($data);
            exit;
        }
        $n_face_image_md5 = md5_file($file_dir."/".$file_name);
    }

    //调用接口创建对应人脸库
    $face_user = $face_users[0];
    if(!empty($n_face_image_md5) && $n_face_image_md5 != $o_face_image_md5){
        $face_user['imageBase64'] = arcface_base64EncodeImage($file_dir."/".$file_name);
    }
    if(!empty($face_user['personId'])){
        $bool = arcface_update_person($face_user, $msg);
    }else{
        $face_user['personId'] = "S".$spaces[0]['id']."_U".$face_user['id'];
        $bool = arcface_creat_person($face_user, $msg);
    }
    if(!$bool){
        //删除新建用户，已存在用户不删除
        if(empty($_REQUEST['faceUserID'])) {
            core_query_data("delete from axgo_face_user where id = '".$face_users[0]['id']."'");
        }
        $data = '{"status":"error","code":"1","msg":"创建人脸库失败 '.$msg.'"}';
        _response($data);
        exit;
    }

    //平台创建成功，更新本地数据库
    if(empty($face_users[0]['personId']) && !empty($face_user['personId'])) {
        core_query_data("update axgo_face_user set personId = '".$face_user['personId']."' where id = '".$face_users[0]['id']."'");
    }

    //绑定到人员库
    $face_group_users = array();
    core_select_data("select * from axgo_face_group_user where personSetId = '".$face_groups[0]['personSetId']."' and personId = '".$face_user['personId']."' limit 1", $face_group_users);
    if(!isset($face_group_users[0])){
        $bool = arcface_user_to_group($face_user['personId'], $face_groups[0]['personSetId'], $msg);
        if(!$bool){
            $data = '{"status":"error","code":"1","msg":"添加到人员库失败 '.$msg.'"}';
            _response($data);
            exit;
        }
        $arr = array();
        $arr['groupID'] = $face_groups[0]['id'];
        $arr['userID'] = $face_users[0]['id'];
        $arr['personSetId'] = $face_groups[0]['personSetId'];
        $arr['personId'] = $face_user['personId'];
        core_query_data("insert into axgo_face_group_user set ".core_db_fmtlist($arr));
    }

    //同步平板信息
    _face_space_device_update_user($spaces[0]['code'], $msg);

    $return = array();
    $return['faceUserID'] = $face_users[0]['id'];
    $data = '{"status":"success","code":"0","msg":"ok", "data":'.json_encode($return).'}';
    _response($data);
    exit;
}

function _face_space_device_update_user($spaceCode, &$msg){
    $device_binds = array();
    core_select_data("select * from axgo_device_bind where spaceCode = '".$spaceCode."'", $device_binds);
    $deviceMacs = "";
    foreach ($device_binds as $device_bind) {
        $deviceMacs .= $deviceMacs == "" ? "'".$device_bind['macaddr']."'" : ",'".$device_bind['macaddr']."'";
    }
    if(empty($deviceMacs)){
        $msg = "无绑定终端";
        return false;
    }
    $devices = array();
    core_select_data("select * from axgo_device where macaddr in (".$deviceMacs.")", $devices);
    foreach ($devices as $device) {
        if(empty($device['faceCode'])){
            continue;
        }
        arcface_user_sync($device['faceCode'], $msg);
    }
    return true;
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
    file_put_contents($CONF['mosquitto_tmpdir']."/".uniqid("MQTT"), json_encode($job), LOCK_EX);

    return true;
}

function _response($data){
    if (isset($_REQUEST['callback'])) {
        $data = $_REQUEST['callback'].'('.$data.')';
    }
    echo $data;
}
?>