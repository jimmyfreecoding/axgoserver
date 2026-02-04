<?php
require(dirname(__FILE__)."/../../../lib/core.pms");

$params = json_decode(file_get_contents("php://input"), true);
if($params){
    $_REQUEST += $params;
}

if(empty($_REQUEST['act'])){
    $data = '{"status":"error","code":"401","msg":"无效请求"}';
    _response($data);
    exit;
}

switch ($_REQUEST['act']) {
    case 'book_modify':
        act_book_modify();
        break;
    case 'book_list':
        act_book_list();
        break;
    case 'book_detail':
        act_book_detail();
        break;
    case 'book_remove':
        act_book_remove();
        break;
    case 'book_cancel':
        act_book_cancel();
        break;
    case 'book_done':
        act_book_done();
        break;

    case 'mroom_list':
        act_mroom_list();
        break;
    default:
        $data = '{"status":"error","code":"401","msg":"请求无效"}';
        _response($data);
        break;
}



function act_mroom_list(){

    $CONF = &$GLOBALS['CONF'];

    if(empty($_REQUEST['unionid']) || empty($_REQUEST['spaceCode'])){
        $data = '{"status":"error","code":"1","msg":"无效请求用户"}';
        _response($data);
        exit;
    }

    $users = array();
    core_select_data("select * from axgo_user where unionid = '".$_REQUEST['unionid']."' limit 1", $users);
    if(!isset($users[0])){
        $data = '{"status":"error","code":"1","msg":"无效用户"}';
        _response($data);
        exit;
    }

    $group_users = array();
    core_select_data("select * from axgo_user_group_user where spaceCode = '".$_REQUEST['spaceCode']."' and userID = '".$users[0]['id']."' and status = '1' limit 1", $group_users);
    if(!isset($group_users[0])){
        $data = '{"status":"error","code":"1","msg":"非该空间用户或未审核"}';
        _response($data);
        exit;
    }

    $result = array();
    $mrooms = array();
    core_select_data("select * from axgo_mroom where spaceCode = '".$_REQUEST['spaceCode']."' and flag = '1' and status = 0 order by sortnum DESC", $mrooms);
    foreach ($mrooms as $mroom) {
        $arr = array();
        $arr['roomId'] = $mroom['id'];
        $arr['title'] = $mroom['room_name'];
        $arr['personNum'] = $mroom['capacity'];
        $file_dir = "/pub/mroom/coverImage/".$mroom['id'].".jpg";
        if(file_exists($CONF['dir_data'].$file_dir)){
            $arr['coverImagePath'] = $file_dir;
        }

        //预定会议
        $arr['books'] = array();
        $books = array();
        core_select_data("select * from axgo_book where spaceCode = '".$_REQUEST['spaceCode']."' and mroom_id = '".$mroom['id']."' order by time_start DESC", $books);
        foreach ($books as $book) {
            $book_arr = array();
            $book_arr['time_start'] = date("Y-m-d H:i", $book['time_start']);
            $book_arr['time_stop'] = date("Y-m-d H:i", $book['time_stop']);
            $book_arr['title'] = $book['subject'];
            $book_arr['id'] = $book['id'];
            $book_arr['booker_name'] = $book['booker_name'];
            array_push($arr['books'], $book_arr);
        }

        array_push($result, $arr);
    }

    $data = '{"status":"success","code":"0","msg":"ok", "data":'.json_encode($result).'}';
    _response($data);
    exit;
}


