#!/bin/sh
log_tagging_start_time=$(date +%s)
c2_file=/etc/redpine/log_tagging.sh
c3_file=/etc/broadcom/wifi/log_tagging.sh

start_time=0
offline=0
zero=0
one=1
two=2
max_offline_dur=600
max_online_dur=600
max_log_bkp_time=10
log_bkp=0

#c3_wifi_stats_start
c3_wifi_stats_start_stop ()
{
	if [ $# -eq 2 ]; then
		if [ $1 -eq 1 ]; then
			file="/etc/broadcom/wifi/$2"
			echo "Capture start Time $(date)" > $file
			echo "<<< VERSION_DETAILS >>>" >> $file
			/usr/sbin/wl ver >> $file
			echo "<<< MAC_DETAILS >>>" >> $file
			/sbin/ifconfig wlan0 >> $file
			echo "<<< CONFIG_DETAILS >>>" >> $file
			cat /etc/rc5.d/S40broadcom >> $file
			chmod 777 $file
			/sbin/wlpriv wlan0 set_log_mode 0xFF		
			#/etc/broadcom/wifi/debug $file 0 >/dev/null
			/usr/bin/nohup /etc/broadcom/wifi/debug $file 0 >/dev/null &
		elif [ $1 == $two ]; then
			echo "entered 2 condition"
			/sbin/wlpriv wlan0 set_log_mode 0
			/usr/bin/killall debug
			#echo "Capture end Time $(date)" >> $file	
		else
			echo -e "Usage:$0 <1/2> file_name\n 1->start logging \n 2->stop logging"
		fi
	else
		echo -e "Usage:$0 <1/2> file_name\n 1->start logging \n 2->stop logging"
	fi
}

c2_wifi_stats_start_stop ()
{
	if [ $# -eq 2 ]; then
		if [ $1 -eq 1 ]; then
			file="/etc/redpine/$2"
			echo "Capture start Time $(date)" > $file
			echo "<<< VERSION_DETAILS >>>" >> $file
			cat /proc/wlan0/version >> $file
			/sbin/iwpriv wlan0 set_log_mode 0xFF
			echo "<<< MAC_DETAILS >>>" >> $file
			/sbin/ifconfig wlan0 >> $file
			echo "<<< CONFIG_DETAILS >>>" >> $file
			cat /etc/init.d/S31redpine >> $file
			chmod 777 $file		
			/sbin/iwpriv wlan0 set_log_mode 0xFF
			/usr/bin/nohup /etc/redpine/debug $file 0 >/dev/null &
			echo "enter 1nd loop"
		elif [ $1 -eq 2 ]; then
			echo "enter 2nd loop"
			/sbin/iwpriv wlan0 set_log_mode 0
			killall debug
			#echo "Capture end Time $(date)" >> $file
			
		else
			echo -e "Usage:$0 <1/2> file_name\n 1->start logging \n 2->stop logging"
		fi
	else
		echo -e "Usage:$0 <1/2> file_name\n 1->start logging \n 2->stop logging"
	fi
}

if [ -f "$c3_file" ]
then
	cd /etc/broadcom/wifi/
	rm /etc/broadcom/wifi/wifi_stats_20mins_before_log
	rm /etc/broadcom/wifi/wifi_stats_10mins_before_log
	rm /etc/broadcom/wifi/wifi_stats_log
	rm /etc/broadcom/wifi/comm3_debug.log
	c3_wifi_stats_start_stop 1 wifi_stats_log
	#nohup sh tts_wifi_log_c3.sh 1 wifi_stats_log &
else
	cd /etc/redpine/
	rm /etc/redpine/wifi_stats_20mins_before_log
	rm /etc/redpine/wifi_stats_10mins_before_log
	rm /etc/redpine/wifi_stats_log
	rm /etc/redpine/messages
	c2_wifi_stats_start_stop 1 wifi_stats_log
	#nohup sh tts_wifi_log.sh 1 wifi_stats_log &
fi


while :
do
	ping -c1 192.168.10.211
	rc=$?
	if [[ $rc -eq 0 ]] 
	then
		offline=0
	else
		offline=1
	fi
	echo $offline
	if [ -f "$c3_file" ]
	then
		if [ $offline == $zero ]
		then
			start_time=0
			debug_log=/etc/broadcom/wifi/comm3_debug.log
			if [ -f "$debug_log" ]
			then
				rm /etc/broadcom/wifi/comm3_debug.log
				log_bkp=0
			fi
			present_time=$(date +%s)
			let "online_duration = $present_time - $log_tagging_start_time"
			if [ $online_duration -gt $max_online_dur ]
			then
				cd /etc/broadcom/wifi/
				c3_wifi_stats_start_stop 2 wifi_stats_log
				#nohup sh tts_wifi_log_c3.sh 2 wifi_stats_log &
				FILE=/etc/broadcom/wifi/wifi_stats_10mins_before_log
				FILE2=/etc/broadcom/wifi/wifi_stats_20mins_before_log
				if [ -f "$FILE" ]
				then
					#rm wifi_stats_10mins_before_log
					if [ -f "$FILE2" ]
					then
						rm /etc/broadcom/wifi/wifi_stats_20mins_before_log
						cp /etc/broadcom/wifi/wifi_stats_10mins_before_log /etc/broadcom/wifi/wifi_stats_20mins_before_log
						rm /etc/broadcom/wifi/wifi_stats_10mins_before_log
						cp /etc/broadcom/wifi/wifi_stats_log /etc/broadcom/wifi/wifi_stats_10mins_before_log
						rm /etc/broadcom/wifi/wifi_stats_log
						c3_wifi_stats_start_stop 1 wifi_stats_log
						#nohup sh tts_wifi_log_c3.sh 1 wifi_stats_log &
						log_tagging_start_time=$(date +%s)
					
					else
						cp /etc/broadcom/wifi/wifi_stats_10mins_before_log /etc/broadcom/wifi/wifi_stats_20mins_before_log
						rm /etc/broadcom/wifi/wifi_stats_10mins_before_log
						cp /etc/broadcom/wifi/wifi_stats_log /etc/broadcom/wifi/wifi_stats_10mins_before_log
						rm /etc/broadcom/wifi/wifi_stats_log
						c3_wifi_stats_start_stop 1 wifi_stats_log
						#nohup sh tts_wifi_log_c3.sh 1 wifi_stats_log &
						log_tagging_start_time=$(date +%s)
						
					fi	
				
				else
					cp /etc/broadcom/wifi/wifi_stats_log /etc/broadcom/wifi/wifi_stats_10mins_before_log
					rm /etc/broadcom/wifi/wifi_stats_log
					c3_wifi_stats_start_stop 1 wifi_stats_log
					#nohup sh tts_wifi_log_c3.sh 1 wifi_stats_log &
					log_tagging_start_time=$(date +%s)
					
				fi
			fi
		fi
		if [ $offline == $one ]
		then
			if [ $start_time == $zero ]
			then
				start_time=$(date +%s)
			else
				end_time=$(date +%s)
			fi
			let "log_time_lat = $end_time - $start_time"
			if [ $log_time_lat -gt $max_log_bkp_time ] && [ $log_bkp == $zero ]
			then
				cp /var/log/theatro/comm3.log /etc/broadcom/wifi/comm3_debug.log
				log_bkp=1
			fi

			let "offline_time_lat = $end_time - $start_time"
			if [ $offline_time_lat -gt $max_offline_dur ]
			then
				#cd /etc/broadcom/wifi/
				c3_wifi_stats_start_stop 2 wifi_stats_log
				#nohup sh tts_wifi_log_c3.sh 2 wifi_stats_log &
				k = 5
				while [$k -gt 0]
				do
					wl status >> connected_state.log
					ifconfig >> connected_state.log
					iwconfig >> connected_state.log
					k = 'expr $k - 1'
					sleep 1
				done
				echo "break"
				break
			fi
			let "offline_time = $end_time - $log_tagging_start_time"
			echo $offline_time
			if [ $offline_time -gt $max_offline_dur ]
			then
				cd /etc/broadcom/wifi/
				c3_wifi_stats_start_stop 2 wifi_stats_log
				#nohup sh tts_wifi_log_c3.sh 2 wifi_stats_log &
				FILE=/etc/broadcom/wifi/wifi_stats_10mins_before_log
				FILE2=/etc/broadcom/wifi/wifi_stats_20mins_before_log
				if [ -f "$FILE" ]
				then
					#rm wifi_stats_10mins_before_log
					if [ -f "$FILE2" ]
					then
						rm /etc/broadcom/wifi/wifi_stats_20mins_before_log
						cp /etc/broadcom/wifi/wifi_stats_10mins_before_log /etc/broadcom/wifi/wifi_stats_20mins_before_log
						rm /etc/broadcom/wifi/wifi_stats_10mins_before_log
						cp /etc/broadcom/wifi/wifi_stats_log /etc/broadcom/wifi/wifi_stats_10mins_before_log
						rm /etc/broadcom/wifi/wifi_stats_log
						c3_wifi_stats_start_stop 1 wifi_stats_log
						#nohup sh tts_wifi_log_c3.sh 1 wifi_stats_log &
						log_tagging_start_time=$(date +%s)
					
					else
						cp /etc/broadcom/wifi/wifi_stats_10mins_before_log /etc/broadcom/wifi/wifi_stats_20mins_before_log
						rm /etc/broadcom/wifi/wifi_stats_10mins_before_log
						cp /etc/broadcom/wifi/wifi_stats_log /etc/broadcom/wifi/wifi_stats_10mins_before_log
						rm /etc/broadcom/wifi/wifi_stats_log
						c3_wifi_stats_start_stop 1 wifi_stats_log
						#nohup sh tts_wifi_log_c3.sh 1 wifi_stats_log &
						log_tagging_start_time=$(date +%s)
						
					fi	
				
				else
					cp /etc/broadcom/wifi/wifi_stats_log /etc/broadcom/wifi/wifi_stats_10mins_before_log
					rm /etc/broadcom/wifi/wifi_stats_log
					c3_wifi_stats_start_stop 1 wifi_stats_log
					#nohup sh tts_wifi_log_c3.sh 1 wifi_stats_log &
					log_tagging_start_time=$(date +%s)
				fi
			fi
		fi
		echo $(date +%s)
	fi
	if [ -f "$c2_file" ]
	then
		if [ $offline == $zero ]
		then
			start_time=0
			debug_log=/etc/redpine/messages
			if [ -f "$debug_log" ]
			then
				rm /etc/redpine/messages
				log_bkp=0
			fi
			present_time=$(date +%s)
			let "online_duration = $present_time - $log_tagging_start_time"
			if [ $online_duration -gt $max_online_dur ]
			then
				cd /etc/redpine
				c2_wifi_stats_start_stop 2 wifi_stats_log
				#nohup sh tts_wifi_log.sh 2 wifi_stats_log &
				FILE=/etc/redpine/wifi_stats_10mins_before_log
				FILE2=/etc/redpine/wifi_stats_20mins_before_log
				if [ -f "$FILE" ]
				then
					#rm wifi_stats_10mins_before_log
					if [ -f "$FILE2" ]
					then
						rm /etc/redpine/wifi_stats_20mins_before_log
						cp /etc/redpine/wifi_stats_10mins_before_log /etc/redpine/wifi_stats_20mins_before_log
						rm /etc/redpine/wifi_stats_10mins_before_log
						cp /etc/redpine/wifi_stats_log /etc/redpine/wifi_stats_10mins_before_log
						rm /etc/redpine/wifi_stats_log
						c2_wifi_stats_start_stop 1 wifi_stats_log
						#nohup sh tts_wifi_log.sh 1 wifi_stats_log &
						log_tagging_start_time=$(date +%s)
					
					else
						cp /etc/redpine/wifi_stats_10mins_before_log /etc/redpine/wifi_stats_20mins_before_log
						rm /etc/redpine/wifi_stats_10mins_before_log
						cp /etc/redpine/wifi_stats_log /etc/redpine/wifi_stats_10mins_before_log
						rm /etc/redpine/wifi_stats_log
						c2_wifi_stats_start_stop 1 wifi_stats_log
						#nohup sh tts_wifi_log.sh 1 wifi_stats_log &
						log_tagging_start_time=$(date +%s)
						
					fi	
				
				else
					cp /etc/redpine/wifi_stats_log /etc/redpine/wifi_stats_10mins_before_log
					rm /etc/redpine/wifi_stats_log
					c2_wifi_stats_start_stop 1 wifi_stats_log
					#nohup sh tts_wifi_log.sh 1 wifi_stats_log &
					log_tagging_start_time=$(date +%s)
					
				fi
			fi
		fi
		if [ $offline == $one ]
		then
			if [ $start_time == $zero ]
			then
				start_time=$(date +%s)
			else
				end_time=$(date +%s)
			fi	
			let "log_time_lat = $end_time - $start_time"
			if [ $log_time_lat -gt $max_log_bkp_time ] && [ $log_bkp == $zero ]
			then
				cp /var/log/messages /etc/redpine/messages
				log_bkp=1
			fi

			let "offline_time_lat = $end_time - $start_time"
			if [ $offline_time_lat -gt $max_offline_dur ]
			then
				cd /etc/redpine/
				c2_wifi_stats_start_stop 2 wifi_stats_log
				#nohup sh tts_wifi_log.sh 2 wifi_stats_log &
				k = 5
				while [$k -gt 0]
				do
					cat /proc/wlan0/stats >> connected_state.log
					ifconfig >> connected_state.log
					iwconfig >> connected_state.log
					k = 'expr $k - 1'
					sleep 1
				done
				echo "break"
				echo $(date +%s)
				break
			fi
			let "offline_time = $end_time - $log_tagging_start_time"
			if [ $offline_time -gt $max_offline_dur ]
			then
				cd /etc/redpine/
				c2_wifi_stats_start_stop 2 wifi_stats_log
				#nohup sh tts_wifi_log.sh 2 wifi_stats_log &
				FILE=/etc/redpine/wifi_stats_10mins_before_log
				FILE2=/etc/redpine/wifi_stats_20mins_before_log
				if [ -f "$FILE" ]
				then
					#rm wifi_stats_10mins_before_log
					if [ -f "$FILE2" ]
					then
						rm /etc/redpine/wifi_stats_20mins_before_log
						cp /etc/redpine/wifi_stats_10mins_before_log /etc/redpine/wifi_stats_20mins_before_log
						rm /etc/redpine/wifi_stats_10mins_before_log
						cp /etc/redpine/wifi_stats_log /etc/redpine/wifi_stats_10mins_before_log
						rm /etc/redpine/wifi_stats_log
						c2_wifi_stats_start_stop 1 wifi_stats_log
						#nohup sh tts_wifi_log.sh 1 wifi_stats_log &
						log_tagging_start_time=$(date +%s)
					
					else
						cp /etc/redpine/wifi_stats_10mins_before_log /etc/redpine/wifi_stats_20mins_before_log
						rm /etc/redpine/wifi_stats_10mins_before_log
						cp /etc/redpine/wifi_stats_log /etc/redpine/wifi_stats_10mins_before_log
						rm /etc/redpine/wifi_stats_log
						c2_wifi_stats_start_stop 1 wifi_stats_log
						#nohup sh tts_wifi_log.sh 1 wifi_stats_log &
						log_tagging_start_time=$(date +%s)
						
					fi	
				
				else
					cp /etc/redpine/wifi_stats_log /etc/redpine/wifi_stats_10mins_before_log
					rm /etc/redpine/wifi_stats_log
					c2_wifi_stats_start_stop 1 wifi_stats_log
					#nohup sh tts_wifi_log.sh 1 wifi_stats_log &
					log_tagging_start_time=$(date +%s)
				fi
			fi
			
		fi
		echo $(date +%s)
	fi
done
