# dbutil

I've been collecting utility functions for a while and I need a good central place to store them. 

This repository is meant to have either no depedencies or to gracefully handle importing and disposing of depencies. When possible functions should be entirely self-contained; they should not depend on other functions in this project or inter-dependecies should be kept shallow and as self-explanatory as possible.

When possible, functions should be platform-agnostic. This should not be done at the expensive of readability. If it is cleared to have several platform-specific functions and wrap them, then this is preferred.
