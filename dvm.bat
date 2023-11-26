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

    #vivado
    'comp'          => \my $comp,
    'elab'          => \my $elab,
    'run'           => \my $run,
    'test=s'        => \my $test,
    'all'           => \my $all,
    'wave'          => \my $wave,
    'gui'           => \my $gui,
    'dumpfile=s'    => \my $dumpfile,

    #help
    'help'          => \my $help,
);

#global vars
our $prjpath;
our $configname;
our %config;
our %fileTemplates;

#arg parsing
if (defined $all) {
    $comp = 1;
    $elab = 1;
    $run = 1;
}
pod2usage(-verbose => 2) and exit 0 if defined $help;
print "No required arguments provided!\n\nFor more info use -help or -h\n" and exit 1 if not defined $prjname and not defined $comp and not defined $elab and not defined $run and not defined $gui;
print "UVM test provided without running simulation - option will be ignored...\n" and undef $test if defined $test and not defined $run;
print "Waveform dump option used without running elaboration or simulation - option will be ignored...\n" and undef $wave if defined $wave and not defined $elab and not defined $run;
print "Vivado GUI option provided while running compilation, elaboration or simulation - option will be ignored...\n" and undef $gui if defined $gui and (defined $comp or defined $elab or defined $run);
print "Waveform dump file provided without running Vivado GUI - option will be ignored...\n" and undef $dumpfile if defined $dumpfile and not defined $gui;

#script config
$fileTemplates{'prjConfig'}     = "$dvmpath\\templates\\dvmproject.conf.template";
$fileTemplates{'tbTop'}         = "$dvmpath\\templates\\dvm_tb_top.sv.template";
$fileTemplates{'compileList'}   = "$dvmpath\\templates\\dvm_compile_list.f.template";
$fileTemplates{'wfcfg'}         = "$dvmpath\\templates\\wfcfg.tcl.template";

$configname = 'dvmproject.conf';
$configname = $cconfigname if defined $cconfigname;

#main
main();

#script body
#TODO: batch test run
sub main {
    #DVM project creation
    createNewProject($prjname) and exit 0 if defined $prjname;
    
    print "Loading DVM project config...\n";

    #load config hash from config file
    loadConfig();

    #init prjpath and sim test
    $prjpath = $config{'project'}{'dir'};
    $test = $config{'simulation'}{'defTest'} if not defined $test;

    #navigate to DVM project top
    prjTop();

    print "DVM project config loaded.\n";

    #vivado wrappers
    compile() if defined $comp;
    elab() if defined $elab;
    runsim() if defined $run;
    gui() if defined $gui;
}

#create new project
#TODO: parametrize template file generation
sub createNewProject {
    my ($name) = @_;
    my $newprjdir = getcwd();
    $newprjdir = "$newprjdir/$name";

    print "Generating new DVM project: $name\n";

    mkdir "$name";
    chdir "$name";

    mkdir "dvm";
    chdir "dvm";

    my $confdata = pUtils::readFile($fileTemplates{'prjConfig'});
    $confdata = pUtils::replace("{{prjdir}}", $newprjdir, $confdata);
    $confdata = pUtils::replace("{{prjname}}", $name, $confdata);
    pUtils::genFile("dvmproject.conf", "$confdata");

    my $cldata = pUtils::readFile($fileTemplates{'compileList'});
    $cldata = pUtils::replace("{{prjname}}", $name, $cldata);
    pUtils::genFile("$name\_compile_list.f", $cldata);

    my $wfcfg = pUtils::readFile($fileTemplates{'wfcfg'});
    pUtils::genFile("wfcfg.tcl", "$wfcfg");

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

sub loadConfig {
    my @configpath = pUtils::findFile($configname, ".");
    my $configData = pUtils::readFile($configpath[0]);

    %config = eval $configData;
}

#navigate to DVM project top
sub prjTop {
    chdir "$prjpath/dvm";
}

sub compile {
    #construct xvlog cmd
    my $cmd = "xvlog -sv -f $config{'compilation'}{'list'} -log $config{'compilation'}{'log'} $config{'compilation'}{'args'}";

    #run xvlog
    #system
print($cmd);
}

sub elab {
    #construct xelab cmd
    my $args = "$config{'elaboration'}{'args'}";
    $args = "$args -debug wave" if defined $wave;
    my $cmd = "xelab $config{'elaboration'}{'tbTop'} -relax -s $config{'elaboration'}{'tbName'} -timescale $config{'elaboration'}{'timescale'} -log $config{'elaboration'}{'log'} $args";

    #runc xelab
    #system
print($cmd);
}

sub runsim {
    #construct xsim cmd
    my $args = "$config{'simulation'}{'args'}";
    if (not defined $wave) {
        $args = "-R $args";
    } else {
        $args = "--tclbatch wfcfg.tcl $args";
    }
    my $cmd = "xsim $config{'elaboration'}{'tbName'} -log $config{'simulation'}{'log'} -testplusarg \"UVM_VERBOSITY=$config{'simulation'}{'verbosity'}\" -testplusarg \"UVM_TESTNAME=$test\" $args";

    #run xsim
    #system
print($cmd);
}

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
    #system
print($cmd);
}

exit 0;

=head2

=head1 DVM - Lumberjacks Vivado Manager

=head2

=head2 DVM is a tool to manage, compile, elaborate and simulate #system
printVerilog

=head2 and UVM based projects using XILINX VIVADO xvlog, xelab and xsim tools.

=head2

=head1 USAGE:

=head2

=head2 At least 1 argument marked with '*' required

=head2

=head2  -help/-h                         displays this help

=head2

=head2  -new=[PROJECT NAME]     *        creates a new DVM project with [PROJECT NAME] in the current working directory

=head2  -comp                   *        compile project

=head2  -elab                   *        elaborate project

=head2  -run                    *        run project simulation

=head2  -all                    *        compiles and elaborates project then runs test simulation

=head2 

=head2 -wave                            generate waveform database

=head2 -gui                             runs Vivado GUI and loads default waveform db

=head2 -dumpfile=[WF DUMP FILE]         specifies waveform dump for -gui

=head2 -test=[TEST NAME]                specifies uvm test to be run with dvm -run

=head2 -configfile=[DVM CONFIG FILE]    specifies DVM config file if not using the default one

=head2

=head1 EXAMPLE:

=head2

=head2 dvm -all -test=best_rtl_project_fulltest -wave

=head2

=head1 NOTES:

=head2

=head2 1. uvm test does not need to be provided if a default test to be run is configured in the DVM cofig file

=head2 2. '-L uvm' args for compilation and elaboration are configured by default in the DVM config file

=cut

#TODO:
#detect invalid arg combinations:
#-dumpfile wo -gui
__END__
:endofperl
@set "ErrorLevel=" & @goto _undefined_label_ 2>NUL || @"%COMSPEC%" /d/c @exit %ErrorLevel%
