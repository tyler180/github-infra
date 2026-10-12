provider "context" {
  delimiter       = "-"
  enabled         = true
  tags_key_case   = "title"
  tags_value_case = "none"

  properties = {
    namespace = {
      required        = false
      include_in_tags = true
      tags_value_case = "lower"
    }
    environment = {
      required        = false
      include_in_tags = true
      tags_value_case = "lower"
    }
    stage = {
      required        = false
      include_in_tags = true
      tags_value_case = "lower"
    }
    name = {
      required        = true
      include_in_tags = true
      tags_value_case = "lower"
    }
  }

  values = {
    name = basename(dirname(path.cwd))
    # name = abspath("${path.module}/..")
  }
}

data "context_tags" "this" {}

data "context_label" "this" {
  template = data.context_tags.this.tags["Name"]
}

data "context_config" "this" {}