#!/bin/bash

alias update-grub='sudo grub2-mkconfig -o /boot/grub2/grub.cfg'

alias update-grub2='update-grub'

# GRUB legacy update
alias grub-update-legacy='sudo grub-mkconfig -o /boot/grub/grub.cfg'