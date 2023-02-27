# string.zsh

When it comes to Zsh scripting, a lot of attention is paid to files and the file system, but it's much harder to find good documentation around string manipulation. Information about Zsh strings gets buried in the docs obscurely labeled [Parameter Expansion][1] or [Modifiers][2]. The [Fish Shell][fish] shell does a way better job with documentation, and has a handy [string][fish-string] command that covers most of the things you'd ever want to do with strings.

This project aims to use Fish's `string` command as a template for building Zsh string functions. You don't necessarily need these Fish functions in Zsh, but they serve as a good tool to show you how Zsh accomplishes all the same things.

## Tests

This README is validated using the excellent [clitest] testing framework. Occassionally in this doc I will include some testing snippets. I will try avoid them being distracting or doing any __magic__ in them. This doc itself is meant to contain all the actual code you need, not have things buried away.

Tests are run using the following command:

```zsh
./.clitests/runtests
```

With that said, here we need to handle test setup.

```zsh
% source string.zsh
%
```

## String lengths

In Zsh you get the length of strings using the `$#var` syntax like so:

```zsh
% str="abcdefghijklmnopqrstuvwxyz"
% echo $#str
26
%
```

Fish handles this with the [string length][string-length] command. If you like how Fish does things, you can also easily accomplish the same functionality in Zsh with a simple function:

```zsh
#string.zsh
##? string-length - print string lengths
##? usage: string length [STRING...]
function string-length {
  (( $# )) || return 1
  local s
  for s in "$@"; do
    echo $#s
  done
}
```

With this function you can now get string lengths similar to how Fish does it:

```zsh
% string-length '' a ab abc
0
1
2
3
%
```

## Changing case

In Zsh you can convert strings to upper or lower case using the `u` or `l` [modifiers][3], **OR** the `U` or `L` [parameter expansion flags][2]. Yep, you read that right - Zsh often has multiple different ways to do the same thing. AND it uses funny names for the syntax which makes it difficult to search for. AND it changes the case of the letters used depending on which syntax you use!

Here's how you use [modifiers][3] to change case:

```zsh
% str="AbCdEfGhIjKlMnOpQrStUvWxYz"
% echo ${str:u}
ABCDEFGHIJKLMNOPQRSTUVWXYZ
% echo ${str:l}
abcdefghijklmnopqrstuvwxyz
%
```

If you forget and use the wrong case, your string will be wrong, which is why it's better to enclose your variables in curly braces when using modifiers:

