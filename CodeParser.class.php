<?php
/**
 * @author Robin Harvey
 * @date Nov/Dec 2007
 * @copyright (c) Robin Harvey
 *
 * This class does 2 jobs.
 * 
 * The first is to act as a wrapper around the php token_get_all() function.  There
 * are methods to parse a single file or a directory subtree.  This class uses
 * an instance of OutputWriter, to which it feeds "parsing events" and data.
 *
 * Second is to artificially generate references to native classes by using the
 * PHP5 Reflection API.
 *
 * TODO: Write code to support 'heredoc'
 * TODO: Test with inline HTML
 *
 *
 * TODO: Finish the new attrib on the parsed-code element, but the issues are:
 *  1) Potentially 2 "roots", i.e. if recursive input class output, each output file has both
 *  a parent input file and a parent root directory of recursion.  Output both, or one?
 */

class CodeParser
{

    const BR_OPEN = '{';
    const BR_CLOSE = '}';
    const SEMI_C = ';';
    private $ow = null;

    const NONE = 1;
    const FUNC = 2;
    const CLAZZ = 3;
    const IFACE = 4;
    const METHOD = 5;


    /**
     * Parse a single file
     * @param string $file The file to parse
     */
    function parse($file) {
        $this->ow = OutputWriter::Object();
        $this->ow->startOutput($file);
        $this->clearAccumulatedNClasses();
        $this->_parse($file);
        $this->ow->endOutput();
    }

    /**
     * Parse a directory subtree
     * @param string $dir The directory subtree root
     */
    function parseRecursive($dir) {
        $this->ow = OutputWriter::Object();
        $rdi = new RecursiveDirectoryIterator($dir);
        $rii = new RecursiveIteratorIterator($rdi);
        $this->clearAccumulatedNClasses();
        $this->ow->startOutput($dir);
        foreach ($rii as $splf) {
            if (substr($splf->getFilename(), -4) == '.php') {
                echo "\nProcessing file {$splf->getFilename()}\n";
                $this->_parse($splf->getRealPath());
            }
        }
        $this->ow->endOutput();
    }

    /**
     * Run the given file through token_get_all(), then loop the resulting array
     * generating events for the OutputWriter.
     * @param string $file The file to parse
     */
    private function _parse($file) {
        if (! is_file($file)) {
            die("\n\n\tNo such file '$file'\n");
        }
        $toks = token_get_all(file_get_contents($file));
        $this->ow->startFile($file);
        $i = 0; //Brace Depth.
        $accum = array();
        $cnt = count($toks);
        for ($z = 0; $z < $cnt; $z++) {
            $tok = $toks[$z];
            $tok_action = '';
            $accum[] = $tok;
            if (is_string($tok)) {
                switch ($tok) {
                case '{':
                    $tok_action = self::BR_OPEN;
                    break;
                case '}':
                    $tok_action = self::BR_CLOSE;
                    break;
                case ';':
                    $tok_action = self::SEMI_C;
                }
            }
            else {
                list($id, $text, $lnum) = $tok;
                switch ($id) {
                case T_CURLY_OPEN:
                case T_DOLLAR_OPEN_CURLY_BRACES:
                    $tok_action = self::BR_OPEN;
                    break;
                }
            }
            //Do stuff.
            if ($tok_action) {
                $l = $this->getListenLevel();
                if ($tok_action == self::BR_CLOSE) $i--;
                if ($i < $l) {
                    $this->accumulate($accum, $tok_action, $i);
                    $accum = array();
                }
                if ($tok_action == self::BR_OPEN) $i++;
            }
        }
        $this->ow->endFile();
        $this->clearFileGlobals();
    }


    /**
     * Convenience method to forward parsing events to other
     * local conveniences which call the OutputWriter methods.
     */
    private function accumulate($accum, $tok_action, $depth) {
        $this->l = 1000;
        switch ($tok_action) {
        case self::BR_OPEN:
            $this->handleBraceOpen($accum, $depth);
            break;
        case self::SEMI_C:
            $this->handleSemiC($accum, $depth);
            break;
        case self::BR_CLOSE:
            if ($this->container() != self::NONE) {
                $this->popContainerItem();
            }
            break;
        }
    }

