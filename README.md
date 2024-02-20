## NSSM2: The Non-Sacking Service Manager
Version 2.24.1, 2024-02-20  
Based on:  
NSSM: The Non-Sucking Service Manager  
Version 2.24, 2014-08-31  

NSSM2 is a service helper program similar to srvany and cygrunsrv.  It can  
start any application as an NT service and will restart the service if it  
fails for any reason.

NSSM2 имее как консольный, так и графический интерфейс.

Полная документация на английском об исходной версии NSSM

                              http://nssm.cc/


Usage
-----
In the usage notes below, arguments to the program may be written in angle  
brackets and/or square brackets.  <string> means you must insert the  
appropriate string and [<string>] means the string is optional.  See the  
examples below...

Note that everywhere <servicename> appears you may substitute the  
service's display name.


Installation using the GUI
--------------------------
To install a service, run

    nssm2 install <servicename>

You will be prompted to enter the full path to the application you wish   
to run and any command line options to pass to that application.

Use the system service manager (services.msc) to control advanced service   
properties such as startup method and desktop interaction.  NSSM2 may   
support these options at a later time...


Installation using the command line
-----------------------------------
To install a service, run

    nssm2 install <servicename> <application> [<options>]

NSSM2 will then attempt to install a service which runs the named application   
with the given options (if you specified any).

Don't forget to enclose paths in "quotes" if they contain spaces!

If you want to include quotes in the options you will need to """quote""" the  
quotes.


Managing the service
--------------------
NSSM2 will launch the application listed in the registry when you send it a   
start signal and will terminate it when you send a stop signal.  So far, so   
much like srvany.  But NSSM2 is the Non-Sucking service manager and can take   
action if/when the application dies.

With no configuration from you, NSSM2 will try to restart itself if it notices  
that the application died but you didn't send it a stop signal.  NSSM2 will  
keep trying, pausing between each attempt, until the service is successfully  
started or you send it a stop signal.

NSSM2 will pause an increasingly longer time between subsequent restart attempts  
if the service fails to start in a timely manner, up to a maximum of four  
minutes.  This is so it does not consume an excessive amount of CPU time trying  
to start a failed application over and over again.  If you identify the cause  
of the failure and don't want to wait you can use the Windows service console  
(where the service will be shown in Paused state) to send a continue signal to  
NSSM2 and it will retry within a few seconds.

By default, NSSM2 defines "a timely manner" to be within 1500 milliseconds.  
You can change the threshold for the service by setting the number of  
milliseconds as a REG_DWORD value in the registry at  
HKLM\SYSTEM\CurrentControlSet\Services\<service>\Parameters\AppThrottle.

Alternatively, NSSM2 can pause for a configurable amount of time before  
attempting to restart the application even if it successfully ran for the  
amount of time specified by AppThrottle.  NSSM2 will consult the REG_DWORD value  
at HKLM\SYSTEM\CurrentControlSet\Services\<service>\Parameters\AppRestartDelay  
for the number of milliseconds to wait before attempting a restart.  If  
AppRestartDelay is set and the application is determined to be subject to  
throttling, NSSM2 will pause the service for whichever is longer of the  
configured restart delay and the calculated throttle period.

If AppRestartDelay is missing or invalid, only throttling will be applied.  

NSSM2 will look in the registry under  
HKLM\SYSTEM\CurrentControlSet\Services\<service>\Parameters\AppExit for  
string (REG_EXPAND_SZ) values corresponding to the exit code of the application.  
If the application exited with code 1, for instance, NSSM2 will look for a  
string value under AppExit called "1" or, if it does not find it, will  
fall back to the AppExit (Default) value.  You can find out the exit code  
for the application by consulting the system event log.  NSSM2 will log the  
exit code when the application exits.

Based on the data found in the registry, NSSM2 will take one of three actions:

If the value data is "Restart" NSSM2 will try to restart the application as  
described above.  This is its default behaviour.

