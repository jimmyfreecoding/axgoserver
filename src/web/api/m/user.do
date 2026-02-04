<?php
require(dirname(__FILE__)."/../../../lib/core.pms");

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
    case 'user_detail':
        act_user_detail();
        break;
    case 'user_modify':
        act_user_modify();
        break;
    case 'user_headimage_upload':
        act_user_headimage_upload();
        break;
    default:
        $data = '{"status":"error","code":"401","msg":"请求无效"}';
        _response($data);
        break;
}

function act_user_headimage_upload(){

    $CONF = &$GLOBALS['CONF'];

    if (empty($_REQUEST['unionid'])) {
        $data = '{"status":"error","code":"1","msg":"请求无效用户"}';
        _response($data);
        exit;
    }

    if(empty($CONF['dir_data'])){
        $data = '{"status":"error","code":"1","msg":"服务器错误"}';
        _response($data);
        exit;
    }

    $users = array();
    core_select_data("select * from axgo_user where unionid = '".$_REQUEST['unionid']."' limit 1", $users);
    if(!isset($users[0])){
        $data = '{"status":"error","code":"1","msg":"请先绑定用户信息后再修改头像"}';
        _response($data);
        exit;
    }


    $file_dir = $CONF['dir_data']."/pub/headImg";
    if(!is_dir($file_dir)){
        @mkdir($file_dir, 0777, true);
    }
    $file_name = $_REQUEST['unionid'].".jpg";

    if(!move_uploaded_file($_FILES['head']['tmp_name'], $file_dir."/".$file_name)){
        $data = '{"status":"error","code":"1","msg":"上传头像失败"}';
        _response($data);
        exit;
    }

    if(!file_exists($file_dir."/".$file_name)){
        $data = '{"status":"error","code":"1","msg":"上传头像失败2"}';
        _response($data);
        exit;
    }

    $data = '{"status":"success","code":"0","msg":"ok"}';
    _response($data);
    exit;
}
function act_user_modify(){
    if(empty($_REQUEST['unionid'])){
        $data = '{"status":"error","code":"1","msg":"无效请求用户"}';
        _response($data);
        exit;
    }
    $arr = array();
    $arr['unionid'] = $_REQUEST['unionid'];
    $arr['realName'] = $_REQUEST['realName'];
    $arr['mobile'] = $_REQUEST['mobile'];
    $arr['orgName'] = $_REQUEST['orgName'];
    $arr['ocuptionName'] = $_REQUEST['ocuptionName'];

    $users = array();
    core_select_data("select * from axgo_user where unionid = '".$_REQUEST['unionid']."' limit 1", $users);
    if(isset($users[0])){
        unset($arr['unionid']);
        core_query_data("update axgo_user set ".core_db_fmtlist($arr)." where id = ".$users[0]['id']);
    }else{
        core_query_data("insert into axgo_user set ".core_db_fmtlist($arr));
    }
    $data = '{"status":"success","code":"0","msg":"ok"}';
    _response($data);
    exit;
}

function act_user_detail(){

    $CONF = &$GLOBALS['CONF'];

    if(empty($_REQUEST['unionid'])){
        $data = '{"status":"error","code":"1","msg":"无效请求用户"}';
        _response($data);
        exit;
    }
    $users = array();
    core_select_data("select * from axgo_user where unionid = '".$_REQUEST['unionid']."' limit 1", $users);
    $data = array();
    if(isset($users[0])){
        $data = $users[0];
        if(file_exists($CONF['dir_data']."/pub/headImg/".$users[0]['unionid'].".jpg")){
            $data['headImgPath'] = "/pub/headImg/".$users[0]['unionid'].".jpg?v=".time();
        }
    }

    $data['spaceAdmin'] = false;
    if(!empty($_REQUEST['spaceCode'])){
        $spaces = array();
        core_select_data("select * from axgo_space where code = '".$_REQUEST['spaceCode']."' limit 1", $spaces);

        $space_admins = array();
        core_select_data("select * from axgo_space_admin where spaceCode = '".$_REQUEST['spaceCode']."' and userID = '".$users[0]['id']."' limit 1", $space_admins);
        if((isset($spaces[0]) && $spaces[0]['createUserID'] == $users[0]['id']) || isset($space_admins[0])){
            $data['spaceAdmin'] = true;
        }
    }

    $data = '{"status":"success","code":"0","msg":"ok", "data":'.json_encode($data).'}';
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