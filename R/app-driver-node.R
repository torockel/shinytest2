node_id_css_selector <- function(
  self, private,
  input = missing_arg(),
  output = missing_arg(),
  selector = missing_arg()
) {
  ckm8_assert_app_driver(self, private)

  input_provided <- !rlang::is_missing(input)
  output_provided <- !rlang::is_missing(output)
  selector_provided <- !rlang::is_missing(selector)

  if (
    sum(input_provided, output_provided, selector_provided) != 1
  ) {
    abort("Must specify either `input`, `output`, or `selector`", app = self)
  }

  css_selector <-
    if (input_provided) {
      ckm8_assert_single_string(input)
      paste0("#", input, ".shiny-bound-input")
    } else if (output_provided) {
      ckm8_assert_single_string(output)
      paste0("#", output, ".shiny-bound-output")
    } else if (selector_provided) {
      ckm8_assert_single_string(selector)
      selector
    } else {
      abort("Should never get here") # internal
    }
  css_selector

}

app_find_node_id <- function(
  self, private,
  ...,
  input = missing_arg(),
  output = missing_arg(),
  selector = missing_arg()
) {
  ckm8_assert_app_driver(self, private)
  ellipsis::check_dots_empty()

  "!DEBUG finding a nodeID"

  css_selector <- node_id_css_selector(
    self, private,
    input = input,
    output = output,
    selector = selector
  )

  el_node_ids <- chromote_find_elements(self$get_chromote_session(), css_selector)

  if (length(el_node_ids) == 0) {
    abort(paste0(
      "Cannot find HTML element with selector ", css_selector
    ), app = self)

  } else if (length(el_node_ids) > 1) {
    warning(
      "Multiple HTML elements found with selector ", css_selector
    )
  }

  node_id <- el_node_ids[[1]]

  node_id
}


#' @importFrom rlang :=
app_click <- function(
  self, private,
  input = missing_arg(),
  output = missing_arg(),
  selector = missing_arg(),
  ...
) {
  ckm8_assert_app_driver(self, private)

  # Will validate that only a single input/output/selector was provided as a single string
  node_id <- app_find_node_id(self, private, input = input, output = output, selector = selector)

  if (!rlang::is_missing(input)) {
    # Will delay until outputs have been updated.
    self$set_inputs(!!input := "click", ...)

  } else {
    self$log_message(paste0(
      "Clicking HTML element with selector: ",
      node_id_css_selector(
        self, private,
        input = input,
        output = output,
        selector = selector
      )
    ))
    click_script <- "
      function() {
        this.click()
      }
    "

    chromote_call_js_on_node(self$get_chromote_session(), node_id, click_script)
  }


  invisible(self)
}

# # TODO-future; Not for this release. Comment for now.
# #' @description
# #' Sends the specified keys to specific HTML element. Shortcut for
# #' `find_widget()` plus `sendKeys()`.
# #' @param keys Keys to send to the widget or the app.
# # ' See [webdriver::key] for how to specific special keys.
# #' @return Self, invisibly.
# ShinyDriver2$set("public", "sendKeys", function(id, keys) {
#   "!DEBUG ShinyDriver2$sendKeys `id`"
#   private$find_widget(id)$sendKeys(keys)
#   invisible(self)
# })


app_list_component_names <- function(self, private) {
  "!DEBUG app_list_component_names()"
  ckm8_assert_app_driver(self, private)

  res <- chromote_eval(self$get_chromote_session(), "shinytest2.listComponents()")$result$value

  res$input <- sort_c(unlist(res$input))
  res$output <- sort_c(unlist(res$output))
  res
}

app_check_unique_widget_names <- function(self, private) {
  "!DEBUG app_check_unique_widget_names()"
  ckm8_assert_app_driver(self, private)

  names <- app_list_component_names(self, private)
  inputs <- names$input
  outputs <- names$output

  check <- function(what, ids) {
    if (any(duplicated(ids))) {
      dup <- paste(unique(ids[duplicated(ids)]), collapse = ", ")
      warning("Possible duplicate ", what, " widget ids: ", dup)
    }
  }

  if (any(inputs %in% outputs)) {
    dups <- unique(inputs[inputs %in% outputs])
    warning(
      "Widget ids both for input and output: ",
      paste(dups, collapse = ", ")
    )

    ## Otherwise the following checks report it, too
    inputs <- setdiff(inputs, dups)
    outputs <- setdiff(outputs, dups)
  }

  if (length(inputs) > 0) check("input", inputs)
  if (length(outputs) > 0) check("output", outputs)

  invisible(self)
}
