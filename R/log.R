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

log_info <- function(..., .ts = Sys.time()) {
  log("info", ..., .ts = .ts)
}

log_status <- function(..., .ts = Sys.time()) {
  log("status", ..., .ts = .ts)
}

log_warn <- function(..., .ts = Sys.time()) {
  log("warn", ..., .ts = .ts)
}

log_system <- function(..., .ts = Sys.time()) {
  log("system", ..., .ts = .ts)
}

log_plain <- function(...) {
  cat(..., "\n", file = stdout())
}
