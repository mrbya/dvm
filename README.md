# DVM - Lumberjacks Vivado Manager

**DVM** is a **Perl** based tool to manage, compile, elaborate and simulate SystemVerilog
and UVM based projects using **XILINX VIVADO** xvlog, xelab and xsim tools.

## Requirements

1. [Vivado Design Suite](https://www.xilinx.com/support/download.html)
2. [Perl](https://www.perl.org/get.html)
3. *[Vivado Install dir]/lib/win64.o* and *[Vivado Install dir/bin]* added to your **PATH**
4. have a **XILINX_PATH** env variable pointing to your Vivado install dir

## Installation

1. Download the latest release of **DVM** or clone the repository
2. Manually add dvm directory to your **PATH** and create an environment variable **dvmPath** pointing to your dvm directory **or** run `initDvm.bat` script

## Contents

1. `dvm.pl` - DVM main script
2. `dvm.bat` - batchfile wrapper for `dvm.pl` to use on Windows
3. `pUtils.pm` - Perl package containing utility subroutines for `dvm.pl`
4. `initDvm.bat` - init script for adding dvm to **PATH** and adding **dvmPath** env variable
5. `templates` - directory containing file templates for **DVM**

## Usage

To manage a **DVM** project use the `dvm` script inside a **DVM** project directory.

For exact usage documentation of the script use `dvm -help`

### New project

To create a new project under your current working directory use `dvm -new=[PROJECT NAME]` (Whitespaces in **DVM** project name are not allowed).

DVM will create a new directory with *[PROJECT NAME]* with all the required directories and config files.

**Example:**
```
[mycodes/vivado]$ dvm -new=best_rtl_project
Generating new DVM project: best_rtl_project
New project created.

[mycodes/vivado]$ cd best_rtl_project

[mycodes/vivado/best_rtl_project]$ 
```

### Project configuration

DVM projects are configured by their *dvmproject.conf* config file located under `...path_to_project/dvm` containing a Perl hash with the following data:

#### project

* **dir** - DVM project directory
* **dvmDir** - DVM project output and config directory (excluding the path to the DVM project)

#### compilation

* **list** - compile list for xvlog (compile list has to be located under the dvm config directory *dvmDir*)
* **log** - xvlog compilation log name (include path if you want to generate log outside DVM project dir)
* **args** - list of additional arguments used during xvlog compilation (`-L uvm` arg configured by default)

#### elaboration

* **tbTop** - top module of the testbench (excluding file extension - default: [PROJECT NAME]_tb_top)
* **tbName** - name of the testbench snapshot created during elaboration
* **timescale** - timescale used for elaboration and simulation (default: 1ns/1ps)
* **log** - xelab elaboration log name (include path if you want to generate log outside DVM project dir)
* **args** - list of additional arguments used during xvlog compilation (`-debug wave` included when using `-wave` option)

#### simulation

* **log** - xsim simulation log name (include path if you want to generate log outside DVM project dir)
* **verbosity** - UVM message verbosity (default: UVM_LOW)
* **defTest** - default UVM test used by `dvm -run` (if not configured need to specify using the `-test` option)
* **args** - list of additional arguments used during xsim simulation (`--tclbatch wfcfg.tcl` included when using `-wave` option)

### Config example

```
(
    'project'     => {
        'dir'       => 'C:/Users/viktor.toth/Desktop/This/mycodes/dvm/best_rtl_project',
        'dvmDir'    => 'dvm',
    },

    'compilation' => {
        'list'      => 'best_rtl_project_compile_list.f',
        'log'       => 'comp.log',
        'args'      => '-L uvm',
    },

    'elaboration' => {
        'tbTop'     => 'best_rtl_project_tb_top',
        'tbName'    => 'top',
        'timescale' => '1ns/1ps',
        'log'       => 'elab.log',
        'args'      => ' ',
    },

    'simulation'  => {
        'log'       => 'sim.log',
        'verbosity' => 'UVM_LOW',
        'defTest'   => 'best_rtl_project_full_test',
        'args'      => ' ',
    },
)
```

## Project compilation

Compile project using `dvm -comp`

**Example:**
```
[mycodes/vivado/alu_uvm_test/dvm]$ dvm -comp
Loading DVM project config...
DVM project config loaded.
ECHO is off.
ECHO is off.
INFO: [VRFC 10-2263] Analyzing SystemVerilog file "C:/Users/viktor.toth/Desktop/This/mycodes/vivado2/alu_uvm_test/design/src/alu.sv" into library work
INFO: [VRFC 10-311] analyzing module alu
INFO: [VRFC 10-2263] Analyzing SystemVerilog file "C:/Users/viktor.toth/Desktop/This/mycodes/vivado2/alu_uvm_test/verif/env/agents/alu_agent/alu_agent_pkg.sv" into library work
INFO: [VRFC 10-2263] Analyzing SystemVerilog file "C:/Users/viktor.toth/Desktop/This/mycodes/vivado2/alu_uvm_test/verif/env/ref_model/alu_ref_model_pkg.sv" into library work
INFO: [VRFC 10-2263] Analyzing SystemVerilog file "C:/Users/viktor.toth/Desktop/This/mycodes/vivado2/alu_uvm_test/verif/env/top/alu_env_pkg.sv" into library work
INFO: [VRFC 10-2263] Analyzing SystemVerilog file "C:/Users/viktor.toth/Desktop/This/mycodes/vivado2/alu_uvm_test/verif/test/seq/alu_seq_pkg.sv" into library work
INFO: [VRFC 10-2263] Analyzing SystemVerilog file "C:/Users/viktor.toth/Desktop/This/mycodes/vivado2/alu_uvm_test/verif/test/src/alu_test_pkg.sv" into library work
INFO: [VRFC 10-2263] Analyzing SystemVerilog file "C:/Users/viktor.toth/Desktop/This/mycodes/vivado2/alu_uvm_test/verif/tb/src/alu_uvm_test_tb_top.sv" into library work
INFO: [VRFC 10-311] analyzing module alu_uvm_test_tb_top

[mycodes/vivado/alu_uvm_test/dvm]$
```

## Project elaboration

Elaborate project using `dvm -elab`

**Example:**
```
[mycodes/vivado/alu_uvm_test/dvm]$ dvm -elab
Loading DVM project config...
DVM project config loaded.
ECHO is off.
ECHO is off.
Vivado Simulator v2023.2
Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
Running: C:/Xilinx/Vivado/2023.2/bin/unwrapped/win64.o/xelab.exe alu_uvm_test_tb_top -relax -s top -timescale 1ns/1ps -log elab.log
Multi-threading is on. Using 10 slave threads.
Starting static elaboration
Pass Through NonSizing Optimizer
Completed static elaboration
Starting simulation data flow analysis
WARNING: [XSIM 43-4468] File : /proj/xbuilds/SWIP/9999.0_0820_0302/installs/lin64/Vivado/2024.1/data/system_verilog/uvm_1.2/xlnx_uvm_package.sv, Line : 25994, RANDC variable size more than 8 bits. This will be treated as a RAND variable instead.
Completed simulation data flow analysis
Time Resolution for simulation is 1ps
Compiling package work.alu_test_pkg
Compiling package uvm.uvm_pkg
Compiling package std.std
Compiling package work.alu_agent_pkg
Compiling package work.alu_ref_model_pkg
Compiling package work.alu_env_pkg
Compiling package work.alu_seq_pkg
Compiling module work.dr_cb
Compiling module work.rc_cb
Compiling module work.alu_interface
Compiling module work.alu
Compiling module work.alu_uvm_test_tb_top
Built simulation snapshot top

[mycodes/vivado/alu_uvm_test/dvm]$
```

## Running simulation

Run simulation using `dvm -run`

Need to provide a UVM test using the `-test` option if a default UVM test is not configured.

**Example:**
```
[mycodes/vivado/alu_uvm_test/dvm]$ dvm -run
Loading DVM project config...
DVM project config loaded.
Use of uninitialized value in concatenation (.) or string at C:\Users\viktor.toth\Desktop\This\mycodes\dvm/dvm.bat line 207.
The syntax of the command is incorrect.

C:\Users\viktor.toth\Desktop\This\mycodes\vivado2\alu_uvm_test\dvm>dvm -run
Loading DVM project config...
DVM project config loaded.
The syntax of the command is incorrect.

C:\Users\viktor.toth\Desktop\This\mycodes\vivado2\alu_uvm_test\dvm>dvm -run
Loading DVM project config...
DVM project config loaded.
ECHO is off.
ECHO is off.

****** xsim v2023.2 (64-bit)
  **** SW Build 4029153 on Fri Oct 13 20:14:34 MDT 2023
  **** IP Build 4028589 on Sat Oct 14 00:45:43 MDT 2023
  **** SharedData Build 4025554 on Tue Oct 10 17:18:54 MDT 2023
    ** Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
    ** Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.

source xsim.dir/top/xsim_script.tcl
# xsim {top} -testplusarg UVM_VERBOSITY=UVM_LOW -testplusarg UVM_TESTNAME=alu_test_cmp_short -autoloadwcfg -runall
Time resolution is 1 ps
run -all

***SIMULATION LOG***
.
.
.
***SIMULATION LOG***

$finish called at time : 2045 ns : File "C:\Xilinx\Vivado\2023.2/data/system_verilog/uvm_1.2/xlnx_uvm_package.sv" Line 18699
exit
INFO: [Common 17-206] Exiting xsim at Sun Nov 26 23:27:22 2023...

[mycodes/vivado/alu_uvm_test/dvm]$
```

## Full run

Compilation, elaboration and simulation steps can be executed in sequence using the `-all` option.

## Waveform dump

DVM does not instruct xelab and xsim to dump waveforms by default. To dump simulation waveforms use the `-wave` option or configure the coresponding elaboration and simulation args in the DVM config file.

DVM `-wave` option dumps all waveforms into a `.wdb` database named after the testbench snapshot.

To subsequently view the waveforms start Vivado GUI using `dvm -gui`
