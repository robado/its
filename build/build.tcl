proc type s {
    sleep .2
    foreach c [split $s ""] {
        send $c
        expect -re .
    }
}

proc respond { w r } {
    expect $w
    type $r
}

proc pdset {} {
    respond "YOU MAY HAVE TO :PDSET" "\032"
    respond "Fair" ":pdset\r"
    set t [timestamp]
    respond "PDSET" [expr [timestamp -seconds $t -format "%Y"] / 100]C
    type [timestamp -seconds $t -format "%y%m%dD"]
    type [timestamp -seconds $t -format "%H%M%ST"]
    type "!."
    expect "DAYLIGHT SAVINGS" {
        type "N"
	respond "IT IS NOW" "Q"
    } "IT IS NOW" {
        type "Q"
    }
    expect ":KILL"
}

proc shutdown {} {
    respond "*" ":lock\r"
    expect "_"
    send "5kill"
    respond "GO DOWN?\r\n" "y"
    respond "BRIEF MESSAGE" "\003"
    respond "NOW IN DDT" "\005"
}

spawn pdp10 build/simh/init

respond "sim>" "b tu1\r"
respond "MTBOOT" "mark\033g"
respond "Format pack on unit #" "0"
respond "Are you sure you want to format pack on drive" "y"
respond "Pack no?" "0\r"
respond "Verify pack?" "n"
respond "Alloc?" "3000\r"
respond "ID?" "foobar\r"
respond "DDT" "tran\033g"
respond "onto unit" "0"
respond "OK" "y"
expect "EOT"
respond "DDT" "\005"

respond "sim>" "b tu2\r"
respond "MTBOOT" "\033g"
respond "DSKDMP" "l\033ddt\r"
expect "\n"; type "t\033its rp06\r"
expect "\n"; type "\033u"
respond "DSKDMP" "m\033salv rp06\r"
expect "\n"; type "d\033its\r"
expect "\n"; type "its\r"
expect "\n"; type "\033g"
pdset
respond "*" ":ksfedr\r"
respond "File not found" "create\r"
expect -re {Directory address: ([0-7]*)\r\n}
set dir $expect_out(1,string)
type "write\r"
respond "Are you sure" "yes\r"
respond "Which file" "bt\r"
respond "Input from" ".;bt rp06\r"
respond "!" "quit\r"
expect ":KILL"
shutdown

respond "sim>" "b tu1\r"
respond "MTBOOT" "feset\033g"
respond "on unit #" "0"
respond "address: " "$dir\r"
respond "DDT" \005
respond "sim>" "quit"

spawn pdp10 build/simh/boot
respond "DSKDMP" "its\r"
type "\033g"
pdset
respond "*" ":print sysbin;..new. (udir)\r"
respond "*" ":midas sysbin;_midas;midas\r"
expect ":KILL"
respond "*" ":job midas\r"
respond "*" ":load sysbin;midas bin\r"
respond "*" "purify\033g"
respond "CR to dump" "\r"
respond "*" ":kill\r"

respond "*" ":midas sysbin;_sysen1;ddt\r"
expect ":KILL"
respond "*" ":job ddt\r"
respond "*" ":load sysbin;ddt bin\r"
respond "*" "purify\033g"
respond "*" ":pdump sys;atsign ddt\r"
respond "*" ":kill\r"

respond "*" ":midas system;_its\r"
respond "MACHINE NAME =" "AI\r"
expect ":KILL"

respond "*" ":midas sysbin;_syseng;dump\r"
respond "WHICH MACHINE?" "DB\r"
expect ":KILL"
respond "*" ":link sys3;ts dump,sysbin;dump bin\r"

respond "*" "\005"
respond "sim>" "at tu0 out/output.tape\r"
respond "sim>" "c\r"
type ":dump\r"
respond "_" "dump full\r"
respond "TAPE NO=" "0\r"
expect "REEL"
respond "_" "quit\r"

shutdown
respond "sim>" "quit"