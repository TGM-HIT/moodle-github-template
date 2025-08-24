# specify MOODLE_TOKEN in there
set dotenv-load := true

export MOODLE_BASE_URL := 'http://localhost:8000/'
export TYPST_ROOT := justfile_directory()


[private]
default:
  @just --list --unsorted

# uses uv to install the `mdl` (Moodle CLI) tool
[group('setup')]
install-mdl:
	uv tool install git+https://github.com/TGM-HIT/moodle-cli@v0.2

# unistalls the Moodle CLI installed via uv
[group('setup')]
uninstall-mdl:
	uv tool uninstall mdl

# calls the Moodle CLI to upload one or more input files
[group('upload')]
upload *ARGS:
	@if test "${MOODLE_TOKEN+ok}" != 'ok'; then \
		echo 'MOODLE_TOKEN not set: make sure you have a .env file containing `MOODLE_TOKEN=...`'; \
		exit 1; \
	fi
	@uv run mdl upload {{ARGS}}

# calls the Moodle CLI to upload the main `course.yaml` and all included files
[group('upload')]
upload-course: (upload "course.yaml")

# compiles a specified Typst document to HTML and PDF
[group('typst')]
compile DOC: (compile-html DOC) (compile-pdf DOC)

# compiles a specified Typst document to HTML
[group('typst')]
compile-html DOC:
	typst compile --features html --format html "{{DOC}}"

# compiles a specified Typst document to PDF
[group('typst')]
compile-pdf DOC:
	typst compile "{{DOC}}"

# prints the frontmatter of a specified Typst document
[group('typst')]
frontmatter DOC:
	typst query "{{DOC}}" '<frontmatter>' --field value --one

# prints the attachments of a specified Typst document
[group('typst')]
attachments DOC:
	typst query "{{DOC}}" '<attachments>' --field value
