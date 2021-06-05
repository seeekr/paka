module ext.passerine.parse.pattern;

import purr.io;
import std.conv;
import purr.ast.ast;
import purr.dynamic;

Dynamic matchExact(Args args)
{
    return dynamic(args[0] == args[1]);
}

bool isIndexable(Dynamic arg)
{
    return arg.isArray;
}

Dynamic matchExactLength(Args args)
{
    return dynamic(args[0].isIndexable && args[0].arr.length == args[1].as!size_t);
}

Dynamic matchNoLength(Args args)
{
    return dynamic(args[0].isIndexable && args[0].arr.length == 0);
}

Dynamic matchNoLessLength(Args args)
{
    return dynamic(args[0].isIndexable && args[0].arr.length >= args[1].as!size_t);
}

Dynamic rindex(Args args)
{
    return args[0].arr[$ - args[1].as!size_t];
}

Dynamic slice(Args args)
{
    return args[0].arr[args[1].as!size_t .. $ - args[2].as!size_t].dynamic;
}

Node matcher(Node value, Node pattern, size_t line = __LINE__)
{
    assert(pattern !is null, "null pattern at: " ~ line.to!string);
    if (Ident id = cast(Ident) pattern)
    {
        if (id.repr == "_")
        {
            return new Form("do", value, new Value(true));
        }
        Node setter = new Form("set", id, value);
        return new Form("do", setter, new Value(true));
    }
    else if (cast(Value) pattern)
    {
        return new Form("==", pattern, value);
    }
    else if (Form call = cast(Form) pattern)
    {
        switch (call.form)
        {
        default:
            return new Form("==", value, pattern);
        case ":":
            Node c1 = matcher(value, call.args[0]);
            Node c2 = matcher(value, call.args[1]);
            return new Form("&&", c1, c2);
        case "|":
            Node c1 = matcher(value, call.args[0]);
            Node c2 = call.args[1];
            return new Form("&&", c1, c2);
        case "tuple":
            if (call.args.length == 0)
            {
                Node ret = new Form("==", new Form("length", value), new Value(0));
            }
            goto arrayLike;
        case "array":
            if (call.args.length == 0)
            {
                Node ret = new Form("==", new Form("length", value), new Value(0));
            }
        arrayLike:
            Node[] pre;
            Node mid = null;
            Node[] post;
            foreach (val; call.args)
            {
                if (Form call2 = cast(Form) val)
                {
                    if (call2.form == "..")
                    {
                        mid = val;
                        continue;
                    }
                }
                if (mid !is null)
                {
                    post ~= val;
                }
                else
                {
                    pre ~= val;
                }
            }
            if (mid is null)
            {
                Node ret = new Form("==", new Form("length", value), new Value(pre.length));
                foreach (index, term; pre)
                {
                    Node indexed = new Form("index", value, new Value(index));
                    ret = new Form("&&", ret, matcher(indexed, term));
                }
                return ret;
            }
            else
            {
                Node ret = new Form(">=", new Form("length", value),
                        new Value(pre.length + post.length));
                foreach (index, term; pre)
                {
                    Node indexed = new Form("index", value, new Value(index));
                    ret = new Form("&&", ret, matcher(indexed, term));
                }
                Node sliced = new Form("slice", value, new Value(pre.length),
                        new Value(post.length));
                Form term0 = cast(Form) mid;
                assert(term0);
                ret = new Form("&&", ret, matcher(sliced, term0.args[0]));
                foreach (index, term; post)
                {
                    ulong backIndex = index + 1;
                    Node indexed = new Form("index", value, new Value(-backIndex));
                    ret = new Form("&&", ret, matcher(indexed, term));
                }
                return ret;
            }
        case "call":
            return new Form("==", pattern, call);
        }
    }
    assert(false);
}