    /**
     * Respond to a opening brace token by proving on event in the
     * OutputWriter.
     */
    private function handleBraceOpen($accum, $depth) {
        switch ($this->container()) {
        case self::NONE:
            //Search for clazz, func 
            switch ($this->searchAccumTokens($accum, array(T_CLASS, T_FUNCTION, T_INTERFACE))) {
            case T_CLASS:
                $this->container(self::CLAZZ);
                $this->parseClassDef($accum, 'class');
                break;
            case T_FUNCTION:
                $this->container(self::FUNC);
                $this->l = $depth + 1;
                $this->parseFunctionDef($accum, 'function');
                break;
            case T_INTERFACE:
                $this->container(self::IFACE);
                $this->parseClassDef($accum, 'interface');
                break;
            }
            break;
        case self::CLAZZ:
            //Search for a method.
            switch ($this->searchAccumTokens($accum, T_FUNCTION)) {
            case T_FUNCTION:
                $this->l = $depth + 1;
                $this->container(self::METHOD);
                $this->parseFunctionDef($accum, 'method');
                break;
            }
            break;
        default:
            throw new Exception('handleBraceOpen(): Illegal flag state', 968);
        }
    }


    /**
     * Respond to a semi-colon token by proving on event in the OutputWriter.
     */
    private function handleSemiC($accum, $depth) {
        switch ($this->container()) {
        case self::NONE:
            //(global variables?)
            switch ($this->searchAccumTokens($accum, array(T_VARIABLE, T_FUNCTION))) {
            case T_VARIABLE:
                $this->parseVariableDef($accum, 'global_variable');
                break;
            }
            break;
        case self::CLAZZ:
            switch ($this->searchAccumTokens($accum, array(T_VARIABLE, T_FUNCTION, T_CONST))) {
            case T_VARIABLE:
                $this->parseVariableDef($accum, 'field');
                break;
            case T_FUNCTION:
                $this->parseFunctionDef($accum, 'method');
                $this->ow->endFunction();
                break;
            case T_CONST:
                $this->parseVariableDef($accum, 'const');
                break;
            }
            //Search for field, abstract method, constant
            break;
        case self::IFACE:
            //Search for an interface method
            if ($this->searchAccumTokens($accum, array(T_FUNCTION))) {
                $this->parseFunctionDef($accum, 'method');
                $this->ow->endFunction();
            }
            break;
        default:
            throw new Exception('handleSemiC(): Illegal flag state', 968);
        }
    }



    /**
     * Simple local stack for storing references to global variables so
     * that they are only output once per file.
     */
    private $fglobals = array();
    private function getFileGlobals() {
        return $this->fglobals;
    }
    private function pushFileGlobal($glob) {
        array_push($this->fglobals, $glob);
    }
    private function clearFileGlobals() {
        $this->fglobals = array();
    }


    private $citems = array(self::NONE);
    private function container($new_item = false) {
        if ($new_item) {
            $this->citems[] = $new_item;
        }
        return ($this->citems) ? $this->citems[count($this->citems) - 1] : false;
    }

    private function popContainerItem() {
        if (count($this->citems) > 1) {
            $e = array_pop($this->citems);
            //EVENT EndXXX
            switch ($e) {
            case self::CLAZZ:
                $this->ow->endClass();
                $this->createNativeReferences();
                break;
            case self::IFACE:
                $this->ow->endInterface();
                $this->createNativeReferences();
                break;
            case self::FUNC:
                $this->ow->endFunction();
                break;
            case self::METHOD:
                $this->ow->endMethod();
                break;
            }
        }
    }

    /**
     * Search backwards through $accum for any of the 
     * tokens in $target, return the first one found.
     */
    private function searchAccumTokens($accum, $target) {
        if (! is_array($target)) {
            $target = (array) $target;
        }
        for ($i = count($accum) - 1; $i >= 0; $i--) {
            if (is_array($accum[$i])) {
                list($tid, $text, $lnum) = $accum[$i];
                if (($k = array_search($tid, $target)) !== false) {
                    return $tid;
                }
            }
        }
        return false;
    }



