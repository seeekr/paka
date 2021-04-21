module paka.plugin;

import paka.base;
import paka.parse.parse;
import purr.plugin.plugin;
import purr.plugin.plugins;

shared static this()
{
    thisPlugin.addPlugin;
}

Plugin thisPlugin()
{
    Plugin plugin = new Plugin;
    plugin.libs ~= pakaBaseLibs;
    plugin.parsers["paka"] = code => parse(code);
    return plugin;
}
