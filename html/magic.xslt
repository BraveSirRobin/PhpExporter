<?xml version="1.0"?>
<!-- 
 Copyright (C) 2008 - 2011  Robin Harvey (harvey.robin@gmail.com)

 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.

 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
-->
<!--

XHTML Output.

-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:func="http://exslt.org/functions"
    xmlns:str="http://exslt.org/strings"
    xmlns:bl="http://bluelines.org"
    version="1.0"
    extension-element-prefixes="func">

    <xsl:param name="output-mode" select="'CONCAT'"/>
    <xsl:param name="output-target" select="'codebase.html'"/>
    <xsl:param name="path-sep" select="'/'"/><!-- filesystem path seperator character. -->
    <!-- TODO: Deal with abstract, native -->
    <xsl:variable name="span-attrs" select="str:tokenize('public,private,protected,static', ',')"/>

    <xsl:output method="xml" doctype-public="-//W3C//DTD XHTML 1.1//EN"
        doctype-system="http://www.w3.org/TR/2000/REC-xhtml1-20000126/DTD/xhtml1-strict.dtd" indent="yes"/>


    <xsl:template match="/">
        <xsl:choose>
            <xsl:when test="$output-mode = 'CONCAT'">
                <xsl:call-template name="output-concat"/>
            </xsl:when>
            <xsl:when test="$output-mode = 'FILE'">
                <xsl:call-template name="output-file"/>
            </xsl:when>
            <xsl:when test="$output-mode = 'CLASS'">
                <xsl:call-template name="output-class"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>Unknown output mode '<xsl:value-of select="$output-mode"/>': defaulting to CONCAT</xsl:message>
                <xsl:call-template name="output-concat"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>



    <xsl:template name="output-concat">
        <xsl:element name="html">
            <xsl:element name="head">
                <xsl:element name="title"><xsl:value-of select="concat('Code documentation, generated ', @parse-date)"/></xsl:element>
                <xsl:element name="link">
                    <xsl:attribute name="rel"><xsl:value-of select="'stylesheet'"/></xsl:attribute>
                    <xsl:attribute name="type"><xsl:value-of select="'text/css'"/></xsl:attribute>
                    <xsl:attribute name="href"><xsl:value-of select="'styles.css'"/></xsl:attribute>
                </xsl:element>
            </xsl:element>
            <xsl:element name="body">
                <xsl:element name="div">
                    <xsl:attribute name="class"><xsl:value-of select="'index'"/></xsl:attribute>
                    <!-- Output Index -->
                    <xsl:for-each select="/parsed-code/file">
                        <xsl:sort select="@href"/>
                        <xsl:element name="ul">
                            <xsl:apply-templates select="." mode="index"/>
                        </xsl:element>
                    </xsl:for-each>
                </xsl:element>
                <xsl:element name="div">
                    <xsl:attribute name="class"><xsl:value-of select="'detail'"/></xsl:attribute>
                    <!-- Output Detail -->
                    <xsl:for-each select="/parsed-code/file">
                        <xsl:sort select="@href"/>
                        <xsl:apply-templates select="." mode="detail"/>
                    </xsl:for-each>
                </xsl:element>
            </xsl:element><!-- body-->
        </xsl:element>
    </xsl:template>



    <xsl:template name="output-file">
    </xsl:template>

    <xsl:template name="output-class">
    </xsl:template>


    <!-- Convenience: return the file name from the given path -->
    <func:function name="bl:fileName">
        <xsl:param name="full-path"/>
        <xsl:variable name="toks" select="str:tokenize($full-path, $path-sep)"/>
        <func:result select="$toks[count($toks)]"/>
    </func:function>

    <!-- Convenience: return the path name from the given path -->
    <func:function name="bl:pathName">
        <xsl:param name="full-path"/>
        <xsl:variable name="toks" select="str:tokenize($full-path, $path-sep)"/>
        <xsl:for-each select="$toks/*">
            <xsl:if test="position() != last()">
                <func:result select="concat($path-sep, .)"/>
            </xsl:if>
        </xsl:for-each>
    </func:function>





    <!--
    =================================================================
    Code Summary
    =================================================================

    -->

    <xsl:template name="summary">
        <xsl:element name="div">
            <xsl:attribute name="class"><xsl:value-of select="'summary'"/></xsl:attribute>
            <xsl:if test="//file">
                <!-- List all files, the top level items they contain -->
                <xsl:element name="div">
                    <xsl:attribute name="class"><xsl:value-of select="'file-summary'"/></xsl:attribute>
                </xsl:element>
            </xsl:if>
            <xsl:if test="//class">
                <!-- list classes, the file they are defined in -->
                <!-- list all class heirachies -->
                <xsl:element name="div">
                    <xsl:attribute name="class"><xsl:value-of select="'class-summary'"/></xsl:attribute>
                </xsl:element>
            </xsl:if>
            <xsl:if test="//interface">
                <!-- list interfaces, the file they are defined in -->
                <!-- show which classes implement interfaces. -->
                <xsl:element name="div">
                    <xsl:attribute name="class"><xsl:value-of select="'interface-summary'"/></xsl:attribute>
                </xsl:element>
            </xsl:if>
            <xsl:if test="//function">
                <!-- list functions, the files they are declared in -->
                <xsl:element name="div">
                    <xsl:attribute name="class"><xsl:value-of select="'function-summary'"/></xsl:attribute>
                </xsl:element>
            </xsl:if>
            <xsl:if test="//gvar">
                <!-- list global vars, the files they are declared in -->
                <xsl:element name="div">
                    <xsl:attribute name="class"><xsl:value-of select="'gvar-summary'"/></xsl:attribute>
                </xsl:element>
            </xsl:if>
        </xsl:element>
    </xsl:template>






    <!--
    =================================================================
    Detail mode:
    =================================================================
    -->
    <xsl:template match="file" mode="detail">
        <xsl:element name="div">
            <xsl:attribute name="class"><xsl:value-of select="'file-detail'"/></xsl:attribute>
            <xsl:element name="h2">
                <xsl:element name="a">
                    <xsl:attribute name="name"><xsl:value-of select="generate-id(.)"/></xsl:attribute>
                    <xsl:value-of select="bl:fileName(@href)"/>
                </xsl:element>
            </xsl:element>
            <!-- Object Summary -->
            <xsl:element name="p">
                <xsl:attribute name="class"><xsl:value-of select="'object-summary'"/></xsl:attribute>
                <xsl:element name="strong">
                    <xsl:value-of select="'Full path to file: '"/>
                </xsl:element>
                <xsl:value-of select="@href"/>
            </xsl:element>
            <!-- Embed all children -->
            <xsl:if test="./*">
                <xsl:apply-templates select="./*" mode="detail"/>
            </xsl:if>
        </xsl:element>
    </xsl:template>
    <xsl:template match="class" mode="detail">
        <xsl:element name="div">
            <xsl:attribute name="class"><xsl:value-of select="'class-detail'"/></xsl:attribute>
            <xsl:element name="h3">
                <xsl:element name="a">
                    <xsl:attribute name="name"><xsl:value-of select="generate-id(.)"/></xsl:attribute>
                    <xsl:value-of select="@name"/>
                </xsl:element>
            </xsl:element>
            <!-- Object Summary -->
            <xsl:if test="@line|@abstract|@native">
                <xsl:element name="p">
                    <xsl:attribute name="class"><xsl:value-of select="'object-summary'"/></xsl:attribute>
                    <xsl:element name="strong">
                        <xsl:value-of select="'Line: '"/>
                    </xsl:element>
                    <xsl:value-of select="@line"/>
                    <xsl:if test="@abstract">
                        <xsl:element name="br"/>
                        <xsl:element name="strong">
                            <xsl:value-of select="'Abstract: '"/>
                        </xsl:element>
                        <xsl:value-of select="'yes'"/>
                    </xsl:if>
                    <xsl:if test="@native">
                        <xsl:element name="br"/>
                        <xsl:element name="strong">
                            <xsl:value-of select="'Native: '"/>
                        </xsl:element>
                        <xsl:value-of select="'yes'"/>
                    </xsl:if>
                </xsl:element>
            </xsl:if>
            <xsl:call-template name="output-class-heir"/>
            <xsl:call-template name="output-interface-heirachy"/>
            <xsl:apply-templates select="./*" mode="detail"/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="interface" mode="detail">
        <xsl:element name="div">
            <xsl:attribute name="class"><xsl:value-of select="'interface-detail'"/></xsl:attribute>
            <xsl:element name="h3">
                <xsl:element name="a">
                    <xsl:attribute name="name"><xsl:value-of select="generate-id(.)"/></xsl:attribute>
                    <xsl:value-of select="@name"/>
                </xsl:element>
            </xsl:element>
            <!-- Object Summary -->
            <xsl:if test="@native">
                <xsl:element name="p">
                    <xsl:attribute name="class"><xsl:value-of select="'object-summary'"/></xsl:attribute>
                    <xsl:if test="@native">
                        <xsl:element name="strong">
                            <xsl:value-of select="'Native: '"/>
                        </xsl:element>
                        <xsl:value-of select="'yes'"/>
                    </xsl:if>
                </xsl:element>
            </xsl:if>
            <xsl:call-template name="output-interface-heirachy"/>
            <xsl:apply-templates select="./*" mode="detail"/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="function" mode="detail">
        <xsl:element name="div">
            <xsl:attribute name="class"><xsl:value-of select="'function-detail'"/></xsl:attribute>
            <xsl:element name="h3">
                <xsl:element name="a">
                    <xsl:attribute name="name"><xsl:value-of select="generate-id(.)"/></xsl:attribute>
                    <xsl:value-of select="@name"/>
                </xsl:element>
            </xsl:element>
            <xsl:if test="@line">
                <xsl:element name="p">
                    <xsl:attribute name="class"><xsl:value-of select="'object-summary'"/></xsl:attribute>
                    <xsl:element name="strong">
                        <xsl:value-of select="'Line: '"/>
                    </xsl:element>
                    <xsl:value-of select="@line"/>
                </xsl:element>
            </xsl:if>
            <xsl:call-template name="output-function-params"/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="method" mode="detail">
        <xsl:element name="div">
            <xsl:attribute name="class"><xsl:value-of select="'method-detail'"/></xsl:attribute>
            <xsl:element name="h3">
                <xsl:element name="a">
                    <xsl:attribute name="name"><xsl:value-of select="generate-id(.)"/></xsl:attribute>
                    <xsl:value-of select="@name"/>
                </xsl:element>
            </xsl:element>
            <!-- Object Summary -->
            <xsl:if test="@line|@abstract|@private|@static|@protected">
                <xsl:element name="p">
                    <xsl:attribute name="class"><xsl:value-of select="'object-summary'"/></xsl:attribute>
                    <xsl:element name="strong">
                        <xsl:value-of select="'Line: '"/>
                    </xsl:element>
                    <xsl:value-of select="@line"/>
                    <xsl:if test="@abstract">
                        <xsl:element name="br"/>
                        <xsl:element name="strong">
                            <xsl:value-of select="'Abstract: '"/>
                        </xsl:element>
                        <xsl:value-of select="'yes'"/>
                    </xsl:if>
                    <!-- Visibility -->
                    <xsl:element name="br"/>
                    <xsl:element name="strong">
                        <xsl:value-of select="'Visibility: '"/>
                    </xsl:element>
                    <xsl:choose>
                        <xsl:when test="@protected"><xsl:value-of select="'Protected'"/></xsl:when>
                        <xsl:when test="@private"><xsl:value-of select="'Private'"/></xsl:when>
                        <xsl:otherwise test="@protected"><xsl:value-of select="'Public'"/></xsl:otherwise>
                    </xsl:choose>
                    <!-- Static -->
                    <xsl:element name="br"/>
                    <xsl:element name="strong">
                        <xsl:value-of select="'Static: '"/>
                    </xsl:element>
                    <xsl:choose>
                        <xsl:when test="@static"><xsl:value-of select="'yes'"/></xsl:when>
                        <xsl:otherwise><xsl:value-of select="'no'"/></xsl:otherwise>
                    </xsl:choose>
                </xsl:element>
                <xsl:call-template name="output-function-params"/>
            </xsl:if>
        </xsl:element>
    </xsl:template>
    <xsl:template match="field" mode="detail">
        <xsl:element name="div">
            <xsl:attribute name="class"><xsl:value-of select="'field-detail'"/></xsl:attribute>
            <xsl:element name="h3">
                <xsl:element name="a">
                    <xsl:attribute name="name"><xsl:value-of select="generate-id(.)"/></xsl:attribute>
                    <xsl:value-of select="@name"/>
                </xsl:element>
            </xsl:element>
            <!-- Object Summary -->
            <xsl:if test="@line|@private|@static|@protected">
                <xsl:element name="p">
                    <xsl:attribute name="class"><xsl:value-of select="'object-summary'"/></xsl:attribute>
                    <xsl:element name="strong">
                        <xsl:value-of select="'Line: '"/>
                    </xsl:element>
                    <xsl:value-of select="@line"/>
                    <!-- Visibility -->
                    <xsl:element name="br"/>
                    <xsl:element name="strong">
                        <xsl:value-of select="'Visibility: '"/>
                    </xsl:element>
                    <xsl:choose>
                        <xsl:when test="@protected"><xsl:value-of select="'Protected'"/></xsl:when>
                        <xsl:when test="@private"><xsl:value-of select="'Private'"/></xsl:when>
                        <xsl:otherwise test="@protected"><xsl:value-of select="'Public'"/></xsl:otherwise>
                    </xsl:choose>
                    <!-- Static -->
                    <xsl:element name="br"/>
                    <xsl:element name="strong">
                        <xsl:value-of select="'Static: '"/>
                    </xsl:element>
                    <xsl:choose>
                        <xsl:when test="@static"><xsl:value-of select="'yes'"/></xsl:when>
                        <xsl:otherwise><xsl:value-of select="'no'"/></xsl:otherwise>
                    </xsl:choose>
                    <!-- Value -->
                    <xsl:if test="./text()">
                        <xsl:element name="br"/>
                        <xsl:element name="strong">
                            <xsl:value-of select="'Value: '"/>
                        </xsl:element>
                        <xsl:value-of select="./text()"/>
                    </xsl:if>

                </xsl:element>
            </xsl:if>
        </xsl:element>
    </xsl:template>
    <xsl:template match="const" mode="detail">
        <xsl:element name="div">
            <xsl:attribute name="class"><xsl:value-of select="'const-detail'"/></xsl:attribute>
            <xsl:element name="h3">
                <xsl:element name="a">
                    <xsl:attribute name="name"><xsl:value-of select="generate-id(.)"/></xsl:attribute>
                    <xsl:value-of select="@name"/>
                </xsl:element>
            </xsl:element>
            <!-- Value -->
            <xsl:if test="./text()">
                <xsl:element name="strong">
                    <xsl:value-of select="'Value: '"/>
                </xsl:element>
                <xsl:value-of select="./text()"/>
            </xsl:if>
        </xsl:element>
    </xsl:template>
    <xsl:template match="gvar" mode="detail">
        <xsl:element name="div">
            <xsl:attribute name="class"><xsl:value-of select="'gvar-detail'"/></xsl:attribute>
            <xsl:element name="h3">
                <xsl:element name="a">
                    <xsl:attribute name="name"><xsl:value-of select="generate-id(.)"/></xsl:attribute>
                    <xsl:value-of select="@name"/>
                </xsl:element>
            </xsl:element>
            <!-- Value -->
            <xsl:if test="./text()">
                <xsl:element name="strong">
                    <xsl:value-of select="'Value: '"/>
                </xsl:element>
                <xsl:value-of select="./text()"/>
            </xsl:if>
        </xsl:element>
    </xsl:template>
    <xsl:template match="comment[@style = 'documentation']" mode="detail">
        <xsl:if test="./text()">
            <xsl:element name="div">
                <xsl:attribute name="class"><xsl:value-of select="'comment-detail'"/></xsl:attribute>
                <xsl:element name="h3">
                    <xsl:element name="a">
                        <xsl:attribute name="name"><xsl:value-of select="generate-id(.)"/></xsl:attribute>
                        <xsl:value-of select="'Documentation'"/>
                    </xsl:element>
                </xsl:element>
                <xsl:element name="pre">
                    <xsl:value-of select="./text()"/>
                </xsl:element>
            </xsl:element>
        </xsl:if>
    </xsl:template>

    <!-- Detail mode indentity to stip out unwanted stuff -->
    <xsl:template match="node()|@*" mode="detail">
        <xsl:apply-templates select="node()|@*" mode="detail"/>
    </xsl:template>

    <!-- Formats a table showing parameters for methods and functions -->
    <xsl:template name="output-function-params">
        <xsl:if test="./param">
            <xsl:element name="h4"><xsl:value-of select="'Parameters'"/></xsl:element>
            <xsl:element name="table">
                <xsl:attribute name="class"><xsl:value-of select="'param-table'"/></xsl:attribute>
                <xsl:element name="thead">
                    <xsl:element name="tr">
                        <xsl:element name="th">Name</xsl:element>
                        <xsl:element name="th">By-Ref</xsl:element>
                        <xsl:element name="th">Type Hint</xsl:element>
                        <xsl:element name="th">Default</xsl:element>
                    </xsl:element>
                </xsl:element>
                <xsl:element name="tbody">
                    <xsl:for-each select="./param">
                        <xsl:element name="tr">
                            <xsl:element name="td"><xsl:value-of select="@name"/></xsl:element>
                            <xsl:element name="td">
                                <xsl:choose>
                                    <xsl:when test="@by-ref"><xsl:value-of select="'Yes'"/></xsl:when>
                                    <xsl:otherwise><xsl:value-of select="'No'"/></xsl:otherwise>
                                </xsl:choose>
                            </xsl:element>
                            <xsl:element name="td">
                                <xsl:choose>
                                    <xsl:when test="@type-hint"><xsl:value-of select="@type-hint"/></xsl:when>
                                    <!-- TODO: Make this an &nbsp; -->
                                    <xsl:otherwise><xsl:value-of select="' '"/></xsl:otherwise>
                                </xsl:choose>
                            </xsl:element>
                            <xsl:element name="td">
                                <xsl:choose>
                                    <xsl:when test="@default"><xsl:value-of select="@default"/></xsl:when>
                                    <xsl:otherwise><xsl:value-of select="' '"/></xsl:otherwise>
                                </xsl:choose>
                            </xsl:element>
                        </xsl:element>
                    </xsl:for-each>
                </xsl:element>
            </xsl:element>
        </xsl:if>
    </xsl:template>


    <!-- Recursive template outputs an interface inheritance heirachy in ul/li -->
    <xsl:template name="output-interface-heirachy" match="interface" mode="ifc-heir">
        <xsl:param name="start" select="true()"/>
        <xsl:choose>
            <xsl:when test="$start">
                <!-- Start. -->
                <xsl:if test="bl:validateInterfaces()">
                    <xsl:element name="h4">
                        <xsl:value-of select="'Interface Inheritance Heirachy'"/>
                    </xsl:element>
                    <xsl:element name="ul">
                        <xsl:attribute name="class"><xsl:value-of select="'ifc-heir'"/></xsl:attribute>
                        <xsl:element name="li">
                            <xsl:value-of select="@name"/>
                            <xsl:element name="ul">
                                <xsl:for-each select="./implemented-interfaces/interface-ref">
                                    <xsl:variable name="ifc-name" select="."/>
                                    <xsl:if test="//interface[@name = $ifc-name]">
                                        <xsl:element name="li">
                                            <xsl:element name="a">
                                                <xsl:attribute name="href"><xsl:value-of select="bl:getLink(//interface[@name = $ifc-name])"/></xsl:attribute>
                                                <xsl:value-of select="."/>
                                            </xsl:element>
                                            <xsl:apply-templates select="//interface[@name = $ifc-name]" mode="ifc-heir">
                                                <xsl:with-param name="start" select="false()"/>
                                            </xsl:apply-templates>
                                        </xsl:element>
                                    </xsl:if>
                                </xsl:for-each>
                            </xsl:element>
                        </xsl:element>
                    </xsl:element>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <!-- Continue. -->
                <xsl:if test="bl:validateInterfaces()">
                    <xsl:element name="ul">
                        <xsl:for-each select="./implemented-interfaces/interface-ref">
                            <xsl:variable name="ifc-name" select="."/>
                            <xsl:if test="//interface[@name = $ifc-name]">
                                <xsl:element name="li">
                                    <xsl:element name="a">
                                        <xsl:attribute name="href"><xsl:value-of select="lb:getLink(//interface[@name = $ifc-name])"/></xsl:attribute>
                                        <xsl:value-of select="."/>
                                    </xsl:element>
                                    <xsl:apply-templates select="//interface[@name = $ifc-name]" mode="ifc-heir">
                                        <xsl:with-param name="start" select="false()"/>
                                    </xsl:apply-templates>
                                </xsl:element>
                            </xsl:if>
                        </xsl:for-each>
                    </xsl:element>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!--
    ~Private~ function to see if any of the current nodes' interfaces are valid
    -->
    <func:function name="bl:validateInterfaces">
        <xsl:variable name="return">
            <xsl:for-each select="./implemented-interfaces/interface-ref">
                <xsl:value-of select="'interface,'"/>
                <xsl:variable name="ifc-name" select="."/>
                <xsl:choose>
                    <xsl:when test="//interface[@name = $ifc-name]">
                        <xsl:value-of select="'true,'"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="contains($return, 'true')">
                <func:result select="true()"/>
            </xsl:when>
            <xsl:when test="contains($return, 'interface')">
                <xsl:message>All interfaces are bad for node <xsl:value-of select="generate-id(.)"/></xsl:message>
                <func:result select="false()"/>
            </xsl:when>
            <xsl:otherwise>
                <func:result select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
    </func:function>

    <!-- Recursive template outputs a class inheritance heirachy in ul/li -->
    <xsl:template name="output-class-heir">
        <xsl:param name="clazz" select="'PSR'"/><!-- PSR == pseudo-random ... used to detect first entry -->
        <xsl:choose>
            <xsl:when test="$clazz = 'PSR'">
                <!-- Start. -->
                <xsl:variable name="spc" select="@super-class"/>
                <xsl:choose>
                    <xsl:when test="(@super-class) and not(//class[@name = $spc])">
                        <xsl:message>Warning: superclass reference to an unreachable class <xsl:value-of select="$spc"/></xsl:message>
                    </xsl:when>
                    <xsl:when test="@super-class">
                        <xsl:element name="h4">
                            <xsl:value-of select="'Class Inheritance Heirachy'"/>
                        </xsl:element>
                        <xsl:element name="ul">
                            <xsl:attribute name="class"><xsl:value-of select="'class-heir'"/></xsl:attribute>
                            <xsl:element name="li">
                                <xsl:value-of select="@name"/>
                                <!-- Recurses -->
                                <xsl:call-template name="output-class-heir">
                                    <xsl:with-param name="clazz" select="@super-class"/>
                                </xsl:call-template>
                            </xsl:element>
                        </xsl:element>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <!-- Continue. -->
                <xsl:element name="ul">
                    <xsl:element name="li">
                        <xsl:element name="a">
                            <xsl:attribute name="href"><xsl:value-of select="bl:getLink(//class[@name = $clazz])"/></xsl:attribute>
                            <xsl:value-of select="$clazz"/>
                        </xsl:element>
                        <!-- check for recursion  -->
                        <xsl:variable name="spc" select="//class[@name = $clazz][@super-class]"/>
                        <xsl:choose>
                            <xsl:when test="(//class[@name = $clazz][@super-class]) and not(//class[@name = $spc])">
                                <xsl:message>Warning: superclass reference to an unreachable class <xsl:value-of select="$spc"/> (2)</xsl:message>
                            </xsl:when>
                            <xsl:when test="//class[@name = $clazz][@super-class]">
                                <!-- Recurses -->
                                <xsl:call-template name="output-class-heir">
                                    <xsl:with-param name="clazz" select="$spc"/>
                                </xsl:call-template>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:element>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>








    <!--
    =================================================================
    Index mode:
    =================================================================
    These named templates produce the basic html ul/li heirachical index.

    -->




    <!-- 
    Make a link:
        parent-id: Pass this in to get back a file reference, else gives back an internal link.
        attr: either href of name, whatever you need
    -->
    <func:function name="bl:getLink">
        <xsl:param name="for" select="."/>
        <xsl:choose>
            <xsl:when test="$output-mode = 'CONCAT'">
                <func:result select="concat('#', generate-id($for))"/>
            </xsl:when>
            <xsl:when test="$output-mode = 'FILE'">
            </xsl:when>
            <xsl:when test="$output-mode = 'CLASS'">
            </xsl:when>
            <xsl:otherwise><xsl:message>WARNING: unknown output-mode: '<xsl:value-of select="$output-mode"/>'</xsl:message></xsl:otherwise>
        </xsl:choose>
    </func:function>




    <!-- These index element can have children. -->
    <xsl:template match="file" mode="index">
        <xsl:element name="li">
            <xsl:attribute name="class"><xsl:value-of select="'file-index'"/></xsl:attribute>
            <xsl:element name="a">
                <xsl:attribute name="href"><xsl:value-of select="bl:getLink()"/></xsl:attribute>
                <xsl:value-of select="bl:fileName(@href)"/>
            </xsl:element>
            <xsl:if test="./*">
                <xsl:element name="ul">
                    <xsl:apply-templates select="./*" mode="index"/>
                </xsl:element>
            </xsl:if>
        </xsl:element>
    </xsl:template>
    <xsl:template match="class" mode="index">
        <xsl:element name="li">
            <xsl:attribute name="class"><xsl:value-of select="'class-index'"/></xsl:attribute>
            <xsl:element name="a">
                <xsl:attribute name="href"><xsl:value-of select="bl:getLink()"/></xsl:attribute>
                <xsl:value-of select="@name"/>
            </xsl:element>
            <xsl:if test="./*[@name != 'implemented-interfaces']">
                <xsl:element name="ul">
                    <xsl:apply-templates select="./*" mode="index"/>
                </xsl:element>
            </xsl:if>
        </xsl:element>
    </xsl:template>
    <xsl:template match="interface" mode="index">
        <xsl:element name="li">
            <xsl:attribute name="class"><xsl:value-of select="'interface-index'"/></xsl:attribute>
            <xsl:element name="a">
                <xsl:attribute name="href"><xsl:value-of select="bl:getLink()"/></xsl:attribute>
                <xsl:value-of select="@name"/>
            </xsl:element>
            <xsl:if test="./*">
                <xsl:element name="ul">
                    <xsl:apply-templates select="./*" mode="index"/>
                </xsl:element>
            </xsl:if>
        </xsl:element>
    </xsl:template>
    <!-- Childless index elements -->
    <xsl:template match="field" mode="index">
        <xsl:element name="li">
            <xsl:attribute name="class"><xsl:value-of select="'field-index'"/></xsl:attribute>
            <xsl:call-template name="wrap-spans">
                <xsl:with-param name="text" select="@name"/>
            </xsl:call-template>
        </xsl:element>
    </xsl:template>
    <xsl:template match="method" mode="index">
        <xsl:element name="li">
            <xsl:attribute name="class"><xsl:value-of select="'method-index'"/></xsl:attribute>
            <xsl:call-template name="wrap-spans">
                <xsl:with-param name="text" select="@name"/>
            </xsl:call-template>
        </xsl:element>
    </xsl:template>
    <xsl:template match="function" mode="index">
        <xsl:element name="li">
            <xsl:attribute name="class"><xsl:value-of select="'function-index'"/></xsl:attribute>
            <xsl:element name="a">
                <xsl:attribute name="href"><xsl:value-of select="bl:getLink()"/></xsl:attribute>
                <xsl:value-of select="@name"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    <xsl:template match="gvar" mode="index">
        <xsl:element name="li">
            <xsl:attribute name="class"><xsl:value-of select="'gvar-index'"/></xsl:attribute>
            <xsl:element name="a">
                <xsl:attribute name="href"><xsl:value-of select="bl:getLink()"/></xsl:attribute>
                <xsl:value-of select="@name"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    <xsl:template match="const" mode="index">
        <xsl:element name="li">
            <xsl:attribute name="class"><xsl:value-of select="'const-index'"/></xsl:attribute>
            <xsl:element name="a">
                <xsl:attribute name="href"><xsl:value-of select="bl:getLink()"/></xsl:attribute>
                <xsl:value-of select="@name"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    <!-- index mode identity -->
    <xsl:template match="node()|@*" mode="index">
        <xsl:apply-templates select="node()|@*" mode="index"/>
    </xsl:template>
    <!-- Utility template to wrap spans around the given text. -->
    <xsl:template name="wrap-spans">
        <xsl:param name="text"/>
        <xsl:param name="base-attr" select="1"/>
        <!--
        <xsl:message>Recursed with 
            $base-attr = <xsl:value-of select="$base-attr"/>,
            $count($span-attrs) = <xsl:value-of select="count($span-attrs)"/>
            $span-attrs[$base-attr]] = <xsl:value-of select="$span-attrs[$base-attr]"/>
            @name = <xsl:value-of select="@name"/>
            element attribs: <xsl:for-each select="@*"><xsl:value-of select="name()"/> </xsl:for-each>
        </xsl:message>
        -->
        <xsl:choose>
            <xsl:when test="$base-attr &lt;= count($span-attrs)">
                <xsl:choose>
                    <xsl:when test="@*[name() = $span-attrs[$base-attr]]">
                        <xsl:element name="span">
                            <xsl:attribute name="class"><xsl:value-of select="$span-attrs[$base-attr]"/></xsl:attribute>
                            <xsl:call-template name="wrap-spans">
                                <xsl:with-param name="text" select="$text"/>
                                <xsl:with-param name="base-attr" select="$base-attr + 1"/>
                            </xsl:call-template>
                        </xsl:element>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="wrap-spans">
                            <xsl:with-param name="text" select="$text"/>
                            <xsl:with-param name="base-attr" select="$base-attr + 1"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:element name="a">
                    <xsl:attribute name="href"><xsl:value-of select="bl:getLink()"/></xsl:attribute>
                    <xsl:value-of select="$text"/>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
