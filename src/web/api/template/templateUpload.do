<?php
require(dirname(__FILE__)."/../../../lib/core.pms");

$params = json_decode(file_get_contents("php://input"), true);
if($params){
    $_REQUEST += $params;
}

if(empty($_REQUEST['uid']) || !isset($_FILES['templateFile'])){
    $data = '{"status":"error","code":500,"msg":"无效模板或无效模板文件"}';
    echo $data;
    exit;
}


$file_dir = "/apps/axruntime/www.axgo.com/module";
$file_ext = pathinfo($_FILES['templateFile']['name'], PATHINFO_EXTENSION);
if(strtoupper($file_ext) != "ZIP"){
    $data = '{"status":"error","code":500,"msg":"文件类型必须是ZIP格式"}';
    echo $data;
    exit;
}

$file_name = $_REQUEST['uid'].".zip";
$file_path = $file_dir."/".$file_name;

if(!move_uploaded_file($_FILES['templateFile']['tmp_name'], $file_path)){
    $data = '{"status":"error","code":500,"msg":"上传文件失败"}';
    echo $data;
    exit;
}

if(!file_exists($file_path)){
    $data = '{"status":"error","code":500,"msg":"上传模板文件失败02"}';
    echo $data;
    exit;
}

//更新数据库md5
$arr = array();
$arr['pkg_md5'] = md5_file($file_path);
$arr['pkg_url'] = "https://www.ax-go.com/module/".$file_name;
core_query_data("update axgo_module set ".core_db_fmtlist($arr)." where uid = '".$_REQUEST['uid']."' limit 1");

$data = '{"status":"success","code":200,"msg":"ok", "data":{"fileName":"'.$file_name.'", "filePath":"/module/'.$file_name.'"}}';
echo $data;
exit;
?>