#!/bin/sh
case `sw_vers -productVersion 2>/dev/null` in
  10.10.*) echo yosemite ;;
  10.11.*) echo el_capitan ;;
  10.12.*) echo sierra ;;
  10.13.*) echo high_sierra ;;
  10.14.*) echo mojave ;;
  10.15.*) echo catalina ;;
  11.*) echo big_sur ;;
  *) exit 1 ;;
esac
