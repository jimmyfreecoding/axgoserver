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
// in service mode
// register signal
pcntl_signal(SIGTERM    , 'awatad_signal_term');
pcntl_signal(SIGINT     , 'awatad_signal_term');
pcntl_signal(SIGHUP     , 'awatad_signal_hup');
pcntl_signal(SIGCHLD    , "awatad_signal_chld");

cmd_main();
exit;

/*------------------------------------------------------------------------
  run now!
-------------------------------------------------------------------------*/
function cmd_main()
{
	$MYCONF = &$GLOBALS['MYCONF'];
	$CONF = &$GLOBALS['CONF'];
	$CLUSTER = &$GLOBALS['CLUSTER'];

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
	cli_message('[mosquitto_keeper] run at '.$MYCONF['pid'],3,$MYCONF['message_handle']);

	// 进入工作时状态
	$runsec = 1;
	$process_limit = 10;   //每次读取任务数，实际内存中最多存在2*10个任务
	while ($MYCONF['isrun']) {
		cli_message('[mosquitto_keeper] weaked up!',3,$MYCONF['message_handle']);
		
		//检测进程中是否超过10条正在处理语音信息
		$process_count = trim(`ps ax|grep mosquitto_pub|grep -v grep|wc -l`);
		if ($process_count > $process_limit) {
			cli_message('[mosquitto_keeper] job beyond limit '.$process_limit,3,$MYCONF['message_handle']);
			sleep($runsec);
			continue;
		}

		//读取指令文件
		$count = 1;  //计数
        if(!is_dir($CONF['mosquitto_tmpdir'])){
            system("mkdir -p ".$CONF['mosquitto_tmpdir']);
        }
		$list = scandir($CONF['mosquitto_tmpdir']);
		foreach ($list as $item) {
			if (!is_file($CONF['mosquitto_tmpdir'].'/'.$item) || $count > $process_limit) {
				continue;
			}
			//移动任务文件，防止第二次被检测到
			system("mv -f ".$CONF['mosquitto_tmpdir'].'/'.$item." /tmp/".$item);
			//分发任务
			cli_run_process("php ".$MYCONF['basedir'].'/mosquitto_pub.php ',array($item,'--quiet'));
			usleep(100000);
			++$count;
		}
		sleep($runsec);
	}
	cli_message('done!',3,$MYCONF['message_handle']);
	exit;
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