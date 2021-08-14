variable "profile" {
  default = "default"
}

variable "region" {
  default = "us-east-1"
}

variable "fte_tags" {
  type = map(any)
  default = {
    "Tool" = "FTE"
    "FTE_Protection" = "true"
  }
}