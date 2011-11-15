source ~/.bash/aliases
source ~/.bash/completions
source ~/.bash/oracle_client
source ~/.bash/paths
source ~/.bash/config
source ~/.bin/bashmarks.sh


if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi

if [ -f ~/.localrc ]; then
  . ~/.localrc
fi

# # need this to compile rubies on OSX Lion (there CC links to llvm-gcc-4.2)
# export CC=/usr/bin/gcc-4.2
# export CC=/usr/bin/gcc


####### AWD #######
function awd_proxies_on
{
 export http_proxy=http://proxy.awd.ch:3128
 export https_proxy=http://proxy.awd.ch:3128
 export ftp_proxy=http://proxy.awd.ch:3128
 echo "AWD proxies activated"
}
function awd_proxies_off
{
 unset http_proxy
 unset https_proxy
 unset ftp_proxy
 echo "AWD proxies deactivated"
}

# check presence of proxies
ping -c1 -t1 -q proxy.awd.ch > /dev/null 2>&1
if [ $? == 0 ]; then
 awd_proxies_on;
else
 echo "AWD proxies not activated."
fi;


source ~/.bash/rvm_setup

