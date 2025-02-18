
Count <- R6Class( # nolint
  "Count",
  private = list(
    count = 0
  ),
  public = list(
    increment = function() {
      private$count <- private$count + 1
      private$count
    },
    get = function() {
      private$count
    }
  )
)

app_next_temp_snapshot_path <- function(
  self, private,
  name, # full path or filename
  ext = "json"
) {
  ckm8_assert_app_driver(self, private)

  fs::path(
    private$save_dir,
    # set the file extension
    fs::path_ext_set(
      # take file name only
      fs::path_file(
        name %||% sprintf("%03d", private$counter$increment())
      ),
      ext
    )
  )
}


Url <- R6Class( # nolint
  "Url",
  private = list(
    url = NULL
  ),
  public = list(
    get = function() {
      private$url
    },
    set = function(url) {
      res <- parse_url(url)

      if (nzchar(res$port)) {
        res$port <- as.integer(res$port)
        ckm8_assert_single_integer(res$port, .var.name = "port")
      } else {
        res$port <- NULL
      }

      res$path <- if (nzchar(res$path)) res$path else "/"

      ckm8_assert_single_string(res$host)
      ckm8_assert_single_url(res$path)

      private$url <- paste0( # nolint
        res$protocol, "://", res$host,
        if (!is.null(res$port)) paste0(":", res$port),
        res$path
      )

      invisible(self)
    }
  )
)
