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

$templateInfo = array();
$templateInfo['uid'] = md5(uniqid(mt_rand(), true));
$templateInfo['name'] = $_REQUEST['name'];
$templateInfo['updateType'] = "0";
$templateInfo['templateDesc'] = $_REQUEST['templateDesc'];
$templateInfo['entry'] = $_REQUEST['entry'];
$templateInfo['tmpdata'] = $_REQUEST['tmpdata'];
$templateInfo['type'] = $_REQUEST['type'];
$templateInfo['auth_macaddr'] = $_REQUEST['auth_macaddr'];
$templateInfo['online'] = intval($_REQUEST['online']);
$templateInfo['templateType'] = $_REQUEST['templateType'];
$templateInfo['createtime'] = time();

$sql = "insert into axgo_module set ".core_db_fmtlist($templateInfo);
if (!empty($_REQUEST['id'])) {
    unset($templateInfo['createtime']);
    unset($templateInfo['uid']);
    $sql = "update axgo_module set ".core_db_fmtlist($templateInfo)." where id = '".$_REQUEST['id']."'";
}

core_query_data($sql);

echo core_response(200, "保存成功");
exit;
?>