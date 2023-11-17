#!/bin/bash

####################################################################################################

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#        * Redistributions of source code must retain the above copyright
#         notice, this list of conditions and the following disclaimer.
#      * Redistributions in binary form must reproduce the above copyright
#           notice, this list of conditions and the following disclaimer in the
#           documentation and/or other materials provided with the distribution.
#         * Neither the name of the JAMF Software, LLC nor the
#           names of its contributors may be used to endorse or promote products
#           derived from this software without specific prior written permission.
# THIS SOFTWARE IS PROVIDED BY JAMF SOFTWARE, LLC "AS IS" AND ANY
# EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL JAMF SOFTWARE, LLC BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

####################################################################################################

url="https://yourserver.jamfcloud.com"
username="username"
password="pasword"

####################################################################################################
# Get bearer token for authentication
getBearerToken() {
	response=$(curl -s -u "$username":"$password" "$url"/api/v1/auth/token -X POST 2>/dev/null)
	bearerToken=$(echo "$response" | plutil -extract token raw -)
	tokenExpiration=$(echo "$response" | plutil -extract expires raw - | awk -F . '{print $1}')
	tokenExpirationEpoch=$(date -j -f "%Y-%m-%dT%T" "$tokenExpiration" +"%s")
}

####################################################################################################
#API BEARER TOKEN Expiration check

checkTokenExpiration() {
	nowEpochUTC=$(date -j -f "%Y-%m-%dT%T" "$(date -u +"%Y-%m-%dT%T")" +"%s")
	if [[ tokenExpirationEpoch -gt nowEpochUTC ]]
	then
		:
	else
		(echo "No valid token available, getting new token")
		getBearerToken
	fi
}

#Variable declarations
bearerToken=""
tokenExpirationEpoch="0"


####################################################################################################
# Pull the serial number and device ID from the smart group
	
networkSegmentList() {
	segmentList=$(curl -X 'GET' \
	"$url/JSSResource/networksegments" 2>/dev/null \
	-H 'accept: application/xml' \
	-H "Authorization: Bearer $bearerToken")
	segmentIDs=$(echo "$segmentList" | xmllint --xpath '/network_segments/network_segment//id/text()' -)
	#serialnumber=$(echo "$computerGroupCheck" | xmllint --xpath '/computer_group/computers/computer/serial_number/text()' -)
	echo "Network Segment IDs are: $segmentIDs"
	#echo "$serialnumber"
}

####################################################################################################
# Just UnManage the device

deleteAllSegments() {
	for networkid in $segmentIDs; do
		echo "Removing management from computer ID: $networkid"
		netDetails=$(curl -H "Authorization: Bearer $bearerToken" -H "Accept: application/xml" -H "Content-type: text/xml" -X DELETE "$url/JSSResource/networksegments/id/$networkid") 
		echo $netDetails
		netResults=$(echo "$netDetails" | xmllint --xpath '/network_segment/id/text()' -)
		echo "Network Segment $netResults deleted...."
		checkTokenExpiration 
	done
}




#gets bearer token for auth
getBearerToken

#list all network segements
networkSegmentList 

#walk through all segments and delete them
deleteAllSegments 
		