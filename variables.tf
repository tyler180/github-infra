variable "github_owner" {
  type        = string
  description = "GitHub account or organization that owns the repositories"
  default     = "tyler180"
}

variable "inventory_file" {
  description = "Repository inventory; stage values are intent, not proof of live verification."
  type        = string
  default     = "repositories.json"
}
