<?php
require(dirname(__FILE__)."/../../../lib/core.pms");

$spaces = array();
core_select_data("select * from axgo_space order by sortIndex DESC", $spaces);

$data = array();
$data['list'] = $spaces;
$data['total'] = count($spaces);
echo core_response(200, "success", $data);
exit;
?>