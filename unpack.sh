#!/bin/bash
SRC_ISO='regular-rescue-latest-x86_64.iso'
mkdir iso_contents
xorriso -osirrox on -indev ${SRC_ISO} -extract / iso_contents
unsquashfs iso_contents/rescue
