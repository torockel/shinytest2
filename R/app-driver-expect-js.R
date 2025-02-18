js_script_helper <- function(script = missing_arg(), file = missing_arg()) {
  if (rlang::is_missing(file)) return(script)

  if (!rlang::is_missing(script)) {
    warning("Both `file` and `script` are specified. `script` will be ignored.")
  }
  read_utf8(file)
}

app_execute_js <- function(
  self, private,
  script,
  ...,
  arguments = list(),
  file = missing_arg(),
  timeout = 15 * 1000
) {
  ckm8_assert_app_driver(self, private)
  ellipsis::check_dots_empty()

  "!DEBUG app_execute_js()"
  chromote_execute_script(
    self$get_chromote_session(),
    js_script_helper(script, file),
    arguments = arguments,
    timeout = timeout
  )$result$value
}


app_expect_js <- function(
  self, private,
  script,
  ...,
  arguments = list(),
  file = missing_arg(),
  timeout = 15 * 1000,
  pre_snapshot = NULL,
  cran = FALSE
) {
  ckm8_assert_app_driver(self, private)
  ellipsis::check_dots_empty()
  arguments <- as.list(arguments)

  result <- self$execute_js(
    script = script,
    arguments = arguments,
    file = file,
    timeout = timeout
  )

  if (is.function(pre_snapshot)) {
    checkmate::assert_integer(length(formals(pre_snapshot)), lower = 1)
    result <- pre_snapshot(result)
  }

  # Must use _value_ output as _print_ output is unstable
  # over different R versions and locales
  app__expect_snapshot_value(
    self, private,
    result,
    cran = cran
  )
}


get_text_js <- function() {
  paste0(
    "const selector = arguments[0];\n",
    "let arr = Array.from(document.querySelectorAll(selector));\n",
    "return arr.map((item, i) => item.textContent);"
  )
}
app_get_text <- function(
  self, private,
  selector
) {
  ckm8_assert_app_driver(self, private)
  # ellipsis::check_dots_empty()

  ret <- self$execute_js(
    script = get_text_js(),
    arguments = list(selector)
  )
  unlist(ret)
}
app_expect_text <- function(
  self, private,
  selector,
  ...,
  cran = FALSE
) {
  ckm8_assert_app_driver(self, private)
  ellipsis::check_dots_empty()

  self$expect_js(
    script = get_text_js(),
    arguments = list(selector),
    pre_snapshot = unlist,
    cran = cran
  )

  invisible(self)
}


get_html_js <- function() {
  paste0(
    "let selector = arguments[0];\n",
    "let outer_html = arguments[1];\n",
    "let map_fn = outer_html ? (item, i) => item.outerHTML : (item, i) => item.innerHTML;\n",
    "let arr = Array.from(document.querySelectorAll(selector));\n",
    "return arr.map(map_fn);")
}
app_get_html <- function(
  self, private,
  selector,
  ...,
  outer_html = FALSE
) {
  ckm8_assert_app_driver(self, private)
  ellipsis::check_dots_empty()

  ret <- self$execute_js(
    script = get_html_js(),
    arguments = list(selector, isTRUE(outer_html))
  )
  unlist(ret)
}
app_expect_html <- function(
  self, private,
  selector,
  ...,
  outer_html = FALSE,
  cran = FALSE
) {
  ckm8_assert_app_driver(self, private)
  ellipsis::check_dots_empty()

  self$expect_js(
    script = get_html_js(),
    arguments = list(selector, isTRUE(outer_html)),
    pre_snapshot = unlist,
    cran = cran
  )

  invisible(self)
}
