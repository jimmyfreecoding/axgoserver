<?php
require(dirname(__FILE__)."/../../../lib/core.pms");

$templates = array();
core_select_data("select * from axgo_module", $templates);

$data = array();
$data['list'] = $templates;
$data['total'] = count($templates);
echo core_response(200, "success", $data);
exit;
?>