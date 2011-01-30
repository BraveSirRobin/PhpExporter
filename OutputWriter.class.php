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
 * Class to handle events during code parsing and output the
 * intermediate XML format.  Events are written to target XML
 * files using the XMLWriter built-in object.  This class contains
 * logic to allow output on different 'granularities' - see the 
 * OUTPUT_* consts.
 *
 */

class OutputWriter
{
    const OUTPUT_CONCAT = 1;//Output in one big file
    const OUTPUT_GRAN_FILE = 2;//One output file for each inputted file.
    const OUTPUT_GRAN_CLASS = 3;//One output file for each inputted class.

    /** singleton plumbing */
    private static $inst = null;
    private function __construct() {}
    static function Object() {
        return (is_null(self::$inst)) ? (self::$inst = new OutputWriter) : self::$inst;
    }

    /** Class proper */
    private $in_capture = false;
    private $w = null; //XMLWriter goes here.

    /*
     * Getters and setters for the output granularity and desitation
     * flags.
     */
    private $gran = self::OUTPUT_CONCAT;
    private $tgt = './ParsedCode.xml';
    function setOutputGran($gran) {
        if ($this->in_capture) {
            die("\nDo no change the output granularity during parsing!\n");
        }
        $this->gran = $gran;
    }
    function getOutputGran() {
        return $this->gran;
    }
    function setOutputTarget($tgt) {
        if ($this->in_capture) {
            die("\nDo no change the output target during parsing!\n");
        }
        $this->tgt = $tgt;
    }
    function getOutputTarget() {
        return $this->tgt;
    }

    /**
     * Getters, setters and info methods for listing native classes,
     * designed to work with the output of the built-in get_declared_xxx()
     * functions.
     * Usage: $obj->setNativeInterfaces(get_declared_interfaces())
     *        $obj->setNativeClasses(get_declared_classes())
     */
    private $nclasses;
    private $ninterfaces;
    function setNativeInterfaces(array $arr) {
        $this->ninterfaces = $arr;
    }
    function getNativeInterfaces() {
        return $this->ninterfaces;
    }
    function isNativeInterface($ifc) {
        return in_array($ifc, $this->ninterfaces);
    }

    function setNativeClasses(array $arr) {
        $this->nclasses = $arr;
    }
    function getNativeClasses(array $arr) {
        return $this->nclasses;
    }
    function isNativeClass($cls) {
        return in_array($cls, $this->nclasses);
    }




    /**
     * Convenience: check the outut target and output granularity match,
     * and that the target is writable
     */
    private function checkConfig() {
        switch ($this->gran) {
        case self::OUTPUT_GRAN_FILE:
        case self::OUTPUT_GRAN_CLASS:
            if (! is_dir($this->tgt)) {
                return "Output dir {$this->tgt} is not a directory";
            }
            else if (! is_writable($this->tgt)) {
                return "Output dir {$this->tgt} is not writable";
            }
            break;
        default:
            echo "WARNING: Unknown output granularity: {$this->gran}, defaulting to OUTPUT_CONCAT";
            $this->gran = self::OUTPUT_CONCAT;
        case self::OUTPUT_CONCAT:
            if (is_file($this->tgt)) {
                return "Output target {$this->tgt} already exists";
            }
            if (! is_writable(dirname($this->tgt))) {
                return "Output Dir" . dirname($this->tgt) . "Is not writable";
            }
            break;          
        }
        return false;
    }

    /**
     * Call this whenever a file name is needed.  Examines current
     * granularity and ensures uniqueness.  If the given event should not
     * produce any output, false is returned
     */
    private function getEventOutputTarget($ev, $src_name = '') {
        $dir = ($this->gran == self::OUTPUT_CONCAT) ? dirname($this->tgt) : $this->tgt;
        switch ($ev) {
        case 'startOutput':
            if ($this->gran == self::OUTPUT_CONCAT) {
                return $this->tgt;
            }
            return false;
        case 'startFile':
            $ret = $dir . '/' . basename($src_name) . '_file.xml';
            break;
        case 'startClass':
            $ret = $dir . '/' . basename($src_name) . '_class.xml';
            break;
        case 'startInterface':
            $ret = $dir . '/' . basename($src_name) . '_interface.xml';
            break;
        default:
            throw new Exception("Event '$ev' should not need to generate an output target.", 98758);
        }
        switch ($this->gran) {
        case self::OUTPUT_CONCAT:
            return false;
            break;
        case self::OUTPUT_GRAN_FILE:
            return ($ev == 'startFile') ? $ret : false;
            break;
        case self::OUTPUT_GRAN_CLASS:
            return ($ev == 'startClass' || $ev == 'startInterface') ? $ret : false;
            break;
        }
        throw new Exception("Farking twotheimer shinkleplarp", 98665);
    }

