# INITIALIZE
BEGIN{ 
  INFUNC="OFF"
  INARGS="TRUE"
  FUNC="NULL"
  I=1
  INCOMM="FALSE"
}


### BGN FUNCTION DEFS ###

function display_function(){
  # print functions with args / args in old style format
  if (length(ARGS) > 0){
    print "main func " FUNC
    for (i=1;i<=length(ARGS);i++){
      print "arg "i" "ARGS[i]
    }
  }
}
### END FUNCTION DEFS ###


### BGN PARSING FILE ###

# skip short comments
/^#/{ next }

# skip long comments
/\/\*/{ INCOMM="TRUE" }
/\*\//{ INCOMM="FALSE"; next }
(INCOMM == "TRUE"){ next }

# handle captured function
/^{/ && INFUNC=="ON"{ 
  display_function()
  INFUNC="OFF" # reset func
  delete ARGS  # clean up args
  I=1          # reset args inc
  next
}

# found function block
/^[a-z_]+ .*\(.+\).*/ && !/;/{ INFUNC="ON"; INARGS="TRUE" }
(INFUNC=="ON" && INARGS=="TRUE"){ 
  FUNC=$0         # capture function def
  INARGS="FALSE"  # specify not args
  next
}

# found function args
(INFUNC=="ON"){
  ARGS[I++]=$0
}

### END PARSING FILE ###
