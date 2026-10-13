# Create from a GitHub template

Replace the template owner and repository in [repositories.json](repositories.json)
with an accessible GitHub template repository. Follow the [parent instructions](../README.md).
The template must contain the `main` branch configured here; adjust the branch
setting to match your template. The apply credential needs access to the source.

GitHub template creation selects a repository, not an immutable source commit.
Record the template and initial generated commit as provenance. Inspect its code,
workflows and checks before introducing secrets or later protection settings.
