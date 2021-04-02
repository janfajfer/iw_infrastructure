#!/bin/bash



function echo_err(){
	echo "$@" 1>&2
}


function get_global_admin_password(){
	# uses tool.sh to get a globaladmin password

	local tool="/opt/icewarp/tool.sh"

	# checks if GlobalAdmin is enabled and stores the result in a variable 
	local global_admin_enabled=$($tool display system C_Accounts_Policies_EnableGlobalAdmin | awk '{print $NF}')

	# if GlobalAdmin is not enabled, enables and generates a password 
	if [ $global_admin_enabled == "0" ]
	then
		echo_err "enabling GlobalAdmin account"
		echo_err $($tool set system C_Accounts_Policies_EnableGlobalAdmin 1)
		echo_err "regenerating GlobalAdmin password"	
		echo_err $($tool set system C_Accounts_Policies_RegenerateGlobalAdminPassword 1)	
	fi

	echo_err "retrieving GlobalAdmin password"
	global_admin_password=$($tool display system C_Accounts_Policies_GlobalAdminPassword | awk '{print $NF}')
	echo $global_admin_password
}

function get_link_to_impersonificate_user(){
	# uses icewarpapi to get a link to impersonificate a user
	# the user email is given as an argument to this function

	local iw_server="127.0.0.1"
	local global_admin_email="globaladmin"
	global_admin_password=$(get_global_admin_password)
	user_email_to_impersonificate=$1

	# prepare a request to the icewarp api to get atoken
	admin_token_request="<iq uid=\"1\" format=\"text/xml\"><query xmlns=\"admin:iq:rpc\" ><commandname>authenticate</commandname><commandparams><email>${global_admin_email}</email><password>${global_admin_password}</password><digest></digest><authtype>0</authtype><persistentlogin>0</persistentlogin></commandparams></query></iq>"

	# gets a web_client_admin_token that is needed to impersonificate a user
	web_client_admin_token=$(curl -s --connect-timeout 8 -m 8 -ikL --data-binary "${atoken_request}" "https://${iw_server}/icewarpapi/" | awk -F '"' '/sid=/{print $(NF-1)}')

	# prepares a request to the icewarp api to get the impersonification link
	impersonification_request="<iq sid=\"${web_client_admin_token}\" format=\"text/xml\"><query xmlns=\"admin:iq:rpc\" ><commandname>impersonatewebclient</commandname><commandparams><email>${user_email_to_impersonificate}</email></commandparams></query></iq>"

	echo_err "impersonification link for user $user_email_to_impersonificate:"
	echo $(curl -s --connect-timeout 8 -m 8 -ikL --data-binary "${impersonification_request}" "https://${iw_server}/icewarpapi/" | awk -F "[<>]" '/<result>/{print $3}')
}

function printUsage() {
cat << EOF
iw_infra_manager.sh help:

options:
	get_global_admin_password: retrieves a password for globaladmin
	get_link_to_impersonificate_user [user_email]: retrieves a link to impersonificate a user
EOF
}


#MAIN
case ${1} in
  get_global_admin_password) get_global_admin_password;
  ;;
  get_link_to_impersonificate_user) get_link_to_impersonificate_user "$2";
  ;;
  *) printUsage;
esac
exit 0