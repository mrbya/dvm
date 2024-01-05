@rem = '--*-Perl-*--
@set "ErrorLevel="
@if "%OS%" == "Windows_NT" @goto WinNT
@perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
@set ErrorLevel=%ErrorLevel%
@goto endofperl
:WinNT
@perl -x -S %0 %*
@set ErrorLevel=%ErrorLevel%
@if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" @goto endofperl
@if %ErrorLevel% == 9009 @echo You do not have Perl in your PATH.
@goto endofperl
@rem ';
#!/usr/bin/perl
#line 16
#TODO: clean project files

use Env;
use strict;
use warnings;
use Getopt::Long;
use Cwd;
use Data::Dumper;
use Pod::Usage;

my $dvmpath = $ENV{dvmPath};
push (@INC, $dvmpath);

require pUtils;

#get script args
GetOptions(
    #dvm project
    'new=s'         => \my $prjname,
    'configfile=s'  => \my $cconfigname,
    'module=s'      => \my $module,
    'path=s'        => \my $path,

    #vivado
    'comp'          => \my $comp,
    'elab'          => \my $elab,
    'run'           => \my $run,
    'dpi'           => \my $dpi,
    'runsv'         => \my $runsv,
    'all'           => \my $all,
    'gui'           => \my $gui,
    'genc'          => \my $genc,
    'cdash'         => \my $cdash,

    #comp args
    'complog=s'     => \my $complog,
    'complist=s'    => \my $complist,

    #dpi args
    'dpilist=s'     => \my $dpilist,

    #elab args
    'elablog=s'     => \my $elablog,
    'timescale=s'   => \my $timescale,
    'tbtop=s'       => \my $tbtop,
    'tb=s'          => \my $tb,

    #sim args
    'simlog=s'      => \my $simlog,
    'test=s'        => \my $test,
    'batch'         => \my $batch,
    'testlist=s'    => \my $testlist,
    'uvmverb=s'     => \my $uvmverb,
    'simtb=s'       => \my $simtb,

    #multi-stage args
    'wave'          => \my $wave,
    'dumpfile=s'    => \my $dumpfile,

    #help
    'help'          => \my $help,

    #debug
    'debug'         => \my $debug,
);

#global vars
our $prjpath;
our $configname;
our %config;
our %fileTemplates;
our @simtests;
our $datestring;

#arg parsing
if (defined $all or defined $debug) {
    $comp = 1;
    $elab = 1;
    $run = 1;
}
pod2usage(-verbose => 2) and exit 0 if defined $help;
print "No required arguments provided!\n\nFor more info use -help or -h\n" and exit 1 if not defined $prjname and not defined $comp and not defined $elab and not defined $run and not defined $gui and not defined $genc and not defined $cdash and not defined $module and not defined $dpi and not defined $runsv;
print "UVM test provided without running simulation - option will be ignored...\n" and undef $test if defined $test and not defined $run;
print "Waveform dump option used without running elaboration or simulation - option will be ignored...\n" and undef $wave if defined $wave and not defined $elab and not defined $run and not defined $runsv;
print "Compile list provided without running compilation - option will be ignored...\n" and undef $complist if defined $complist and not defined $comp;
print "Vivado GUI option provided while running compilation, elaboration or simulation - option will be ignored...\n" and undef $gui if defined $gui and (defined $comp or defined $elab or defined $run);
print "Waveform dump file provided without running Vivado GUI - option will be ignored...\n" and undef $dumpfile if defined $dumpfile and not defined $gui;
print "Testbench snapshot provided without running elaboration - option will be ignored...\n" and undef $tb if defined $tb and not defined $elab;
print "Timescale provided without running elaboration - option will be ignored...\n" and undef $timescale if defined $timescale and not defined $elab;
print "UVM verbosity provided without running simulation - option will be ignored...\n" and undef $uvmverb if defined $uvmverb and not defined $run;
print "Simulation testbench snapshot provided without running simulation - option will be ignored...\n" and undef $simtb if defined $simtb and not defined $run;
print "Testbench topmodule provided without running elaboration - option will be ignored...\n" and undef $tbtop if defined $tbtop and not defined $elab;
print "Module template path provided without generating module template - option will be ignored...\n" and undef $path if defined $path and not defined $module;

#script config
$fileTemplates{'prjConfig'}     = "$dvmpath\\templates\\dvmproject.conf.template";
$fileTemplates{'tbTop'}         = "$dvmpath\\templates\\dvm_tb_top.sv.template";
$fileTemplates{'compileList'}   = "$dvmpath\\templates\\dvm_compile_list.f.template";
$fileTemplates{'wfcfg'}         = "$dvmpath\\templates\\wfcfg.tcl.template";
$fileTemplates{'testlist'}      = "$dvmpath\\templates\\test_list.f.template";
$fileTemplates{'svmodule'}      = "$dvmpath\\templates\\svmodule.sv.template";

