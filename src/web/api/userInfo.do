<?php
require(dirname(__FILE__)."/../../lib/core.pms");
if(empty($_SERVER['HTTP_AUTHORIZATION']) || strpos($_SERVER['HTTP_AUTHORIZATION'],"Bearer ") === FALSE){
    echo core_response(403, "Token已过期，请重新登陆");
    exit;
}

$token = substr($_SERVER['HTTP_AUTHORIZATION'], 7, strlen($_SERVER['HTTP_AUTHORIZATION']) - 7);
$userInfo = Jwt::verifyToken($token);
if(!$userInfo){
    echo core_response(403, "Token已过期，请重新登陆");
    exit;
}

//后续完善对应功能
$data = array();
$data['roles'] = array("Admin");
$data['ability'] = array("READ", "WRITE", "DELETE");
$data['username'] = $userInfo['userName'];
$data['avatar'] = "https://i.gtimg.cn/club/item/face/img/8/15918_100.gif";
echo core_response(200, "success", $data);
exit;
?>