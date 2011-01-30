#! /bin/bash

# Creates dia class diagrams for each ZF module

for f in `find . -maxdepth 1 -mindepth 1 -type d`
do
    echo Processing $f;
    pushd . > /dev/null;
    cd $f;

    # Archive old files
    if [ -f module.dia ]; then 
        echo "Archive existing module..";
        mv module.dia module.dia.old;
    else
        echo "Do not remove module";
    fi;

    # Copy the main module file from ../ in to this dir 
    # so that it is included in the output
    MODULE_FILE="../";
    PWD=`pwd`;
    MODULE_FILE+=`basename $PWD`;
    MODULE_FILE+=".php";
    REMOVE_MODFILE=0;

    if [ -f $MODULE_FILE ]; then
        echo Copy module file to pwd temporarily;
        cp $MODULE_FILE .;
        REMOVE_MODFILE=1;
    fi;    

    # Creates the XML source
    rm ParsedCode.xml 2>/dev/null;
    code_parser .;
    # Creates the dia XML
    echo Creating diagram for module $f;
    xsltproc /home/robin/dev/php/tokens2/dia/magic.xslt ./ParsedCode.xml > module.xml;
    gzip ./module.xml;
    mv ./module.xml.gz ./module.dia;

    # Remove the module file from pwd, if required.
    if [ $REMOVE_MODFILE = 1 ]; then
        echo "Remove module main file..";
        MODULE_FILE=`basename $PWD`;
        MODULE_FILE+=".php";
        rm $MODULE_FILE;
    fi;

    popd > /dev/null;
done;
