# Additional clean files
cmake_minimum_required(VERSION 3.16)

if("${CONFIG}" STREQUAL "" OR "${CONFIG}" STREQUAL "")
  file(REMOVE_RECURSE
  "F:\\Project_IDAQclone\\Project_IDAQ\\Software_Space\\TMP451_Space\\TMP451_SYS_Pltfrm\\ps7_cortexa9_0\\standalone_ps7_cortexa9_0\\bsp\\include\\sleep.h"
  "F:\\Project_IDAQclone\\Project_IDAQ\\Software_Space\\TMP451_Space\\TMP451_SYS_Pltfrm\\ps7_cortexa9_0\\standalone_ps7_cortexa9_0\\bsp\\include\\xiltimer.h"
  "F:\\Project_IDAQclone\\Project_IDAQ\\Software_Space\\TMP451_Space\\TMP451_SYS_Pltfrm\\ps7_cortexa9_0\\standalone_ps7_cortexa9_0\\bsp\\include\\xtimer_config.h"
  "F:\\Project_IDAQclone\\Project_IDAQ\\Software_Space\\TMP451_Space\\TMP451_SYS_Pltfrm\\ps7_cortexa9_0\\standalone_ps7_cortexa9_0\\bsp\\lib\\libxiltimer.a"
  )
endif()
