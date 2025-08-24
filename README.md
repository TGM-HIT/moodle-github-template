# Moodle Github Template

This is a template repository for connecting Moodle with Github to update (certain parts of) Moodle activities via Github actions.

## Overview

Once [configured correctly](#prerequisites), you can record Moodle activities in `course.yaml` and have them uploaded to Moodle automatically.

### Basic example

This repository has some example content, but here's an even more basic example.

Let's say you have an assignment with URL http://localhost:8000/mod/assign/view.php?id=2.
To automatically populate the assignment's description from Github, e.g. from a Markdown file, you would

- Create the Markdown file, e.g. `assignment.md`:
  ```md
  *Hello!* This is the assignment.
  ```
- Add that Markdown file to `course.yaml`:
  ```yaml
  children:
  - assignment.md
  ```
- Add _frontmatter_ to the Markdown file to specify where the content should be uploaded to:
  ```md
  ---
  # this part is the frontmatter
  mod: assign   # what kind of activity this file is uploaded to
  course: 2     # optional; checks that the activity belongs to this course before uploading
                # this can be useful to prevent (some) copy/paste errors
  cmid: 2       # the "course module id"; you get this from the URL: `view.php?id=<cmid>`
  intro:        # the description for the activity: get it from the file itself
    source: assignment.md
  ---
  *Hello!* This is the assignment.
  ```
  Apart from Markdown, content can be written in HTML, plain text and [Typst](https://typst.app/) (compiled to HTML).
  More information on the frontmatter and file formats, can be found in the [Moodle CLI readme](https://github.com/TGM-HIT/moodle-cli?tab=readme-ov-file#module-configuration-files).

When you commit these changes to your repository and push, a Github Actions workflow will do the following:

- It lists all changed files in the repo: `assignment.md`, `course.yaml`
- It lists all files that, according to `course.yaml`, contain content for our Moodle course: `assignment.md`
- It updates all activities that depend on changed files: http://localhost:8000/mod/assign/view.php?id=2.
  Unchaged activities will not be re-uploaded!

### Using attachments

The content automatically uploaded to Moodle basically replaces what one would otherwise put into the Atto or TinyMCE rich text editors in the Moodle web interface.
These also let us add e.g. images to a text description, which is also supported here.
You could change your `assignment.md` as follows:

```md
---
mod: assign
course: 2
cmid: 2
intro:
  source: assignment.md
  attachments:
    - image.png
---
*Hello!* This is the assignment.

![an image](@@PLUGINFILE@@/image.png)
```

The image is listed as an attachment in the frontmatter.
In content, references to attachments need to be specified as `@@PLUGINFILE@@/<filename>`.
Here, `@@PLUGINFILE@@` is a prefix that Moodle normally inserts when post-processing form input—but since we're not filling out a form, we have to do this ourselves.

To go through the Github Actions workflow again:

- List all changed files in the repo: `assignment.md`, `image.png`
- List all files that contain Moodle content: `assignment.md`, `image.png`
- Update only activities that depend on changed files: http://localhost:8000/mod/assign/view.php?id=2.

### Limitations

This template is limited by the capabilities of the underlying [Typst CLI](https://github.com/TGM-HIT/moodle-cli) and [local_modcontentservice plugin](https://github.com/TGM-HIT/moodle-local_modcontentservice).
Most importantly:

- Only the plugin types
  [`mod_assign`](https://docs.moodle.org/500/en/Assignment_activity),
  [`mod_folder`](https://docs.moodle.org/500/en/Folder_resource),
  [`mod_label`](https://docs.moodle.org/500/en/Text_and_media_area),
  [`mod_page`](https://docs.moodle.org/500/en/Page_resource),
  [`mod_resource`](https://docs.moodle.org/500/en/File_resource),
  as well as course sections are supported.
- Within these, only content (descriptions, activity instructions, section summaries, etc.) as well as files (folder contents, etc.) can be modified.
  In particular, activity _names_ can not be modified; and neither things like deadlines, grading keys, ...

  This was mainly a pragmatic decision to keep the initial development scope small and focused on what we wanted to use at our school.

Apart from that, the Github Actions workflow can't handle force pushes because it breaks the change detection.
If you insist on using force pushes on the main branch, you have basically two options:
- first, force push one commit further back than ordinarily necessary, then do a regular push over that. For example, if your main branch consisted of `a->b1` and you want to force push `a->b2`, first force push `a`, then regularly push `a->b2`. All changes between `a` and `b2` will be detected; be aware that this may mean some changes between `b1` and `b2` remain undetected!
- go to `https://github.com/<username>/<repo>/actions/workflows/moodle.yml` and use the "Run workflow" dropdown to manually trigger the workflow. This will skip change detection and re-upload all resources in your `course.yaml` file.

## Prerequisites

To use the scripts and workflows in this repo, your Moodle installation needs the [local_modcontentservice](https://github.com/TGM-HIT/moodle-local_modcontentservice) plugin installed and configured.
That means:

- The plugin needs to be installed, i.e. a [release](https://github.com/TGM-HIT/moodle-local_modcontentservice/releases) of the plugin extracted to the `local/` directory of your Moodle installation.
  If done correctly, an admin logging in to Moodle should be prompted to upgrade the installation, which will register the webservice.
- The "Mod Content Service" webservice needs to be enabled.
  This can be done by an admin at the `/admin/settings.php?section=externalservices` URL.
- You as a user need to have the `webservice/rest:use` capability to use the plugin, and the `moodle/webservice:createtoken` capability to create a token by yourself to authenticate with the service.
  Your admin can use `/admin/tool/capability/index.php` to check which roles have these capabilities, assign them to an existing/new role, and give you the required role.

If your admin has done the above steps, you should then be able to do the following yourself:

- Create a webservice token at `/user/managetoken.php` for the "Mod Content Service". Keep this token secret, as if it was your Moodle password!
- To modify Moodle courses through Github Actions:
  - In your repository, add that token as a secret: go to `https://github.com/<username>/<repo>/settings/secrets/actions`, create a repository secret `MOODLE_TOKEN` and use the token as the value.
  - In the file `.github/workflows/moodle.yml`, find the line `MOODLE_BASE_URL: http://localhost:8000/` and replace the URL with that of your Moodle server.
- To modify Moodle courses through running scripts locally, a [Justfile](https://just.systems/man/en/) is provided (note: the commands are tested under Linux):
  - You need to install the [Moodle CLI](https://github.com/TGM-HIT/moodle-cli?tab=readme-ov-file#installation) tool—either manually or, if you have [`uv`](https://docs.astral.sh/uv/) installed already, through `just install-mdl`.
  - Create a `.env` file and add `MOODLE_TOKEN=<your-token-here>` to it. That file is in `.gitignore` and should not be committed to your repo!
  - In the `justfile`, find the line `export MOODLE_BASE_URL := 'http://localhost:8000/'` and replace the URL with that of your Moodle server.
  - Alternatively, run the lines in that script without `just`, according to the [Moodle CLI readme](https://github.com/TGM-HIT/moodle-cli?tab=readme-ov-file#example-usage).

Once these are done, you should be able to modify (the currently supported aspects of) your moodle courses through Github Actions or local scripts.
