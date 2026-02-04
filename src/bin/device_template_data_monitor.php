<?php
//ini_set("display_errors","On");
/*
	208-02-01 PuJiang <bristy.pu@gmail.com>
*/
/*---------------------------------------------------------------------
 * include and initization of modules
 *--------------------------------------------------------------------*/
error_reporting(E_ALL); //Everything report
set_time_limit(0);  //Tuneoff time limit
ob_implicit_flush();    //flash
declare(ticks = 1);    //fix som bugs with SIG

/*-------------------------------------------------------------------------
  Basic variables
-------------------------------------------------------------------------*/
$MYCONF = array();  //server variable
$MYCONF['name'] = basename($_SERVER['SCRIPT_NAME']);
$MYCONF['cli_args'] = array();
$MYCONF['basedir'] = dirname(__FILE__);
$MYCONF['runmode'] = 0;
$MYCONF['message_handle'] = null;
$MYCONF['log_file'] = '/var/log/'.$MYCONF['name'].'.log';
$MYCONF['pid'] = null;
$MYCONF['pid_file'] = '/var/run/'.$MYCONF['name'].'.pid';
$MYCONF['isrun'] = true;

// args and options
foreach ($argv as $id=>$each) {
    if ($id===0)
        continue;
    $MYCONF['cli_args'][$each]=true;
}
if (isset($MYCONF['cli_args']['--verbose'])==true) {
    $MYCONF['runmode']=0; // 0 means verbose
	$MYCONF['message_handle'] = fopen("php://stderr","w");
} else {
    $MYCONF['runmode']=1; // 1 means quiet
}
if (isset($MYCONF['cli_args']['--log'])==true) // 如果设置了--log 就开启为记录日志文件模式
	$MYCONF['message_handle'] = fopen($MYCONF['log_file'],"a");

/*-------------------------------------------------------------------------
  init and entry
-------------------------------------------------------------------------*/
// common functions
require($MYCONF['basedir']."/../lib/cli.pms");
require($MYCONF['basedir']."/../lib/core.pms");
// in service mode
// register signal
pcntl_signal(SIGTERM    , 'cli_signal_term');
pcntl_signal(SIGINT     , 'cli_signal_term');
pcntl_signal(SIGHUP     , 'cli_signal_hup');
pcntl_signal(SIGCHLD    , "cli_signal_chld");

cmd_main();
exit;

/*------------------------------------------------------------------------
  run now!
-------------------------------------------------------------------------*/
function cmd_main()
{
	$MYCONF = &$GLOBALS['MYCONF'];
    $ARCFACE = &$GLOBALS['ARCFACE'];

    // run me as background
    if (isset($MYCONF['cli_args']['--quiet']) && $MYCONF['cli_args']['--quiet']==true) {
        $pid = pcntl_fork();
        //fork failed
        if ($pid == -1) {
			cli_message('fork failure! ',3,$MYCONF['message_handle']);
            exit();
        //in parent to close the parent
        } elseif ($pid) {
            exit();
        //in child
        } else {
			usleep(500000); // 子进程如果异常退出内存会导致主进程崩溃(开启SIGCHLD状态下)
        }
    }

    // pid check and process
    posix_setsid();
    umask(0);
    $MYCONF['pid']=posix_getpid();

    // Checking myself in pid and locker make
    if (cli_proc_checkpid($MYCONF['pid_file'],$MYCONF['name']) == true) {
		cli_message('I was alreadly exists in memory, Please kill the old and try me again!',3,$MYCONF['message_handle']);
        exit;
    }
    if (file_put_contents($MYCONF['pid_file'],$MYCONF['pid'],LOCK_EX)===false) {
		cli_message('Write pid file failure, abort.!',3,$MYCONF['message_handle']);
        exit;
    }
	cli_message('[device_template_data_monitor] run at '.$MYCONF['pid'],3,$MYCONF['message_handle']);

	$runloopsec = 1;
	while ($MYCONF['isrun']) {
		cli_message('[device_template_data_monitor] weaked up!',3,$MYCONF['message_handle']);

        $device_template_data_syncs = array();
        core_select_data("select * from axgo_device_template_data_sync limit 20", $device_template_data_syncs);
        foreach($device_template_data_syncs as $device_template_data_sync){
            _sync_device_one_template_data($device_template_data_sync['deviceID'], $device_template_data_sync['relationID'], $device_template_data_sync['templateType']);
            core_query_data("delete from axgo_device_template_data_sync where id = '".$device_template_data_sync['id']."'");
        }

		//exit; //临时测试代码
		//进入下次循环等待
		sleep($runloopsec);
	}
	cli_message('done!',3,$MYCONF['message_handle']);
	exit;
}

