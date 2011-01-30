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
 * 1) Subclass this class to create a test suite
 * 2) Tests must be contained in methods of the superclass
 * called testXXX()
 * 3) Each testXXX() method must accept a single parameter BY REFERENCE
 * which acts as a way of passing a string message back to the suite.
 * 4) Each testXXX() method must return either TEST_PASSED or TEST_FAILED.
 * If it does not, it is marked as being defective.
 * 
 */
abstract class TestSuite
{
	const TEST_NOT_RUN = 1;
	const TEST_PASSED = 2;
	const TEST_FAILED = 3;
	const TEST_DEFECTIVE = 4;

	private $results = array();
	
	private $_result = null;
	private $_expectedErrors = array();

	final function runTests() {
		$refl = new ReflectionClass(get_class($this));
		$this->results = array();
		//Check to see if there is a setup method.
		if ($refl->hasMethod('setup')) {
		    try {
		        $this->setup();
		    } catch (Exception $e) {
		        echo "\nFailed to set up test environment, cancelling all tests.\n\n{$e->getMessage()}";
		        return;
		    }
		}
		set_error_handler(array($this, 'errCallback'));
		foreach ($refl->getMethods() as $meth) {
			if (substr($meth->getName(), 0, 4) == 'test') {
				//prepare the result holder.
				$this->_result = array();
				$this->_result['exception'] = null;
				$this->_result['errors'] = null;
				$this->_result['assertions'] = null;
				$this->_result['result'] = self::TEST_PASSED;
				$this->_expectedErrors = array();
				$output = null;
				//run the test
				try {
					$r = $this->{$meth->getName()}($output);
				} catch (Exception $e) {
					$this->_result['exception'] = $e;
					$this->_result['result'] = self::TEST_FAILED;
				}
				$this->_result['output'] = $output;
				//Deal with error assertions.
				if (count($this->_expectedErrors) > 0) {
					if (! is_array($this->_result['assertions'])) $this->_result['assertions'] = array();
					foreach ($this->_expectedErrors as $key => $value) {
						$this->_result['assertions'][$key] = false;
					}
				}
				//Check the result and amend for errors and assertion failures.
				if (array_search($r, array(self::TEST_DEFECTIVE, self::TEST_FAILED, self::TEST_NOT_RUN)) !== false) {
					$this->_result['result'] = $r;
				}
				else if ($this->_result['errors'] != null) {
					$this->_result['result'] = self::TEST_FAILED;
				}
				else if ($this->_result['assertions'] != null) {
					foreach ($this->_result['assertions'] as $ass) {
						if ($ass == false) {
							$this->_result['result'] = self::TEST_FAILED;
							break;
						}
					}
				}
				$this->results[substr($meth->getName(), 4)] = $this->_result;
			}
		}
		restore_error_handler();
		//finally, call the teardown method (if it exists)
		if ($refl->hasMethod('tearDown')) {
		    try {
		        $this->tearDown();
		    } catch (Exception $e) {
		        echo "\nWARNING: teardown method raised an exception:\n{$e->getMessage()}\n";
		    }
		}
	}
	
	final function getResults() { return $this->results; }
	
	final function getFailures() {
		return array_filter($this->results, array($this, 'failureFilter'));
	}
	
	private final function failureFilter($test) {
		return ($test['result'] != self::TEST_PASSED);
	}
	
	final function errCallback($errno, $errstr, $errfile, $errline, $errcontext) {
		if (! is_array($this->_result)) {
			echo "Error Raised, file $errfile line $errline:\n\n$errstr";
			return;
		}
		if (($key = array_search($errstr, $this->_expectedErrors)) !== false) {
			//Turn the expected error in to a sucessfull assertion
			if (! is_array($this->_result['assertions'])) $this->_result['assertions'] = array();
			$this->_result['assertions'][$key] = true;
			unset($this->_expectedErrors[$key]);
			return;
		}
		$this->_result['errors'][] = array('errno' => $errno, 
			'errstr' => $errstr, 
			'errfile' => $errfile,
			'errline' => $errline,
			'errcontext' => $errcontext);
	}

	protected final function assertError($errstr) {
		$bt = debug_backtrace();
		$this->_expectedErrors["line {$bt[0]['line']}"] = $errstr;
	}

	protected final function assert($bool) {
		if (! is_array($this->_result)) {
			return;
		}
		if (! is_array($this->_result['assertions'])) $this->_result['assertions'] = array();
		$bt = debug_backtrace();
		$index = "line {$bt[0]['line']}";
		$this->_result['assertions'][$index] = (boolean) $bool;
	}
}
?>