```zsh
% # EPIC FAIL EXAMPLES:
% # modifiers without curly braces may succeed in unexpected ways
% echo $str:U
AbCdEfGhIjKlMnOpQrStUvWxYz:U
% # use curly braces when using modifiers:
% echo ${str:U}  #=> --regex unrecognized modifier
% # zsh: unrecognized modifier `U'
%
```

Here's how you would use [parameter expansion flags][2] to change case:

```zsh
% str="AbCdEfGhIjKlMnOpQrStUvWxYz"
% echo ${(U)str}
ABCDEFGHIJKLMNOPQRSTUVWXYZ
% echo ${(L)str}
abcdefghijklmnopqrstuvwxyz
%
```

Unfortunately, you won't be so lucky if you accidentally use the wrong case when you use parameter expansion flags, because the lowercase `u` is used to apply uniqueness to the result.

```zsh
% # EPIC FAIL EXAMPLES:
% # modifiers without curly braces may succeed in unexpected ways
% arr=(aAa bBb cCc AaA cCc)
% echo ${(U)arr}
AAA BBB CCC AAA CCC
% # don't make a mistake here
% echo ${(u)arr}
aAa bBb cCc AaA
%
```

Fish handles changing case with the [string lower][string-lower] and [string upper][string-upper] commands. If you like how Fish does things, you can also easily accomplish the same functionality in Zsh with these simple functions:

```zsh
#string.zsh
##? string-lower - convert strings to lowercase
##? usage: string lower [STRING...]
function string-lower {
  (( $# )) || return 1
  local s
  for s in "$@"; do
    echo ${s:l}
  done
}

##? string-upper - convert strings to uppercase
##? usage: string upper [STRING...]
function string-upper {
  (( $# )) || return 1
  local s
  for s in "$@"; do
    echo ${s:u}
  done
}
```

With these functions you can now get change string case similar to how Fish does it:

```zsh
% # upper case
% string-upper A bb Abc
A
BB
ABC
% # lower case
% string-lower A bb Abc
a
bb
abc
%
```

## Joining strings

Fish handles joining strings with the [string join][string-join] and [string join0][string-join0] commands. In Zsh you can join strings with a separator using the `j` [parameter expansion flag][2].

```zsh
$ words=(abc def ghi)
$ sep=:
$ echo ${(pj.$sep.)words}
abc:def:ghi
$
```

A common join seperator is the null character (`$'\0'`). Many shell utilities will generate null separated data. For example, `find` does this with the `-print0` option.

_Note: Since the null character isn't viewable, I'll need replace it in the following examples using `| tr '\0' '0'` so it's visible for the purpose of demonstration._

```zsh
% find . -maxdepth 1 -type f -name '*.zsh' -print0 | tr '\0' '0' && echo
./string.zsh0./string.plugin.zsh0
%
```

Fish includes a [`join0`][fish-join0] command, which is just a special case of `join` with the null character as a separator, but with one notable exception; the result ends with a null character as well. In Zsh, we can accomplish this simply by adding an empty element to the end of whatever list we're joining.

```zsh
$ words=(abc def ghi '')
$ nul=$'\0'
$ echo ${(pj.$nul.)words} | tr '\0' '0'
abc0def0ghi0
$
```

If you like how Fish does things, you can also easily accomplish the same functionality in Zsh with these simple functions:

```zsh
#string.zsh
##? string-join - join strings with delimiter
##? usage: string join SEP [STRING...]
function string-join {
  (( $# )) || return 1
  local sep=$1; shift
  echo ${(pj.$sep.)@}
}

##? string-join0 - join strings with null character
##? usage: string join0 [STRING...]
function string-join0 {
  (( $# )) || return 1
  string-join $'\0' "$@" ''
}
```

Now we also have proper `join` commands in Zsh.

```zsh
% string join '/' a b c
a/b/c
% string join0 x y z | tr '\0' '0'
x0y0z0
%
```

## Substrings

Unfortunately, like many areas of Zsh, there are multiple diffent ways to get a substring in Zsh. Zsh also refers to substrings as 'parameter subscripting', which makes it difficult to find in the docs.

In Zsh you get substrings using the `$name[start,end]` syntax, or the `${name:offset:length}` syntax. With `$name[start,end]` syntax, `start` and `end` refer to the 1-based index position. You can also use negative numbers to index from the end of a string.

```zsh
% name="abcdefghijklmnopqrstuvwxyz"
% echo $name[3,6]
cdef
% echo $name[-3,-1]
xyz
%
```

With the `${name:offset:length}` syntax, `offset` is a 0-based index. Negative indexing is also supported, but requires you to surround the number with parenthesis so that the `:-` part isn't interperted as the `${name:-word}` substitution syntax. The length portion is optional, and if omitted means go to the end of the string.

```zsh
% name="abcdefghijklmnopqrstuvwxyz"
% echo ${name:2:4}
cdef
% echo ${name:(-4)}
wxyz
% echo ${name:(-15):(-3)}
lmnopqrstuvw
%
```

Fish handles this with the [string sub][string-sub] command. You can easily accomplish something similar in Zsh with your own version of this function:

```zsh
#string.zsh
##? string-sub - extract substrings
##? usage: string sub [-s start] [-e end] [STRINGS...]
function string-sub {
  (( $# )) || return 1
  local -A opts=(-s 1 -e '-1')
  zparseopts -D -F -K -A opts -- s: e: || return 1
  local s
  for s in "$@"; do
    echo $s[$opts[-s],$opts[-e]]
  done
}
```

This function is a little more involved than previous examples because we neet to pass option arguments. We use `zparseopts`, and if you are unfamiliar with that Zsh builtin take a second and [familiarize yourself with it here](#zparseopts).

`string-sub` uses the `-s` option for the starting position, with a default value of 1, which is the first position in the string. The `-e` option is the final position, with a default value of -1 (the end of the string).

With this function you can now work with substrings similar to how Fish does:

```zsh
% string sub -s 2 -e 3 abcde
bc
% string sub -s-2 abcde
de
% string sub -e3 abcde
abc
% string sub -e-5 abcde
a
% string sub -s2 -e-3 abcde
bc
% string sub -s -5 -e -3 abcdefgh
def
% string sub -s -100 -e -3 abcde
abc
% string sub -s -5 -e 2 abcde
ab
% string sub -s -50 -e -100 abcde

% string sub -s 2 -e -5 abcde

%
```

If you prefer 0-based indexing, you can do that too:

```zsh
#string.zsh
##? string-sub0 - extract substrings using 0-based indexing
##? usage: string sub0 [-o offset] [-l len] [STRINGS...]
function string-sub0 {
  (( $# )) || return 1
  local -A opts=(-o 0)
  zparseopts -D -K -A opts -- o: l:
  local s
  for s in "$@"; do
    echo ${s:$opts[-o]:${opts[-l]:-$#s}}
  done
}
```

With the `string-sub0` function you can now get substrings using 0-based offset/length indexing:

```zsh
% string-sub0 -o1 -l 2 abcde
bc
% string-sub0 -o-2 abcde
de
% string-sub0 -l3 abcde
abc
% string-sub0 -o-6 -l1 abcde
a
% string-sub0 -o -6 -l 2 abcde
ab
%
```

## String padding

In Zsh you can left pad strings using the `l:expr::string1::string2:` syntax. Similarly, right padding is done by changing the leading `l` to an `r` like this `r:expr::string1::string2:`. This is described in the [Expansion Flags][2] section of the Zsh docs.

This can be confusing, so let's look at a simple example.

```zsh
% str="abc"
% echo ${(l:7:: :)str}
    abc
% echo ${(l:10::-:)str}
-------abc
% echo ${(r:6::.:)str}
abc...
% echo ${(l:10::-#::=:)str}
-#-#-#=abc
%
```

Fish handles this with the [string pad][string-pad] command. You can easily accomplish the same thing in Zsh with your own version of this function:

```zsh
#string.zsh
##? string-pad - pad strings to a fixed width
##? usage: string pad [-r] [-c padchar] [-w width] [STRINGS...]
function string-pad {
  (( $# )) || return 1
  local s rl padexp
  local -A opts=(-c ' ' -w 0)
  zparseopts -D -K -F -A opts -- r c: w: || return
  for s in "$@"; do
    [[ $#s -gt $opts[-w] ]] && opts[-w]=$#s
  done
  for s in "$@"; do
    [[ -v opts[-r] ]] && rl='r' || rl='l'
    padexp="$rl:$opts[-w]::$opts[-c]:"
    eval "echo \"\${($padexp)s}\""
  done
}
```

This function is a lot more complicated than previous examples, so let's break it down. First, we need to parse options again. The `-c padchar` option is for the padding character, with a default value of a single space. The `-w width` option tells us how far out to pad. If `-w` isn't specifed, we use the length of the longest string provided to the function. The `-r` option switches from the default left padding to the right side.

We also use the `[[ test ]]` syntax. `[[ -v var ]]` tests whether a variable is set. `[[ num1 -gt num2 ]]` tests whether num1 is greater than num2.

And finally, we build out a padding expression to `eval` because Zsh doesn't allow the padding expression to use variable substitution, and we need it to.

With this function you can now pad strings similar to how Fish does:

```zsh
% string pad -c. long longer longest
...long
.longer
longest
% string pad -c ' ' -w8 a ccc bb dddd
       a
     ccc
      bb
    dddd
% string pad -c_ -w5 -r a ccc bb dddd
a____
ccc__
bb___
dddd_
%
```

## The `string` wrapper

Fish's [`string` command][fish-string] wraps all this functionality and handles pipe input too. You can also easily accomplish the same thing in Zsh.

```zsh
#string.zsh
##? string - manipulate strings
function string {
  emulate -L zsh
  setopt local_options
  0=${(%):-%x}

  if [[ "$1" == (-h|--help) ]]; then
    grep "^##? string -" ${0:A} | cut -c 5-
    echo "usage:"
    grep "^##? usage:" ${0:A} | cut -c 11-
    return
  fi

  if [[ ! -t 0 ]] && [[ -p /dev/stdin ]]; then
    if (( $# )); then
      set -- "$@" "${(@f)$(cat)}"
    else
      set -- "${(@f)$(cat)}"
    fi
  fi

  if (( $+functions[string-$1] )); then
    string-$1 "$@[2,-1]"
  else
    echo >&2 "string: Subcommand '$1' is not valid." && return 1
  fi
}
```

Now, all your string commands can accept piped input too:

```zsh
% printf '%s\n' a bb ccc | string length
1
2
3
% printf '%s\n' a bb ccc | string pad -c.
..a
.bb
ccc
%
```

## Additional testing

Here, we do any final testing of our string utilities.

Show that unrecognized subcommands fail properly:

```zsh
% string foo #=> --exit 1
% string foo
string: Subcommand 'foo' is not valid.
%
```

## Additional notes

### Fish's `--quiet` flag

Many of Fish's `string` commands include a `-q | --quiet` flag to suppress output. None of our examples here do that because in a POSIX shell, like Zsh, the preferred method for suppressing stdin is simply redirecting it to `/dev/null` like so:

```zsh
% echo "Secret message" >/dev/null
%
```

Fish also lets you add `>/dev/null` to commands, but it includes the quiet flag too. For the purposed of this demo, it's unnecessary complexity to support a `-q` flag in nearly every command when there's a preferred alternative.

### Fish's `string collect`

We didn't show an example of writing a [`string-collect`](string-collect) function because that may be needed for Fish, but not Zsh.

However, for completeness, it's worth noting that you can already collect multi-line input into a variable. You can also collect it into an array by combining the `@` and `f` expansion flags in Zsh like so:

```zsh
% str=$(echo "one\ntwo\nthree")
% echo $str
one
two
three
% arr=( ${(@f)str} )
% echo $#arr
3
% printf '[%s]\n' $arr
[one]
[two]
[three]
%
```

### zparseopts

To parse option arguments, many of these scripts use the `zparseopts` builtin. You will see this pattern throughout this doc:

```zsh
local -A opts=(-x 1 -z 3)
zparseopts -D -F -K -A opts -- x: y z: || return 1
```

If you are not familiar with `zparseopts`, you can [read more in the docs][zparseopts]. The short explaination is that we are telling `zparseopts` to:

- **delete (`-D`)** parsed options from `$@`.
- **fail (`-F`)** if a bad option is passed by the user.
- **keep (`-K`)** any options we've already set in the `$opts` associative array. "Associative array" is another word for a key/value dictionary.
- use the **associative array named 'opts' (`-A opts`)** to store the parsed options.

### Supported Zsh Version

A quick note on Zsh versions - the scripts in this doc are verified with a modern release of Zsh only. There may be subtle differences in these scripts on previous Zsh versions. Backward compatibility is not a primary concern here, but if it is a problem for you, you might need to be careful with `zparseopts` usage since its behavior has changed over the years. You can read more about Zsh releases on the [news page][zsh-news].


[1]: https://zsh.sourceforge.io/Doc/Release/Expansion.html#Parameter-Expansion
[2]: https://zsh.sourceforge.io/Doc/Release/Expansion.html#Parameter-Expansion-Flags
[3]: https://zsh.sourceforge.io/Doc/Release/Expansion.html#Modifiers
[4]: https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html#The-zsh_002fpcre-Module
[fish]: https://fishshell.com
[fish-string]: https://fishshell.com/docs/current/cmds/string.html
[string-collect]: https://fishshell.com/docs/current/cmds/string-collect.html
[string-escape]: https://fishshell.com/docs/current/cmds/string-escape.html
[string-join]: https://fishshell.com/docs/current/cmds/string-join.html
[string-join0]: https://fishshell.com/docs/current/cmds/string-join0.html
[string-length]: https://fishshell.com/docs/current/cmds/string-length.html
[string-lower]: https://fishshell.com/docs/current/cmds/string-lower.html
[string-match]: https://fishshell.com/docs/current/cmds/string-match.html
[string-pad]: https://fishshell.com/docs/current/cmds/string-pad.html
[string-repeat]: https://fishshell.com/docs/current/cmds/string-repeat.html
[string-replace]: https://fishshell.com/docs/current/cmds/string-replace.html
[string-split]: https://fishshell.com/docs/current/cmds/string-split.html
[string-split0]: https://fishshell.com/docs/current/cmds/string-split0.html
[string-sub]: https://fishshell.com/docs/current/cmds/string-sub.html
[string-trim]: https://fishshell.com/docs/current/cmds/string-trim.html
[string-unescape]: https://fishshell.com/docs/current/cmds/string-unescape.html
[string-upper]: https://fishshell.com/docs/current/cmds/string-upper.html
[clitest]: https://github.com/aureliojargas/clitest
[zsh-news]: https://zsh.sourceforge.io/News/
[zparseopts]: https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html#index-zparseopts