    /**
     * Generates events for variable and const declarations
     */
    private function parseVariableDef($accum, $tag_name) {
        //Step 1 - strip crap from the beginning of $accum
        for ($i = count($accum) - 1; $i >= 0; $i--) {
            if ($accum[$i] == ';' || $accum[$i] == '}') {
                $accum = array_slice($accum, count($accum) - $i);
                break;
            }
        }

        $private_flag = false;
        $final_flag = false;
        $static_flag = false;
        $name = '';
        $value = '';
        $const_flag = false;
        $valflag = false;
        $commstack = array(); //collect comments
        $wsf = false; //whitespace flag
        $line_num = 0;
        $decl = '';//YO
        foreach ($accum as $tok) {
            if (is_array($tok)) {
                list($tid, $val, $lid) = $tok;
                if (! in_array($tid, array(T_COMMENT, T_DOC_COMMENT))) {
                    $decl .= $val;
                }
                switch ($tid) {
                case T_PRIVATE:
                    $private_flag = true;
                    break;
                case T_FINAL:
                    $final_flag = true;
                    break;
                case T_STATIC:
                    $static_flag = true;
                    break;
                case T_CONST:
                    $const_flag = true;
                    break;
                case T_STRING:
                    if ($const_flag) {
                        $name = $val;
                    }
                    else if ($valflag) {
                        $value .= $val;
                        $wsf = true;
                    }
                    break;
                case T_VARIABLE:
                    if ($name == '') {
                        $name = $val;
                        $line_num = $lid;
                    }
                    else if ($valflag) {
                        $value .= $val;
                    }
                    break;
                case T_COMMENT:
                case T_DOC_COMMENT:
                    $commstack[] = $tok;
                    break;
                case T_WHITESPACE:
                    if ($wsf) {
                        $value .= $val;
                    }
                    continue;
                default:
                    if ($valflag) {
                        $value .= $val;
                        $wsf = true;
                    }
                }//switch
            }
            else if ($tok == '=') {
                $decl .= $tok;
                $valflag = true;
            }
            else if ($tok == ';') {
                $decl .= $tok;
                break;
            }
            else if ($valflag) {
                $decl .= $tok;
                $value .= $tok;
            }
        }
        //Now output.
        $data = new stdClass;
        $data->comments = $commstack;
        $data->line_number = $line_num;
        $data->name = $name;
        $data->private_flag = $private_flag;
        $data->final_flag = $final_flag;
        $data->static_flag = $static_flag;
        $data->decl = $decl;
        $data->value = $value;
        switch ($tag_name) {
        case 'field':
            $this->ow->writeField($data);
            break;
        case 'const':
            $this->ow->writeClassConst($data);
            break;
        case 'global_variable':
            if (! in_array($data->name, $this->getFileGlobals())) {
                $this->pushFileGlobal($data->name);
                $this->ow->writeGlobalVariable($data);
            }
            break;
        default:
            throw new Exception("Unknown tag '$tag_name'", 967765);
        }
    }


    /** Extract and output a class (or interface) definition from $accum, write the elements name as $tag_name */
    private function parseClassDef($accum, $tag_name) {
        //Step 1 - strip crap from the beginning of $accum
        for ($i = count($accum) - 1; $i >= 0; $i--) {
            if ($accum[$i] == ';' || $accum[$i] == '}') {
                $accum = array_slice($accum, count($accum) - $i);
                break;
            }
        }
        //Parse forwards!
        $flag = '';

        $name = '';
        $ext = '';
        $impl = array();
        $abstract_flag = false;
        $commstack = array();
        $line_num = 0;
        $decl = '';//YO
        foreach ($accum as $tok) {
            if (is_array($tok)) {
                list($tid, $val, $lnum) = $tok;
                if (! in_array($tid, array(T_COMMENT, T_DOC_COMMENT, T_OPEN_TAG))) {
                    $decl .= $val;
                }
                switch ($tid) {
                case T_CLASS:
                case T_INTERFACE:
                    $flag = 'class';
                    break;
                case T_EXTENDS:
                    $flag = 'ext';
                    break;
                case T_IMPLEMENTS:
                    $flag = 'impl';
                    break;
                case T_ABSTRACT:
                    $abstract_flag = true;
                    break;
                case T_COMMENT:
                case T_DOC_COMMENT:
                    $commstack[] = $tok;
                    break;
                case T_STRING:
                    if ($flag == 'class') {
                        $name = $val;
                        $line_num = $lnum;
                    }
                    else if ($flag == 'ext') {
                        $ext = $val;
                        if (OutputWriter::Object()->isNativeClass($val)) {
                            $this->accumulateNative($val);
                        }
                    }
                    else if ($flag == 'impl') {
                        $impl[] = $val;
                        if (OutputWriter::Object()->isNativeInterface($val)) {
                            $this->accumulateNative($val);
                        }
                    }
                }
            }
            else {
                $decl .= $tok;
            }
        }
        $data = new stdClass;
        $data->comments = $commstack;
        $data->line_number = $line_num;
        $data->name = $name;
        $data->is_native = false;
        $data->abstract_flag = $abstract_flag;
        $data->ext = $ext;
        $data->decl = $decl;
        if ($impl) {
            $data->impl = $impl;
        }
        else {
            $data->impl = array();
        }
        switch ($tag_name) {
        case 'class':
            $this->ow->startClass($data);
            break;
        case 'interface':
            $this->ow->startInterface($data);
            break;
        default:
            throw new Exception("Unknown tag '$tag_name'", 967765);
        }
    }