If the value data is "Ignore" NSSM2 will not try to restart the application  
but will continue running itself.  This emulates the (usually undesirable)  
behaviour of srvany.  The Windows Services console would show the service  
as still running even though the application has exited.

If the value data is "Exit" NSSM2 will exit gracefully.  The Windows Services  
console would show the service as stopped.  If you wish to provide  
finer-grained control over service recovery you should use this code and  
edit the failure action manually.  Please note that Windows versions prior  
to Vista will not consider such an exit to be a failure.  On older versions  
of Windows you should use "Suicide" instead.

If the value data is "Suicide" NSSM2 will simulate a crash and exit without  
informing the service manager.  This option should only be used for  
pre-Vista systems where you wish to apply a service recovery action.  Note  
that if the monitored application exits with code 0, NSSM2 will only honour a  
request to suicide if you explicitly configure a registry key for exit code 0.  
If only the default action is set to Suicide NSSM2 will instead exit gracefully.


Application priority
--------------------
NSSM2 can set the priority class of the managed application.  NSSM2 will look in  
the registry under HKLM\SYSTEM\CurrentControlSet\Services\<service>\Parameters  
for the REG_DWORD entry AppPriority.  Valid values correspond to arguments to  
SetPriorityClass().  If AppPriority() is missing or invalid the  
application will be launched with normal priority.


Processor affinity
------------------
NSSM2 can set the CPU affinity of the managed application.  NSSM2 will look in  
the registry under HKLM\SYSTEM\CurrentControlSet\Services\<service>\Parameters  
for the REG_SZ entry AppAffinity.   It should specify a comma-separated listed  
of zero-indexed processor IDs.  A range of processors may optionally be  
specified with a dash.  No other characters are allowed in the string.  

For example, to specify the first; second; third and fifth CPUs, an appropriate  
AppAffinity would be 0-2,4.

If AppAffinity is missing or invalid, NSSM2 will not attempt to restrict the  
application to specific CPUs.

Note that the 64-bit version of NSSM2 can configure a maximum of 64 CPUs in this  
way and that the 32-bit version can configure a maxium of 32 CPUs even when  
running on 64-bit Windows.


Stopping the service
--------------------
When stopping a service NSSM2 will attempt several different methods of killing  
the monitored application, each of which can be disabled if necessary.

First NSSM2 will attempt to generate a Control-C event and send it to the  
application's console.  Batch scripts or console applications may intercept  
the event and shut themselves down gracefully.  GUI applications do not have  
consoles and will not respond to this method.

Secondly NSSM2 will enumerate all windows created by the application and send  
them a WM_CLOSE message, requesting a graceful exit.

Thirdly NSSM2 will enumerate all threads created by the application and send  
them a WM_QUIT message, requesting a graceful exit.  Not all applications'  
threads have message queues; those which do not will not respond to this  
method.

Finally NSSM2 will call TerminateProcess() to request that the operating  
system forcibly terminate the application.  TerminateProcess() cannot be  
trapped or ignored, so in most circumstances the application will be killed.  
However, there is no guarantee that it will have a chance to perform any  
tidyup operations before it exits.

Any or all of the methods above may be disabled.  NSSM2 will look for the  
HKLM\SYSTEM\CurrentControlSet\Services\<service>\Parameters\AppStopMethodSkip  
registry value which should be of type REG_DWORD set to a bit field describing  
which methods should not be applied.

  If AppStopMethodSkip includes 1, Control-C events will not be generated. 
  If AppStopMethodSkip includes 2, WM_CLOSE messages will not be posted.  
  If AppStopMethodSkip includes 4, WM_QUIT messages will not be posted.  
  If AppStopMethodSkip includes 8, TerminateProcess() will not be called.  

If, for example, you knew that an application did not respond to Control-C  
events and did not have a thread message queue, you could set AppStopMethodSkip  
to 5 and NSSM2 would not attempt to use those methods to stop the application.  

