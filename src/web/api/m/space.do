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
    case 'user_spaces':
        act_user_spaces();
        break;
    case 'user_space_modify':
        act_user_space_modify();
        break;
    case 'user_space_info':
        act_user_space_info();
        break;
    case 'user_space_remove':
        act_user_space_remove();
        break;

    case 'space_user_group':
        act_space_user_group();
        break;
    case 'space_user_group_modify':
        act_space_user_group_modify();
        break;
    case 'space_user_group_remove':
        act_space_user_group_remove();
        break;

    case 'space_user_bind_group':
        act_space_user_bind_group();
        break;
    case 'space_user_auth':
        act_space_user_auth();
        break;
    case 'space_user_remove':
        act_space_user_remove();
        break;
    case 'space_user_check':
        act_space_user_check();
        break;

    case 'user_space_floor_modify':
        act_user_space_floor_modify();
        break;
    case 'user_space_floor_remove':
        act_user_space_floor_remove();
        break;

    case 'user_space_floor_rooms':
        act_user_space_floor_rooms();
        break;
    case 'user_space_floor_room_detail':
        act_user_space_floor_room_detail();
        break;
    case 'user_space_floor_room_modify':
        act_user_space_floor_room_modify();
        break;
    case 'user_space_floor_room_remove':
        act_user_space_floor_room_remove();
        break;
    case 'user_space_floor_room_coverimage_upload':
        act_user_space_floor_room_coverimage_upload();
        break;

    case 'user_space_floor_mrooms':
        act_user_space_floor_mrooms();
        break;
    case 'user_space_floor_mroom_detail':
        act_user_space_floor_mroom_detail();
        break;
    case 'user_space_floor_mroom_modify':
        act_user_space_floor_mroom_modify();
        break;
    case 'user_space_floor_mroom_remove':
        act_user_space_floor_mroom_remove();
        break;
    case 'user_space_floor_mroom_coverimage_upload':
        act_user_space_floor_mroom_coverimage_upload();
        break;
    default:
        $data = '{"status":"error","code":"401","msg":"请求无效"}';
        _response($data);
        break;
}


