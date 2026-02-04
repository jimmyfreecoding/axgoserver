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
require($MYCONF['basedir']."/../lib/arcface.pms");
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
	cli_message('[arcface] run at '.$MYCONF['pid'],3,$MYCONF['message_handle']);

	$runloopsec = 60;
	while ($MYCONF['isrun']) {
		cli_message('[arcface] weaked up!',3,$MYCONF['message_handle']);

        $config = json_decode(file_get_contents($ARCFACE['configPath']), true);
        if(!$config ||
            empty($config['accessToken']) ||
            empty($config['tokenType']) ||
            empty($config['expiresIn']) ||
            empty($config['syncTime']) ||
            $config['syncTime'] + $config['expiresIn'] <= time() + 600){
            arcface_get_token($msg);
            cli_message('[arcface] update token config!'.$msg,3,$MYCONF['message_handle']);
        }
		//exit; //临时测试代码
		//进入下次循环等待
		sleep($runloopsec);
	}
	cli_message('done!',3,$MYCONF['message_handle']);
	exit;
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