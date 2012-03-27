source ~/.bash/aliases
source ~/.bash/completions
source ~/.bash/env_variables
source ~/.bash/paths
source ~/.bash/prompt_config
source ~/.bash/awd_proxies
source ~/.bash/bashmarks.sh

if [ -f ~/.bashrc ]; then
  source ~/.bashrc
fi
if [ -f ~/.localrc ]; then
  source ~/.localrc
fi

source ~/.bash/rvm_setup