function act_user_space_floor_room_coverimage_upload(){

    $CONF = &$GLOBALS['CONF'];

    if(empty($_REQUEST['unionid']) || empty($_REQUEST['spaceCode']) || empty($_REQUEST['floorCode']) || empty($_REQUEST['id'])){
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

    $rooms = array();
    core_select_data("select * from axgo_room where id = '".$_REQUEST['id']."'", $rooms);
    if(!isset($rooms[0]) || $rooms[0]['floorCode'] != $_REQUEST['floorCode']){
        $data = '{"status":"error","code":"1","msg":"无效房间或无权限"}';
        _response($data);
        exit;
    }

    $file_dir = $CONF['dir_data']."/pub/room/coverImage";
    if(!is_dir($file_dir)){
        @mkdir($file_dir, 0777, true);
    }
    $file_name = $rooms[0]['id'].".jpg";

    if(!move_uploaded_file($_FILES['coverImage']['tmp_name'], $file_dir."/".$file_name)){
        $data = '{"status":"error","code":"1","msg":"上传封面图失败"}';
        _response($data);
        exit;
    }

    if(!file_exists($file_dir."/".$file_name)){
        $data = '{"status":"error","code":"1","msg":"上传封面图失败02"}';
        _response($data);
        exit;
    }

    $data = '{"status":"success","code":"0","msg":"ok"}';
    _response($data);
    exit;
}

function act_user_space_floor_room_detail(){

    $CONF = &$GLOBALS['CONF'];

    if(empty($_REQUEST['unionid']) || empty($_REQUEST['spaceCode']) || empty($_REQUEST['id'])){
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

    $rooms = array();
    core_select_data("select * from axgo_room where id = '".$_REQUEST['id']."'", $rooms);
    if(!isset($rooms[0]) || $rooms[0]['spaceCode'] != $spaces[0]['code']){
        $data = '{"status":"error","code":"1","msg":"无效房间或无权限"}';
        _response($data);
        exit;
    }

    $file_dir = "/pub/room/coverImage/".$rooms[0]['id'].".jpg";
    if(file_exists($CONF['dir_data'].$file_dir)){
        $rooms[0]['coverImagePath'] = $file_dir."?v=".time();
    }

    //绑定设备
    $rooms[0]['devices'] = array();
    core_select_data("select * from axgo_room_device where roomID = '".$rooms[0]['id']."'", $rooms[0]['devices']);

    $data = '{"status":"success","code":"0","msg":"ok","data":'.json_encode($rooms[0]).'}';
    _response($data);
    exit;
}

function act_user_space_floor_mroom_detail(){

    $CONF = &$GLOBALS['CONF'];

    if(empty($_REQUEST['unionid']) || empty($_REQUEST['spaceCode']) || empty($_REQUEST['id'])){
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

    $mrooms = array();
    core_select_data("select * from axgo_mroom where id = '".$_REQUEST['id']."'", $mrooms);
    if(!isset($mrooms[0]) || $mrooms[0]['spaceCode'] != $spaces[0]['code']){
        $data = '{"status":"error","code":"1","msg":"无效房间或无权限"}';
        _response($data);
        exit;
    }

    $file_dir = "/pub/mroom/coverImage/".$mrooms[0]['id'].".jpg";
    if(file_exists($CONF['dir_data'].$file_dir)){
        $mrooms[0]['coverImagePath'] = $file_dir."?v=".time();
    }

    //绑定设备
    $mrooms[0]['devices'] = array();
    core_select_data("select * from axgo_mroom_device where mroomID = '".$mrooms[0]['id']."'", $mrooms[0]['devices']);

    $data = '{"status":"success","code":"0","msg":"ok","data":'.json_encode($mrooms[0]).'}';
    _response($data);
    exit;
}

function act_user_space_floor_mroom_coverimage_upload(){

    $CONF = &$GLOBALS['CONF'];

    if(empty($_REQUEST['unionid']) || empty($_REQUEST['spaceCode']) || empty($_REQUEST['floorCode']) || empty($_REQUEST['id'])){
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

    $mrooms = array();
    core_select_data("select * from axgo_mroom where id = '".$_REQUEST['id']."'", $mrooms);
    if(!isset($mrooms[0]) || $mrooms[0]['floorCode'] != $_REQUEST['floorCode']){
        $data = '{"status":"error","code":"1","msg":"无效房间或无权限"}';
        _response($data);
        exit;
    }

    $file_dir = $CONF['dir_data']."/pub/mroom/coverImage";
    if(!is_dir($file_dir)){
        @mkdir($file_dir, 0777, true);
    }
    $file_name = $mrooms[0]['id'].".jpg";

    if(!move_uploaded_file($_FILES['coverImage']['tmp_name'], $file_dir."/".$file_name)){
        $data = '{"status":"error","code":"1","msg":"上传封面图失败"}';
        _response($data);
        exit;
    }

    if(!file_exists($file_dir."/".$file_name)){
        $data = '{"status":"error","code":"1","msg":"上传封面图失败02"}';
        _response($data);
        exit;
    }

    $data = '{"status":"success","code":"0","msg":"ok"}';
    _response($data);
    exit;
}

function act_user_space_floor_mroom_remove(){
    if(empty($_REQUEST['unionid']) || empty($_REQUEST['spaceCode']) || empty($_REQUEST['id'])){
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

    $mrooms = array();
    core_select_data("select * from axgo_mroom where id = '".$_REQUEST['id']."'", $mrooms);
    if(!isset($mrooms[0]) || $mrooms[0]['spaceCode'] != $spaces[0]['code']){
        $data = '{"status":"error","code":"1","msg":"无效房间或无权限"}';
        _response($data);
        exit;
    }

    core_query_data("update axgo_mroom set status = 1 where id = ".$mrooms[0]['id']);
    core_query_data("delete from axgo_mroom_device where mroomID = ".$mrooms[0]['id']);


    $data = '{"status":"success","code":"0","msg":"ok"}';
    _response($data);
    exit;
}


function act_user_space_floor_mroom_modify(){
    if(empty($_REQUEST['unionid']) || empty($_REQUEST['spaceCode']) || empty($_REQUEST['floorCode']) || empty($_REQUEST['room_name'])){
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

    $current_time = time();

    $arr = array();
    $arr['room_name'] = $_REQUEST['room_name'];
    $arr['spaceCode'] = $spaces[0]['code'];
    $arr['floorCode'] = $_REQUEST['floorCode'];
    $arr['flag'] = intval($_REQUEST['flag']);
    $arr['book_start'] = $_REQUEST['book_start'];
    $arr['book_end'] = $_REQUEST['book_end'];
    $arr['book_day'] = $_REQUEST['book_day'];
    $arr['capacity'] = $_REQUEST['capacity'];
    $arr['max_leadtime'] = $_REQUEST['max_leadtime'];
    $arr['max_duration'] = $_REQUEST['max_duration'];
    $arr['note'] = $_REQUEST['note'];
    $arr['people_range'] = $_REQUEST['people_range'];
    $arr['room_service'] = $_REQUEST['room_service'];
    $arr['sortnum'] = $_REQUEST['sortnum'];
    $arr['createtime'] = $current_time;

    $mrooms = array();
    $sql = "insert into axgo_mroom set ".core_db_fmtlist($arr);
    if(!empty($_REQUEST['id'])){
        core_select_data("select * from axgo_mroom where id = '".$_REQUEST['id']."'", $mrooms);
        if(!isset($mrooms[0]) || $mrooms[0]['floorCode'] != $_REQUEST['floorCode']){
            $data = '{"status":"error","code":"1","msg":"无效会议室或无权限"}';
            _response($data);
            exit;
        }
        unset($arr['spaceCode']);
        unset($arr['floorCode']);
        unset($arr['createtime']);
        $sql = "update axgo_mroom set ".core_db_fmtlist($arr)." where id = ".$mrooms[0]['id'];
    }
    core_query_data($sql);

    if(!isset($mrooms[0])){
        core_select_data("select * from axgo_mroom where spaceCode = '".$spaces[0]['code']."' and room_name = '".$_REQUEST['room_name']."' and createtime = '".$current_time."' limit 1", $mrooms);
    }

    if(!isset($mrooms[0])){
        $data = '{"status":"error","code":"1","msg":"新增会议室失败"}';
        _response($data);
        exit;
    }

    //绑定设备
    core_query_data("delete from axgo_mroom_device where mroomID = '".$mrooms[0]['id']."'");
    $devices = json_decode($_REQUEST['devices'], true);
    foreach ($devices as $deviceID) {
        $one_devices = array();
        core_select_data("select * from axgo_device where id = '".$deviceID."'", $one_devices);
        if(!isset($one_devices[0])){
            continue;
        }
        $arr = array();
        $arr['mroomID'] = $mrooms[0]['id'];
        $arr['mroomName'] = $mrooms[0]['room_name'];
        $arr['deviceID'] = $one_devices[0]['id'];
        $arr['deviceName'] = $one_devices[0]['devicenick'];
        $arr['macaddr'] = $one_devices[0]['macaddr'];
        core_query_data("insert into axgo_mroom_device set ".core_db_fmtlist($arr));
    }

    $data = '{"status":"success","code":"0","msg":"ok"}';
    _response($data);
    exit;
}

function act_user_space_floor_mrooms(){
    if(empty($_REQUEST['unionid']) || empty($_REQUEST['spaceCode']) || empty($_REQUEST['floorCode'])){
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

    $mrooms = array();
    core_select_data("select * from axgo_mroom where spaceCode = '".$spaces[0]['code']."' and floorCode = '".$_REQUEST['floorCode']."'  and status = 0", $mrooms);

    $data = '{"status":"success","code":"0","msg":"ok", "data":'.json_encode($mrooms).'}';
    _response($data);
    exit;
}










//管理员审核用户
function act_space_user_check(){

    if(empty($_REQUEST['unionid']) || empty($_REQUEST['spaceCode'])){
        $data = '{"status":"error","code":"1","msg":"无效用户请求"}';
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

    $result = array();
    $user_group_users = array();
    core_select_data("select * from axgo_user_group_user where spaceCode = '".$spaces[0]['code']."' and userID = '".$users[0]['id']."' limit 1", $user_group_users);
    if(!isset($user_group_users[0])){
        $result['bindStatus'] = "-1";
    }elseif($user_group_users[0]['status'] == '1'){
        $result['bindStatus'] = "1";
    }else{
        $result['bindStatus'] = "0";
    }

    $data = '{"status":"success","code":"0","msg":"ok","data":'.json_encode($result).'}';
    _response($data);
    exit;
}

function act_user_space_floor_room_remove(){
    if(empty($_REQUEST['unionid']) || empty($_REQUEST['spaceCode']) || empty($_REQUEST['floorCode']) || empty($_REQUEST['id'])){
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

    $rooms = array();
    core_select_data("select * from axgo_room where id = '".$_REQUEST['id']."'", $rooms);
    if(!isset($rooms[0]) || $rooms[0]['floorCode'] != $_REQUEST['floorCode']){
        $data = '{"status":"error","code":"1","msg":"无效房间或无权限"}';
        _response($data);
        exit;
    }

    core_query_data("delete from axgo_room where id = ".$rooms[0]['id']);
    core_query_data("delete from axgo_room_device where roomID = ".$rooms[0]['id']);

    $data = '{"status":"success","code":"0","msg":"ok"}';
    _response($data);
    exit;
}


function act_user_space_floor_room_modify(){
    if(empty($_REQUEST['unionid']) || empty($_REQUEST['spaceCode']) || empty($_REQUEST['floorCode']) || empty($_REQUEST['name'])){
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

    $current_time = time();

    $arr = array();
    $arr['name'] = $_REQUEST['name'];
    $arr['spaceCode'] = $spaces[0]['code'];
    $arr['floorCode'] = $_REQUEST['floorCode'];
    $arr['description'] = $_REQUEST['description'] ? $_REQUEST['description'] : '';
    $arr['sortIndex'] = isset($_REQUEST['sortIndex']) ? intval($_REQUEST['sortIndex'])+'' : '0';
    $arr['createtime'] = $current_time;

    $rooms = array();

    $sql = "insert into axgo_room set ".core_db_fmtlist($arr);
    if(!empty($_REQUEST['id'])){
        core_select_data("select * from axgo_room where id = '".$_REQUEST['id']."'", $rooms);
        if(!isset($rooms[0]) || $rooms[0]['floorCode'] != $_REQUEST['floorCode']){
            $data = '{"status":"error","code":"1","msg":"无效房间或无权限"}';
            _response($data);
            exit;
        }
        unset($arr['spaceCode']);
        unset($arr['floorCode']);
        unset($arr['createtime']);
        $sql = "update axgo_room set ".core_db_fmtlist($arr)." where id = ".$rooms[0]['id'];
    }
    core_query_data($sql);


    if(!isset($rooms[0])){
        core_select_data("select * from axgo_room where spaceCode = '".$spaces[0]['code']."' and name = '".$_REQUEST['name']."' and createtime = '".$current_time."' limit 1", $rooms);
    }

    if(!isset($rooms[0])){
        $data = '{"status":"error","code":"1","msg":"新增房间失败"}';
        _response($data);
        exit;
    }

    //绑定设备
    core_query_data("delete from axgo_room_device where roomID = '".$rooms[0]['id']."'");
    $devices = json_decode($_REQUEST['devices'], true);
    foreach ($devices as $deviceID) {
        $one_devices = array();
        core_select_data("select * from axgo_device where id = '".$deviceID."'", $one_devices);
        if(!isset($one_devices[0])){
            continue;
        }
        $arr = array();
        $arr['roomID'] = $rooms[0]['id'];
        $arr['roomName'] = $rooms[0]['name'];
        $arr['deviceID'] = $one_devices[0]['id'];
        $arr['deviceName'] = $one_devices[0]['devicenick'];
        $arr['macaddr'] = $one_devices[0]['macaddr'];
        core_query_data("insert into axgo_room_device set ".core_db_fmtlist($arr));
    }

    $data = '{"status":"success","code":"0","msg":"ok"}';
    _response($data);
    exit;
}

//获取楼层下的房间和会议室组合列表
function act_user_space_floor_rooms(){
    if(empty($_REQUEST['unionid']) || empty($_REQUEST['spaceCode']) || empty($_REQUEST['floorCode'])){
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

    $result = array();

    $rooms = array();
    core_select_data("select * from axgo_room where spaceCode = '".$spaces[0]['code']."' and floorCode = '".$_REQUEST['floorCode']."'", $rooms);

    $data = '{"status":"success","code":"0","msg":"ok", "data":'.json_encode($rooms).'}';
    _response($data);
    exit;
}

function act_user_space_floor_remove(){
    if(empty($_REQUEST['unionid']) || empty($_REQUEST['spaceCode']) || empty($_REQUEST['code'])){
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

    $floors = array();
    core_select_data("select * from axgo_floor where code = '".$_REQUEST['code']."' limit 1", $floors);
    if(!isset($floors[0]) || $floors[0]['spaceCode'] != $spaces[0]['code']){
        $data = '{"status":"error","code":"1","msg":"无效楼层或无权限"}';
        _response($data);
        exit;
    }

    $rooms = array();
    core_select_data("select * from axgo_room where floorCode = '".$floors[0]['code']."' limit 1", $rooms);
    if(isset($rooms[0])){
        $data = '{"status":"error","code":"1","msg":"楼层下存在房间不能删除"}';
        _response($data);
        exit;
    }

    $mrooms = array();
    core_select_data("select * from axgo_mroom where floorCode = '".$floors[0]['code']."'  and status = 0 limit 1", $mrooms);
    if(isset($mrooms[0])){
        $data = '{"status":"error","code":"1","msg":"楼层下存在会议室不能删除"}';
        _response($data);
        exit;
    }

    core_query_data("delete from axgo_floor where id = ".$floors[0]['id']);

    $data = '{"status":"success","code":"0","msg":"ok"}';
    _response($data);
    exit;
}

function act_user_space_floor_modify(){
    if(empty($_REQUEST['unionid']) || empty($_REQUEST['spaceCode']) || empty($_REQUEST['name'])){
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

    $arr = array();
    $arr['name'] = $_REQUEST['name'];
    $arr['code'] = md5(uniqid(mt_rand(), true));
    $arr['spaceCode'] = $spaces[0]['code'];
    $arr['description'] = $_REQUEST['description'] ? $_REQUEST['description'] : '';
    $arr['sortIndex'] = isset($_REQUEST['sortIndex']) ? intval($_REQUEST['sortIndex'])+'' : '0';
    $arr['createtime'] = time();

    $sql = "insert into axgo_floor set ".core_db_fmtlist($arr);
    if(!empty($_REQUEST['code'])){
        $floors = array();
        core_select_data("select * from axgo_floor where code = '".$_REQUEST['code']."' limit 1", $floors);
        if(!isset($floors[0]) || $floors[0]['spaceCode'] != $spaces[0]['code']){
            $data = '{"status":"error","code":"1","msg":"无效楼层或无权限"}';
            _response($data);
            exit;
        }
        unset($arr['spaceCode']);
        unset($arr['code']);
        unset($arr['createtime']);
        $sql = "update axgo_floor set ".core_db_fmtlist($arr)." where id = ".$floors[0]['id'];
    }
    core_query_data($sql);

    $data = '{"status":"success","code":"0","msg":"ok"}';
    _response($data);
    exit;
}


//管理员审核用户
function act_space_user_remove(){

    if(empty($_REQUEST['unionid']) || empty($_REQUEST['spaceCode']) || empty($_REQUEST['userID'])){
        $data = '{"status":"error","code":"1","msg":"无效用户请求"}';
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

    $user_group_users = array();
    core_select_data("select * from axgo_user_group_user where spaceCode = '".$spaces[0]['code']."' and userID = '".$users[0]['id']."' limit 1", $user_group_users);
    if(!isset($user_group_users[0])){
        $data = '{"status":"error","code":"1","msg":"无效空间用户数据"}';
        _response($data);
        exit;
    }

    core_query_data("delete from axgo_user_group_user where spaceCode = '".$spaces[0]['code']."' and userID = '".$users[0]['id']."'");

    $data = '{"status":"success","code":"0","msg":"ok"}';
    _response($data);
    exit;
}

//管理员审核用户
function act_space_user_auth(){

    if(empty($_REQUEST['unionid']) || empty($_REQUEST['spaceCode']) || empty($_REQUEST['userID'])){
        $data = '{"status":"error","code":"1","msg":"无效用户请求"}';
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

    $user_group_users = array();
    core_select_data("select * from axgo_user_group_user where spaceCode = '".$spaces[0]['code']."' and userID = '".$_REQUEST['userID']."' limit 1", $user_group_users);
    if(!isset($user_group_users[0])){
        $data = '{"status":"error","code":"1","msg":"无效空间用户数据"}';
        _response($data);
        exit;
    }

    $status = '1';
    if($_REQUEST['status'] != '1'){
        $status = '0';
    }

    $arr = array();
    $arr['status'] = $status;
    core_query_data("update axgo_user_group_user set ".core_db_fmtlist($arr)." where spaceCode = '".$spaces[0]['code']."' and userID = '".$_REQUEST['userID']."'");

    $data = '{"status":"success","code":"0","msg":"ok"}';
    _response($data);
    exit;
}

//用户主动申请加入到空间（或空间分组）  需管理员审核
function act_space_user_bind_group(){

    if(empty($_REQUEST['unionid']) || empty($_REQUEST['spaceCode'])){
        $data = '{"status":"error","code":"1","msg":"无效用户请求"}';
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

    $user_groups = array();
    if(!empty($_REQUEST['groupId'])){
        core_select_data("select * from axgo_user_group where id = '".$_REQUEST['groupId']."'", $user_groups);
        if(!isset($user_groups[0]) || $user_groups[0]['spaceCode'] != $spaces[0]['code']){
            $data = '{"status":"error","code":"1","msg":"无效分组或无权限"}';
            _response($data);
            exit;
        }
    }

    $user_group_users = array();
    core_select_data("select * from axgo_user_group_user where spaceCode = '".$spaces[0]['code']."' and userID = '".$users[0]['id']."' limit 1", $user_group_users);
    if(isset($user_group_users[0])){
        $data = '{"status":"error","code":"1","msg":"您已经在该空间中无需重复申请"}';
        _response($data);
        exit;
    }

    $arr = array();
    $arr['spaceCode'] = $spaces[0]['code'];
    $arr['groupId'] = !isset($user_groups[0]) ? $user_groups[0]['id'] : '';
    $arr['userID'] = $users[0]['id'];
    $arr['status'] = "0";
    $sql = "insert into axgo_user_group_user set ".core_db_fmtlist($arr);
    core_query_data($sql);

    $data = '{"status":"success","code":"0","msg":"ok"}';
    _response($data);
    exit;
}

function act_space_user_group_remove(){
    if(empty($_REQUEST['unionid']) || empty($_REQUEST['spaceCode']) || empty($_REQUEST['id'])){
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

    $user_groups = array();
    core_select_data("select * from axgo_user_group where id = '".$_REQUEST['id']."'", $user_groups);
    if(!isset($user_groups[0]) || $user_groups[0]['spaceCode'] != $spaces[0]['code']){
        $data = '{"status":"error","code":"1","msg":"无效分组或无权限"}';
        _response($data);
        exit;
    }

    $sub_user_groups = array();
    core_select_data("select * from axgo_user_group where spaceCode = '".$spaces[0]['code']."' and parentId = '".$user_groups[0]['id']."' limit 1", $sub_user_groups);
    if(isset($sub_user_groups[0])){
        $data = '{"status":"error","code":"1","msg":"当前分组下存在子分组无法删除"}';
        _response($data);
        exit;
    }

    $user_group_users = array();
    core_select_data("select * from axgo_user_group where spaceCode = '".$spaces[0]['code']."' and groupId = '".$user_groups[0]['id']."' limit 1", $user_group_users);
    if(isset($user_group_users[0])){
        $data = '{"status":"error","code":"1","msg":"当前分组下存在用户无法删除"}';
        _response($data);
        exit;
    }

    core_query_data("delete from axgo_user_group where id = '".$user_groups[0]['id']."'");

    $data = '{"status":"success","code":"0","msg":"ok"}';
    _response($data);
    exit;
}

function act_space_user_group_modify(){
    if(empty($_REQUEST['unionid']) || empty($_REQUEST['spaceCode']) || empty($_REQUEST['name'])){
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

    $arr = array();
    $arr['name'] = $_REQUEST['name'];
    $arr['spaceCode'] = $spaces[0]['code'];
    $arr['parentId'] = $_REQUEST['parentId'] ? $_REQUEST['parentId'] : '';
    $arr['sortIndex'] = isset($_REQUEST['sortIndex']) ? intval($_REQUEST['sortIndex'])+'' : '0';
    $arr['createtime'] = time();

    $sql = "insert into axgo_user_group set ".core_db_fmtlist($arr);
    if(!empty($_REQUEST['id'])){
        $user_groups = array();
        core_select_data("select * from axgo_user_group where id = '".$_REQUEST['id']."'", $user_groups);
        if(!isset($user_groups[0]) || $user_groups[0]['spaceCode'] != $spaces[0]['code']){
            $data = '{"status":"error","code":"1","msg":"无效分组或无权限"}';
            _response($data);
            exit;
        }
        unset($arr['spaceCode']);
        unset($arr['parentId']);
        unset($arr['createtime']);
        $sql = "update axgo_user_group set ".core_db_fmtlist($arr)." where id = ".$user_groups[0]['id'];
    }
    core_query_data($sql);

    $data = '{"status":"success","code":"0","msg":"ok"}';
    _response($data);
    exit;
}

function act_space_user_group(){
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
        $data = '{"status":"error","code":"1","msg":"无权限操作"}';
        _response($data);
        exit;
    }

    $groupId = "";
    if(!empty($_REQUEST['groupId'])){
        $groupId = $_REQUEST['groupId'];
    }
    $user_groups = array();
    core_select_data("select * from axgo_user_group where spaceCode = '".$spaces[0]['code']."' and parentId = '".$groupId."' order by sortIndex DESC", $user_groups);

    $user_group_users = array();
    $user_group_users_obj = array();
    core_select_data("select * from axgo_user_group_user where spaceCode = '".$spaces[0]['code']."' and groupId = '".$groupId."'", $user_group_users);
    $userIDs = "";
    foreach ($user_group_users as $user_group_user){
        $userIDs .= $userIDs == "" ? $user_group_user['userID'] : ",".$user_group_user['userID'];
        $user_group_users_obj[$user_group_user['userID']] = $user_group_user['status'];
    }
    $users = array();
    if(!empty($userIDs)){
        core_select_data("select id, realName from axgo_user where id  in (".$userIDs.")", $users);
    }
    foreach ($users as $key => $user) {
        if(isset($user_group_users_obj[$user['id']])){
            $users[$key]['status'] = $user_group_users_obj[$user['id']];
        }
    }

    $data = '{"status":"success","code":"0","msg":"ok","data":{"groups":'.json_encode($user_groups).',"users":'.json_encode($users).'}}';
    _response($data);
    exit;
}

function act_user_space_info(){
    if(empty($_REQUEST['unionid']) || empty($_REQUEST['code'])){
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
    core_select_data("select * from axgo_space where code = '".$_REQUEST['code']."' limit 1", $spaces);
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

    //空间楼层
    $spaces[0]['floors'] = array();
    core_select_data("select * from axgo_floor where spaceCode = '".$spaces[0]['code']."' order by sortIndex DESC", $spaces[0]['floors']);
    //楼层房间会议室数量
    foreach ($spaces[0]['floors'] as $key => $floor) {
        $rooms = array();
        core_select_data("select * from axgo_room where spaceCode = '".$spaces[0]['code']."' and floorCode = '".$floor['code']."'", $rooms);
        if(isset($rooms[0])){
            $spaces[0]['floors'][$key]['roomCount'] = count($rooms);
        }

        $mrooms = array();
        core_select_data("select * from axgo_mroom where spaceCode = '".$spaces[0]['code']."' and floorCode = '".$floor['code']."' and status = 0", $mrooms);
        if(isset($mrooms[0])){
            $spaces[0]['floors'][$key]['mroomCount'] = count($mrooms);
        }
    }

    //空间管理员
    $space_admins = array();
    core_select_data("select * from axgo_space_admin where spaceCode = '".$spaces[0]['code']."'", $space_admins);
    $userIDs = "";
    foreach ($space_admins as $space_admin) {
        $userIDs .= $userIDs == "" ? $space_admin['userID'] : ",".$space_admin['userID'];
    }
    $spaces[0]['admins'] = array();
    if(!empty($userIDs)){
        core_select_data("select id, realName from axgo_user where id in (".$userIDs.")", $spaces[0]['admins']);
    }

    $data = '{"status":"success","code":"0","msg":"ok","data":'.json_encode($spaces[0]).'}';
    _response($data);
    exit;
}

function act_user_space_remove(){
    if(empty($_REQUEST['unionid']) || empty($_REQUEST['code'])){
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
    core_select_data("select * from axgo_space where code = '".$_REQUEST['code']."' limit 1", $spaces);
    if(!isset($spaces[0])){
        $data = '{"status":"error","code":"1","msg":"无效空间"}';
        _response($data);
        exit;
    }

    if($spaces[0]['createUserID'] != $users[0]['id']){
        $data = '{"status":"error","code":"1","msg":"无权限操作"}';
        _response($data);
        exit;
    }

    //检测空间下是否绑定了设备
    $device_binds = array();
    core_select_data("select * from axgo_device_bind where spaceCode = '".$spaces[0]['code']."' limit 1", $device_binds);
    if(isset($device_binds[0])){
        $data = '{"status":"error","code":"1","msg":"该空间绑定了设备，无法删除"}';
        _response($data);
        exit;
    }

    //检测楼层
    $floors = array();
    core_select_data("select * from axgo_floor where spaceCode = '".$spaces[0]['code']."' limit 1", $floors);
    if(isset($floors[0])){
        $data = '{"status":"error","code":"1","msg":"空间下存在楼层不能删除"}';
        _response($data);
        exit;
    }

    core_query_data("delete from axgo_space where id = ".$spaces[0]['id']);

    $data = '{"status":"success","code":"0","msg":"ok"}';
    _response($data);
    exit;
}

function act_user_space_modify(){
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
    $arr['code'] = md5(uniqid(mt_rand(), true));
    $arr['name'] = $_REQUEST['name'];
    $arr['shortName'] = $_REQUEST['shortName'] ? $_REQUEST['shortName'] : '';
    $arr['address'] = $_REQUEST['address'] ? $_REQUEST['address'] : '';
    $arr['type'] = $_REQUEST['type'] ? $_REQUEST['type'] : '';
    $arr['province'] = $_REQUEST['province'] ? $_REQUEST['province'] : '';
    $arr['city'] = $_REQUEST['city'] ? $_REQUEST['city'] : '';
    $arr['region'] = $_REQUEST['region'] ? $_REQUEST['region'] : '';
    $arr['createUserID'] = $users[0]['id'];
    $arr['createUserName'] = $users[0]['realName'];

    $sql = "insert into axgo_space set ".core_db_fmtlist($arr);
    $spaces = array();
    if(!empty($_REQUEST['code'])){
        core_select_data("select * from axgo_space where code = '".$_REQUEST['code']."' limit 1", $spaces);
        if(!isset($spaces[0])){
            $data = '{"status":"error","code":"1","msg":"无效空间"}';
            _response($data);
            exit;
        }
//        if($spaces[0]['createUserID'] != $users[0]['id']){
//            $data = '{"status":"error","code":"1","msg":"无权限操作"}';
//            _response($data);
//            exit;
//        }
        unset($arr['code']);
        unset($arr['createUserID']);
        unset($arr['createUserName']);
        $sql = "update axgo_space set ".core_db_fmtlist($arr)." where id = ".$spaces[0]['id'];
    }
    core_query_data($sql);

    if(!isset($spaces[0])){
        core_select_data("select * from axgo_space where code = '".$arr['code']."' limit 1", $spaces);
    }
    if(!isset($spaces[0])){
        $data = '{"status":"error","code":"1","msg":"新增空间失败"}';
        _response($data);
        exit;
    }

    $groups = array();
    core_select_data("select * from axgo_face_group where spaceCode = '".$spaces[0]['code']."' limit 1", $groups);
    if(!isset($groups[0])){
        $arr = array();
        $arr['name'] = $spaces[0]['name'];
        $arr['spaceCode'] = $spaces[0]['code'];
        $arr['personSetId'] = $spaces[0]['name']."_S".$spaces[0]['id'];
        $arr['createUserID'] = $users[0]['id'];
        $arr['createUserName'] = $users[0]['realName'];
        $arr['createtime'] = time();

        $bool = arcface_creat_group($arr['personSetId'], $msg);
        if(!$bool){
            $data = '{"status":"error","code":"1","msg":"同步创建人员库失败 '.$msg.'"}';
            _response($data);
            exit;
        }
        core_query_data("insert into axgo_face_group set ".core_db_fmtlist($arr));
    }

    $data = '{"status":"success","code":"0","msg":"ok"}';
    _response($data);
    exit;
}

function act_user_spaces(){

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

    $sql = "select * from axgo_space where createUserID = '".$users[0]['id']."'";
    if(!empty($space_admin_codes)){
        $sql .= " or code in (".$space_admin_codes.")";
    }
    $spaces = array();
    $spaces_obj = array();
    core_select_data($sql, $spaces);
    foreach ($spaces as $key => $space) {
        $spaces_obj[$space['code']] = true;
        $spaces[$key]['isAdmin'] = true;
    }

    //获取普通用户绑定的空间
    $user_space_codes = "";
    $axgo_user_group_users = array();
    core_select_data("select * from axgo_user_group_user where userID = '".$users[0]['id']."' and status = '1'", $axgo_user_group_users);
    foreach ($axgo_user_group_users as $axgo_user_group_user) {
        if(isset($spaces_obj[$axgo_user_group_user['spaceCode']])){
            continue;
        }
        $user_space_codes .= $user_space_codes == "" ? "'".$axgo_user_group_user['spaceCode']."'" : ",'".$axgo_user_group_user['spaceCode']."'";
    }
    if(!empty($user_space_codes)){
        $user_spaces = array();
        core_select_data("select * from axgo_space where code in (".$user_space_codes.")", $user_spaces);
        foreach ($user_spaces as $user_space) {
            $user_space['isAdmin'] = false;
            array_push($spaces, $user_space);
        }
    }

    $data = '{"status":"success","code":"0","msg":"ok", "data":'.json_encode($spaces).'}';
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