$datestring = localtime();

$configname = 'dvmproject.conf';
$configname = $cconfigname if defined $cconfigname;

#main
main();

#script body
sub main {
    #DVM project creation
    createNewProject($prjname) and exit 0 if defined $prjname;
    
    print "Loading DVM project config...\n";

    #load config hash from config file
    loadConfig();

    #init prjpath and sim test
    $prjpath = $config{'project'}{'dir'};

    #navigate to DVM project top
    prjTop();

    if (defined $batch) {
        $batch = 1;
    } else {
        $batch = $config{'simulation'}{'batch'};
    }

    if ($batch == 1) {
        print "UVM test provided even though running in batch mode - option will be ignored...\n" and undef $test if defined $test;
        
        $testlist = $config{'simulation'}{'testlist'} if not defined $testlist;
        getTestList();
    } else {
        print "UVM test list provided without running in batch mode - option will be ignored...\n" and undef $testlist if defined $testlist;
        $test = $config{'simulation'}{'defTest'} if not defined $test;
    }

    print "DVM project config loaded.\n";

    #sv module template generation
    createModuleTemplate($module, $path) and exit 0 if defined $module;

    #vivado wrappers
    compile()   if defined $comp;
    dpi_c()     if defined $dpi;
    elab()      if defined $elab;
    runsim()    if defined $run;
    runsvsim()  if defined $runsv;
    gui()       if defined $gui;
    genCov()    if defined $genc;
    covDash()   if defined $cdash;
}#main

#create new project
#TODO: parametrize template file generation and project dir structure
sub createNewProject {
    my ($name) = @_;
    my $newprjdir = getcwd();
    $newprjdir = "$newprjdir/$name";

    print "Generating new DVM project: $name\n";

    mkdir "$name";
    chdir "$name";

    mkdir "dvm";
    chdir "dvm";
    mkdir "logs";

    chdir "logs";
    mkdir "comp";
    mkdir "elab";
    mkdir "sim";
    mkdir "dpi";
    chdir "..";

    my $confdata = pUtils::readFile($fileTemplates{'prjConfig'});
    $confdata = pUtils::replace("{{prjname}}", $name, $confdata);
    $confdata = pUtils::replace("{{prjdir}}", $newprjdir, $confdata);
    $confdata = pUtils::replace("{{prjname}}", $name, $confdata);
    pUtils::genFile("dvmproject.conf", "$confdata");

    my $cldata = pUtils::readFile($fileTemplates{'compileList'});
    $cldata = pUtils::replace("{{prjname}}", $name, $cldata);
    pUtils::genFile("$name\_compile_list.f", $cldata);

    my $wfcfg = pUtils::readFile($fileTemplates{'wfcfg'});
    pUtils::genFile("wfcfg.tcl", "$wfcfg");

    my $tldata = pUtils::readFile($fileTemplates{'testlist'});
    pUtils::genFile("$name\_test_list.f", $tldata);

    chdir "..";
    mkdir "design";
    chdir "design";
    mkdir "src";

    chdir "..";

    mkdir "verif";
    chdir "verif";

    mkdir "env";
    chdir "env";
    mkdir "agents";
    mkdir "top";

    chdir "..";

    mkdir "tb";
    chdir "tb";
    mkdir "src";
    chdir "src";

    my $tbTopData = pUtils::readFile($fileTemplates{'tbTop'});
    $tbTopData = pUtils::replace("{{PRJNAME}}", uc($name), $tbTopData);
    $tbTopData = pUtils::replace("{{prjname}}", $name, $tbTopData);
    pUtils::genFile("$name\_tb_top.sv", $tbTopData);

    chdir "..";
    chdir "..";

    mkdir "test";
    chdir "test";
    mkdir "seq";
    mkdir "src";

    print "New project created.\n";
}#createNewProject