    /**
     * Convenience: start a new XMLWriter, making sure to flush the old one,
     * if required.
     */
    private function startNewWriter($tgt, $parse_target = false) {
        if ($this->w instanceof XMLWriter) {
            $this->w->flush();
        }
        $this->w = new XmlWriter;
        $this->w->openURI($tgt);
        $this->w->setIndent(true);
        $this->w->setIndentString('  ');
        $this->w->startDocument('1.0', 'UTF-8');
        $this->w->startElement('parsed-code');
        $this->w->writeAttribute('parse-date', date('Y-m-d\TH:i:s\Z'));
        if ($parse_target) {
            $this->w->writeAttribute('base', $parse_target);
        }
    }

    /**
     * Convenience
     */
    private function genericEndObject() {
        if ($this->w instanceof XMLWriter) {
            $this->w->endElement();
        }
    }

    /**
     * Convenience function which strips leading whitespace from
     * multi-line documentation comments before they're written
     * to the output.
     */
    private function cleanDocComment($comm) {
        return preg_replace("/^(\s*)(.*$)/m", "$2", $comm);
    }



    /**
     * Event handlers - called from instances of CodeParser
     */
    private $curr_file;
    function startOutput($parse_target) {
        if ($this->in_capture) {
            throw new Exception('Cannot start multiple output sessions simultaneously!', 7689);
        }
        if ($err = $this->checkConfig()) {
            throw new Exception($err, 7809);
        }
        if ($tgt = $this->getEventOutputTarget('startOutput')) {
            $this->in_capture = true;//Moved inside
            $this->startNewWriter($tgt, $parse_target);
        }
        
    }

    function endOutput() {
        $this->genericEndObject();
        if ($this->gran == self::OUTPUT_CONCAT) {
            $this->w->flush();
            $this->in_capture = false;
        }
    }

    function startFile($file) {
        if ($this->gran == self::OUTPUT_GRAN_CLASS) {
            //File is omitted implicitly at this granularity
            return;
        }
        if ($tgt = $this->getEventOutputTarget('startFile', $file)) {
            $this->in_capture = true;
            $this->startNewWriter($tgt);
        }
        $this->w->startElement('file');
        $this->w->writeAttribute('href', $file);
    }

    function endFile() {
        if ($this->gran == self::OUTPUT_GRAN_CLASS) {
            //File is omitted implicitly at this granularity
            return;
        }
        $this->genericEndObject();
        if ($this->gran == self::OUTPUT_GRAN_FILE) {
            $this->genericEndObject();
            $this->w->flush();
            $this->in_capture = false;
        }
    }

    function startClass($data) {
        if ($tgt = $this->getEventOutputTarget('startClass', $data->name)) {
            $this->in_capture = true;
            $this->startNewWriter($tgt);
        }
        $this->writeComments($data);
        $this->w->startElement('class');
        if ($data->line_number) {
            $this->w->writeAttribute('line', $data->line_number);
        }

        $this->w->writeAttribute('name', $data->name);
        if ($data->abstract_flag) {
            $this->w->writeAttribute('abstract', 'true');
        }
        if ($data->ext) {
            $this->w->writeAttribute('super-class', $data->ext);
        }
        if ($data->is_native) {
            $this->w->writeAttribute('native', 'true');
        }
        if ($data->decl) {
            $this->w->writeAttribute('declaration', trim($data->decl));
        }
        if ($data->impl) {
            $this->w->startElement('implemented-interfaces');
            foreach ($data->impl as $ifc) {
                $this->w->writeElement('interface-ref', $ifc);
            }
            $this->w->endElement();
        }
    }

    function endClass() {
        $this->genericEndObject();
        if ($this->gran == self::OUTPUT_GRAN_CLASS) {
            $this->genericEndObject();
            $this->w->flush();
            $this->in_capture = false;
        }
    }

    function startInterface($data) {
        if ($tgt = $this->getEventOutputTarget('startInterface', $data->name)) {
            $this->in_capture = true;
            $this->startNewWriter($tgt);
        }
        $this->writeComments($data);
        $this->w->startElement('interface');
        if ($data->line_number) {
            $this->w->writeAttribute('line', $data->line_number);
        }

        $this->w->writeAttribute('name', $data->name);
        if ($data->abstract_flag) {
            $this->w->writeAttribute('abstract', 'true');
        }
        if ($data->ext) {
            $this->w->writeAttribute('super-class', $data->ext);
        }
        if ($data->is_native) {
            $this->w->writeAttribute('native', 'true');
        }
        if ($data->decl) {
            $this->w->writeAttribute('declaration', trim($data->decl));
        }
        if ($data->impl) {
            $this->w->startElement('implemented-interfaces');
            foreach ($data->impl as $ifc) {
                $this->w->writeElement('interface', $ifc);
            }
            $this->w->endElement();
        }
    }

    function endInterface() {
        //$this->genericEndObject();
        $this->genericEndObject();
        if ($this->gran == self::OUTPUT_GRAN_CLASS) {
            $this->genericEndObject();
            $this->w->flush();
            $this->in_capture = false;
        }
    }

