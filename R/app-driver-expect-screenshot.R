default_screenshot_args <- function(screenshot_args) {
  if (is_missing_value(screenshot_args) || is.null(screenshot_args) || isTRUE(screenshot_args)) {
    screenshot_args <- list()
  }
  screenshot_args
}

app_screenshot <- function(
  self, private,
  file = NULL,
  ...,
  screenshot_args = missing_arg(),
  delay = missing_arg(),
  selector = missing_arg()
) {
  "!DEBUG app_screenshot()"
  ckm8_assert_app_driver(self, private)
  ellipsis::check_dots_empty()

  screenshot_args <- default_screenshot_args(
    maybe_missing_value(screenshot_args, private$default_screenshot_args)
  )
  if (is_false(screenshot_args)) {
    warning("`screenshot_args` can not be `FALSE` when calling `app$screenshot()`. Setting to `list()`")
    screenshot_args <- list()
  }
  checkmate::assert_list(screenshot_args)

  screenshot_args$delay <- maybe_missing_value(delay, screenshot_args$delay) %||% 0
  screenshot_args$selector <- maybe_missing_value(selector, screenshot_args$selector) %||% "html"

  checkmate::assert_number(screenshot_args$delay, lower = 0, finite = TRUE, null.ok = TRUE)

  if (is.null(file)) {
    self$log_message("Taking screenshot")
  } else {
    self$log_message(paste0("Taking screenshot: ", file))
  }
  path <- temp_file(".png")
  screenshot_args$filename <- path

  do.call(self$get_chromote_session()$screenshot, screenshot_args)

  # Fix up the PNG resolution header on windows
  if (is_windows()) {
    normalize_png_res_header(path)
  }

  if (is.null(file)) {
    withr::local_par(list(bg = "grey90"))
    png <- png::readPNG(path)
    graphics::plot(grDevices::as.raster(png))
  } else {
    fs::file_copy(path, file)
  }

  invisible(self)
}


app_expect_screenshot <- function(
  self, private,
  ...,
  name = NULL,
  screenshot_args = missing_arg(),
  delay = missing_arg(),
  selector = missing_arg(),
  cran = FALSE
) {
  "!DEBUG app_screenshot()"
  ckm8_assert_app_driver(self, private)
  ellipsis::check_dots_empty()

  filename <- app_next_temp_snapshot_path(self, private, name, "png")

  # Take screenshot
  self$screenshot(
    file = filename,
    screenshot_args = screenshot_args,
    delay = delay,
    selector = selector
  )

  # Assert screenshot value
  app__expect_snapshot_file(
    self, private,
    filename,
    cran = cran,
    compare = testthat::compare_file_binary
  )
}

app_expect_screenshot_and_variant <- function( # nolint
  self, private,
  ...
) {
  if (app_is_missing_variant(self, private)) {
    abort(c(
      "This `AppDriver` object can not call `$expect_screenshot()` without a `variant` initialized. Please supply a `variant` value when creating your `AppDriver` object, like `AppDriver(variant = <value>)`",
      i = "`variant = platform_variant()` is the suggested value",
      i = "`variant = NULL` can work, but screenshots are known to cause conflicts when changing R version or platform."
    ))
  }
  # Expect screenshot
  app_expect_screenshot(self, private, ...)
}