function act_book_remove(){

    if(empty($_REQUEST['unionid']) || empty($_REQUEST['spaceCode']) || empty($_REQUEST['id'])){
        $data = '{"status":"error","code":"1","msg":"无效请求用户"}';
        _response($data);
        exit;
    }

    $users = array();
    core_select_data("select * from axgo_user where unionid = '".$_REQUEST['unionid']."' limit 1", $users);
    if(!isset($users[0])){
        $data = '{"status":"error","code":"1","msg":"无效用户"}';
        _response($data);
        exit;
    }

    $group_users = array();
    core_select_data("select * from axgo_user_group_user where spaceCode = '".$_REQUEST['spaceCode']."' and userID = '".$users[0]['id']."' and status = '1' limit 1", $group_users);
    if(!isset($group_users[0])){
        $data = '{"status":"error","code":"1","msg":"非该空间用户"}';
        _response($data);
        exit;
    }

    $books = array();
    core_select_data("select * from axgo_book where id = '".$_REQUEST['id']."'", $books);
    if(!isset($books[0]) || $books[0]['booker_id'] != $users[0]['id']){
        $data = '{"status":"error","code":"1","msg":"无效会议或无权限"}';
        _response($data);
        exit;
    }
    core_select_data("update axgo_book set flag = '1' where id = '".$books[0]['id']."'");

    $data = '{"status":"success","code":"0","msg":"ok"}';
    _response($data);
    exit;
}


function act_book_cancel(){

    if(empty($_REQUEST['unionid']) || empty($_REQUEST['spaceCode']) || empty($_REQUEST['id'])){
        $data = '{"status":"error","code":"1","msg":"无效请求用户"}';
        _response($data);
        exit;
    }

    $users = array();
    core_select_data("select * from axgo_user where unionid = '".$_REQUEST['unionid']."' limit 1", $users);
    if(!isset($users[0])){
        $data = '{"status":"error","code":"1","msg":"无效用户"}';
        _response($data);
        exit;
    }

    $group_users = array();
    core_select_data("select * from axgo_user_group_user where spaceCode = '".$_REQUEST['spaceCode']."' and userID = '".$users[0]['id']."' and status = '1' limit 1", $group_users);
    if(!isset($group_users[0])){
        $data = '{"status":"error","code":"1","msg":"非该空间用户"}';
        _response($data);
        exit;
    }

    $books = array();
    core_select_data("select * from axgo_book where id = '".$_REQUEST['id']."'", $books);
    if(!isset($books[0]) || $books[0]['booker_id'] != $users[0]['id']){
        $data = '{"status":"error","code":"1","msg":"无效会议或无权限"}';
        _response($data);
        exit;
    }

    //未开始会议可取消
    $current_time = time();
    if($books[0]['time_start'] <= $current_time){
        $data = '{"status":"error","code":"1","msg":"会议已开始或已结束无法取消"}';
        _response($data);
        exit;
    }

    core_select_data("update axgo_book set flag = '2' where id = '".$books[0]['id']."'");

    $data = '{"status":"success","code":"0","msg":"ok"}';
    _response($data);
    exit;
}


function act_book_done(){

    if(empty($_REQUEST['unionid']) || empty($_REQUEST['spaceCode']) || empty($_REQUEST['id'])){
        $data = '{"status":"error","code":"1","msg":"无效请求用户"}';
        _response($data);
        exit;
    }

    $users = array();
    core_select_data("select * from axgo_user where unionid = '".$_REQUEST['unionid']."' limit 1", $users);
    if(!isset($users[0])){
        $data = '{"status":"error","code":"1","msg":"无效用户"}';
        _response($data);
        exit;
    }

    $group_users = array();
    core_select_data("select * from axgo_user_group_user where spaceCode = '".$_REQUEST['spaceCode']."' and userID = '".$users[0]['id']."' and status = '1' limit 1", $group_users);
    if(!isset($group_users[0])){
        $data = '{"status":"error","code":"1","msg":"非该空间用户"}';
        _response($data);
        exit;
    }

    $books = array();
    core_select_data("select * from axgo_book where id = '".$_REQUEST['id']."'", $books);
    if(!isset($books[0]) || $books[0]['booker_id'] != $users[0]['id']){
        $data = '{"status":"error","code":"1","msg":"无效会议或无权限"}';
        _response($data);
        exit;
    }

    //正在进行的开始会议可提前结束
    $current_time = time();
    if($books[0]['time_start'] > $current_time || $books[0]['time_stop'] < $current_time){
        $data = '{"status":"error","code":"1","msg":"会议未开始或已结束无法提前结束"}';
        _response($data);
        exit;
    }

    core_select_data("update axgo_book set time_stop = '".$current_time."' where id = '".$books[0]['id']."'");

    $data = '{"status":"success","code":"0","msg":"ok"}';
    _response($data);
    exit;
}


