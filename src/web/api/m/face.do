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
    case 'face_group_list':
        act_face_group_list();
        break;
//
//    case 'face_group_modify':
//        act_face_group_modify();
//        break;
//    case 'face_group_remove':
//        act_face_group_remvoe();
//        break;

    case 'face_users':
        act_face_users();
        break;

    case 'face_user_modify':
        act_face_user_modify();
        break;
    case 'face_user_remove':
        act_face_user_remove();
        break;
    case 'face_device_update_user':
        act_face_device_update_user();
        break;

    default:
        $data = '{"status":"error","code":"401","msg":"请求无效"}';
        _response($data);
        break;
}

function act_face_users(){

    $CONF = &$GLOBALS['CONF'];

    if(empty($_REQUEST['unionid']) || empty($_REQUEST['spaceCode'])){
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

    $spaces = array();
    core_select_data("select * from axgo_space where code = '".$_REQUEST['spaceCode']."' limit 1", $spaces);
    if(!isset($spaces[0])){
        $data = '{"status":"error","code":"1","msg":"无效空间"}';
        _response($data);
        exit;
    }

    $space_admins = array();
    core_select_data("select * from axgo_space_admin where spaceCode = '".$spaces[0]['code']."' and userID = '".$users[0]['id']."' limit 1", $space_admins);

    if($spaces[0]['createUserID'] != $users[0]['id'] && !isset($space_admins[0])){
        $data = '{"status":"error","code":"1","msg":"无权限"}';
        _response($data);
        exit;
    }

    $face_groups = array();
    core_select_data("select * from axgo_face_group where spaceCode = '".$spaces[0]['code']."' limit 1", $face_groups);
    if(!isset($face_groups[0]) || empty($face_groups[0]['personSetId'])){
        $data = '{"status":"error","code":"1","msg":"当前空间未指定人脸库"}';
        _response($data);
        exit;
    }

    $face_group_users = array();
    $face_group_user_ids = "";
    core_select_data("select * from axgo_face_group_user where personSetId = '".$face_groups[0]['personSetId']."'", $face_group_users);
    foreach ($face_group_users as $face_group_user) {
//        if(empty($face_group_user['personId'])){
//            continue;
//        }
        $face_group_user_ids .= $face_group_user_ids == "" ? "'".$face_group_user['personId']."'" : ",'".$face_group_user['personId']."'";
    }

    $face_users = array();
    if(!empty($face_group_user_ids)){
        core_select_data("select * from axgo_face_user where personId in (".$face_group_user_ids.")", $face_users);
    }
    $file_dir = $CONF['dir_data']."/pub/faceImg";
    foreach ($face_users as $key => $face_user) {
        if(file_exists($file_dir."/".$face_user['id'].".jpg")){
            $face_users[$key]['faceImagePath'] = "/pub/faceImg/".$face_user['id'].".jpg";
        }
    }

    $data = '{"status":"success","code":"0","msg":"ok","data":'.json_encode($face_users).'}';
    _response($data);
    exit;
}

//同步用户到指定终端
function act_face_device_update_user(){

    if(empty($_REQUEST['unionid']) || empty($_REQUEST['macaddr'])){
        $data = '{"status":"error","code":"1","msg":"无效请求"}';
        _response($data);
        exit;
    }

    $bool = _face_device_update_user($_REQUEST['unionid'], $_REQUEST['macaddr'], $msg);
    if(!$bool){
        $data = '{"status":"error","code":"1","msg":"'.$msg.'"}';
        _response($data);
        exit;
    }

    $data = '{"status":"success","code":"0","msg":"ok"}';
    _response($data);
    exit;
}


function _face_device_update_user($unionid, $macaddr, &$msg){

    if(empty($unionid) || empty($macaddr)){
        $msg = "缺少必要参数";
        return false;
    }
    $users = array();
    core_select_data("select * from axgo_user where unionid = '".$unionid."' limit 1", $users);
    if(!isset($users[0])){
        $msg = "无效用户";
        return false;
    }

    $devices = array();
    core_select_data("select * from axgo_device where macaddr = '".$macaddr."' limit 1", $devices);
    if(!isset($devices[0]) || empty($devices[0]['faceCode'])){
        $msg = "无效设备或非法人脸终端";
        return false;
    }

    $device_binds = array();
    core_select_data("select * from axgo_device_bind where macaddr = '".$devices[0]['macaddr']."' limit 1", $device_binds);
    if(!isset($device_binds[0])){
        $msg = "无权限操作01";
        return false;
    }
    $spaces = array();
    core_select_data("select * from axgo_space where code = '".$device_binds[0]['spaceCode']."' limit 1", $spaces);
    if(!isset($spaces[0]) || $spaces[0]['createUserID'] != $users[0]['id']){
        $msg = "无权限操作";
        return false;
    }

    $bool = arcface_user_sync($devices[0]['faceCode'], $msg);
    if(!$bool){
        $msg = "同步人员失败 ".$msg;
        return false;
    }
    $msg = "同步人员成功";
    return true;
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

function _face_all_device_update_user($unionid, &$msg){

    if(empty($unionid)){
        $msg = "缺少必要参数";
        return false;
    }
    $users = array();
    core_select_data("select * from axgo_user where unionid = '".$unionid."' limit 1", $users);
    if(!isset($users[0])){
        $msg = "无效用户";
        return false;
    }

    $spaces = array();
    core_select_data("select * from axgo_space where createUserID = '".$users[0]['id']."' ", $spaces);
    $spaceCodes = "";
    foreach ($spaces as $space) {
        $spaceCodes .= $spaceCodes == "" ? "'".$space['code']."'" : ",'".$space['code']."'";
    }
    if(empty($spaceCodes)){
        $msg = "无效空间";
        return false;
    }
    $device_binds = array();
    core_select_data("select * from axgo_device_bind where spaceCode in (".$spaceCodes.")", $device_binds);
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

function act_face_user_remove(){

    $CONF = &$GLOBALS['CONF'];

    if(empty($_REQUEST['unionid']) || empty($_REQUEST['id']) || empty($_REQUEST['spaceCode'])){
        $data = '{"status":"error","code":"1","msg":"无效请求"}';
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

    $spaces = array();
    core_select_data("select * from axgo_space where code = '".$_REQUEST['spaceCode']."' limit 1", $spaces);
    if(!isset($spaces[0])){
        $data = '{"status":"error","code":"1","msg":"无效空间"}';
        _response($data);
        exit;
    }

    $space_admins = array();
    core_select_data("select * from axgo_space_admin where spaceCode = '".$spaces[0]['code']."' and userID = '".$users[0]['id']."' limit 1", $space_admins);

    if($spaces[0]['createUserID'] != $users[0]['id'] && !isset($space_admins[0])){
        $data = '{"status":"error","code":"1","msg":"无权限操作"}';
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
    core_select_data("select * from axgo_face_user where id = '".$_REQUEST['id']."'", $face_users);
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
        core_select_data("select * from axgo_face_group_user where personId = '".$face_users[0]['personId']."'", $face_group_users);
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

    if(empty($_REQUEST['unionid']) || empty($_REQUEST['name']) || empty($_REQUEST['spaceCode'])){
        $data = '{"status":"error","code":"1","msg":"无效请求"}';
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

    $spaces = array();
    core_select_data("select * from axgo_space where code = '".$_REQUEST['spaceCode']."' limit 1", $spaces);
    if(!isset($spaces[0])){
        $data = '{"status":"error","code":"1","msg":"无效空间"}';
        _response($data);
        exit;
    }

    $space_admins = array();
    core_select_data("select * from axgo_space_admin where spaceCode = '".$spaces[0]['code']."' and userID = '".$users[0]['id']."' limit 1", $space_admins);

    if($spaces[0]['createUserID'] != $users[0]['id'] && !isset($space_admins[0])){
        $data = '{"status":"error","code":"1","msg":"无权限操作"}';
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
    $arr['createUserID'] = $users[0]['id'];
    $arr['createUserName'] = $users[0]['realName'];
    $arr['createtime'] = $current_time;

    $sql = "insert into axgo_face_user set ".core_db_fmtlist($arr);
    if(!empty($_REQUEST['id'])){
        unset($arr['createtime']);
        unset($arr['createUserID']);
        unset($arr['createUserName']);
        $sql = "update axgo_face_user set ".core_db_fmtlist($arr)." where id = '".$_REQUEST['id']."'";
    }
    core_query_data($sql);

    //check用户是否本地写入成功
    $face_users = array();
    if(!empty($_REQUEST['id'])) {
        core_select_data("select * from axgo_face_user where id = '" . $_REQUEST['id'] . "'", $face_users);
    }else{
        core_select_data("select * from axgo_face_user where createUserID = '" . $users[0]['id'] . "' and name = '".$_REQUEST['name']."' and createtime = '".$current_time."' limit 1", $face_users);
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
    }

    //调用接口创建对应人脸库
    $face_user = $face_users[0];
    if(isset($_FILES['faceImage']) && file_exists($file_dir."/".$file_name)){
//    if(file_exists($file_dir."/".$file_name)){
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
        if(empty($_REQUEST['id'])) {
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

    $data = '{"status":"success","code":"0","msg":"ok"}';
    _response($data);
    exit;
}

function act_face_group_remvoe(){

    if(empty($_REQUEST['unionid']) || empty($_REQUEST['id'])){
        $data = '{"status":"error","code":"1","msg":"无效请求"}';
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

    $groups = array();
    core_select_data("select * from axgo_face_group where id = '".$_REQUEST['id']."'", $groups);
    if(!isset($groups[0])){
        $data = '{"status":"error","code":"1","msg":"无效人员库"}';
        _response($data);
        exit;
    }elseif($groups[0]['createUserID'] != $users[0]['id']){
        $data = '{"status":"error","code":"1","msg":"无权限操作"}';
        _response($data);
        exit;
    }
    $bool = arcface_delete_group($groups[0]['personSetId'], $msg);
    if(!$bool){
        $data = '{"status":"error","code":"1","msg":"删除人脸库失败 '.$msg.'"}';
        _response($data);
        exit;
    }
    core_query_data("delete from axgo_face_group where id = '".$groups[0]['id']."'");

    $data = '{"status":"success","code":"0","msg":"ok"}';
    _response($data);
    exit;
}

function act_face_group_modify(){

    if(empty($_REQUEST['unionid']) || empty($_REQUEST['name'])){
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

    $arr = array();
    $arr['name'] = $_REQUEST['name'];
    $arr['personSetId'] = $_REQUEST['name']."_".$users[0]['id'];
    $arr['createUserID'] = $users[0]['id'];
    $arr['createUserName'] = $users[0]['realName'];
    $arr['createtime'] = time();

    $sql = "insert into axgo_face_group set ".core_db_fmtlist($arr);
    //修改
    $groups = array();
    if(!empty($_REQUEST['id'])){
        core_select_data("select * from axgo_face_group where id = '".$_REQUEST['id']."'", $groups);
        if(!isset($groups[0])){
            $data = '{"status":"error","code":"1","msg":"无效人员库"}';
            _response($data);
            exit;
        }elseif($groups[0]['createUserID'] != $users[0]['id']){
            $data = '{"status":"error","code":"1","msg":"无权限操作"}';
            _response($data);
            exit;
        }elseif($groups[0]['name'] == $_REQUEST['name']){  //不需要修改
            $data = '{"status":"success","code":"0","msg":"ok1"}';
            _response($data);
            exit;
        }
        unset($arr['createtime']);
        unset($arr['createUserID']);
        unset($arr['createUserName']);
        $sql = "update axgo_face_group set ".core_db_fmtlist($arr)." where id = '".$groups[0]['id']."'";
    }

    //调用接口创建对应人脸库
    if(isset($groups[0]) && !empty($groups[0]['personSetId'])){
        $bool = arcface_modify_group($groups[0]['personSetId'], $arr['personSetId'], $msg);
    }else{
        $bool = arcface_creat_group($arr['personSetId'], $msg);
    }
    if(!$bool){
        $data = '{"status":"error","code":"1","msg":"创建人脸库失败 '.$msg.'"}';
        _response($data);
        exit;
    }

    //平台创建成功，写入本地数据库
    core_query_data($sql);

    //自动绑定人员库到该用户下所有平板设备上
    $faceCodes = "";
    $spaces = array();
    core_select_data("select * from axgo_space where createUserID = '".$users[0]['id']."' ", $spaces);
    $spaceCodes = "";
    foreach ($spaces as $space) {
        $spaceCodes .= $spaceCodes == "" ? "'".$space['code']."'" : ",'".$space['code']."'";
    }
    if(!empty($spaceCodes)){
        $device_binds = array();
        core_select_data("select * from axgo_device_bind where spaceCode in (".$spaceCodes.")", $device_binds);
        $deviceMacs = "";
        foreach ($device_binds as $device_bind) {
            $deviceMacs .= $deviceMacs == "" ? "'".$device_bind['macaddr']."'" : ",'".$device_bind['macaddr']."'";
        }
        if(!empty($deviceMacs)){
            $devices = array();
            core_select_data("select * from axgo_device where macaddr in (".$deviceMacs.")", $devices);
            foreach ($devices as $device) {
                if(empty($device['faceCode'])){
                    continue;
                }
                $faceCodes .= $faceCodes == "" ? $device['faceCode'] : ",".$device['faceCode'];
            }
        }
    }
    if(!empty($faceCodes)){
        arcface_groupbind_devices($faceCodes, $arr['personSetId'], $msg);
    }

    $data = '{"status":"success","code":"0","msg":"ok"}';
    _response($data);
    exit;
}

function act_face_group_list(){

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

    //被授权的空间
    $space_admins = array();
    $space_admin_codes = "";
    core_select_data("select * from axgo_space_admin where userID = '".$users[0]['id']."'", $space_admins);
    foreach ($space_admins as $space_admin) {
        $space_admin_codes .= $space_admin_codes == "" ? "'".$space_admin['spaceCode']."'" : ",'".$space_admin['spaceCode']."'";
    }
    $spaces = array();
    core_select_data("select * from axgo_space where createUserID = '".$users[0]['id']."'", $spaces);
    foreach ($spaces as $space) {
        $space_admin_codes .= $space_admin_codes == "" ? "'".$space['code']."'" : ",'".$space['code']."'";
    }

    $face_groups = array();
    if(!empty($space_admin_codes)){
        core_select_data("select * from axgo_face_group where spaceCode in (".$space_admin_codes.")", $face_groups);
    }

    $data = '{"status":"success","code":"0","msg":"ok", "data":'.json_encode($face_groups).'}';
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