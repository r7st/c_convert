# INITIALIZE
BEGIN{ 
  INFUNC="OFF"
  INARGS="FALSE"
  FUNC="NULL"
  I=1
  INCOMM="FALSE"
  PARGC=1
  LINEC=1
}


### BGN FUNCTION DEFS ###

function get_type(Arg){
    match(Arg,/^(struct )?.* +/)
    Type=substr(Arg,RSTART,RLENGTH)
    return Type
}
function multi_var(Type, Vars){
  split(Vars,SplitVars,",")             # split by comma
  for (j=1;j<=length(SplitVars);j++){   # parse vars of Type
    sub(/;/,"",SplitVars[j])            # strip semicolon off last arg
    PARGS[PARGC++]=Type" "SplitVars[j]  # append to parsed args
  }
}
function parse_args(){
  for (i=1;i<=length(ARGS);i++){
    sub(/[\t ]+$/, "", ARGS[i]) # strip line trailing spaces
    Type = get_type(ARGS[i])    # get type
    sub(/[\t ]+$/,"",Type)      # strip type trailing spaces
    sub(/^(struct )?.* +/,"",ARGS[i])   # strip type from ARG
    if (match(ARGS[i],/^[^,]+,/) > 0){  # check for multiple vars of type
      multi_var(Type, ARGS[i])
    }
    else{ # single argument (not comma separated)
      sub(/;/,"",ARGS[i])            # strip semicolon
      PARGS[PARGC++]=Type" "ARGS[i]  # append to parsed args
    }
  }
}
function form_function(){
  match(FUNC,/^.*\(/)
  Body=substr(FUNC,RSTART,RLENGTH)
  Fields=PARGS[1]   
  if (PARGC > 1){
    i=2
    while(i<PARGC){
      Fields=Fields", "PARGS[i]
      i++
    }
  }
  else{
    LINES[LINEC++]=$0
    return
  }
  NewFunction=Body Fields"){"
  sub(/[\t ]+/," ",NewFunction)
  LINES[LINEC++]=NewFunction
}

function display_function(){
  # print functions with args / args in old style format
  if (length(ARGS) > 0){
    parse_args()     # split out function arguments
    form_function()  # build function in ansi format
    delete PARGS     # flush parsed args
    PARGC=1          # reset parsed arg counter
    return
  }
}

### END FUNCTION DEFS ###


### BGN PARSING FILE ###

# found ansi function block
/^[a-z_]+ +.*\( *([^,]+ +[^,]+(, +[^,]+)?){1,} *\).*/ && !/;/{
  INFUNC="OFF"
  INARGS="FALSE"
  LINES[LINEC++]=$0
  next
}

/^[a-z_]+ +.*\( *(void)? *\).*/ && !/;/{
  INFUNC="OFF"
  INARGS="FALSE"
  LINES[LINEC++]=$0
  next
}

# found k&r function block
/^[a-z_]+ +.*\(.+\).*/ && !/;/{ INFUNC="ON"; INARGS="TRUE" }
(INFUNC=="ON" && INARGS=="TRUE"){
  gsub(/[\t ]+/," ")
  FUNC=$0         # capture function def
  INARGS="FALSE"  # specify not args
  next
}

# skip short comments
(INARGS == TRUE) && /^#/{ next }

# skip long comments
(INARGS == TRUE) && /\/\*/{ INCOMM="TRUE" }
(INARGS == TRUE) && /\*\//{ INCOMM="FALSE"; next }
(INARGS == TRUE) && (INCOMM == "TRUE"){ next }

# handle captured function
/^{/ && INFUNC=="ON"{
  display_function()
  INFUNC="OFF" # reset func
  delete ARGS  # clean up args
  I=1          # reset args inc
  next
}

# found function args
(INFUNC=="ON"){
  gsub(/[\t ]+/," ")
  ARGS[I++]=$0
}

(INFUNC == "OFF" && INARGS == "FALSE"){ LINES[LINEC++]=$0 }
### END PARSING FILE ###

# print transofmred file
END{
  for (i=0;i<length(LINES);i++)
  print LINES[i]
}