    function startFunction($data) {
        if ($this->in_capture) {
            $this->funcImpl($data, 'function');
        }
    }
    function startMethod($data) {
        if ($this->in_capture) {
            $this->funcImpl($data, 'method');
        }
        else {
            var_dump($data);
            //die;
        }
    }

    private function funcImpl($data, $type) {
        $this->writeComments($data);
        $this->w->startElement($type);
        if ($data->line_number) {
            $this->w->writeAttribute('line', $data->line_number);
        }

        $this->w->writeAttribute('name', $data->func_name);
        if ($data->abstract_flag) {
            $this->w->writeAttribute('abstract', 'true');
        }
        if ($data->static_flag) {
            $this->w->writeAttribute('static', 'true');
        }
        if ($data->final_flag) {
            $this->w->writeAttribute('final', 'true');
        }
        if ($data->protected_flag) {
            $this->w->writeAttribute('protected', 'true');
        }
        if ($data->private_flag) {
            $this->w->writeAttribute('private', 'true');
        }
        if ($data->decl) {
            $this->w->writeAttribute('declaration', trim($data->decl));
        }
        if ($data->params) {
            foreach ($data->params as $prm) {
                $this->w->startElement('param');
                $this->w->writeAttribute('name', $prm->var);
                if ($prm->hint) {
                    $this->w->writeAttribute('type-hint', $prm->hint);
                }
                if ($prm->default) {
                    $this->w->writeAttribute('default', $prm->default);
                }
                if ($prm->by_ref_flag) {
                    $this->w->writeAttribute('by-ref', 'true');
                }
                $this->w->endElement();
            }
        }
    }

    function endFunction() {
        if ($this->in_capture) {
            $this->genericEndObject();
        }
    }
    function endMethod() {
        if ($this->in_capture) {
            $this->genericEndObject();
        }
    }
    function writeVariable() {
        //Not implemented ar the CodeParser level
    }

    function writeClassConst($data) {
        $this->writeComments($data);
        $this->w->startElement('const');
        if ($data->line_number) {
            $this->w->writeAttribute('line', $data->line_number);
        }

        $this->w->writeAttribute('name', $data->name);
        if ($data->private_flag) {
            $this->w->writeAttribute('private', 'true');
        }
        if ($data->final_flag) {
            $this->w->writeAttribute('final', 'true');
        }
        if ($data->static_flag) {
            $this->w->writeAttribute('static', 'true');
        }
        if ($data->decl) {
            $this->w->writeAttribute('declaration', trim($data->decl));
        }
        if ($data->value != '') {
            $this->w->text($data->value);
        }
        $this->w->endElement();
    }

    function writeField($data) {
        $this->writeComments($data);
        $this->w->startElement('field');
        if ($data->line_number) {
            $this->w->writeAttribute('line', $data->line_number);
        }

        $this->w->writeAttribute('name', $data->name);
        if ($data->private_flag) {
            $this->w->writeAttribute('private', 'true');
        }
        if ($data->final_flag) {
            $this->w->writeAttribute('final', 'true');
        }
        if ($data->static_flag) {
            $this->w->writeAttribute('static', 'true');
        }
        if ($data->decl) {
            $this->w->writeAttribute('declaration', trim($data->decl));
        }
        if ($data->value != '') {
            $this->w->text($data->value);
        }
        $this->w->endElement();
    }

    function writeGlobalVariable($data) {
        if ($this->gran == self::OUTPUT_GRAN_CLASS) {
            return;
        }
        $this->writeComments($data);
        $this->w->startElement('gvar');
        if ($data->line_number) {
            $this->w->writeAttribute('line', $data->line_number);
        }

        $this->w->writeAttribute('name', $data->name);
        if ($data->decl) {
            $this->w->writeAttribute('declaration', trim($data->decl));
        }
        if ($data->value != '') {
            $this->w->text($data->value);
        }
        $this->w->endElement();
    }

    private function writeComments($data) {
        if ($data->comments) {
            foreach ($data->comments as $tok) {
                switch ($tok[0]) {
                case T_COMMENT:
                    $this->w->startElement('comment');
                    if ($data->line_number) {
                        $this->w->writeAttribute('line', $tok[2]);
                    }
                    $this->w->writeAttribute('style', 'inline');
                    $this->w->text($this->cleanDocComment(trim($tok[1])));
                    $this->w->endElement();
                    break;
                case T_DOC_COMMENT:
                    $this->w->startElement('comment');
                    if ($data->line_number) {
                        $this->w->writeAttribute('line', $tok[2]);
                    }
                    $this->w->writeAttribute('style', 'documentation');
                    $this->w->text($this->cleanDocComment(trim($tok[1])));
                    $this->w->endElement();
                    break;
                default:
                    trigger_error('Illegal token for comment: \'' . token_name($tok[0]) . '\'');
                }
            }
        }

    }

}

?>
