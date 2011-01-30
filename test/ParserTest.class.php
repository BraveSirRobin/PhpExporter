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

/**
 * A test suite for the Code Parsing code.  This one parses all PHP
 * code found from a given base directory, and outputs it
 * all to a file.  The XML must be valid in all cases for the tests
 * to pass
 */
$classes = get_declared_classes();
$interfaces = get_declared_interfaces();
require('TestSuite.class.php');
require('../CodeParser.class.php');
require('../OutputWriter.class.php');

class ParserTest extends TestSuite
{
    private $mybase;

    private $recursive_base = '/home/robin/dev/framework/';

    function setup() {
        global $interfaces, $classes;
        $this->mybase = dirname(__FILE__) . '/out';
        if (is_dir($this->mybase)) {
            $this->delTree($this->mybase);
            mkdir($this->mybase);
        }
        else {
            mkdir($this->mybase);
        }
        OutputWriter::Object()->setNativeInterfaces($interfaces);
        OutputWriter::Object()->setNativeClasses($classes);
    }

    function testSingleInputConcatOutput(&$output) {
        echo "\n\ttestSingleInputConcatOutput\n";
        $p = new CodeParser;
        $tgt = $this->mybase . '/testSingleInputConcatOutput_results.xml';
        OutputWriter::Object()->setOutputGran(OutputWriter::OUTPUT_CONCAT);
        OutputWriter::Object()->setOutputTarget($tgt);
        $p->parse(dirname(__FILE__) . '/sample.php');
    }

    function testSingleInputFileOutput(&$output) {
        echo "\n\ttestSingleInputFileOutput\n";
        $p = new CodeParser;
        $tgt = $this->mybase . '/testSingleInputFileOutput_results';
        mkdir($tgt);
        //Currently this produces broken XML
        OutputWriter::Object()->setOutputGran(OutputWriter::OUTPUT_GRAN_FILE);
        OutputWriter::Object()->setOutputTarget($tgt);
        $p->parse(dirname(__FILE__) . '/sample.php');
    }

    function testSingleInputClassOutput(&$output) {
        echo "\n\ttestSingleInputClassOutput\n";
        $p = new CodeParser;
        $tgt = $this->mybase . '/testSingleInputClassOutput_results';
        mkdir($tgt);
        OutputWriter::Object()->setOutputGran(OutputWriter::OUTPUT_GRAN_CLASS);
        OutputWriter::Object()->setOutputTarget($tgt);
        $p->parse(dirname(__FILE__) . '/sample.php');
    }

    function testRecursiveInputConcatOutput(&$output) {
        echo "\n\ttestRecursiveInputConcatOutput\n";
        $p = new CodeParser;
        $tgt = $this->mybase . '/testRecursiveInputConcatOutput_results.xml';
        OutputWriter::Object()->setOutputGran(OutputWriter::OUTPUT_CONCAT);
        OutputWriter::Object()->setOutputTarget($tgt);
        $p->parseRecursive($this->recursive_base);
    }
    function testRecursiveInputFileOutput(&$output) {
        echo "\n\ttestRecursiveInputFileOutput\n";
        $p = new CodeParser;
        $tgt = $this->mybase . '/testRecursiveInputFileOutput';
        mkdir($tgt);
        OutputWriter::Object()->setOutputGran(OutputWriter::OUTPUT_GRAN_FILE);
        OutputWriter::Object()->setOutputTarget($tgt);
        $p->parseRecursive($this->recursive_base);
    }

    function testRecursiveInputClassOutput(&$output) {
        echo "\n\ttestRecursiveInputClassOutput\n";
        $p = new CodeParser;
        $tgt = $this->mybase . '/testRecursiveInputClassOutput';
        mkdir($tgt);
        OutputWriter::Object()->setOutputGran(OutputWriter::OUTPUT_GRAN_CLASS);
        OutputWriter::Object()->setOutputTarget($tgt);
        $p->parseRecursive($this->recursive_base);
    }



    private function deltree($f){
        if( is_dir($f)){
            foreach( scandir($f) as $item ){
                if( !strcmp($item, '.') || ! strcmp($item, '..')) {
                    continue;
                }
                $this->deltree( $f . "/" . $item );
            }
            rmdir($f);
        }
        else{
            unlink($f);
        }
    }
}

$t = new ParserTest;
$t->runTests();

var_dump($t->getFailures());
?>
