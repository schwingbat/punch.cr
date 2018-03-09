# Punch.cr

This is the experimental [Crystal](https://crystal-lang.org) version of my command line time tracker, Punch, which is originally written in JavaScript and running on Node.js. You can check that out [here](https://github.com/schwingbat/punch). I'll update this README when things come together enough for this version to be usable. Both versions are compatible, so they can be used side by side, but this faster native version is intended to eventually replace the JS version. Node has noticeable startup latency which comes into play every time the `punch` command is run, and it requires the runtime to be installed by the user beforehand. This version will be lightning fast and have no external dependencies whatsoever. Just download the binary and run it.

## To Do

- Have commands print out descriptions for all their arguments in the help text when mapping fails
- Show argument descriptions in general help
- Implement everything