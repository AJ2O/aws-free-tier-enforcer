variable "profile" {
  default = "default"
}

variable "region" {
  default = "us-east-1"
}

variable "fft_prefix" {
  default = "FFT"
}

variable "fft_tags" {
  type = map
  default = {
    "Tool" = "FFT"
  }
}