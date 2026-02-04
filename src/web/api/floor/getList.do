<?php
require(dirname(__FILE__)."/../../../lib/core.pms");

$params = json_decode(file_get_contents("php://input"), true);
if($params){
    $_REQUEST += $params;
}

if(empty($_REQUEST['spaceCode'])){
    echo core_response(500, "无效请求");
    exit;
}

$floors = array();
core_select_data("select * from axgo_floor where spaceCode = '".$_REQUEST['spaceCode']."' order by sortIndex DESC", $floors);

$data = array();
$data['list'] = $floors;
$data['total'] = count($floors);
echo core_response(200, "success", $data);
exit;
?>