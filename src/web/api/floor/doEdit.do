<?php
require(dirname(__FILE__)."/../../../lib/core.pms");

$params = json_decode(file_get_contents("php://input"), true);
if($params){
    $_REQUEST += $params;
}

$data = array();
if(empty($_REQUEST['spaceCode'])){
    echo core_response(500, "无效请求");
    exit;
}
if(empty($_REQUEST['name'])){
    echo core_response(500, "请补充楼层名称");
    exit;
}

$spaces = array();
core_select_data("select * from axgo_space where code = '".$_REQUEST['spaceCode']."' limit 1", $spaces);
if(!isset($spaces[0])){
    echo core_response(500, "无效空间信息");
    exit;
}

$floorInfo = array();
$floorInfo['spaceCode'] = $spaces[0]['code'];
$floorInfo['code'] = md5(uniqid(mt_rand(), true));
$floorInfo['name'] = $_REQUEST['name'];
$floorInfo['sortIndex'] = intval($_REQUEST['sortIndex']);
$floorInfo['description'] = $_REQUEST['description'];
$floorInfo['createtime'] = time();

$sql = "insert into axgo_floor set ".core_db_fmtlist($floorInfo);
if (!empty($_REQUEST['id'])) {
    unset($spaceInfo['createtime']);
    unset($spaceInfo['code']);
    $sql = "update axgo_floor set ".core_db_fmtlist($floorInfo)." where id = '".$_REQUEST['id']."'";
}
core_query_data($sql);

echo core_response(200, "保存成功");
exit;
?>