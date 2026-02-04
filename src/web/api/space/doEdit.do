<?php
require(dirname(__FILE__)."/../../../lib/core.pms");

$params = json_decode(file_get_contents("php://input"), true);
if($params){
    $_REQUEST += $params;
}

$data = array();
if(empty($_REQUEST['name'])){
    echo core_response(500, "请补充空间名称");
    exit;
}

$spaceInfo = array();
$spaceInfo['code'] = md5(uniqid(mt_rand(), true));
$spaceInfo['name'] = $_REQUEST['name'];
$spaceInfo['shortName'] = $_REQUEST['shortName'];
$spaceInfo['type'] = $_REQUEST['type'];
$spaceInfo['province'] = $_REQUEST['province'];
$spaceInfo['city'] = $_REQUEST['city'];
$spaceInfo['region'] = $_REQUEST['region'];
$spaceInfo['address'] = $_REQUEST['address'];
$spaceInfo['longitude'] = $_REQUEST['longitude'];
$spaceInfo['latitude'] = $_REQUEST['latitude'];
$spaceInfo['tags'] = $_REQUEST['tags'];
$spaceInfo['description'] = $_REQUEST['description'];
$spaceInfo['createtime'] = time();

$sql = "insert into axgo_space set ".core_db_fmtlist($spaceInfo);
if (!empty($_REQUEST['id'])) {
    unset($spaceInfo['createtime']);
    unset($spaceInfo['code']);
    $sql = "update axgo_space set ".core_db_fmtlist($spaceInfo)." where id = '".$_REQUEST['id']."'";
}

core_query_data($sql);

echo core_response(200, "保存成功");
exit;
?>