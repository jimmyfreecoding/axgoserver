#!/apps/axruntime/bin/jdk-cli 
<?php
//ini_set("display_errors","On");
/*
	Copyright by Geeqee

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
$MYCONF['internal_restart'] = false;
$MYCONF['internal_startup'] = true;

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
require($MYCONF['basedir']."/../lib/c_common.pms");
require($MYCONF['basedir']."/../lib/c_cloud.pms");
// in service mode
// register signal
pcntl_signal(SIGTERM    , 'awatad_signal_term');
pcntl_signal(SIGINT     , 'awatad_signal_term');
pcntl_signal(SIGHUP     , 'awatad_signal_hup');
pcntl_signal(SIGCHLD    , "awatad_signal_chld");

$MYCONF['job_file'] = "/tmp/".$argv[1];
if(!is_file($MYCONF['job_file'])){
	cli_message('Job not found!',0,$MYCONF['message_handle']);
	exit;
}

cmd_main();
exit;

/*------------------------------------------------------------------------
  run now!
-------------------------------------------------------------------------*/
function cmd_main()
{
	$MYCONF = &$GLOBALS['MYCONF'];
	$CONF = &$GLOBALS['CONF'];

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

	$command_str = file_get_contents($MYCONF['job_file']);
	$command = json_decode($command_str, true, 16);
	@unlink($MYCONF['job_file']);
	if ($command === FALSE || $command === NULL || !isset($command['macaddr'])) {
		cli_message('[mosquitto_pub] command file error '.$MYCONF['job_file'],3,$MYCONF['message_handle']);
		exit;
	}

	//是否保存下发指令
	$save_command = 0;
	if ($command['commandType'] != "system") {
		$save_command = 1;
	}

	$cipher = new Crypt_RC4();
	$cipher->setKey(C_CLOUD_STATIC_KEY);
	//$command_str = cloud_encrypt($command_str, $cipher);

	$MYCONF['mqtt_client'] = new Mosquitto\Client();
	$MYCONF['mqtt_client']->onConnect("_callback_mqtt_connect");
	$MYCONF['mqtt_client']->onDisconnect("_callback_mqtt_disconnect");
	$MYCONF['mqtt_client']->setCredentials($CONF['mosquitto_user'], $CONF['mosquitto_passwd']);
	$MYCONF['mqtt_client']->connect($CONF['mosquitto_server'], $CONF['mosquitto_port'], $CONF['mosquitto_keepalive']);

	for ($i = 1; $i <= 1; $i++) {
		$MYCONF['mqtt_client']->loop();
		$MYCONF['mqtt_client']->publish('com.geeqee.'.$command['macaddr'], $command_str, 1, $save_command);
		//file_put_contents("/work/gscreen.geeqee.com/log/log.txt", date("Y-m-d H:i:s", time()).' ===> com.gscreen.command.'.$command['macaddr']." ===> ".$command_str."\n", FILE_APPEND);
		$MYCONF['mqtt_client']->loop();
		usleep(500000);
	}

	//关闭MQTT链接
	$MYCONF['mqtt_client']->disconnect();
	cli_message('done!',3,$MYCONF['message_handle']);
	exit;
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
		//_mqtt_connect();
	}

	cli_message('mqtt disconnect!',3,$MYCONF['message_handle']);
	return true;
}

/*---------------------------------------------------------------------------------
  负责处理 SIGNAL 本程序相关信号
---------------------------------------------------------------------------------*/

// 发现sig_hup信号以后记录下要求,等待主进程loop的时候正式执行
function awatad_signal_hup()
{
	$MYCONF = &$GLOBALS['MYCONF'];

	$MYCONF['internal_restart'] = true;
	$MYCONF['internal_startup'] = true;

	return(true);
}

// 发现sig_term信号后设置不执行,等待主进程loop的时候关闭主进程(被维护的进程不关闭)
function awatad_signal_term()
{
	$MYCONF = &$GLOBALS['MYCONF'];

	$MYCONF['isrun'] = false;
	sleep(1);
	exit;
}

// for main server sig chld only
function awatad_signal_chld()
{
	while (($pid = pcntl_waitpid(-1, $status,WNOHANG)) > 0)
	{
	}
}

function awatad_signal_clear($sig)
{
	switch($sig) {
		case SIGTERM	:   exit();break;
		case SIGINT	    :	exit();break;
		case SIGHUP 	:   exit();break;
	}
}
?>