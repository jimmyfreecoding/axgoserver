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
require($MYCONF['basedir']."/../lib/c_config.pms");
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
	cli_message('[heartbeat_monitor] run at '.$MYCONF['pid'],3,$MYCONF['message_handle']);


	//启动MQTT连接
	_mqtt_connect();
	
	// 进入工作时状态
	$runloopsec = 1;
	while ($MYCONF['isrun']) {
		cli_message('[heartbeat_monitor] weaked up!',3,$MYCONF['message_handle']);
		$MYCONF['mqtt_client']->loop(50);
		$MYCONF['mqtt_client']->subscribe('com.geeqee.heartbeat_monitor', 1);
		sleep($runloopsec);
	}

	//关闭MQTT链接
	$MYCONF['mqtt_client']->disconnect();
	cli_message('done!',3,$MYCONF['message_handle']);
	exit;
}

function _callback_message($m){
	
	$MYCONF = &$GLOBALS['MYCONF'];
    cli_message($m->payload,3,$MYCONF['message_handle']);
    $heartinfo_arr = json_decode($m->payload, true);
	if ($heartinfo_arr === NULL || $heartinfo_arr === FALSE) {
		cli_message('com.gscreen.heartbeat_monitor error!',3,$MYCONF['message_handle']);
	}
	
    //必要参数
	if (!isset($heartinfo_arr['deviceMac'])) {
		cli_message('com.gscreen.heartbeat_monitor too few params!',3,$MYCONF['message_handle']);
	}

	//使用子进程处理
    $filename = uniqid("heartbeat");
	file_put_contents("/tmp/".$filename, json_encode($heartinfo_arr, JSON_UNESCAPED_UNICODE), LOCK_EX);
    //分发任务
    cli_run_process('/apps/axruntime/bin/heartbeat_action',array($filename,'--quiet'));

}

function _mqtt_connect(){
	
	$MYCONF = &$GLOBALS['MYCONF'];
	$CONF = &$GLOBALS['CONF'];

	$MYCONF['mqtt_client'] = new Mosquitto\Client();
	$MYCONF['mqtt_client']->onConnect("_callback_mqtt_connect");
	$MYCONF['mqtt_client']->onDisconnect("_callback_mqtt_disconnect");
	$MYCONF['mqtt_client']->onMessage("_callback_message");
	$MYCONF['mqtt_client']->setCredentials($CONF['mosquitto_user'], $CONF['mosquitto_passwd']);
	$MYCONF['mqtt_client']->connect($CONF['mosquitto_server'], $CONF['mosquitto_port'], $CONF['mosquitto_keepalive']);
	return true;
}

function _callback_mqtt_connect($rc){
	$MYCONF = &$GLOBALS['MYCONF'];
	if ($rc == 0) {
		cli_message('mqtt connected!',3,$MYCONF['message_handle']);
		return true;
	}
	
	cli_message('mqtt connect failed, error code=!'.$rc,3,$MYCONF['message_handle']);
	return false;
}

function _callback_mqtt_disconnect($rc){
	$MYCONF = &$GLOBALS['MYCONF'];
	if ($rc != 0) { //非法断开
		cli_message('mqtt disconnect illegal, restart now!',3,$MYCONF['message_handle']);
		_mqtt_connect();
	}
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