#!/bin/bash

init() {
	tput clear
	tput civis

	stty -echo -icanon time 0 min 0

	screenWidth=$(tput cols)
	screenHeight=$(tput lines)
	
	paddleSize=15
	paddleX=$(($screenWidth/2 + $paddleSize/2))
	paddleY=$((screenHeight - 1)) 
	paddleSpeed=5

	draw_top
	
	init_ball

	lives=3

	score=0

	update_score
}

draw_top() {
	tput cup 2 0
	for ((i=0; i<$screenWidth; i++)) {
		echo -n "-"
	}
}

init_ball() {
	ballX=$((screenWidth/2))
	ballY=$((screenHeight/2))

	ballXDir=1
	ballYDir=1
}

clean_up_and_exit() {
	tput clear
	tput cnorm
	exit
}

move_left() {
	if [ $(($paddleX - $paddleSpeed)) -ge 0 ]; then 
		erase_paddle
		paddleX=$(($paddleX - $paddleSpeed))
		draw_paddle	
	else
		erase_paddle
		paddleX=0
		draw_paddle	
	fi
}

move_right() {
	if [ $(($paddleX + $paddleSize + $paddleSpeed)) -lt $(($screenWidth - 1)) ]; then
		erase_paddle
		paddleX=$(($paddleX + $paddleSpeed))
		draw_paddle
	else
		erase_paddle
		paddleX=$(($screenWidth - $paddleSize))
		draw_paddle
	fi
}

draw_paddle() {
	tput cup $paddleY $paddleX

	for ((i=0; i<$paddleSize; i++)) {
		echo -n "="
	}
}

erase_paddle() {
	tput cup $paddleY $paddleX

	for ((i=0; i<$paddleSize; i++)) {
		echo -n " "
	}
}

erase_ball() {
	tput cup $2 $1
	echo -n " "
}

draw_ball() {
	tput cup $2 $1
	echo -n "o"	
}

die() {
	lives=$(($lives - 1))
	[ $lives -gt 0 ] && update_lives || clean_up_and_exit
}

update_lives() {
	tput cup 1 $(($screenWidth-14))
	echo -n "lives: "

	for ((i=0; i<3; i++)) {
		[ $i -lt $lives ] &&
		echo -n "$(tput setaf 5)♥ $(tput setaf 9)" ||
		echo -n "  "
	}
}

update_score() {
	tput cup 1 1
	echo -n "score: $score"
}

update_ball() {
	erase_ball $ballX $ballY
	ballX=$(($ballX + $ballXDir))
	ballY=$(($ballY + $ballYDir))

	[ $ballX -eq 0 ] && ballXDir=$((-$ballXDir))
	[ $ballX -eq $(($screenWidth-1)) ] && ballXDir=$((-$ballXDir))

	[ $ballY -eq 3 ] && ballYDir=$((-$ballYDir))

	if [ $ballY -eq $(($paddleY-1)) ]; then

		[ $paddleX -le $ballX ] && 
		[ $(($paddleX + $paddleSize)) -ge $ballX ] &&
			ballYDir=$((-$ballYDir)) &&
			score=$(($score + 1)) &&
			update_score

	fi

	[ $ballY -eq $screenHeight ] && die && sleep 1 && init_ball 

	draw_ball $ballX $ballY
}

trap clean_up_and_exit EXIT TERM INT

init
update_lives
draw_ball $ballX $ballY
draw_paddle
iter=0

while true; do
	key=$(dd bs=3 count=1 2>/dev/null)

	case "$key" in
		$'\x1b[C')
			move_right
		;;
		$'\x1b[D')
			move_left
		;;
		q)
			clean_up_and_exit
		;;
	esac
	
	iter=$((iter+1))
	if [[ $iter -eq 10 ]]; then
		update_ball
		iter=0
	fi
done
