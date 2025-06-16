log <- function(prefix, ..., .ts = Sys.time()) {
  cat(
    sprintf("> %s [%s]", format(.ts, "%Y-%m-%d %H:%M:%S"), toupper(prefix)),
    sprintf(...),
    "\n",
    file = stdout()
  )
}

loge <- function(prefix, ..., .ts = Sys.time()) {
  cat(
    sprintf("> %s [%s]", format(.ts, "%Y-%m-%d %H:%M:%S"), toupper(prefix)),
    sprintf(...),
    "\n",
    file = stderr()
  )
}