Take great care when including 8 in the value of AppStopMethodSkip.  If NSSM2  
does not call TerminateProcess() it is possible that the application will not  
exit when the service stops.

By default NSSM2 will allow processes 1500ms to respond to each of the methods  
described above before proceeding to the next one.  The timeout can be  
configured on a per-method basis by creating REG_DWORD entries in the  
registry under HKLM\SYSTEM\CurrentControlSet\Services\<service>\Parameters.  

  AppStopMethodConsole 
  AppStopMethodWindow  
  AppStopMethodThreads  

Each value should be set to the number of milliseconds to wait.  Please note  
that the timeout applies to each process in the application's process tree,  
so the actual time to shutdown may be longer than the sum of all configured  
timeouts if the application spawns multiple subprocesses.

To skip applying the above stop methods to all processes in the application's 
process tree, applying them only to the original application process, set the  
HKLM\SYSTEM\CurrentControlSet\Services\<service>\Parameters\AppKillProcessTree  
registry value, which should be of type REG_DWORD, to 0.


Console window
--------------
By default, NSSM2 will create a console window so that applications which  
are capable of reading user input can do so - subject to the service being  
allowed to interact with the desktop.

Creation of the console can be suppressed by setting the integer (REG_DWORD)  
HKLM\SYSTEM\CurrentControlSet\Services\<service>\Parameters\AppNoConsole  
registry value to 1.


I/O redirection
---------------
NSSM2 can redirect the managed application's I/O to any path capable of being  
opened by CreateFile().  This enables, for example, capturing the log output  
of an application which would otherwise only write to the console or accepting  
input from a serial port.

NSSM2 will look in the registry under  
HKLM\SYSTEM\CurrentControlSet\Services\<service>\Parameters for the keys 
corresponding to arguments to CreateFile().  All are optional.  If no path is  
given for a particular stream it will not be redirected.  If a path is given  
but any of the other values are omitted they will be receive sensible defaults.  

  AppStdin: Path to receive input.  
  AppStdout: Path to receive output.  
  AppStderr: Path to receive error output.  

Parameters for CreateFile() are providing with the "AppStdinShareMode",  
"AppStdinCreationDisposition" and "AppStdinFlagsAndAttributes" values (and  
analogously for stdout and stderr).

In general, if you want the service to log its output, set AppStdout and  
AppStderr to the same path, eg C:\Users\Public\service.log, and it should  
work.  Remember, however, that the path must be accessible to the user  
running the service.


File rotation
-------------
When using I/O redirection, NSSM2 can rotate existing output files prior to  
opening stdout and/or stderr.  An existing file will be renamed with a  
suffix based on the file's last write time, to millisecond precision.  For  
example, the file nssm.log might be rotated to nssm-20131221T113939.457.log.

NSSM2 will look in the registry under  
HKLM\SYSTEM\CurrentControlSet\Services\<service>\Parameters for REG_DWORD  
entries which control how rotation happens.

If AppRotateFiles is missing or set to 0, rotation is disabled.  Any non-zero  
value enables rotation.

If AppRotateSeconds is non-zero, a file will not be rotated if its last write  
time is less than the given number of seconds in the past.

If AppRotateBytes is non-zero, a file will not be rotated if it is smaller  
than the given number of bytes.  64-bit file sizes can be handled by setting  
a non-zero value of AppRotateBytesHigh.

If AppRotateDelay is non-zero, NSSM2 will pause for the given number of  
milliseconds after rotation.

If AppStdoutCopyAndTruncate or AppStderrCopyAndTruncate are non-zero, the  
stdout (or stderr respectively) file will be rotated by first taking a copy  
of the file then truncating the original file to zero size.  This allows  
NSSM2 to rotate files which are held open by other processes, preventing the 
usual MoveFile() from succeeding.  Note that the copy process may take some  
time if the file is large, and will temporarily consume twice as much disk  
space as the original file.  Note also that applications reading the log file  
may not notice that the file size changed.  Using this option in conjunction  
with AppRotateDelay may help in that case.

