# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'


# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi


##################
# Customizations #
##################

# Custom aliases
alias home='clear;'

# Alias Homebrew's install of emacs
alias emacs='open -a /usr/local/Cellar/emacs/24.4/Emacs.app'

# Alias Skim for quick PDF viewing
alias skim='open -a /Users/ely_spears/Applications/Skim.app/Contents/MacOS/Skim'

# Alias Mou for quick Markdown viewing
alias mou='open -a /Users/ely_spears/Applications/Mou.app'

# Alias for skype
alias skype='open -a /Users/ely_spears/Applications/Skype.app'

# Alias MacTex install of pdflatex
alias pdflatex='/usr/texbin/pdflatex'

# Alias for Mnemosyne program
alias mnemosyne='open -a /Applications/Mnemosyne.app'

# Helper aliases for quick cd to workspaces
alias cdworkspace='cd $WORKSPACE'
alias cdlearnsmart='cd $LEARNSMART'
alias cdflow='cd $FLOW'
alias cdflowlib='cd $FLOWLIB'
alias cdconfigs='cd $HOME/configs'
alias cdflowwww='cd $FLOWWWW'

# Exports and system path configs
export EDITOR=emacs
export GIT_EDITOR=emacs

# added by Anaconda 2.1.0 installer
export PATH="/Users/ely_spears/anaconda/bin:$PATH"

# Putting emacs downloads on the path.
export PATH="/home/ely/.emacs.d:$PATH"

# Paths for Neko install needed by Flow
export NEKOPATH=$HOME/neko
export PATH=$NEKOPATH:$PATH

# Paths for Flow libraries
export WORKSPACE=$HOME/workspace
export LEARNSMART=$WORKSPACE/learnsmart
export COPENHAGEN=$LEARNSMART/copenhagen
export FLOW=$LEARNSMART/flow
export FLOWLIB=$FLOW/lib
export FLOWSRC=$FLOW/src
export FLOWWWW=$FLOW/www
export FLOWLINGO=$FLOWLIB/lingo
export PATH=$FLOW/bin:$PATH

# Paths for Haxe install needed by Flow
export HAXEPATH=$HOME/haxe
export HAXEPATH=$FLOWSRC:$HAXEPATH
export HAXE_LIBRARY_PATH=$HAXEPATH/std
export PATH=$HAXEPATH:$PATH
export DYLD_LIBRARY_PATH=$NEKOPATH:$DYLD_LIBRARY_PATH




####################
# Helper functions #
####################

alias killSimpleServer='pkill -9 -f SimpleHTTPServer'
alias generatePR='hub pull-request -b master -o'

# Custom man pages for these are sym linked in /usr/local/share/man/man1
# which points to scratch/creating_man_pages for the version controlled
# source.

function searchHere() {
    if [ "$#" -gt 1 ]; then
        grep -ir "$1" $PWD --include "$2"
    else
        grep -ir "$1" $PWD
    fi
}

function flowLibSearch() {
    # If --<search_loc> given, then dispatch different searches.
    if [ "$#" -gt 1 ]; then
        if [ "$1" == "--copenhagen" ]; then
            grep -ir "$2" ${COPENHAGEN} --include "*.flow"
        elif [ "$1" == "--source" ]; then
            grep -ir "$2" ${FLOWSRC} --include "*.hx" --include "*.flow"
        elif [ "$1" == "--lingo" ]; then
            grep -ir "$2" ${FLOWLINGO} --include "*.lingo" --include "*.flow"
        elif [ "$1" == "--lib" ]; then
            grep -ir "$2" ${FLOWLIB} --include "*.flow"
        fi
    # Otherwise assume it is lib search.
    else
        grep -ir "$1" ${FLOWLIB} --include "*.flow"
    fi
}

function jsLaunch() {
    cp "$1" $FLOWWWW;
    pushd $FLOWWWW;
    open http://localhost/flow/flowjs.html?name="${1%%.*}";
    popd;
}

function swfLaunch() {
    cp "$1" $FLOWWWW;
    pushd $FLOWWWW;
    open http://localhost/flow/flowswf.html?name="${1%%.*}";
    popd;
}

function flowdbg() {
    rlwrap flowcpp --batch --debug "$1"
}

function pushNewBranch() {
    git push -u origin "$1"
}











