/**********************************************************************
 *
 *    FILE:            Stencil.cpp
 *
 *    DESCRIPTION:    Read/Write osg::Stencil in binary format to disk.
 *
 *    CREATED BY:        Auto generated by iveGenerated
 *                    and later modified by Rune Schmidt Jensen.
 *
 *    HISTORY:        Created 21.3.2003
 *
 *    Copyright 2003 VR-C
 **********************************************************************/

#include "Exception.h"
#include "StencilTwoSided.h"
#include "Object.h"

using namespace ive;

void StencilTwoSided::write(DataOutputStream* out){
    // Write Stencil's identification.
    out->writeInt(IVESTENCILTWOSIDED);
    // If the osg class is inherited by any other class we should also write this to file.
    osg::Object*  obj = dynamic_cast<osg::Object*>(this);
    if(obj){
        ((ive::Object*)(obj))->write(out);
    }
    else
        out_THROW_EXCEPTION("Stencil::write(): Could not cast this osg::Stencil to an osg::Object.");
    // Write Stencil's properties.

    out->writeInt(getFunction(FRONT));
    out->writeInt(getFunctionRef(FRONT));
    out->writeUInt(getFunctionMask(FRONT));

    out->writeInt(getStencilFailOperation(FRONT));
    out->writeInt(getStencilPassAndDepthFailOperation(FRONT));
    out->writeInt(getStencilPassAndDepthPassOperation(FRONT));

    out->writeUInt(getWriteMask(FRONT));

    out->writeInt(getFunction(BACK));
    out->writeInt(getFunctionRef(BACK));
    out->writeUInt(getFunctionMask(BACK));

    out->writeInt(getStencilFailOperation(BACK));
    out->writeInt(getStencilPassAndDepthFailOperation(BACK));
    out->writeInt(getStencilPassAndDepthPassOperation(BACK));

    out->writeUInt(getWriteMask(BACK));
}

void StencilTwoSided::read(DataInputStream* in){
    // Peek on Stencil's identification.
    int id = in->peekInt();
    if(id == IVESTENCILTWOSIDED)
    {
        // Read Stencil's identification.
        id = in->readInt();
        // If the osg class is inherited by any other class we should also read this from file.
        osg::Object*  obj = dynamic_cast<osg::Object*>(this);
        if(obj){
            ((ive::Object*)(obj))->read(in);
        }
        else
            in_THROW_EXCEPTION("Stencil::read(): Could not cast this osg::Stencil to an osg::Object.");

        setFunction(FRONT, (Function)in->readInt());
        setFunctionRef(FRONT, in->readInt());
        setFunctionMask(FRONT, in->readUInt());

        setStencilFailOperation(FRONT, (Operation)in->readInt());
        setStencilPassAndDepthFailOperation(FRONT, (Operation)in->readInt());
        setStencilPassAndDepthPassOperation(FRONT, (Operation)in->readInt());

        setWriteMask(FRONT, in->readUInt());

        setFunction(BACK, (Function)in->readInt());
        setFunctionRef(BACK, in->readInt());
        setFunctionMask(BACK, in->readUInt());

        setStencilFailOperation(BACK, (Operation)in->readInt());
        setStencilPassAndDepthFailOperation(BACK, (Operation)in->readInt());
        setStencilPassAndDepthPassOperation(BACK, (Operation)in->readInt());

        setWriteMask(BACK, in->readUInt());
    }
    else{
        in_THROW_EXCEPTION("Stencil::read(): Expected Stencil identification.");
    }
}