Rotation is independent of the CreateFile() parameters used to open the files.  
They will be rotated regardless of whether NSSM2 would otherwise have appended  
or replaced them.

NSSM2 can also rotate files which hit the configured size threshold while the  
service is running.  Additionally, you can trigger an on-demand rotation by  
running the command

    nssm2 rotate <servicename>

On-demand rotations will happen after the next line of data is read from  
the managed application, regardless of the value of AppRotateBytes. Be aware  
that if the application is not particularly verbose the rotation may not  
happen for some time.

To enable online and on-demand rotation, set AppRotateOnline to a non-zero  
value.

Note that online rotation requires NSSM2 to intercept the application's I/O  
and create the output files on its behalf.  This is more complex and  
error-prone than simply redirecting the I/O streams before launching the  
application.  Therefore online rotation is not enabled by default.


Environment variables
---------------------
NSSM2 can replace or append to the managed application's environment.  Two  
multi-valued string (REG_MULTI_SZ) registry values are recognised under  
HKLM\SYSTEM\CurrentControlSet\Services\<service>\Parameters.

AppEnvironment defines a list of environment variables which will override  
the service's environment.  AppEnvironmentExtra defines a list of  
environment variables which will be added to the service's environment. 

Each entry in the list should be of the form KEY=VALUE.  It is possible to  
omit the VALUE but the = symbol is mandatory.

Environment variables listed in both AppEnvironment and AppEnvironmentExtra  
are subject to normal expansion, so it is possible, for example, to update the  
system path by setting "PATH=C:\bin;%PATH%" in AppEnvironmentExtra.  Variables  
are expanded in the order in which they appear, so if you want to include the  
value of one variable in another variable you should declare the dependency  
first.

Because variables defined in AppEnvironment override the existing  
environment it is not possible to refer to any variables which were previously  
defined.

For example, the following AppEnvironment block:

      PATH=C:\Windows\System32;C:\Windows  
      PATH=C:\bin;%PATH%

Would result in a PATH of "C:\bin;C:\Windows\System32;C:\Windows" as expected.

Whereas the following AppEnvironment block:

      PATH=C:\bin;%PATH%

Would result in a path containing only C:\bin and probably cause the  
application to fail to start.

Most people will want to use AppEnvironmentExtra exclusively.  srvany only  
supports AppEnvironment.

As of version 2.25, NSSM2 parses AppEnvironment and AppEnvironmentExtra  
itself, before reading any other registry values.  As a result it is now  
possible to refer to custom environment variables in Application,  
AppDirectory and other parameters.


Merged service environment
--------------------------
All Windows services can be passed additional environment variables by  
creating a multi-valued string (REG_MULTI_SZ) registry value named  
HLKM\SYSTEM\CurrentControlSet\Services\<service>\Environment.

The contents of this environment block will be merged into the system  
environment before the service starts.

Note, however, that the merged environment will be sorted alphabetically  
before being processed.  This means that in practice you cannot set,  
for example, DIR=%PROGRAMFILES% in the Environment block because the  
environment passed to the service will not have defined %PROGRAMFILES%  
by the time it comes to define %DIR%.  Environment variables defined in  
AppEnvironmentExtra do not suffer from this limitation. 

As of version 2.25, NSSM2 can get and set the Environment block using  
commands similar to:

    nssm2 get <servicename> Environment

It is worth reiterating that the Environment block is available to all  
Windows services, not just NSSM2 services.


Service startup environment
---------------------------
The environment NSSM2 passes to the application depends on how various  
registry values are configured.  The following flow describes how the  
environment is modified.

By default: 
    The service inherits the system environment.

If <service>\Environment is defined:  
    The contents of Environment are MERGED into the environment.

If <service>\Parameters\AppEnvironment is defined: 
    The service inherits the environment specified in AppEnvironment.

