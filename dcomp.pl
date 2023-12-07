#!/usr/bin/perl

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
    #dcomp
    'source=s'      => \my $source,

    #help
    'help'          => \my $help,
    'debug'         => \my $debug,
);

#global vars
our $isapath = "$dvmpath/dcomp/isa.conf";
our %isa;

#arg parsing

#main
main();

sub main {
    loadIsa();

    my $sdata = pUtils::readFile($source);
    my @slines = pUtils::getList($sdata);

    my $hex = "";

    foreach (@slines) {
        open(f, '>', "test.hex") or die $!;
        if (index($_, "i_") != -1) {
            my $res = 0;
            my $sline = substr($_, index($_, "i_"), length($_));
            my ($inst) = $sline =~ /^(\S+)/;
            $inst = substr($inst, 2, length($inst));

            #add opcode
            $res = $res | ($isa{'inst'}{$inst} << 12);

            if (index($sline, "rd") != -1) {
                $sline = substr($sline, index($sline, "rd"), length($sline));
                my ($rd) = $sline =~ /^(\S+)/;
                $rd = substr($rd, 2, length($rd));
                $rd = int($rd);

                #dd rd
                $res = $res | ($rd << 9);
            }

            if (index($sline, "ra") != -1) {
                $sline = substr($sline, index($sline, "ra"), length($sline));
                my ($ra) = $sline =~ /^(\S+)/;
                $ra = substr($ra, 2, length($ra));
                $ra = int($ra);

                #dd ra~
                $res = $res | ($ra << 5);
            }

            if (index($sline, "rb") != -1) {
                $sline = substr($sline, index($sline, "rb"), length($sline));
                my ($rb) = $sline =~ /^(\S+)/;
                $rb = substr($rb, 2, length($rb));
                $rb = int($rb);

                #dd rb
                $res = $res | ($rb << 2);
            }

            if (index($sline, "imm_") != -1) {
                $sline = substr($sline, index($sline, "imm_"), length($sline));
                my ($imm) = $sline =~ /^(\S+)/;
                $imm = substr($imm, 4, length($imm));
                $imm = int($imm);

                #dd imm
                $res = $res | $imm;
            }

            if (index($sline, "c_") != -1) {
                $sline = substr($sline, index($sline, "c_"), length($sline));
                my ($cond) = $sline =~ /^(\S+)/;
                $cond = substr($cond, 2, length($cond));
                $cond = int($cond);

                #dd cond imm
                $res = $res | $isa{'cond'}{$cond};
            }

            $res = sprintf("%x\n", $res);
            $hex = "$hex$res";
        }
    }

    $hex = substr($hex, 0, length($hex) - 1);
    print f $hex;
    close(f);
}#main

#load isa hash
sub loadIsa {
    my $isaData = pUtils::readFile($isapath);

    %isa = eval $isaData;
}#loadIsa

exit 0;

=head2

=head1 dcomp - Lumberjacks Compiler

=head2

=head2 dcomp is a tool to... ehm... "compile" pseudoassembly code of my own ISA

=head2

=head1 USAGE:

=head2

=head2 dcomp -source/-s=[Source file]
