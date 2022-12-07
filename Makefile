##############################################
## STD OUT
##############################################

green=$$(tput setaf 2)
yellow=$$(tput setaf 3)
red=$$(tput setaf 1)
normal=$$(tput sgr0)
INFO=sh -c 'printf "`date +%y/%m/%d_%H:%M:%S` :: %b $$1 \n" "${green}[INFO]${normal}"' INFO
WARN=sh -c 'printf "`date +%y/%m/%d_%H:%M:%S` :: %b $$1 \n" "${yellow}[WARN]${normal}"' WARN
FAIL=sh -c 'printf "`date +%y/%m/%d_%H:%M:%S` :: %b $$1 \n" "${red}[FAILURE]${normal}"; exit $$2' FAIL

ifneq (,$(findstring n, $(MAKEFLAGS)))
INFO=: INFO
WARN=: WARN
FAIL=: FAIL
endif

.SILENT: install_reqs

##############################################
## REQUIREMENTS
##############################################

install_reqs:
	${INFO} "verifying brew"
	if ! brew --version >/dev/null 2>&1; then \
	  ${FAIL} "you must install brew" 1; \
	fi
	${INFO} "installing requirements"
	brew install infracost terraform tflint terraform-docs infracost pre-commit commitizen go
	${INFO} "installing pre-commit"
	pre-commit install