If <service>\Parameters\AppEnvironmentExtra is defined:  
    The contents of AppEnvironmentExtra are APPENDED to the environment.

Note that AppEnvironment overrides the system environment and the  
merged Environment block.  Note also that AppEnvironmentExtra is  
guaranteed to be appended to the startup environment if it is defined.  


Event hooks
-----------
NSSM2 can run user-configurable commands in response to application events.  
These commands are referred to as "hooks" below.

All hooks are optional.  Any hooks which are run will be launched with the  
environment configured for the service.  NSSM2 will place additional  
variables into the environment which hooks can query to learn how and why  
they were called.

Hooks are categorised by Event and Action.  Some hooks are run synchronously  
and some are run asynchronously.  Hooks prefixed with an *asterisk are run  
synchronously.  NSSM2 will wait for these hooks to complete before continuing  
its work.  Note, however, that ALL hooks are subject to a deadline after which  
they will be killed, regardless of whether they are run asynchronously  
or not.

  Event: Start - Triggered when the service is requested to start. 
   *Action: Pre - Called before NSSM2 attempts to launch the application.  
    Action: Post - Called after the application successfully starts.  

  Event: Stop - Triggered when the service is requested to stop.  
   *Action: Pre - Called before NSSM2 attempts to kill the application.  

  Event: Exit - Triggered when the application exits.  
   *Action: Post - Called after NSSM2 has cleaned up the application.  

  Event: Rotate - Triggered when online log rotation is requested.  
   *Action: Pre - Called before NSSM2 rotates logs.  
    Action: Post - Called after NSSM2 rotates logs.  

  Event: Power  
    Action: Change - Called when the system power status has changed.  
    Action: Resume - Called when the system has resumed from standby.  
     
Note that there is no Stop/Post hook.  This is because Exit/Post is called  
when the application exits, regardless of whether it did so in response to 
a service shutdown request.  Stop/Pre is only called before a graceful  
shutdown attempt.

NSSM2 sets the environment variable NSSM_HOOK_VERSION to a positive number.  
Hooks can check the value of the number to determine which other environment  
variables are available to them.

If NSSM_HOOK_VERSION is 1 or greater, these variables are provided:

  NSSM_EXE - Path to NSSM2 itself.  
  NSSM_CONFIGURATION - Build information for the NSSM2 executable,  
    eg 64-bit debug.  
  NSSM_VERSION - Version of the NSSM2 executable.  
  NSSM_BUILD_DATE - Build date of NSSM.  
  NSSM_PID - Process ID of the running NSSM2 executable.  
  NSSM_DEADLINE - Deadline number of milliseconds after which NSSM2 will  
    kill the hook if it is still running.  
  NSSM_SERVICE_NAME - Name of the service controlled by NSSM.  
  NSSM_SERVICE_DISPLAYNAME - Display name of the service.  
  NSSM_COMMAND_LINE - Command line used to launch the application.  
  NSSM_APPLICATION_PID - Process ID of the primary application process.  
    May be blank if the process is not running.  
  NSSM_EVENT - Event class triggering the hook.  
  NSSM_ACTION - Event action triggering the hook.  
  NSSM_TRIGGER - Service control triggering the hook.  May be blank if  
    the hook was not triggered by a service control, eg Exit/Post.  
  NSSM_LAST_CONTROL - Last service control handled by NSSM.  
  NSSM_START_REQUESTED_COUNT - Number of times the application was  
    requested to start.  
  NSSM_START_COUNT - Number of times the application successfully started.  
  NSSM_THROTTLE_COUNT - Number of times the application ran for less than  
    the throttle period.  Reset to zero on successful start or when the  
    service is explicitly unpaused. 
  NSSM_EXIT_COUNT - Number of times the application exited.  
  NSSM_EXITCODE - Exit code of the application.  May be blank if the  
    application is still running or has not started yet.  
  NSSM_RUNTIME - Number of milliseconds for which the NSSM2 executable has  
    been running.  
  NSSM_APPLICATION_RUNTIME - Number of milliseconds for which the  
    application has been running since it was last started.  May be blank  
    if the application has not been started yet.

