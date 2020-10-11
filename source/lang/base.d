module lang.base;

import std.algorithm;
import lang.dynamic;
import lang.bytecode;
import lang.lib.io;
import lang.lib.sys;
import lang.lib.str;
import lang.lib.arr;
import lang.lib.proc;

struct Pair
{
    string name;
    Dynamic val;
}

Pair[][] rootBases;

ref Pair[] rootBase(size_t index = rootBases.length - 1)
{
    return rootBases[index];
}

static this()
{
    rootBases ~= getRootBase;
}

size_t enterCtx()
{
    rootBases ~= getRootBase;
    return rootBases.length - 1;
}

void exitCtx()
{
    rootBases.length--;
}

void defineRoot(string name, Dynamic val)
{
    rootBase ~= Pair(name, val);
}

void addLib(ref Pair[] pairs, string name, Pair[] lib)
{
    foreach (entry; lib)
    {
        pairs ~= Pair(name ~ "." ~ entry.name, entry.val);
    }
    Table dyn;
    foreach (entry; lib)
    {
        if (!entry.name.canFind('.'))
        {
            dyn[dynamic(entry.name)] = entry.val;
        }
    }
    pairs ~= Pair(name, dynamic(dyn));
}

Pair[] getRootBase()
{
    Pair[] ret = [
        Pair("_both_map", dynamic(&syslibubothmap)),
        Pair("_lhs_map", dynamic(&syslibulhsmap)),
        Pair("_rhs_map", dynamic(&sysliburhsmap)),
        Pair("_pre_map", dynamic(&syslibupremap)),
    ];
    ret.addLib("str", libstr);
    ret.addLib("arr", libarr);
    ret.addLib("io", libio);
    ret.addLib("sys", libsys);
    ret.addLib("proc", libproc);
    return ret;
}

Function baseFunction(size_t ctx = rootBases.length - 1)
{
    Function ret = new Function;
    uint[string] byName;
    foreach (i; ctx.rootBase)
    {
        byName[i.name] = cast(uint) byName.length;
    }
    string[] byPlace = ["print"];
    ret.stab = Function.Lookup(byName, byPlace);
    return ret;
}

Dynamic*[] loadBase(size_t ctx = rootBases.length - 1)
{
    Dynamic*[] ret;
    foreach (i; ctx.rootBase)
    {
        ret ~= [i.val].ptr;
    }
    return ret;
}
