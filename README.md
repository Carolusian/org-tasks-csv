# Export Task Entries from org-mode to CSV

`org-tasks-csv` is a package for you to export your org-mode todo/done tasks into csv. It is inspired by the package [`org-clock-csv`](https://github.com/atheriel/org-clock-csv) from Aaron Jacobs.

## Installation

### Using `use-package`

```
(use-package org-tasks-csv
  :straight (:host github :repo "carolusian/org-tasks-csv"))
  ...)
```

### Using Doom Emacs

Add the following in your `packages.el` to install the package from github

```
(package! org-tasks-csv
  :recipe (:host github
           :branch "main"
           :repo "carolusian/org-tasks-csv"))
```

### Without a package manager

To install the package without using a package manager you have the option below:

- Ensure you have installed `org-clock-csv` which is a dependency by `org-tasks-csv`
- Clone `org-tasks-csv` with git from this source code repository;
- Setup proper `load-path` to the package: `(add-to-list 'load-path "/path/to/org-tasks-csv")`

After the steps, you will be able to resolve `(require 'org-tasks-csv)` call.

## Configuration

```
(use-package! org-tasks-csv
   :after org)
```

## Usage in Interactive mode

### `org-tasks-csv`

It will open a buffer in CSV format, with parsed entries from the files in `org-agenda-files`

### `org-tasks-csv-to-file`

It will write the `org-tasks-csv` output to a file.