Future versions of NSSM2 may provide more environment variables, in which  
case NSSM_HOOK_VERSION will be set to a higher number.

Hooks are configured by creating string (REG_EXPAND_SZ) values in the  
registry named after the hook action and placed under  
HKLM\SYSTEM\CurrentControlSet\Services\<service>\Parameters\AppEvents\<event>.

For example the service could be configured to restart when the system  
resumes from standby by setting AppEvents\Power\Resume to:

    %NSSM_EXE% restart %NSSM_SERVICE_NAME%

Note that NSSM2 will abort the startup of the application if a Start/Pre hook  
returns exit code of 99.

A service will normally run hooks in the following order:

  Start/Pre  
  Start/Post  
  Stop/Pre  
  Exit/Post  

If the application crashes and is restarted by NSSM, the order might be:

  Start/Pre  
  Start/Post  
  Exit/Post  
  Start/Pre  
  Start/Post  
  Stop/Pre  
  Exit/Post  


Managing services using the GUI
-------------------------------
NSSM2 can edit the settings of existing services with the same GUI that is  
used to install them.  Run

    nssm2 edit <servicename>

to bring up the GUI.

NSSM2 offers limited editing capabilities for services other than those which  
run NSSM2 itself.  When NSSM2 is asked to edit a service which does not have  
the App* registry settings described above, the GUI will allow editing only  
system settings such as the service display name and description.


Managing services using the command line
----------------------------------------
NSSM2 can retrieve or set individual service parameters from the command line.  
In general the syntax is as follows, though see below for exceptions.

    nssm2 get <servicename> <parameter>

    nssm2 set <servicename> <parameter> <value>

Parameters can also be reset to their default values.

    nssm2 reset <servicename> <parameter>

The parameter names recognised by NSSM2 are the same as the registry entry  
names described above, eg AppDirectory.

NSSM2 offers limited editing capabilities for Services other than those which  
run NSSM2 itself.  The parameters recognised are as follows:

  Description: Service description. 
  DisplayName: Service display name.  
  Environment: Service merged environment. 
  ImagePath: Path to the service executable.  
  ObjectName: User account which runs the service.  
  Name: Service key name. 
  Start: Service startup type.  
  Type: Service type.  

These correspond to the registry values under the service's key  
HKLM\SYSTEM\CurrentControlSet\Services\<service>.


Note that NSSM2 will concatenate all arguments passed on the command line  
with spaces to form the value to set.  Thus the following two invocations  
would have the same effect.

    nssm2 set <servicename> Description "NSSM2 managed service"

    nssm2 set <servicename> Description NSSM2 managed service


Non-standard parameters
-----------------------
The AppEnvironment and AppEnvironmentExtra parameters recognise an 
additional argument when querying the environment.  The following syntax  
will print all extra environment variables configured for a service

    nssm2 get <servicename> AppEnvironmentExtra

whereas the syntax below will print only the value of the CLASSPATH  
variable if it is configured in the environment block, or the empty string  
if it is not configured.  

    nssm2 get <servicename> AppEnvironmentExtra CLASSPATH

When setting an environment block, each variable should be specified as a  
KEY=VALUE pair in separate command line arguments.  For example:

    nssm2 set <servicename> AppEnvironment CLASSPATH=C:\Classes TEMP=C:\Temp


The AppExit parameter requires an additional argument specifying the exit  
code to get or set.  The default action can be specified with the string  
Default.

For example, to get the default exit action for a service you should run

    nssm2 get <servicename> AppExit Default

To get the exit action when the application exits with exit code 2, run

    nssm2 get <servicename> AppExit 2

Note that if no explicit action is configured for a specified exit code,  
NSSM2 will print the default exit action.

To set configure the service to stop when the application exits with an  
exit code of 2, run

    nssm2 set <servicename> AppExit 2 Exit