function act_book_detail(){

    if(empty($_REQUEST['unionid']) || empty($_REQUEST['spaceCode']) || empty($_REQUEST['id'])){
        $data = '{"status":"error","code":"1","msg":"无效请求用户"}';
        _response($data);
        exit;
    }

    $users = array();
    core_select_data("select * from axgo_user where unionid = '".$_REQUEST['unionid']."' limit 1", $users);
    if(!isset($users[0])){
        $data = '{"status":"error","code":"1","msg":"无效用户"}';
        _response($data);
        exit;
    }

    $group_users = array();
    core_select_data("select * from axgo_user_group_user where spaceCode = '".$_REQUEST['spaceCode']."' and userID = '".$users[0]['id']."' and status = '1' limit 1", $group_users);
    if(!isset($group_users[0])){
        $data = '{"status":"error","code":"1","msg":"非该空间用户"}';
        _response($data);
        exit;
    }

    $books = array();
    core_select_data("select * from axgo_book where id = '".$_REQUEST['id']."'", $books);
    if(!isset($books[0]) || $books[0]['booker_id'] != $users[0]['id']){
        $data = '{"status":"error","code":"1","msg":"无效会议或无权限"}';
        _response($data);
        exit;
    }
    $books[0]['members'] = array();
    core_select_data("select * from axgo_book_member where book_id = '".$books[0]['id']."'", $books[0]['members']);
    $books[0]['memberNames'] = "";
    $books[0]['memberUsers'] = array();
    foreach ($books[0]['members'] as $member) {
        $books[0]['memberNames'] .= $books[0]['memberNames'] == "" ? $member['user_name'] : ",".$member['user_name'];
        array_push($books[0]['memberUsers'], array(
            "id" => $member['user_id'],
            "realName" => $member['user_name'],
        ));
    }

    $books[0]['bookStartDate'] = date("Y-m-d", $books[0]['time_start']);
    $books[0]['bookStartTime'] = date("H:i", $books[0]['time_start']);
    $books[0]['bookStopTime'] = date("H:i", $books[0]['time_stop']);

    //会议状态， 待召开，已召开，已取消
    $current_time = time();
    $books[0]['status'] = "";
    if($books[0]['flag'] == 2){
        $books[0]['status'] = "cancel";
    }elseif($books[0]['time_start'] > $current_time){
        $books[0]['status'] = "todo";
    }elseif($books[0]['time_start'] <= $current_time && $books[0]['time_stop'] >= $current_time){
        $books[0]['status'] = "doing";
    }elseif($books[0]['time_stop'] < $current_time){
        $books[0]['status'] = "done";
    }

    $data = '{"status":"success","code":"0","msg":"ok", "data":'.json_encode($books[0]).'}';
    _response($data);
    exit;
}

