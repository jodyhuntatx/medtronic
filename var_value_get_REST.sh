#!/bin/bash
#
# Authenticates as host identity with API key and gets value of a specified variable
#

export CONJUR_APPLIANCE_URL=https://<fqdn-of-conjur-host-vm>
export CONJUR_ACCOUNT=dev
export CONJUR_CERT_FILE=<path-to-master-cert-pem-file>

################  MAIN   ################
# Takes 3 arguments:
#   $1 - host/<dap-host-identity-from-policy>
#   $2 - API key
#   $3 - name of variable to value to return
#
main() {

  if [[ $# -ne 3 ]] ; then
    printf "\nUsage: %s <host-identity> <api-key> <variable-name>\n" $0
    exit -1
  fi
  local CONJUR_AUTHN_LOGIN=$1
  local CONJUR_AUTHN_API_KEY=$2
  local variable_name=$3
				# authenticate, get ACCESS_TOKEN
  ACCESS_TOKEN=$(authn_host $CONJUR_AUTHN_LOGIN $CONJUR_AUTHN_API_KEY)
  if [[ "$ACCESS_TOKEN" == "" ]]; then
    echo "Authentication failed..."
    exit -1
  fi

  local encoded_var_name=$(urlify "$variable_name")
  curl -s \
	--cacert $CONJUR_CERT_FILE \
	-H "Content-Type: application/json" \
	-H "Authorization: Token token=\"$ACCESS_TOKEN\"" \
     $CONJUR_APPLIANCE_URL/secrets/$CONJUR_ACCOUNT/variable/$encoded_var_name
}

##################
# AUTHN HOST
#  $1 - host identity
#  $2 - API key
#
authn_host() {
  local host_id=$1; shift
  local api_key=$1; shift

  local encoded_host_id=$(urlify "$host_id")
  local response=$(curl -s \
		     --cacert $CONJUR_CERT_FILE \
                     --data $api_key \
                     $CONJUR_APPLIANCE_URL/authn/$CONJUR_ACCOUNT/$encoded_host_id/authenticate)
  access_token=$(echo -n $response| base64 | tr -d '\r\n')
  echo "$access_token"
}

################
# URLIFY - url encodes input string
# in: $1 - string to encode
# out: URLIFIED - global variable containing encoded string
urlify() {
        local str=$1; shift
        str=$(echo $str | sed 's= =%20=g')
        str=$(echo $str | sed 's=/=%2F=g')
        str=$(echo $str | sed 's=:=%3A=g')
        str=$(echo $str | sed 's=+=%2B=g')
        str=$(echo $str | sed 's=&=%26=g')
        str=$(echo $str | sed 's=@=%40=g')
        echo $str
}

main "$@"