The AppPriority parameter is used to set the priority class of the  
managed application.  Valid priorities are as follows:

  REALTIME_PRIORITY_CLASS 
  HIGH_PRIORITY_CLASS  
  ABOVE_NORMAL_PRIORITY_CLASS  
  NORMAL_PRIORITY_CLASS 
  BELOW_NORMAL_PRIORITY_CLASS  
  IDLE_PRIORITY_CLASS


The DependOnGroup and DependOnService parameters are used to query or set  
the dependencies for the service.  When setting dependencies, each service  
or service group (preceded with the + symbol) should be specified in  
separate command line arguments.  For example:

    nssm2 set <servicename> DependOnService RpcSs LanmanWorkstation  


The Name parameter can only be queried, not set.  It returns the service's  
registry key name.  This may be useful to know if you take advantage of  
the fact that you can substitute the service's display name anywhere where  
the syntax calls for <servicename>.


The ObjectName parameter requires an additional argument only when setting 
a username.  The additional argument is the password of the user.

To retrieve the username, run

    nssm2 get <servicename> ObjectName

To set the username and password, run

    nssm2 set <servicename> ObjectName <username> <password>

Note that the rules of argument concatenation still apply.  The following  
invocation is valid and will have the expected effect.

    nssm2 set <servicename> ObjectName <username> correct horse battery staple  

The following well-known usernames do not need a password.  The password  
parameter can be omitted when using them:

  "LocalSystem" aka "System" aka "NT Authority\System"  
  "LocalService" aka "Local Service" aka "NT Authority\Local Service"  
  "NetworkService" aka "Network Service" aka "NT Authority\Network Service"  


The Start parameter is used to query or set the startup type of the service. 
Valid service startup types are as follows:

  SERVICE_AUTO_START: Automatic startup at boot.  
  SERVICE_DELAYED_START: Delayed startup at boot.  
  SERVICE_DEMAND_START: Manual service startup.  
  SERVICE_DISABLED: The service is disabled.

Note that SERVICE_DELAYED_START is not supported on versions of Windows prior 
to Vista.  NSSM2 will set the service to automatic startup if delayed start is  
unavailable.


The Type parameter is used to query or set the service type.  NSSM2 recognises 
all currently documented service types but will only allow setting one of two  
types:

  SERVICE_WIN32_OWN_PROCESS: A standalone service.  This is the default.  
  SERVICE_INTERACTIVE_PROCESS: A service which can interact with the desktop.

Note that a service may only be configured as interactive if it runs under  
the LocalSystem account.  The safe way to configure an interactive service 
is in two stages as follows.

    nssm2 reset <servicename> ObjectName  
    nssm2 set <servicename> Type SERVICE_INTERACTIVE_PROCESS


Controlling services using the command line
-------------------------------------------
NSSM2 offers rudimentary service control features.

    nssm2 start <servicename>

    nssm2 restart <servicename>

    nssm2 stop <servicename>

    nssm2 status <servicename>


Removing services using the GUI
-------------------------------
NSSM2 can also remove services.  Run

    nssm2 remove <servicename>

to remove a service.  You will prompted for confirmation before the service   
is removed.  Try not to remove essential system services...


Removing service using the command line
---------------------------------------
To remove a service without confirmation from the GUI, run

    nssm2 remove <servicename> confirm

Try not to remove essential system services...


Logging
-------
NSSM2 logs to the Windows event log.  It registers itself as an event log source 
and uses unique event IDs for each type of message it logs.  New versions may  
add event types but existing event IDs will never be changed.

Because of the way NSSM2 registers itself you should be aware that you may not 
be able to replace the NSSM2 binary if you have the event viewer open and that  
running multiple instances of NSSM2 from different locations may be confusing if  
they are not all the same version.


Example usage
-------------
To install an Unreal Tournament server:

    nssm2 install UT2004 c:\games\ut2004\system\ucc.exe server