function _sync_device_one_template_data($deviceID, $relationID, $templateType){

    $CONF = &$GLOBALS['CONF'];

    //获取对应设备 对应业务类型数据
    $datas = array();
    $dataKey = "";
    if($templateType == "doorplate"){  //会议室类型，获取对应会议室预定数据
        _mroom_books_data($relationID, $datas);
        $dataKey = "books";
        //处理数据
        $new_datas= array();
        foreach ($datas as $data) {
            $arr = array();
            $arr['subject'] = $data['subject'];
            $arr['sTime'] = date("Y-m-d H:i", $data['time_start']);
            $arr['eTime'] = date("Y-m-d H:i", $data['time_stop']);
            array_push($new_datas, $arr);
        }
        $datas = $new_datas;
    }

    if(empty($dataKey)){
        return false;
    }

    //更新设备对应数据，不通业务类型更新不通数据字段，需要提前定义好
    $device_module_datas = array();
    core_select_data("select * from axgo_device_module_data where deviceID = '".$deviceID."' and templateType = '".$templateType."'", $device_module_datas);
    foreach($device_module_datas as $device_module_data){
        $templateData = json_decode($device_module_data['templateData'], true);
        if(!$templateData){
            continue;
        }
        $templateData[$dataKey] = $datas;
        core_query_data("update axgo_device_module_data set templateData = '".json_encode($templateData, JSON_UNESCAPED_UNICODE)."' where id = '".$device_module_data['id']."'");

        //下发模板数据
        $job = array();
        $job['macaddr'] = $device_module_data['macaddr'];
        $job['command'] = array();
        $job['command']['type'] = "template_data";
        $job['command']['templateUUID'] = $device_module_data['template'];
        $job['command']['data'] = $templateData;
        file_put_contents($CONF['mosquitto_tmpdir']."/".uniqid("MQTT"), json_encode($job), LOCK_EX);
    }
}

function _mroom_books_data($relationID, &$books){
    $mrooms = array();
    core_select_data("select * from axgo_mroom where id = '".$relationID."'", $mrooms);
    if(!isset($mrooms[0])){
        return false;
    }
    $current_time = time();
    core_select_data("select * from axgo_book where mroom_id = '".$mrooms[0]['id']."' and ((time_stop >= ".$current_time." and time_start <= '".$current_time."') or time_start >= '".$current_time."') order by time_start ASC", $books);
    return true;
}

/*---------------------------------------------------------------------------------
  负责处理 SIGNAL 本程序相关信号
---------------------------------------------------------------------------------*/

// 发现sig_hup信号以后记录下要求,等待主进程loop的时候正式执行
function cli_signal_hup()
{
	$MYCONF = &$GLOBALS['MYCONF'];

	cli_message('hup '.$MYCONF['name'].'.',3,$MYCONF['message_handle']);
	$MYCONF['isrun'] = false;
	return(true);
}

// 发现sig_term信号后设置不执行,等待主进程loop的时候关闭主进程(被维护的进程不关闭)
function cli_signal_term()
{
	$MYCONF = &$GLOBALS['MYCONF'];

	cli_message('term '.$MYCONF['name'].'.',3,$MYCONF['message_handle']);
	$MYCONF['isrun'] = false;
	sleep(1);
	exit;
}

// for main server sig chld only
function cli_signal_chld()
{
	while (($pid = pcntl_waitpid(-1, $status,WNOHANG)) > 0)
	{
	}
}

function cli_signal_clear($sig)
{
	switch($sig) {
		case SIGTERM	:   exit();break;
		case SIGINT	    :	exit();break;
		case SIGHUP 	:   exit();break;
	}
}

?>