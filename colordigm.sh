#!/bin/sh
if [ -r $1 ]
then
	echo "Cannot read $1, aborting"
fi
COLORFILE=$1
COLORNAMES=""
COLORVALUES=""
COMMANDS=""
TOTAL=0
echo "Running simulation..."
LINES=$(cat $COLORFILE | wc -l)
COUNT=0
while read LINE; do
	COUNT=$(expr $COUNT + 1)
	printf "$(expr $COUNT \* 100 / $LINES)%%\r"
	if echo $LINE | grep -q "^S[ \t]\+"
	then
		SIMULATE=$(echo $LINE | awk '{$1="";print substr($0,2,length($0))}')
	fi
	if echo $LINE | grep -q "^D[ \t]\+"
	then
		COLORNAMES="$COLORNAMES\n$(echo $LINE | awk '{print$2}')"
		COLORVALUES="$COLORVALUES\n$(echo $LINE | awk '{print$3}')"
	fi
	if echo $LINE | grep -q "^F[ \t]\+"
	then
		FILE=$(echo $LINE | awk '{$1="";print substr($0,2,length($0))}')
		if [ ! -e $FILE ]
		then
			echo "$FILE does not exist, aborting"
			exit 0
		elif [ ! -w $FILE ]
		then
			echo "$FILE is not writable, aborting"
			exit 0
		fi
	fi
	if echo $LINE | grep -q "^C[ \t]\+"
	then
		INDEX=$(echo $COLORNAMES | grep -n $(echo $LINE | awk '{$1="";print $0}') | cut -d":" -f1)
		COLOR=$(echo $COLORVALUES | sed -n ${INDEX}p)
		if [ -z $INDEX ] || [ -z $COLOR ]
		then
			echo "ERROR: Color $(echo $LINE | awk '{$1="";print substr($0,2,length($0))}') not defined, aborting"
			exit 0
		fi
	fi
	if echo $LINE | grep -q "^P[ \t]\+"
	then
		TOTAL=$(expr $TOTAL + 1)
		PATTERN=$(echo $LINE | awk '{$1="";print substr($0,2,length($0))}')
		sed -n "s/$PATTERN/\\1$COLOR\\3/gp" $FILE 1>/dev/null
		RESULT=$?
		if [ $RESULT -ne 0 ]
		then
			echo "Error: sed returned error code $RESULT"
			echo "This is probably due to a misformed pattern"
			echo "COLOR: $COLOR"
			echo "FILE: $FILE"
			echo "PATTERN: $PATTERN"
			echo "Aborting."
			exit 0
		elif [ $(sed -n "s/$PATTERN/\\1$COLOR\\3/gp" $FILE | wc -l) -ne 1 ]
		then
			echo "Error: found $(sed -n "s/$PATTERN/\\1$COLOR\\3/gp" $FILE | wc -l) matches with"
			echo "COLOR: $COLOR"
			echo "FILE: $FILE"
			echo "PATTERN: $PATTERN"
			echo "Aborting."
			exit 0
		fi
	fi
done < $COLORFILE

echo "All $TOTAL pattern(s) look okay."

if [ "$SIMULATE" = "TRUE" ]
then
	echo "Simulation only request detected, exiting"
	exit 0
fi


echo "Running actual replacements..."
echo ""

COLORNAMES=""
COLORVALUES=""
COUNT=0
while read LINE; do
	if echo $LINE | grep -q "^M[ \t]\+"
	then
		echo $LINE | awk '{$1="";print substr($0,2,length($0))}'
	fi
	if echo $LINE | grep -q "^R[ \t]\+"
	then
		echo "Request to run: $(echo $LINE | awk '{$1="";print substr($0,2,length($0))}')"
		COMMANDS="$COMMANDS\n$(echo $LINE | awk '{$1="";print substr($0,2,length($0))}')"
	fi
	if echo $LINE | grep -q "^D[ \t]\+"
	then
		COLORNAMES="$COLORNAMES\n$(echo $LINE | awk '{print$2}')"
		COLORVALUES="$COLORVALUES\n$(echo $LINE | awk '{print$3}')"
	fi
	if echo $LINE | grep -q "^F[ \t]\+"
	then
		FILE=$(echo $LINE | awk '{$1="";print substr($0,2,length($0))}')
	fi
	if echo $LINE | grep -q "^C[ \t]\+"
	then
		INDEX=$(echo $COLORNAMES | grep -n $(echo $LINE | awk '{$1="";print $0}') | cut -d":" -f1)
		COLOR=$(echo $COLORVALUES | sed -n ${INDEX}p)
	fi
	if echo $LINE | grep -q "^P[ \t]\+"
	then
		PATTERN=$(echo $LINE | awk '{$1="";print substr($0,2,length($0))}')
		sed -i "s/$PATTERN/\\1$COLOR\\3/g" $FILE
		COUNT=$(expr $COUNT + 1)
		printf "$(expr $COUNT \* 100 / $TOTAL)%%\r"
	fi
done < $COLORFILE

if [ ! -z "$COMMANDS" ]
then
	for INDEX in $(seq 2 $(echo $COMMANDS | wc -l))
	do
		COMMAND=$(echo $COMMANDS | sed -n ${INDEX}p)
		echo "Run following command?"
		echo $COMMAND
		COMMAND="($COMMAND)"
		echo -n "(y/N): "
		read YN
		if [ "$YN" = "y" ] || [ "$YN" = "yes" ] || "$YN" = "Y" ]
		then
			echo "Running command..."
			eval $COMMAND
			echo "done."
		else
			echo "Skipping command"
		fi
	done
fi

echo ""
echo "done."
