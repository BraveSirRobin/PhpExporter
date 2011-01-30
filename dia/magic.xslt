<?xml version="1.0"?>
<!-- 
 Copyright (C) 2007 - 2011  Robin Harvey (harvey.robin@gmail.com)

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
TODO: Relationships
TODO: Class Consts?
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dia="http://www.lysator.liu.se/~alla/dia/"
    xmlns:func="http://exslt.org/functions"
    version="1.0">

    <xsl:output method="xml" indent="yes"/>


    <xsl:template match="/">
        <dia:diagram xmlns:dia="http://www.lysator.liu.se/~alla/dia/">
            <dia:diagramdata>
                <dia:attribute name="background">
                    <dia:color val="#ffffff"/>
                </dia:attribute>
                <dia:attribute name="pagebreak">
                    <dia:color val="#000099"/>
                </dia:attribute>
                <dia:attribute name="paper">
                    <dia:composite type="paper">
                        <dia:attribute name="name">
                            <dia:string>#A4#</dia:string>
                        </dia:attribute>
                        <dia:attribute name="tmargin">
                            <dia:real val="2.8222000598907471"/>
                        </dia:attribute>
                        <dia:attribute name="bmargin">
                            <dia:real val="2.8222000598907471"/>
                        </dia:attribute>
                        <dia:attribute name="lmargin">
                            <dia:real val="2.8222000598907471"/>
                        </dia:attribute>
                        <dia:attribute name="rmargin">
                            <dia:real val="2.8222000598907471"/>
                        </dia:attribute>
                        <dia:attribute name="is_portrait">
                            <dia:boolean val="true"/>
                        </dia:attribute>
                        <dia:attribute name="scaling">
                            <dia:real val="1"/>
                        </dia:attribute>
                        <dia:attribute name="fitto">
                            <dia:boolean val="false"/>
                        </dia:attribute>
                    </dia:composite>
                </dia:attribute>
                <dia:attribute name="grid">
                    <dia:composite type="grid">
                        <dia:attribute name="width_x">
                            <dia:real val="1"/>
                        </dia:attribute>
                        <dia:attribute name="width_y">
                            <dia:real val="1"/>
                        </dia:attribute>
                        <dia:attribute name="visible_x">
                            <dia:int val="1"/>
                        </dia:attribute>
                        <dia:attribute name="visible_y">
                            <dia:int val="1"/>
                        </dia:attribute>
                        <dia:composite type="color"/>
                    </dia:composite>
                </dia:attribute>
                <dia:attribute name="color">
                    <dia:color val="#d8e5e5"/>
                </dia:attribute>
                <dia:attribute name="guides">
                    <dia:composite type="guides">
                        <dia:attribute name="hguides"/>
                        <dia:attribute name="vguides"/>
                    </dia:composite>
                </dia:attribute>
            </dia:diagramdata>
            <dia:layer name="Background" visible="true">
                <!-- content goes here. -->
                <xsl:call-template name="output-classes"/>
                <xsl:call-template name="output-relationships"/>
            </dia:layer>
        </dia:diagram>
    </xsl:template>

    <xsl:template name="output-classes">
        <xsl:for-each select="/parsed-code/file">
            <xsl:variable name="href" select="@href"/>
            <xsl:for-each select="class|interface">
                <xsl:call-template name="output-class">
                    <xsl:with-param name="base-href" select="$href"/>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="output-class">
        <xsl:param name="base-href"/>
        <xsl:variable name="stereotype">
            <xsl:choose>
                <xsl:when test="(name() = 'interface') and (@native = 'true')">
                    <xsl:value-of select="'Interface (Native)'"/>
                </xsl:when>
                <xsl:when test="name() = 'interface'">
                    <xsl:value-of select="'Interface'"/>
                </xsl:when>
                <xsl:when test="@native = 'true'">
                    <xsl:value-of select="'Native'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="''"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:element name="dia:object">
            <!--<dia:object type="UML - Class" version="0" id="O0">-->
            <xsl:attribute name="type">UML - Class</xsl:attribute>
            <xsl:attribute name="version">0</xsl:attribute>
            <xsl:attribute name="id"><xsl:value-of select="generate-id(.)"/></xsl:attribute>
            <dia:attribute name="obj_pos">
                <dia:point val="8.3,12.45"/>
            </dia:attribute>
            <dia:attribute name="obj_bb">
                <dia:rectangle val="8.25,12.4;31.25,16.7"/>
            </dia:attribute>
            <dia:attribute name="elem_corner">
                <dia:point val="8.3,12.45"/>
            </dia:attribute>
            <dia:attribute name="elem_width">
                <dia:real val="22.899999999999999"/>
            </dia:attribute>
            <dia:attribute name="elem_height">
                <dia:real val="4.2000000000000002"/>
            </dia:attribute>
            <dia:attribute name="name">
                <dia:string>#<xsl:value-of select="@name"/>#</dia:string>
            </dia:attribute>
            <dia:attribute name="stereotype">
                <dia:string>#<xsl:value-of select="$stereotype"/>#</dia:string>
            </dia:attribute>
            <dia:attribute name="comment">
                <dia:string>#<xsl:value-of select="concat('Generated from file ', $base-href)"/>#</dia:string>
            </dia:attribute>
            <dia:attribute name="abstract">
                <xsl:choose>
                    <xsl:when test="@abstract and (@abstract = 'true')">
                        <dia:boolean val="true"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <dia:boolean val="false"/>
                    </xsl:otherwise>
                </xsl:choose>
            </dia:attribute>
            <dia:attribute name="suppress_attributes">
                <dia:boolean val="false"/>
            </dia:attribute>
            <dia:attribute name="suppress_operations">
                <dia:boolean val="false"/>
            </dia:attribute>
            <dia:attribute name="visible_attributes">
                <dia:boolean val="true"/>
            </dia:attribute>
            <dia:attribute name="visible_operations">
                <dia:boolean val="true"/>
            </dia:attribute>
            <dia:attribute name="visible_comments">
                <dia:boolean val="false"/>
            </dia:attribute>
            <dia:attribute name="wrap_operations">
                <dia:boolean val="false"/>
            </dia:attribute>
            <dia:attribute name="wrap_after_char">
                <dia:int val="40"/>
            </dia:attribute>
            <dia:attribute name="comment_line_length">
                <dia:int val="17"/>
            </dia:attribute>
            <dia:attribute name="comment_tagging">
                <dia:boolean val="false"/>
            </dia:attribute>
            <dia:attribute name="line_color">
                <dia:color val="#000000"/>
            </dia:attribute>
            <dia:attribute name="fill_color">
                <dia:color val="#ffffff"/>
            </dia:attribute>
            <dia:attribute name="text_color">
                <dia:color val="#000000"/>
            </dia:attribute>
            <dia:attribute name="normal_font">
                <dia:font family="monospace" style="0" name="Courier"/>
            </dia:attribute>
            <dia:attribute name="abstract_font">
                <dia:font family="monospace" style="88" name="Courier-BoldOblique"/>
            </dia:attribute>
            <dia:attribute name="polymorphic_font">
                <dia:font family="monospace" style="8" name="Courier-Oblique"/>
            </dia:attribute>
            <dia:attribute name="classname_font">
                <dia:font family="sans" style="80" name="Helvetica-Bold"/>
            </dia:attribute>
            <dia:attribute name="abstract_classname_font">
                <dia:font family="sans" style="88" name="Helvetica-BoldOblique"/>
            </dia:attribute>
            <dia:attribute name="comment_font">
                <dia:font family="sans" style="8" name="Helvetica-Oblique"/>
            </dia:attribute>
            <dia:attribute name="normal_font_height">
                <dia:real val="0.80000000000000004"/>
            </dia:attribute>
            <dia:attribute name="polymorphic_font_height">
                <dia:real val="0.80000000000000004"/>
            </dia:attribute>
            <dia:attribute name="abstract_font_height">
                <dia:real val="0.80000000000000004"/>
            </dia:attribute>
            <dia:attribute name="classname_font_height">
                <dia:real val="1"/>
            </dia:attribute>
            <dia:attribute name="abstract_classname_font_height">
                <dia:real val="1"/>
            </dia:attribute>
            <dia:attribute name="comment_font_height">
                <dia:real val="0.69999999999999996"/>
            </dia:attribute>
            <!-- TODO: Consts? -->
            <!-- Output UML Attributes to correspond to class variables. -->
            <xsl:if test="field">
                <dia:attribute name="attributes">
                    <xsl:for-each select="field">
                        <dia:composite type="umlattribute"><!-- This is the basic block for an attribute, add siblings -->
                            <dia:attribute name="name">
                                <dia:string>#<xsl:value-of select="@name"/>#</dia:string>
                            </dia:attribute>
                            <dia:attribute name="type">
                                <dia:string>##</dia:string>
                            </dia:attribute>
                            <dia:attribute name="value">
                                <dia:string>#<xsl:if test="@value"><xsl:value-of select="@value"/></xsl:if>#</dia:string>
                            </dia:attribute>
                            <dia:attribute name="comment">
                                <dia:string>#<xsl:value-of select="concat('GenerateID Test: ', generate-id(.))"/>#</dia:string>
                            </dia:attribute>
                            <dia:attribute name="visibility">
                                <xsl:choose>
                                    <xsl:when test="@private">
                                        <dia:enum val="1"/>
                                    </xsl:when>
                                    <xsl:when test="@protected">
                                        <dia:enum val="2"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <dia:enum val="0"/><!-- Public -->
                                    </xsl:otherwise>
                                </xsl:choose>
                            </dia:attribute>
                            <dia:attribute name="abstract">
                                <xsl:choose>
                                    <xsl:when test="@abstract">
                                        <dia:boolean val="true"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <dia:boolean val="false"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </dia:attribute>
                            <dia:attribute name="class_scope">
                                <xsl:choose>
                                    <xsl:when test="@static">
                                        <dia:boolean val="true"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <dia:boolean val="false"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </dia:attribute>
                        </dia:composite>
                    </xsl:for-each>
                </dia:attribute>
            </xsl:if>
            <xsl:if test="method">
                <dia:attribute name="operations">
                    <xsl:for-each select="method">
                        <dia:composite type="umloperation"><!-- Building block for operations, add siblings as req. -->
                            <dia:attribute name="name">
                                <dia:string>#<xsl:value-of select="@name"/>#</dia:string>
                            </dia:attribute>
                            <dia:attribute name="stereotype">
                                <dia:string>##</dia:string>
                            </dia:attribute>
                            <dia:attribute name="type">
                                <dia:string>##</dia:string>
                            </dia:attribute>
                            <dia:attribute name="visibility">
                                <xsl:choose>
                                    <xsl:when test="@private">
                                        <dia:enum val="1"/>
                                    </xsl:when>
                                    <xsl:when test="@protected">
                                        <dia:enum val="2"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <dia:enum val="0"/><!-- Public -->
                                    </xsl:otherwise>
                                </xsl:choose>
                            </dia:attribute>
                            <dia:attribute name="comment">
                                <dia:string>##</dia:string>
                            </dia:attribute>
                            <dia:attribute name="abstract">
                                <xsl:choose>
                                    <xsl:when test="@abstract">
                                        <dia:boolean val="true"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <dia:boolean val="false"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                                <dia:boolean val="false"/>
                            </dia:attribute>
                            <dia:attribute name="inheritance_type">
                                <xsl:choose>
                                    <xsl:when test="@abstract">
                                        <dia:enum val="0"/><!-- abstract -->
                                    </xsl:when>
                                    <xsl:when test="@final">
                                        <dia:enum val="2"/><!-- Leaf, final -->
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <dia:enum val="1"/><!-- Polymorphic, virtual (assumption, needs BE'ing)-->
                                    </xsl:otherwise>
                                </xsl:choose>
                            </dia:attribute>
                            <dia:attribute name="query">
                                <dia:boolean val="false"/>
                            </dia:attribute>
                            <dia:attribute name="class_scope">
                                <xsl:choose>
                                    <xsl:when test="@static">
                                        <dia:boolean val="true"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <dia:boolean val="false"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </dia:attribute>
                            <dia:attribute name="parameters"><!-- Leave as self-closing where no attrs. -->
                                <xsl:for-each select="param">
                                    <dia:composite type="umlparameter">
                                        <dia:attribute name="name">
                                            <dia:string>#<xsl:value-of select="@name"/>#</dia:string>
                                        </dia:attribute>
                                        <dia:attribute name="type">
                                            <dia:string>#<xsl:value-of select="@type-hint"/>#</dia:string>
                                        </dia:attribute>
                                        <dia:attribute name="value">
                                            <dia:string>#<xsl:value-of select="@default"/>#</dia:string>
                                        </dia:attribute>
                                        <dia:attribute name="comment">
                                            <dia:string>##</dia:string>
                                        </dia:attribute>
                                        <dia:attribute name="kind">
                                            <dia:enum val="0"/>
                                        </dia:attribute>
                                    </dia:composite>
                                </xsl:for-each>
                            </dia:attribute>
                        </dia:composite>
                    </xsl:for-each>
                </dia:attribute>
            </xsl:if>
            <dia:attribute name="template">
                <dia:boolean val="false"/>
            </dia:attribute>
            <dia:attribute name="templates"/>
            <!--</dia:object>-->
        </xsl:element>
    </xsl:template>
    
    
    
 
    <xsl:template name="output-relationships">

        <!-- First, output arrows for Class inheritance -->

        <xsl:for-each select="//class[@super-class]">
            <xsl:variable name="tgt-class" select="@super-class"/>
            <xsl:choose>
                <xsl:when test="count(//class[@name = $tgt-class]) &gt;= 1">
                    <xsl:if test="count(//class[@name = $tgt-class]) &gt; 1">
                        <xsl:message>WARNING: Found more than one potential super class:
Base Class: <xsl:value-of select="@super-class"/>
Super class: <xsl:value-of select="//class[@name = $tgt-class]/@name"/>
                        </xsl:message>
                    </xsl:if>
                    <!--</xsl:when>
                <xsl:when test="count(//class[@name = $tgt-class]) = 1">-->
                    <!--<dia:object type="UML - Generalization" version="1" id="O8">-->
                    <xsl:element name="dia:object">
                        <xsl:attribute name="type">UML - Generalization</xsl:attribute>
                        <xsl:attribute name="version">1</xsl:attribute>
                        <xsl:attribute name="id"><xsl:value-of select="concat('rel', position())"/></xsl:attribute>
                        <dia:attribute name="obj_pos">
                            <dia:point val="9.1554,13.55"/>
                        </dia:attribute>
                        <dia:attribute name="obj_bb">
                            <dia:rectangle val="9.1054,12.7;18.9275,14.66"/>
                        </dia:attribute>
                        <dia:attribute name="orth_points">
                            <dia:point val="9.1554,13.55"/>
                            <dia:point val="13.9275,13.55"/>
                            <dia:point val="13.9275,13.65"/>
                            <dia:point val="18.6996,13.65"/>
                        </dia:attribute>
                        <dia:attribute name="orth_orient">
                            <dia:enum val="0"/>
                            <dia:enum val="1"/>
                            <dia:enum val="0"/>
                        </dia:attribute>
                        <dia:attribute name="orth_autoroute">
                            <dia:boolean val="true"/>
                        </dia:attribute>
                        <dia:attribute name="text_colour">
                            <dia:color val="#000000"/>
                        </dia:attribute>
                        <dia:attribute name="line_colour">
                            <dia:color val="#000000"/>
                        </dia:attribute>
                        <dia:attribute name="name">
                            <dia:string>##</dia:string>
                        </dia:attribute>
                        <dia:attribute name="stereotype">
                            <dia:string>##</dia:string>
                        </dia:attribute>
                        <dia:connections>
                            <xsl:element name="dia:connection">
                                <xsl:attribute name="handle">0</xsl:attribute>
                                <xsl:attribute name="to"><xsl:value-of select="generate-id(//class[@name = $tgt-class])"/></xsl:attribute>
                                <xsl:attribute name="connection">8</xsl:attribute>
                            </xsl:element>
                            <xsl:element name="dia:connection">
                                <xsl:attribute name="handle">1</xsl:attribute>
                                <xsl:attribute name="to"><xsl:value-of select="generate-id(.)"/></xsl:attribute>
                                <xsl:attribute name="connection">8</xsl:attribute>
                            </xsl:element>
                        </dia:connections>
                    </xsl:element>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>WARNING: Super class not found:
Base Class: <xsl:value-of select="@super-class"/>
Super class: <xsl:value-of select="//class[@name = $tgt-class]/@name"/>
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <!-- Now, output arrows for interface implementation -->

        <xsl:for-each select="//class[child::implemented-interfaces]">
            <xsl:variable name="clazz" select="@name"/>
            <xsl:variable name="p1" select="position()"/>
            <xsl:variable name="point-to" select="generate-id(.)"/>
            <xsl:for-each select="./implemented-interfaces/interface-ref"><!-- YO -->
                <xsl:variable name="p2" select="position()"/>
                <xsl:variable name="interface" select="."/>
                <xsl:choose>
                    <xsl:when test="count(//interface[@name = $interface]) &gt; 1">
                        <xsl:message>WARNING: more than one instance of interface <xsl:value-of select="$interface"/> was found!</xsl:message>
                    </xsl:when>
                    <xsl:when test="count(//interface[@name = $interface]) = 0">
                        <xsl:message>WARNING: interface <xsl:value-of select="$interface"/> not found</xsl:message>
                    </xsl:when>
                    <xsl:otherwise>
                        <!--<dia:object type="UML - Realizes" version="1" id="O5">-->
                        <xsl:element name="dia:object">
                            <xsl:attribute name="type">UML - Realizes</xsl:attribute>
                            <xsl:attribute name="version">1</xsl:attribute>
                            <xsl:attribute name="id"><xsl:value-of select="concat('int', $p1, $p2)"/></xsl:attribute>
                            <dia:attribute name="obj_pos">
                                <dia:point val="9.0054,9.75"/>
                            </dia:attribute>
                            <dia:attribute name="obj_bb">
                                <dia:rectangle val="8.9554,8.9;18.7496,10.7175"/>
                            </dia:attribute>
                            <dia:attribute name="orth_points">
                                <dia:point val="9.0054,9.75"/>
                                <dia:point val="13.8525,9.75"/>
                                <dia:point val="13.8525,9.85"/>
                                <dia:point val="18.6996,9.85"/>
                            </dia:attribute>
                            <dia:attribute name="orth_orient">
                                <dia:enum val="0"/>
                                <dia:enum val="1"/>
                                <dia:enum val="0"/>
                            </dia:attribute>
                            <dia:attribute name="orth_autoroute">
                                <dia:boolean val="true"/>
                            </dia:attribute>
                            <dia:attribute name="line_colour">
                                <dia:color val="#000000"/>
                            </dia:attribute>
                            <dia:attribute name="text_colour">
                                <dia:color val="#000000"/>
                            </dia:attribute>
                            <dia:attribute name="name">
                                <dia:string>##</dia:string>
                            </dia:attribute>
                            <dia:attribute name="stereotype">
                                <dia:string>##</dia:string>
                            </dia:attribute>
                            <dia:connections>
                                <!--
                                <dia:connection handle="0" to="O2" connection="8"/>
                                <dia:connection handle="1" to="O3" connection="8"/>
                                -->
                                <xsl:element name="dia:connection">
                                    <xsl:attribute name="handle"><xsl:value-of select="0"/></xsl:attribute>
                                    <xsl:attribute name="to"><xsl:value-of select="generate-id(//interface[@name = $interface])"/></xsl:attribute>
                                    <xsl:attribute name="connection">8</xsl:attribute>
                                </xsl:element>
                                <xsl:element name="dia:connection">
                                    <xsl:attribute name="handle"><xsl:value-of select="1"/></xsl:attribute>
                                    <xsl:attribute name="to"><xsl:value-of select="$point-to"/></xsl:attribute>
                                    <xsl:attribute name="connection">8</xsl:attribute>
                                </xsl:element>
                                <!-- HERE! -->
                            </dia:connections>
                        </xsl:element>
                            <!--</dia:object>-->
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:for-each>
 

    </xsl:template>
   
</xsl:stylesheet>