To run the server as the "games" user:

    nssm2 set UT2004 ObjectName games password

To configure the server to log to a file:

    nssm2 set UT2004 AppStdout c:\games\ut2004\service.log

To restrict the server to a single CPU:

    nssm2 set UT2004 AppAffinity 0

To remove the server:

    nssm2 remove UT2004 confirm

To find out the service name of a service with a display name:

    nssm2 get "Background Intelligent Transfer Service" Name


Building NSSM2 from source
-------------------------
NSSM2 is known to compile with Visual Studio 2008 and later.  Older Visual
Studio releases may or may not work if you install an appropriate SDK and
edit the nssm.vcproj and nssm.sln files to set a lower version number.
They are known not to work with default settings.

NSSM2 will also compile with Visual Studio 2010 but the resulting executable
will not run on versions of Windows older than XP SP2.  If you require
compatiblity with older Windows releases you should change the Platform
Toolset to v90 in the General section of the project's Configuration
Properties.


Credits
-------
- Thanks to Bernard Loh for finding a bug with service recovery.
- Thanks to Benjamin Mayrargue (www.softlion.com) for adding 64-bit support.
- Thanks to Joel Reingold for spotting a command line truncation bug.
- Thanks to Arve Knudsen for spotting that child processes of the monitored
application could be left running on service shutdown, and that a missing
registry value for AppDirectory confused NSSM.
- Thanks to Peter Wagemans and Laszlo Keresztfalvi for suggesting throttling
restarts.
- Thanks to Eugene Lifshitz for finding an edge case in CreateProcess() and for
advising how to build messages.mc correctly in paths containing spaces.
- Thanks to Rob Sharp for pointing out that NSSM2 did not respect the
AppEnvironment registry value used by srvany.
- Thanks to Szymon Nowak for help with Windows 2000 compatibility.
- Thanks to François-Régis Tardy and Gildas le Nadan for French translation.
- Thanks to Emilio Frini for spotting that French was inadvertently set as
the default language when the user's display language was not translated.
- Thanks to Riccardo Gusmeroli and Marco Certelli for Italian translation.
- Thanks to Eric Cheldelin for the inspiration to generate a Control-C event
on shutdown.
- Thanks to Brian Baxter for suggesting how to escape quotes from the command
prompt.
- Thanks to Russ Holmann for suggesting that the shutdown timeout be configurable.
- Thanks to Paul Spause for spotting a bug with default registry entries.
- Thanks to BUGHUNTER for spotting more GUI bugs.
- Thanks to Doug Watson for suggesting file rotation.
- Thanks to Арслан Сайдуганов for suggesting setting process priority.
- Thanks to Robert Middleton for suggestion and draft implementation of process
affinity support.
- Thanks to Andrew RedzMax for suggesting an unconditional restart delay.
- Thanks to Bryan Senseman for noticing that applications with redirected stdout
and/or stderr which attempt to read from stdin would fail.
- Thanks to Czenda Czendov for help with Visual Studio 2013 and Server 2012R2.
- Thanks to Alessandro Gherardi for reporting and draft fix of the bug whereby
the second restart of the application would have a corrupted environment.
- Thanks to Hadrien Kohl for suggesting to disable the console window's menu.
- Thanks to Allen Vailliencourt for noticing bugs with configuring the service to
run under a local user account.
- Thanks to Sam Townsend for noticing a regression with TerminateProcess().
- Thanks to Barrett Lewis for suggesting the option to skip terminating the
application's child processes.
- Thanks to Miguel Angel Terrón for suggesting copy/truncate rotation.
- Thanks to Yuriy Lesiuk for suggesting setting the environment before querying
the registry for parameters.
- Thanks to Gerald Haider for noticing that installing a service with NSSM2 in a
path containing spaces was technically a security vulnerability.

Licence
-------
NSSM2 is public domain.  You may unconditionally use it and/or its source code 
for any purpose you wish.