function act_book_list(){

    if(empty($_REQUEST['unionid']) || empty($_REQUEST['spaceCode'])){
        $data = '{"status":"error","code":"1","msg":"无效请求用户"}';
        _response($data);
        exit;
    }

    $users = array();
    core_select_data("select * from axgo_user where unionid = '".$_REQUEST['unionid']."' limit 1", $users);
    if(!isset($users[0])){
        $data = '{"status":"error","code":"1","msg":"无效用户"}';
        _response($data);
        exit;
    }

    $group_users = array();
    core_select_data("select * from axgo_user_group_user where spaceCode = '".$_REQUEST['spaceCode']."' and userID = '".$users[0]['id']."' and status = '1' limit 1", $group_users);
    if(!isset($group_users[0])){
        $data = '{"status":"error","code":"1","msg":"非该空间用户"}';
        _response($data);
        exit;
    }

    $where = "";
    if(!empty($_REQUEST['mroom_id'])){
        $mrooms = array();
        core_select_data("select * from axgo_mroom where id = '".$_REQUEST['mroom_id']."'", $mrooms);
        if(!isset($mrooms[0]) || $mrooms[0]['spaceCode'] != $_REQUEST['spaceCode']){
            $data = '{"status":"error","code":"1","msg":"无效会议室或无权限"}';
            _response($data);
            exit;
        }
        $where = " and mroom_id = '".$mrooms[0]['id']."' ";
    }

    $books = array();
    core_select_data("select * from axgo_book where booker_id = '".$users[0]['id']."' and spaceCode = '".$_REQUEST['spaceCode']."' and flag != '1' ".$where." order by time_start DESC", $books);

    $current_time = time();
    $result = array();
    $result['todoBooks'] = array();
    $result['doingBooks'] = array();
    $result['doneBooks'] = array();
    $result['cancelBooks'] = array();
    foreach ($books as $key => $book) {
        $books[$key]['timeStartShow'] = date("Y-m-d H:i", $book['time_start']);
        $books[$key]['timeStopShow'] = date("Y-m-d H:i", $book['time_stop']);
        if(date("Y-m-d", $book['time_start']) == date("Y-m-d", $book['time_stop'])){
            $books[$key]['timeStopShow'] = date("H:i", $book['time_stop']);
        }

        //会议状态， 待召开，已召开，已取消
        $books[$key]['status'] = "";
        if($book['flag'] == 2){
            $books[$key]['status'] = "cancel";
            array_push($result['cancelBooks'], $books[$key]);
        }elseif($book['time_start'] > $current_time){
            $books[$key]['status'] = "todo";
            array_push($result['todoBooks'], $books[$key]);
        }elseif($book['time_start'] <= $current_time && $book['time_stop'] >= $current_time){
            $books[$key]['status'] = "doing";
            array_push($result['doingBooks'], $books[$key]);
        }elseif($book['time_stop'] < $current_time){
            $books[$key]['status'] = "done";
            array_push($result['doneBooks'], $books[$key]);
        }
    }

    $data = '{"status":"success","code":"0","msg":"ok", "data":'.json_encode($result).'}';
    _response($data);
    exit;
}

