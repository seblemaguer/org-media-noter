**WARNING - The package is in preliminary stage of development**

# org-media-noter

This package provides another layer to [org-media-note](https://github.com/yuchen-lea/org-media-note) to get [org-roam](https://github.com/org-roam/org-roam) friendly notes in the manner of [org-noter](https://github.com/weirdNox/org-noter)


## Installation

```elisp
(use-package org-media-noter
   :straight (org-media-noter :type git :host github :repo "seblemaguer/org-media-noter")
   :commands (org-media-noter))
```

## Usage

This package provides 3 commands:
  - `org-media-noter` which is the equivalent of `org-noter`. It opens a new file or the file pointed by the media property
  - `org-media-noter-insert-note` to insert a note associated to a dedicated timestamp
  - `org-media-noter-seek` go to the timestemp pointed by the property
