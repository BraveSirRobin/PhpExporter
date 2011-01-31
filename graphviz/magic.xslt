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
    xmlns:func="http://exslt.org/functions"
    version="1.0"
    extension-element-prefixes="func">

    <xsl:output method="text" indent="no"/>
    <xsl:strip-space elements="*"/>
    

    <xsl:template match="/">
<xsl:text>digraph G {
    
    node [
            shape = "record"
    ]

    edge [
    ]
    </xsl:text>
    <!-- content goes here. -->
    <xsl:call-template name="output-classes"/>
    <xsl:call-template name="output-relationships"/>
}
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
        <xsl:variable name="quot">"</xsl:variable>
        <xsl:variable name="equot">\"</xsl:variable>
        <xsl:variable name="stereotype"><!-- TODO: use the results -->
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
        <!-- TODO: namespace escaping -->
        <xsl:value-of select="@name"/><xsl:text> [
                label = "{</xsl:text><xsl:value-of select="@name"/><xsl:text>|</xsl:text>
                <xsl:for-each select="field">
                    <xsl:choose>
                        <xsl:when test="@private">-</xsl:when>
                        <xsl:when test="@protected">#</xsl:when>
                        <xsl:otherwise>+</xsl:otherwise>
                    </xsl:choose>
                    <xsl:value-of select="@name"/>
                    <xsl:choose>
                        <xsl:when test="@abstract"> &amp;#171;abstract&amp;#187;</xsl:when>
                        <xsl:otherwise/>
                    </xsl:choose>
                    <xsl:choose>
                        <xsl:when test="@static"> &amp;#171;static&amp;#187;</xsl:when>
                        <xsl:otherwise/>
                    </xsl:choose>
                    <xsl:text>\l</xsl:text>
                </xsl:for-each>
                <xsl:text>|</xsl:text>
                <xsl:for-each select="method">
                    <xsl:choose>
                        <xsl:when test="@private">-</xsl:when>
                        <xsl:when test="@protected">#</xsl:when>
                        <xsl:otherwise>+</xsl:otherwise>
                    </xsl:choose>
                    <xsl:value-of select="@name"/>
                    <xsl:if test="param"><xsl:text>( </xsl:text>
                        <xsl:for-each select="param">
                            <xsl:value-of select="@name"/>
                            <xsl:if test="@type-hint"> : <xsl:value-of select="@type-hint"/></xsl:if>
                            <!-- xsl:if test="@default"> = <xsl:value-of select="func:replace(@default, $quot, $equot)"/></xsl:if -->
                            <xsl:if test="position() &lt; last()">
                                <xsl:text>, </xsl:text>
                            </xsl:if>
                        </xsl:for-each><xsl:text> )</xsl:text>
                    </xsl:if>
                    <xsl:choose>
                        <xsl:when test="@abstract"> &amp;#171;abstract&amp;#187;</xsl:when>
                        <xsl:when test="@final"> &amp;#171;final&amp;#187;</xsl:when>
                        <xsl:otherwise/>
                    </xsl:choose>
                    <xsl:choose>
                        <xsl:when test="@static"> &amp;#171;static&amp;#187;</xsl:when>
                        <xsl:otherwise/>
                    </xsl:choose>
                    <xsl:text>\l</xsl:text>
                </xsl:for-each>
                <xsl:text>}"</xsl:text>
        ]
    </xsl:template>

    <xsl:template name="output-relationships">

        <!-- First, output arrows for Class inheritance -->

        edge [
                arrowhead = "empty"
        ]
        
        <xsl:for-each select="//class[@super-class]">
            <xsl:variable name="tgt-class" select="@super-class"/>
            <xsl:if test="count(//class[@name = $tgt-class]) &gt; 1">
                <xsl:message>WARNING: Found more than one potential super class:
Base Class: <xsl:value-of select="@super-class"/>
Super class: <xsl:value-of select="//class[@name = $tgt-class]/@name"/>
                </xsl:message>
            </xsl:if>
            <xsl:if test="count(//class[@name = $tgt-class]) &lt; 1">
                <xsl:message>WARNING: Super class not found:
Base Class: <xsl:value-of select="@super-class"/>
Super class: <xsl:value-of select="//class[@name = $tgt-class]/@name"/>
                </xsl:message>
            </xsl:if>
            <xsl:if test="@name">
                <xsl:value-of select="@name"/> -&gt; <xsl:value-of select="@super-class"/>
            </xsl:if>
        </xsl:for-each>

        <!-- Now, output arrows for interface implementation -->

        edge [
                arrowhead = "empty"
        ]
        
        <xsl:for-each select="//class[child::implemented-interfaces]">
            <xsl:for-each select="./implemented-interfaces/interface-ref">
                <xsl:variable name="p2" select="position()"/>
                <xsl:variable name="interface" select="."/>
                <xsl:variable name="tgt-class" select="@super-class"/>
                <xsl:if test="count(//class[@name = $interface]) &gt; 1">
                    <xsl:message>WARNING: more than one instance of interface <xsl:value-of select="$interface"/> was found!</xsl:message>
                </xsl:if>
                <xsl:if test="count(//class[@name = $interface]) &lt; 1">
                    <xsl:message>WARNING: interface <xsl:value-of select="$interface"/> not found</xsl:message>
                </xsl:if>
                <xsl:if test="@name">
                    <xsl:value-of select="@name"/> -&gt; <xsl:value-of select="$interface"/>
                </xsl:if>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>