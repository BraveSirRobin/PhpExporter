#! /usr/bin/php
<?php
/**
 * 
 * Copyright (C) 2007 - 2011  Robin Harvey (harvey.robin@gmail.com)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */






/** Get a reliable list of native classes and interfaces **/
$classes = get_declared_classes();
$interfaces = get_declared_interfaces();

require(dirname(__FILE__) . '/CodeParser.class.php');
require(dirname(__FILE__) . '/OutputWriter.class.php');


class CLICommand
{

    private $default_file_output = 'ParsedCode.xml';
    private $default_dir_output = 'parsedcode.d';

    private $gran = OutputWriter::OUTPUT_CONCAT;
    private $out;
    private $tgt;

    function run() {
        global $classes, $interfaces;
        $p = new CodeParser;
        OutputWriter::Object()->setNativeInterfaces($interfaces);
        OutputWriter::Object()->setNativeClasses($classes);
        OutputWriter::Object()->setOutputGran($this->gran);
        OutputWriter::Object()->setOutputTarget($this->out);
        //if ($this->gran == OutputWriter::OUTPUT_GRAN_CLASS || $this->gran == OutputWriter::OUTPUT_GRAN_FILE) {
        if (is_dir($this->tgt)) {
            $p->parseRecursive($this->tgt);
        }
        else {
            $p->parse($this->tgt);
        }
    }

    /**
     * Parse the commandline args.
     */
    function __construct() {
        global $argv;

        $recv = '';
        foreach ($argv as $i => $arg) {
            if ($i == 0) {
                continue;
            }
            if ($recv == '' && substr($arg, 0, 2) == '--') {
                switch ($arg) {
                case '--gran':
                    $recv = 'GRAN';
                    continue;
                case '--out':
                    $recv = 'OUT';
                    continue;
                case '--help':
                    die($this->usage);
                default:
                    echo "\nUnknown Option '$arg'";
                    continue;
                }
            }
            else if ($recv) {
                switch ($recv) {
                case 'GRAN':
                    if (strtolower($arg) == 'class') {
                        $this->gran = OutputWriter::OUTPUT_GRAN_CLASS;
                    }
                    else if (strtolower($arg) == 'file') {
                        $this->gran = OutputWriter::OUTPUT_GRAN_FILE;
                    }
                    else if (strtolower($arg) == 'concat') {
                        $this->gran = OutputWriter::OUTPUT_CONCAT;
                    }
                    else {
                        echo "\nWARNING: bad output granularity: $arg\n";
                    }
                    $recv = '';
                    continue;
                case 'OUT':
                    $this->out = $arg;
                    $recv = '';
                    continue;
                }
            }
            else if (! $this->tgt) {
                $this->tgt = $arg;
            }
            else {
                echo "\nBad command line args, ignoring $arg";
            }
        } //foreach

        if (! $this->tgt) {
            die("\nNo parse target, exiting\n");
        }
        //TODO: $pstyle not used.
        if (is_dir($this->tgt)) {
            $pstyle = 'recursive';
        }
        else if (is_file($this->tgt)) {
            $pstyle = 'flat';
        }
        else {
            die("\nBad parsing target {$this->tgt}\n");
        }

        //Sanify the output and granularity
        if ($this->gran == OutputWriter::OUTPUT_GRAN_FILE || $this->gran == OutputWriter::OUTPUT_GRAN_CLASS) {
            if (! $this->out) {
                $this->out = $this->default_dir_output;
            }
            //Check for suitable output dir
            if (is_dir($this->out)) {
                die("\nOutput Dir {$this->out} already exists\n");
            }
            else if (is_file($this->out)) {
                die("\nThe given output Dir '{$this->out}' is a file!\n");
            }
            else if (! @mkdir($this->out)) {
                die("\nFailed to create output directory $dir\n");
            }
        }
        else if ($this->gran == OutputWriter::OUTPUT_CONCAT) {
            if (! $this->out) {
                $this->out = $this->default_file_output;
            }
            if (is_file($this->out)) {
                die("\nOutput file {$this->out} already exists\n");
            }
            else if (! is_writable(dirname($this->out))) {
                die("\nCannot write in the specified output directory '" . dirname($this->out) . "'\n");
            }
        }
        //Sanify the target
        if (! (is_dir($this->tgt) || is_file($this->tgt))) {
            die("\nParse target does not exist: {$this->tgt}\n");
        }
    }

    private $usage = "USAGE:\ncode_parser [--gran concat|file|class] [--out file|dir] file|dir\n";
}

$c = new CLICommand;
$c->run();

?>
