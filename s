#!/bin/bash
# Searches for the NetID in the student and staff directory 
# Place in your $PATH for easy lookups.
studentdir -full -E $1 && staffdir -full -E $1