    /** Extract and ouput a full function def from $accum, write the outer elements name as $field_name */
    private function parseFunctionDef($accum, $field_name) {
        $brac_flag = 0;
        $begun = false;
        $raw_params = array();//Array of sub arrays, each sub is a set of tokens delimeted by ',' from the funcion arguments
        $param = array();//Placeholder while building $raw_params
        $decl = array();//Array tokens from accum which correspond to the function declaration
        for ($i = count($accum) - 1; $i >= 0; $i--) {
            if ($begun == false) {
                if ($accum[$i] == ')') {
                    $begun = true;
                }
                continue;
            }
            if ($accum[$i] == '(') {
                if ($brac_flag == 0) {
                    if ($param) {
                        $raw_params[] = $param;
                    }
                }
                $brac_flag--;
            }
            else if ($accum[$i] == ')') {
                $brac_flag++;
            }
            if ($brac_flag < 0) {
                //Function name
                if ($accum[$i] == '}' || $accum[$i] == ';') {
                    die("HAPPIT");
                    break;
                }
                $decl[] = $accum[$i];
            }
            else {
                if ($accum[$i] == ',') {
                    $raw_params[] = $param;
                    $param = array();
                }
                else {
                    $param[] = $accum[$i];
                }
            }
        }
        //Output the function definition modifiers
        $abstract_flag = false;
        $static_flag = false;
        $final_flag = false;
        $protected_flag = false;
        $private_flag = false;
        $func_name = '';

        $func_flag = false;
        $commstack = array();
        $line_num = 0;
        $decl2 = ''; //YO
        for ($i = count($decl) - 1; $i >= 0; $i--) {
            if (is_array($decl[$i])) {
                list($tok, $val, $ln) = $decl[$i];
                if (! in_array($tok, array(T_COMMENT, T_DOC_COMMENT, T_OPEN_TAG))) {
                    $decl2 .= $val;
                }
                switch ($tok) {
                case T_PRIVATE:
                    $private_flag = true;
                    break;
                case T_ABSTRACT:
                    $abstract_flag = true;
                    break;
                case T_FINAL:
                    $final_flag = true;
                    break;
                case T_PROTECTED:
                    $protected_flag = true;
                    break;
                case T_STATIC:
                    $static_flag = true;
                    break;
                case T_FUNCTION:
                    $func_flag = true;
                    break;
                case T_STRING:
                    if ($func_flag) {
                        $func_flag = false;
                        $func_name = $val;
                        $line_num = $ln;
                    }
                    break;
                case T_COMMENT:
                case T_DOC_COMMENT:
                    $commstack[] = $decl[$i];
                    break;
                }//switch
            }
            else {
                $decl2 .= $decl[$i];
            }
        }
        //Create the data holder object
        $data = new stdClass;
        $data->comments = $commstack;
        $data->line_number = $line_num;
        $data->func_name = $func_name;
        $data->abstract_flag = $abstract_flag;
        $data->static_flag = $static_flag;
        $data->final_flag = $final_flag;
        $data->protected_flag = $protected_flag;
        $data->private_flag = $private_flag;
        $data->params = array();

        //Now deal with the function parameters.
        for ($i = count($raw_params) - 1; $i >= 0; $i--) {
            $hint = '';
            $var = '';
            $default = '';
            $def_flag = false;
            $by_ref_flag = false;
            for ($j = count($raw_params[$i]) - 1; $j >= 0; $j--) {
                $param = $raw_params[$i][$j];
                if (is_array($param)) {
                    list($tok, $val, $ln) = $param;
                    $decl2 .= $val;
                    switch ($tok) {
                    case T_STRING:
                        if ($var == '') {
                            $hint = $val;
                        }
                        else {
                            $default = $val;
                        }
                        break;
                    case T_ARRAY:
                        if ($var == '') {
                            $hint = $val;
                        }
                        break;
                    case T_VARIABLE:
                        $var = $val;
                        //YO
                        if ($i > 0) {
                            $decl2 .= ",";
                        }
                        break;
                    case T_WHITESPACE:
                        continue;
                    default:
                        if ($def_flag) {
                            $default .= $val;
                        }
                    }
                }
                else if ($param == '=') {
                    $decl2 .= $param;
                    $def_flag = true;
                }
                else if ($def_flag) {
                    $decl2 .= $param;
                    $default .= $val;
                }
                else if ($param == '&' && $var == '') {
                    $decl2 .= $param;
                    $by_ref_flag = true;
                }
            }//for
            $prm = new stdClass;
            $prm->var = $var;
            $prm->hint = $hint;
            $prm->default = $default;
            $prm->by_ref_flag = $by_ref_flag;
            $data->params[] = $prm;
        }
        //append the declaration
        $data->decl = "$decl2)";

        switch ($field_name) {
        case 'function':
            $this->ow->startFunction($data);
            break;
        case 'method':
            $this->ow->startMethod($data);
            break;
        default:
            throw new Exception("Unexpected tag name for function '$field_name'", 9867);
        }
    }

