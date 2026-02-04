<?php
$file_dir = "/tmp";
$file_ext = pathinfo($_FILES['myFile']['name'], PATHINFO_EXTENSION);
$file_name = md5(uniqid(mt_rand(), true));
if(!empty($file_ext)){
    $file_name .= ".".$file_ext;
}

$params = json_decode(file_get_contents("php://input"), true);
if($params){
    $_REQUEST += $params;
}

if(!move_uploaded_file($_FILES['myFile']['tmp_name'], $file_dir."/".$file_name)){
    $data = '{"status":"error","code":500,"msg":"上传文件失败"}';
    echo $data;
    exit;
}

if(!file_exists($file_dir."/".$file_name)){
    $data = '{"status":"error","code":500,"msg":"上传文件失败2"}';
    echo $data;
    exit;
}

$data = '{"status":"success","code":200,"msg":"ok", "data":{"fileName":"'.$file_name.'", "filePath":"/pub/tfcyyz/bp/'.$file_name.'"}}';
echo $data;
exit;
?>