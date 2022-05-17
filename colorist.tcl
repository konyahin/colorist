#!/usr/bin/env tclsh

proc array'reverse {oldName newName} {
    upvar 1 $oldName old $newName new
    foreach {key value} [array get old] {set new($value) $key}
}

# Xresources
array set from_xresources {
    *.foreground: foreground
    *.background: background
    *.cursorColor: cursor
    *.color0: black
    *.color8: black_bright
    *.color1: red
    *.color9: red_bright
    *.color2: green
    *.color10: green_bright
    *.color3: yellow
    *.color11: yellow_bright
    *.color4: blue
    *.color12: blue_bright
    *.color5: magenta
    *.color13: magenta_bright
    *.color6: cyan
    *.color14: cyan_bright
    *.color7: white
    *.color15: white_bright
}
array'reverse from_xresources to_xresources

proc parse_xresources {filename} {
    global from_xresources
    set file [open $filename r]
    set file_data [read $file]
    close $file
    set lines [split $file_data "\n"]

    array set colors {}
    foreach line $lines {
        set line [string trim $line]
        if { $line eq {} || [string first "!" $line] >= 0 } {
            continue
        }
        set name [lindex $line 0]
        set value [lindex $line 1]
        if {[info exist from_xresources($name)]} {
            set key $from_xresources($name)
            set colors($key) $value
        }
    }
    return [array get colors]
}

proc produce_xresources {_colors} {
    global to_xresources
    upvar $_colors colors
    foreach color [array names colors] {
        if {[info exist to_xresources($color)]} {
            set key $to_xresources($color)
            set value $colors($color)
            puts "! $color"
            puts "$key\t$value"
        }
    }
}

# Simple Terminal (suckless)
set st_colors [list white red green yellow blue magenta cyan black \
    white_bright red_bright green_bright yellow_bright blue_bright \
    magenta_bright cyan_bright black_bright]
set st_more_colors [list cursor background foreground background]

proc process_st_colors {keys _colors} {
    upvar $_colors colors
    foreach key $keys {
        if {[info exist colors($key)]} {
            set value $colors($key)
            puts "\t\"$value\", // $key"
        } else {
            puts stderr "Missed color $key"
            exit 1
        }
    }
}

proc produce_st {_colors} {
    global st_colors st_more_colors
    upvar $_colors colors
    puts "static const char *colorname\[\] = \{"
    process_st_colors $st_colors colors
    puts "\t\[255\] = 0,"
    process_st_colors $st_more_colors colors
    puts "\};"
}

# DWM
array set dwm_colors {
    active_font background 
    inactive_font foreground \
    active_bg foreground 
    inactive_bg background
}
proc produce_dwm {_colors} {
    global dwm_colors
    upvar $_colors colors
    foreach key [array names dwm_colors] {
        set color $dwm_colors($key)
        set value $colors($color)
        puts "static const char $key\[\] = \"$value\";"
    }
}

# dmenu
set dmenu_colors [list SchemeNorm background foreground \
    SchemeSel foreground background \
    SchemeOut red cyan]
proc produce_dmenu {_colors} {
    global dmenu_colors
    upvar $_colors colors
    puts "static const char *colors\[SchemeLast\]\[2\] = \{"
    foreach {name fg bg} $dmenu_colors {
        set fg_color $colors($fg)
        set bg_color $colors($bg)
        puts "\t\[$name\] = \{ \"$fg_color\", \"$bg_color\" \},"
    }
    puts "\};"
}

# Xinit
proc produce_xinit {_colors} {
    upvar $_colors colors
    set color $colors(blue)
    puts "xsetroot -solid \"$color\" &"
    puts "exec dwm"
}

proc produce {file_format _colors} {
    upvar $_colors colors
    switch $file_format {
        xres {
            produce_xresources colors
        }
        st {
            produce_st colors
        }
        dwm {
            produce_dwm colors
        }
        dmenu {
            produce_dmenu colors
        }
        xinit {
            produce_xinit colors
        }
        default {
            puts stderr "Unknown format."
            exit 1
        }
    }
}

if {$argc < 3} {
    puts "Usage:"
    puts "\t$argv0 produce format color_scheme"
    puts "\t$argv0 parse format file"
    puts "\tformat: xres st dwm xinit"
    exit 1
}

switch [lindex $argv 0] {
    produce {
        set file_format [lindex $argv 1]
        set color_scheme [lindex $argv 2]
        set file [open $color_scheme r]
        set file_data [read $file]
        close $file
        array set colors [join $file_data]
        produce $file_format colors
    }
    parse {
        set file_format [lindex $argv 1]
        set filename [lindex $argv 2]
        if {$file_format ne "xres"} {
            puts stderr "Unsuported format for parsing $file_format. Use xres."
            exit 1
        }
        set scheme [parse_xresources $filename]
        foreach {key value} $scheme {
            puts "$key $value"
        }
    }
    default {
        puts stderr "unknown command"
        exit 1
    }
}
