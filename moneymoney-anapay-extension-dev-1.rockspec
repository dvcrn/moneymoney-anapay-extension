package = "moneymoney-anapay-extension"
version = "dev-1"
source = {
   url = "github.com/dvcrn/moneymoney-anapay-extension"
}
description = {
   homepage = "*** please enter a project homepage ***",
   license = "*** please specify a license ***"
}
dependencies = {
   "dkjson",
   "http",
   "amalg",
}
build = {
   type = "builtin",
   modules = {
      main = "main.lua"
   }
}