    /**
     * Return the level at which the main loop should generate events.
     * This is used internally to avoid generating events for ALL code
     * encountered.
     * Note that the default value of $l means events are generated when
     * parsing starts, and is then switched off for tokens we're not 
     * interested in.
     */
    private $l = 1000;
    private function getListenLevel() {
        return $this->l;
    }


    /**
     * This section deals with generating markup for native class and
     * interface definitions.
     */

    /** Stack of classes and interfaces waiting to the output */
    private $my_native = array();
    /** Reference stack of already output classes, interfaces */
    private $my_nshadow = array();
    private function accumulateNative($cls) {
        if (! in_array($cls, $this->my_nshadow)) {
            $this->my_native[] = $cls;
            $this->my_nshadow[] = $cls;
        }
    }
    private function clearAccumulatedNClasses() {
        $this->my_native = array();
    }

    /**
     * Takes the references to native object and interface references,
     * and outputs definitions for these.
     *
     * Problem: Where to call this method such that the OutputWriter has nat already
     * closed the XMLWriter
     * Idea: Call from the popContainerItem() method.
     *
     */
    private function createNativeReferences() {
        if (! $this->my_native) {
            return;
        }
        foreach ($this->my_native as $cls) {
            try {
                $clazz = new ReflectionClass($cls);
                $data = new stdClass;
                $data->comments = array();
                $data->line_number = 0;
                $data->is_native = true;
                $data->name = $cls;
                $data->abstract_flag = false;
                $data->ext = '';
                $data->impl = array();
                $data->decl = false;
                //Class consts
                $consts = array();
                foreach ($clazz->getConstants() as $name => $value) {
                    $c = new stdClass;
                    $c->comments = array();
                    $c->line_number = 0;
                    $c->name = $name;
                    $c->value = $value;
                    $c->private_flag = false;
                    $c->final_flag = false;
                    $c->static_flag = false;
                    $c->decl = '';
                    $consts[] = $c;
                }
                //Fields
                $fields = array();
                foreach ($clazz->getProperties() as $prop) {
                    $p = new stdClass;
                    $p->comments = array();
                    $p->line_number = 0;
                    $p->private_flag = $prop->isPrivate();
                    $p->static_flag = $prop->isStatic();
                    $p->final_flag = false;
                    $p->name = $prop->getName();
                    $p->value = '[[CODE PARSER FAILED]]'; //There's no reliable way of getting this info!
                    $p->decl = '';
                    $fields[] = $p;
                }
                //Methods
                $meths = array();
                foreach ($clazz->getMethods() as $meth) {
                    $m = new stdClass;
                    $m->comments = array();
                    $m->line_number = 0;
                    $m->abstract_flag = $meth->isAbstract() && ! $clazz->isInterface();
                    $m->static_flag = $meth->isStatic();
                    $m->final_flag = $meth->isFinal();
                    $m->protected_flag = $meth->isProtected();
                    $m->private_flag = $meth->isPrivate();
                    $m->func_name = $meth->getName();
                    $m->decl = false;
                    $m->params = array();
                    foreach ($meth->getParameters() as $param) {
                        $prm = new stdClass;
                        $prm->var = $param->getName();
                        $prm->hint = ($param->getClass()) ? $param->getClass()->getName() : '';
                        //$prm->default = $param->getDefaultValue();
                        $prm->default = '';
                        $prm->by_ref_flag = $param->isPassedByReference();
                    }
                    $meths[] = $m;
                }
                //Now send all data to the OutputWriter
                if ($clazz->isInterface()) {
                    $this->ow->startInterface($data);
                }
                else {
                    $this->ow->startClass($data);
                }
                foreach ($consts as $const) {
                    $this->ow->writeClassConst($const);
                }
                foreach ($fields as $field) {
                    $this->ow->writeField($field);
                }
                foreach ($meths as $meth) {
                    $this->ow->startMethod($meth);
                    $this->ow->endMethod();
                }
                if ($clazz->isInterface()) {
                    $this->ow->endInterface();
                }
                else {
                    $this->ow->endClass();
                }
            } catch (Exception $e) {
                //echo "\nWARNING: Exception occured in CodeParser::createNativeReferences():\n{$e->getMessage()}\n";
                var_dump($e);
                die;
                continue;
            }
        }//foreach

        $this->clearAccumulatedNClasses();
    }


}

?>
