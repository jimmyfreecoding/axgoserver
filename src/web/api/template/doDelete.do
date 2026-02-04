<?php
require(dirname(__FILE__)."/../../../lib/core.pms");

$params = json_decode(file_get_contents("php://input"), true);
if($params){
    $_REQUEST += $params;
}

$data = array();
if(empty($_REQUEST['ids'])){
    echo core_response(500, "无效请求");
    exit;
}

core_query_data("delete from axgo_module where id in (".$_REQUEST['ids'].")");

echo core_response(200, "删除成功");
exit;
?>