function act_book_modify(){

    if(empty($_REQUEST['unionid']) ||
        empty($_REQUEST['spaceCode']) ||
        empty($_REQUEST['mroom_id']) ||
        empty($_REQUEST['subject']) ||
        empty($_REQUEST['date_start']) ||
        empty($_REQUEST['date_stop']) ||
        empty($_REQUEST['time_start']) ||
        empty($_REQUEST['time_stop'])){
        $data = '{"status":"error","code":"1","msg":"无效请求用户"}';
        _response($data);
        exit;
    }

    $users = array();
    core_select_data("select * from axgo_user where unionid = '".$_REQUEST['unionid']."' limit 1", $users);
    if(!isset($users[0])){
        $data = '{"status":"error","code":"1","msg":"无效用户"}';
        _response($data);
        exit;
    }

    $group_users = array();
    core_select_data("select * from axgo_user_group_user where spaceCode = '".$_REQUEST['spaceCode']."' and userID = '".$users[0]['id']."' and status = '1' limit 1", $group_users);
    if(!isset($group_users[0])){
        $data = '{"status":"error","code":"1","msg":"非空间用户不能预定"}';
        _response($data);
        exit;
    }

    $mrooms = array();
    core_select_data("select * from axgo_mroom where id = '".$_REQUEST['mroom_id']."'", $mrooms);
    if(!isset($mrooms[0]) || $mrooms[0]['spaceCode'] != $_REQUEST['spaceCode']){
        $data = '{"status":"error","code":"1","msg":"无效会议室或无权限"}';
        _response($data);
        exit;
    }
    if ($mrooms[0]['flag'] == '0') {
        $data = '{"status":"error","code":"2","msg":"会议室未开放"}';
        _response($data);
        exit;
    }

    $book_week = date("w",strtotime($_REQUEST['date_start']));
    if (strpos(",".$mrooms[0]['book_day'].",", ",".$book_week.",") === FALSE) {
        $data = '{"status":"error","code":"3","msg":"不在会议室规定预定周期内"}';
        _response($data);
        exit;
    }

    $current_time = time();
    $book_time_stop = strtotime($_REQUEST['date_stop'].' '.$_REQUEST['time_stop']);
    $mrooms[0]['max_leadtime'] = intval($mrooms[0]['max_leadtime']);  //day
    if ($current_time + ($mrooms[0]['max_leadtime'] * 86400) < $book_time_stop) {
        $data = '{"status":"error","code":"4","msg":"超出规定提前时间, 限制提前 '.$mrooms[0]['max_leadtime'].' 天"}';
        _response($data);
        exit;
    }

    $book_time_start = strtotime($_REQUEST['date_start'].' '.$_REQUEST['time_start']);
    $time_start_allow = strtotime($_REQUEST['date_start'].' '.$mrooms[0]['book_start']);
    $time_stop_allow = strtotime($_REQUEST['date_stop'].' '.$mrooms[0]['book_end']);
    if ($book_time_start < $time_start_allow || $book_time_stop > $time_stop_allow) {
        $data = '{"status":"error","code":"5","msg":"不在会议室规定预定时间内, 限制在 '.$mrooms[0]['book_start'].' ~ '.$mrooms[0]['book_end'].'."}';
        _response($data);
        exit;
    }
    if (empty($_REQUEST['id']) && ($book_time_start <= $current_time || $book_time_start >= $book_time_stop)) {
        $data = '{"status":"error","code":"9","msg":"无效开始时间"}';
        _response($data);
        exit;
    }

    $mrooms[0]['max_duration'] = intval($mrooms[0]['max_duration']);  //min
    if ($book_time_stop - $book_time_start > ($mrooms[0]['max_duration'] * 60)) {
        $data = '{"status":"error","code":"6","msg":"超出单会议时长限制, 允许 '.$mrooms[0]['max_duration'].' 分钟"}';
        _response($data);
        exit;
    }

//    $members = json_decode($_REQUEST['member'], true);
//    if (count($members) > $mrooms[0]['capacity']) {
//        $data = '{"status":"error","code":"7","msg":"超出会议室允许人数, 允许 '.$mrooms[0]['capacity'].' 人"}';
//        _response($data);
//        exit;
//    }


    $book_date_start = strtotime($_REQUEST['date_start']);
    $sql22 = 'select id,time_start,time_stop from axgo_book where mroom_id = '.$_REQUEST['mroom_id'].' and time_start between '.$book_date_start.' and '.($book_date_start + 86400);
    if (!empty($_REQUEST['id'])) {
        $sql22 .= ' and id != '.$_REQUEST['id'];
    }
    $books_current_date = array();
    core_select_data($sql22, $books_current_date);
    foreach ($books_current_date as $book_current_date) {
        //内包含+外包含+交叉
        if (($book_time_start <= $book_current_date['time_start'] && $book_time_stop >= $book_current_date['time_stop']) ||
            ($book_time_start >= $book_current_date['time_start'] && $book_time_start < $book_current_date['time_stop']) ||
            ($book_time_stop > $book_current_date['time_start'] && $book_time_stop <= $book_current_date['time_stop'])) {
            $data = '{"status":"error","code":"8","msg":"与其他会议时间冲突"}';
            _response($data);
            exit;
        }
    }

    $arr = array();
    $arr['mroom_id'] = $mrooms[0]['id'];
    $arr['mroom_name'] = $mrooms[0]['room_name'];
    $arr['spaceCode'] = $_REQUEST['spaceCode'];
    $arr['subject'] = $_REQUEST['subject'];
    $arr['time_start'] = $book_time_start;
    $arr['time_stop'] = $book_time_stop;
    $arr['booker_id'] = $users[0]['id'];
    $arr['booker_name'] = $users[0]['realName'];
    $arr['note'] = $_REQUEST['note'];
    $arr['createtime'] = $current_time;
    $sql = 'insert into axgo_book set '.core_db_fmtlist($arr);

    $books = array();
    if (!empty($_REQUEST['id'])) {
        unset($arr['createtime']);
        core_select_data('select * from axgo_book where id = '.$_REQUEST['id'], $books);
        if(!isset($books[0])){
            $data = '{"status":"error","code":"8","msg":"无效会议"}';
            _response($data);
            exit;
        }
        $book = $books[0];
        if ($book['booker_id'] != $users[0]['id']) {
            $data = '{"status":"error","code":"11","msg":"你没有权限修改此会议"}';
            _response($data);
            exit;
        }
        if ($book['time_stop'] <= $current_time) {
            $data = '{"status":"error","code":"12","msg":"会议已过期"}';
            _response($data);
            exit;
        } elseif ($book['time_start'] <= $current_time && $book_time_stop <= $current_time) {
            $data = '{"status":"error","code":"13","msg":"会议结束时间有误"}';
            _response($data);
            exit;
        } elseif ($book['time_start'] <= $current_time && $book_time_stop > $current_time) {
            unset($arr['time_start']);
        } elseif ($book_time_start <= $current_time) {
            $data = '{"status":"error","code":"9","msg":"会议开始时间有误"}';
            _response($data);
            exit;
        }
        $sql = 'update axgo_book set '.core_db_fmtlist($arr).' where id = '.$_REQUEST['id'];
    }
    core_query_data($sql);

    if(!isset($books[0])){
        core_select_data("select * from axgo_book where mroom_id = '".$_REQUEST['mroom_id']."' and subject = '".$_REQUEST['subject']."' and createtime = '".$current_time."' limit 1", $books);
    }
    if(!isset($books[0])){
        $data = '{"status":"error","code":"9","msg":"新增会议失败"}';
        _response($data);
        exit;
    }

    //参会人
    core_query_data("delete from axgo_book_member where book_id = '".$books[0]['id']."'");
    $members = json_decode($_REQUEST['members'], true);
    foreach ($members as $member) {
        $arr = array();
        $arr['book_id'] = $books[0]['id'];
        $arr['user_id'] = $member['id'];
        $arr['user_name'] = $member['realName'];
        core_query_data('insert into axgo_book_member set '.core_db_fmtlist($arr));
    }

    //新预定会议通知，未完成

    //预定会议室触发绑定设备的数据下发
    $mroom_devices = array();
    core_select_data("select * from axgo_mroom_device where mroomID = '".$mrooms[0]['id']."'", $mroom_devices);
    foreach ($mroom_devices as $mroom_device) {
        $device_template_data_syncs = array();
        core_select_data("select * from axgo_device_template_data_sync where deviceID = '".$mroom_device['deviceID']."' and templateType = 'doorplate' and relationID = '".$mrooms[0]['id']."' limit 1", $device_template_data_syncs);
        if(isset($device_template_data_syncs[0])){
            continue;
        }
        $arr = array();
        $arr['deviceID'] = $mroom_device['deviceID'];
        $arr['macaddr'] = $mroom_device['macaddr'];
        $arr['templateType'] = "doorplate";
        $arr['relationID'] = $mrooms[0]['id'];
        $arr['createtime'] = time();
        core_query_data('insert into axgo_device_template_data_sync set '.core_db_fmtlist($arr));
    }

    $data = '{"status":"success","code":"0","msg":"ok"}';
    _response($data);
    exit;
}

function _response($data){
    if (isset($_REQUEST['callback'])) {
        $data = $_REQUEST['callback'].'('.$data.')';
    }
    echo $data;
}
?>