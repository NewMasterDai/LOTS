# LOTS — Linux Opinionated Templates Script

A lightweight shell script that fetches and applies opinionated configuration
templates for Linux systems using `curl`.

## Templates

- a .pptx file
- a .docx file
- a .sh file
- a .xlsx file

## Requirements

- a GNU/Linux distribution

## Contributing Templates

New templates are welcome! If there's a configuration you'd like to see
included in LOTS, open an [issue](https://github.com/NewMasterDai/LOTS/issues)
or submit a pull request. The goal is to build a complete feature set
of opinionated default Templates that cover the most common post-install needs.

## For Distro Developers

If you maintain a Linux distribution and want to ship sensible,
opinionated Templates defaults out of the box, LOTS is designed to be embedded
or referenced as a post-install step. It's lightweight and idempotent,
which makes implementation trivial.

Consider adding a pointer to LOTS in your documentation or as an
optional post-install suggestion. If you'd like a distro-specific
template set, you can reach out as I'm happy to collaborate.

## Support

If you find LOTS useful, consider giving it a ⭐ on
[GitHub](https://github.com/NewMasterDai/LOTS). It helps the project gain
visibility and motivates further development.   

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/NewMasterDai/LOTS/main/lots.sh | bash   
