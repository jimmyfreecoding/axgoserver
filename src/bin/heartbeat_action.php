<?php
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
$MYCONF['pid'] = null;
$MYCONF['pid_file'] = null;
$MYCONF['internal_restart'] = false;
$MYCONF['internal_startup'] = true;
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

/*-------------------------------------------------------------------------
  init and entry
-------------------------------------------------------------------------*/
// common functions
$AX=array();
require($MYCONF['basedir']."/../lib/cli.pms");
require($MYCONF['basedir']."/../lib/c_config.pms");
require($MYCONF['basedir']."/../lib/c_common.pms");
require($MYCONF['basedir']."/../lib/c_cloud.pms");

$AX['myconf']=&$MYCONF;
$MYCONF['pid_file']=$AX['dir_run'].'/'.$MYCONF['name'].'.pid';

// in service mode
// register signal
pcntl_signal(SIGTERM    , 'awatad_signal_term');
pcntl_signal(SIGINT     , 'awatad_signal_term');
pcntl_signal(SIGHUP     , 'awatad_signal_hup');
pcntl_signal(SIGCHLD    , "awatad_signal_chld");

if(!isset($argv[1])){
    cli_message('Too few options!',0,$MYCONF['message_handle']);
    exit;
}

$job_file = '/tmp/'.$argv[1];
if(!is_file($job_file)){
    cli_message('Job not found!',0,$MYCONF['message_handle']);
    exit;
}

cmd_job_execute($job_file);
exit;

/*-------------------------------------------------------------------------
  run now!
-------------------------------------------------------------------------*/
function cmd_job_execute($job_file){

    $AX = &$GLOBALS['AX'];
    $MYCONF = &$GLOBALS['MYCONF'];

    // run me as background
    if (isset($MYCONF['cli_args']['--quiet']) && $MYCONF['cli_args']['--quiet']==true) {
        $pid = pcntl_fork();
        //fork failed
        if ($pid == -1) {
            cli_message('fork failure! ',3,$AX['myconf']['message_handle']);
            exit();
            //in parent to close the parent
        } elseif ($pid) {
            exit();
            //in child
        } else {
            usleep(500000); // 子进程如果异常退出内存会导致主进程崩溃(开启SIGCHLD状态下)
        }
    }

    //获取扫描的MAC信息
    $jobcontent = file_get_contents($job_file);
    if ($jobcontent === FALSE) {
        cli_message('Job invalid!',3,$MYCONF['message_handle']);
        exit;
    }
    unlink($job_file);
    $jobcontent = json_decode($jobcontent,true);
    //任务内容不合法
    if ($jobcontent === FALSE ||
        $jobcontent === NULL ||
        empty($jobcontent['deviceMac'])) {
        cli_message('Job invalid2!',3,$MYCONF['message_handle']);
        exit;
    }



    cli_message('smartiot_di_control done!',3,$MYCONF['message_handle']);
    exit;
}

/*---------------------------------------------------------------------------------
  负责处理 SIGNAL 本程序相关信号
---------------------------------------------------------------------------------*/

// 发现sig_hup信号以后记录下要求,等待主进程loop的时候正式执行
function awatad_signal_hup()
{
    sleep(1);
    exit;
}

// 发现sig_term信号后设置不执行,等待主进程loop的时候关闭主进程(被维护的进程不关闭)
function awatad_signal_term()
{
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
