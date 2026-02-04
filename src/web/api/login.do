<?php
require(dirname(__FILE__)."/../../lib/core.pms");
$params = json_decode(file_get_contents("php://input"), true);
if($params){
    $_REQUEST += $params;
}

if(empty($_REQUEST['username']) || empty($_REQUEST['password'])){
    echo core_response(500, "请输入正确的账号或密码");
    exit;
}

$users = array();
core_select_data("select * from axgo_user where userName = '".$_REQUEST['username']."' limit 1", $users);
if(!isset($users[0]) || $users[0]['passwd'] !== $_REQUEST['password']){
    echo core_response(500, "请输入正确的账号或密码");
    exit;
}
//后续可增加自定义认证信息
$userInfo = array();
$userInfo['userName'] = $users[0]['userName'];
$token = Jwt::getToken($userInfo);
if(!$token){
    echo core_response(500, "登陆失败，请重新登陆");
    exit;
}

$data = array();
$data['token'] = $token;
echo core_response(200, "success", $data);
exit;
?>