sub createModuleTemplate {
    my ($moduleName, $modulePath) = @_;
    my $moduleData = pUtils::readFile($fileTemplates{'svmodule'});
    my $delimiter;
    my @dirList;

    $moduleData = pUtils::replace("{{timescale}}", $config{'elaboration'}{'timescale'}, $moduleData);
    $moduleData = pUtils::replace("{{date}}", $datestring, $moduleData);
    $moduleData = pUtils::replace("{{prjname}}", $config{'project'}{'name'}, $moduleData);
    $moduleData = pUtils::replace("{{module}}", $moduleName, $moduleData);
    $moduleData = pUtils::replace("{{module}}", $moduleName, $moduleData);

    chdir "../design/src";

    if (defined $modulePath) {
        $modulePath = pUtils::replace("/", "\"", $modulePath);

        @dirList = split(/"/, $modulePath);

        foreach (@dirList) {
            if (not -d $_) {
                mkdir $_;
            }

            chdir $_;
        }
    }

    pUtils::genFile("$moduleName.sv", $moduleData);
}

#load config hash
sub loadConfig {
    my @configpath = pUtils::findFile($configname, ".");
    my $configData = pUtils::readFile($configpath[0]);

    %config = eval $configData;
}#loadConfig

#navigate to DVM project top
sub prjTop {
    chdir "$prjpath/dvm";
}#prjTop

#get list of tests from testlist
sub getTestList {
    my $tldata = pUtils::readFile($testlist);
    @simtests = pUtils::getList($tldata);
}#getTestList

#run compilation
sub compile {
    #construct xvlog cmd
    my $args = $config{'compilation'}{'args'};

    my $logname = $config{'compilation'}{'log'};
    $logname = "$config{'project'}{'logDir'}\\$config{'compilation'}{'logDir'}\\$logname";
    $logname = $complog if defined $complog;

    $complist = $config{'compilation'}{'list'} if not defined $complist;

    my $cmd = "xvlog -sv -f $complist -log $logname $args";

    #run xvlog
    system($cmd);
}#compile

#run elaboration
sub elab {
    #construct xelab cmd
    my $args = "$config{'elaboration'}{'args'}";
    $args = "$args -debug wave" if defined $wave;

    my $logname = $config{'elaboration'}{'log'};
    $logname = "$config{'project'}{'logDir'}\\$config{'elaboration'}{'logDir'}\\$logname";
    $logname = $elablog if defined $elablog;

    $tbtop = $config{'elaboration'}{'tbTop'} if not defined $tbtop;

    $tb = $config{'elaboration'}{'tbName'} if not defined $tb;

    $timescale = $config{'elaboration'}{'timescale'} if not defined $timescale;

    if ($config{'elaboration'}{'dpilib'}) {
        $args = "-sv_lib dpi $args";
    }

    my $cmd = "xelab $tbtop -relax -s $tb -timescale $timescale -log $logname $args";

    #runc xelab
    system($cmd);
}#elab

#run simulation
sub runsim {
    #construct xsim cmd
    my $args = "$config{'simulation'}{'args'}";
    if (not defined $wave) {
        $args = "-R $args";
    } else {
        $args = "--tclbatch wfcfg.tcl $args";
    }

    my @simtestlist;

    if ($batch == 0) {
        push(@simtestlist, $test);
    } else {
        push(@simtestlist, @simtests);
    }
    
    foreach (@simtestlist) {
        my $logname = $config{'simulation'}{'log'};
        $logname = pUtils::replace("{{testname}}", $_, $logname);

        $logname = "$config{'project'}{'logDir'}\\$config{'simulation'}{'logDir'}\\$logname";

        if ($batch == 0 and defined $simlog) {
            $logname = $simlog;
        }

        if (not defined $simtb) {
            $simtb = $simtb = $config{'elaboration'}{'tbName'};
            $simtb = $tb if defined $tb;
        }

        $uvmverb = $config{'simulation'}{'verbosity'} if not defined $uvmverb;

        my $cmd = "xsim $simtb -log $logname -testplusarg \"UVM_VERBOSITY=$uvmverb\" -testplusarg \"UVM_TESTNAME=$_\" $args";

        #run xsim
        system($cmd);
    }
}#runsim

#run pure systemverilog sim
sub runsvsim {
    #construct xsim cmd
    my $args = "$config{'simulation'}{'args'}";
    if (not defined $wave) {
        $args = "-R $args";
    } else {
        $args = "--tclbatch wfcfg.tcl $args";
    }

    my @simtestlist;

    if ($batch == 0) {
        push(@simtestlist, $test);
    } else {
        push(@simtestlist, @simtests);
    }
    
    my $logname = $config{'simulation'}{'log'};
    $logname = pUtils::replace("{{testname}}", "svsim", $logname);

    $logname = "$config{'project'}{'logDir'}\\$config{'simulation'}{'logDir'}\\$logname";

    if ($batch == 0 and defined $simlog) {
        $logname = $simlog;
    }

    if (not defined $simtb) {
        $simtb = $simtb = $config{'elaboration'}{'tbName'};
        $simtb = $tb if defined $tb;
    }

    $uvmverb = $config{'simulation'}{'verbosity'} if not defined $uvmverb;

    my $cmd = "xsim $simtb -log $logname $args";

    #run xsim
    system($cmd);
}

#run xsc compiler for dpi-c code
sub dpi_c {
    my $args = "$config{'dpi'}{'args'}";

    my $dpilist = "$config{'dpi'}{'list'}" if not defined $dpilist;
    $dpilist = pUtils::readFile($dpilist);
    my @srclist = pUtils::getList($dpilist);

    my $cmd = "xsc @srclist $args";

    #run xsc compiler
    system($cmd);
}

#open waveform dump in gui
sub gui {
    #construct xsim gui command
    my $wfile;

    if (defined $dumpfile) {
        $wfile = $dumpfile;
    } else {
        $wfile = "$config{'elaboration'}{'tbName'}.wdb";
    }
    my $cmd = "xsim --gui $wfile";

    #run xsim gui
    system($cmd);
}#gui

#generate html dashboard from coverage db
sub genCov {
    my $cmd = "xcrg -report_format html -dir xsim.covdb";

    #run xcrg
    system($cmd);
}

#open coverage dashboard
sub covDash {
    #navigate to generated coverage dashboard dir
    prjTop();
    chdir "xcrg_func_cov_report";

    #open coverage dashboard html
    system("dashboard.html");
}

exit 0;

=head2

=head1 DVM - Lumberjacks Vivado Manager

=head2

=head2 DVM is a tool to manage, compile, elaborate and simulate SystemVerilog

=head2 and UVM based projects using XILINX VIVADO xvlog, xelab and xsim tools.

=head2

=head1 USAGE:

=head2

=head2 -help, -h                        displays this help

=head2

=head1 required args (at least one of the following):

=head2

=head2 -new=[PROJECT NAME]              creates a new DVM project with [PROJECT NAME] nam under the current working directory

=head2 -module=[MODULE NAME]            generates a SystemVerilog module template under {DVMprojectTop}/design/src

=head2 -comp                            compile project

=head2 -elab                            elaborate project

=head2 -run                             run project simulation

=head2 -all                             compiles and elaborates project then runs test simulation

=head2 -runsv                           runs pure SystemVerilog simulation (ingores UVM arguments and config)

=head2 -dpi                             compiles C code to link into a snapshot during elaboration using DPI-C

=head2 -gui                             runs Vivado GUI and loads default waveform db specified in config file

=head2 

=head1 compilation args:

=head2

=head2 -complog=[COMP LOG NAME]         specifies compilation log filename (ignores config)

=head2 -complist=[COMPILE LIST]         specifies compile list for compilation (ignores config)

=head2 

=head1 elaboration args:

=head2

=head2 -elablog=[ELAB LOG NAME]         specifies elaboration log name (ignores config)

=head2 -timescale=[TIMESCALE]           specifies timescale for elaborated testbench snapshot (ignores config)

=head2 -tbtop=[TESTBENCH TOP MODULE]    specifies testbench top module to be elaborated (ignores config)

=head2 -tb=[TESTBENCH SNAPSHOT]         specifies testbench snapshot created by elaboration (ignores config)

=head2

=head1 simulation args:

=head2

=head2 -simlog=[SIM LOG NAME]           specifies simulation run log name (ignores config)

=head2 -test=[TEST NAME]                specifies uvm test to be run with dvm -run (ignores config)

=head2 -batch                           run a batch of UVM tests from a test list (ignores config)

=head2 -testlist=[TEST LIST FILE]       specifies test list file for batch test run (ignores config)

=head2 -uvmverb=UVM_[VERBOSITY]         specifies UVM verbosity level for simulation log (ignores config)

=head2 -simtb=[TESTBENCH SNAPSHOT]      specifies testbench snapshot used for simulation (ignores config)

=head2

=head1 dpi compilation args:

=head2

=head2 -dpilist=[DPI COMPILE LIST]      specifies compile list for dpi C code compilation (ignores config)

=head2

=head1 multi-stage args:

=head2

=head2 -wave                            specifies waveform dump for elaboration and simulation

=head2 -dumpfile=[WF DUMP FILE]         specifies waveform dump database (ignores config)

=head2 

=head1 misc args:

=head2

=head2 -configfile=[DVM CONFIG FILE]    specifies DVM project config file

=head2 -path=[RELATIVE PATH]            specifies sv module template path relative to {DVMprojectTop}/design/src

=head2 

=head1 EXAMPLE:

=head2

=head2 dvm -all -batch -testlist=./best_rtl_tests.f -wave

=head2

=head1 NOTES:

=head2

=head2 1. args ignoring config do not have to be provided if they are configured in the DVM config file

=head2 2. args ignoring config do not overwrite the DVM config file, they are passed to vivado tools @ run time

=head2 3. in case of running -all and -tb is provided without providing -simtb, simulation will be run on the snapshot provided by -tb

=head2 4. '-L uvm' args for compilation and elaboration are configured by default in the DVM config file

=head2 5. for DVM project documentation refer to https://github.com/vtoth2/dvm

=cut

#TODO:
#quiet cmd calls
__END__
:endofperl
@set "ErrorLevel=" & @goto _undefined_label_ 2>NUL || @"%COMSPEC%" /d/c @exit %ErrorLevel%
