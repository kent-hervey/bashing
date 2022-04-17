function fun1(){
  return 34
}

function fun2(){
  fun1
  local res=$?
  echo $res
}

fun2
